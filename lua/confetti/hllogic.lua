local M = {}

local constants = require("confetti.constants")

---@require "confetti.types"

-- TODO:use jobs
-- TODO: return nil|Job

--- default highlighting logic, should always work
--- Only works on 1 line!
--- Using both regexp matching to find lines and literal text in lua...
---
---     vim.fn.search -> search for pattern, return line number. 'n' flag to not move cursor
---     vim.fn.getline -> get contents of line
---     vim.fn.matchlist -> search for pattern in String, return list of matches, using capture groups
---
---     # EXAMPLE
---     local defaults = vim.fn.matchlist(vim.fn.getline(vim.fn.search('^defaults:', 'n')), '^defaults:\\s*\\(.*\\)$')[2]
---     defaults = defaults and ' -d '..defaults or ''
---
---     vim.bo.makeprg = 'pandoc' .. defaults .. ' -o "%:p:r.pdf" "%:p"'
---     vim.bo.errorformat = '%f, line %l: %m' -- TODO
---@param regexp string Regular expression for vim.fn.searchpos
---@param hl_group string
---@param bufnr number Buffer number to highlight in
---@param winid number Window ID to use for searching
---@return boolean
local hl_with_pattern_search_in_buffer = function(regexp, hl_group, bufnr, winid)
  local original_win = vim.api.nvim_get_current_win()

  -- Switch to the target window temporarily to perform search
  vim.api.nvim_set_current_win(winid)

  local cursor_pos = vim.api.nvim_win_get_cursor(winid) -- remember cursor position

  constants.log("Pattern: <" .. regexp .. ">")
  vim.api.nvim_win_set_cursor(winid, { 1, 0 })

  local line_txt
  local start, final
  local lnum, col = 1, 0
  -- 'n'	do Not move the cursor
  -- 'W'	don't Wrap around the end of the file
  local search_flags = "W"
  while (lnum > 0) or (col > 0) do
    lnum, col = unpack(vim.fn.searchpos(regexp, search_flags))
    line_txt = vim.fn.getline(lnum)
    final = 0
    while final ~= -1 do
      _, start, final = unpack(vim.fn.matchstrpos(line_txt, regexp, start))
      if start ~= -1 and final ~= -1 then
        vim.hl.range(bufnr, constants.ns_id, hl_group, { lnum - 1, start }, { lnum - 1, final }, {})
        start = final
      end
    end
    -- Move cursor to next line, but check bounds first
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if lnum + 1 <= line_count then
      vim.api.nvim_win_set_cursor(winid, { lnum + 1, 0 })
    end
  end
  -- Recover cursor position
  vim.api.nvim_win_set_cursor(winid, cursor_pos)

  -- Return to original window
  vim.api.nvim_set_current_win(original_win)

  return true
end

--- Wrapper that applies highlighting to all visible windows
---@param regexp string Regular expression for vim.fn.searchpos
---@param hl_group string
---@return boolean
local hl_with_pattern_search = function(regexp, hl_group)
  -- Get all visible windows in the current tabpage
  local windows = vim.api.nvim_tabpage_list_wins(0)

  for _, winid in ipairs(windows) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    -- Only highlight in normal buffers (skip special buffers)
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buftype == "" then
      hl_with_pattern_search_in_buffer(regexp, hl_group, bufnr, winid)
    end
  end

  return true
end

--- Visual selection
---@param hl_group hl_group
---@return Job?
M.visual_selection = function(hl_group)
  if vim.api.nvim_get_mode().mode ~= "v" then
    -- Not in visual mode
    return nil
  end
  -- Get visual selection (see https://www.davekuhlman.org/nvim-lua-info-notes.html)
  -- CURRENT visual selection between v .
  -- Last visual selection is between < >
  local _, line1, col1, _ = unpack(vim.fn.getpos("v"))
  local _, line2, col2, _ = unpack(vim.fn.getpos("."))
  -- Looks good actually, but could use cursor_pos?

  -- Do we need to sort?
  if line1 >= line2 and col1 > col2 then
    local auxl, auxc = unpack({ line1, col1 })
    line1, col1 = unpack({ line2, col2 })
    line2, col2 = unpack({ auxl, auxc })
  end
  -- local tt = vim.api.nvim_buf_get_text(0, ls-1, cs-1, le-1, ce, {})
  --
  -- Use the line locations to retrieve the text in the selection/range.
  -- The result is a table (array) containing one element for each line

  -- register type "c""v" charwise "l""V"linewise "b"blockwise-visual
  local charwise = "c"
  local region = vim.region(0, { line1, col1 }, { line2, col2 }, charwise, true)
  local text = ""
  for linenr, cols in pairs(region) do
    local buffer_text_tbl = vim.api.nvim_buf_get_text(0, linenr - 1, cols[1] - 1, linenr - 1, cols[2] - 1, {})
    -- Only ever one line, so [1] is fine
    text = text .. buffer_text_tbl[1]
  end
  -- local selected_lines = vim.api.nvim_buf_get_lines(0, line1 - 1, end_line, true)
  -- local selected_text = table.concat(selected_lines, "\n")
  -- TODO: trim?
  -- vim.fn.trim(text, mask?, dir?)
  if #text == 0 then
    return nil
  end
  constants.log("Visual selection: <" .. text .. ">")
  local regexp = text
  if hl_with_pattern_search(regexp, hl_group) then
    return { fcn = hl_with_pattern_search, args = { regexp, hl_group } }
  end
  return nil
end

--- default highlighting logic, should always work
--- TODO: try builtin.grep_string() Default result is current word
--- local current_word = require("telescope.builtin").grep_string()
---@param hl_group string
---@return Job?
M.cword = function(hl_group)
  ---@type string
  local current_word = vim.call("expand", "<cword>") ---@diagnostic disable-line: param-type-mismatch,assign-type-mismatch
  constants.log("Current word: <" .. current_word .. ">")
  -- local regexp = "\\W\\zs" .. current_word .. "\\ze\\W"
  -- local regexp = "\\s\\zs" .. current_word .. "\\ze\\s"
  -- But it will still miss vi followed by the punctuation or at the end of the line/file. The right way is to put special word boundary symbols "\<" and "\>" around vi.
  -- s:\<vi\>:VIM:g
  local regexp = "\\<" .. current_word .. "\\>"
  constants.log("regexp: <" .. regexp .. ">")
  if hl_with_pattern_search(regexp, hl_group) then
    return { fcn = hl_with_pattern_search, args = { regexp, hl_group } }
  end
  return nil
end

---TODO: input?
---@param node_text string
---@param hl_group string
---@param bufnr number Buffer number to highlight in
---@return boolean ok
local hl_with_treesitter_in_buffer = function(node_text, hl_group, bufnr)
  local parser = nil
  local status, _ = pcall(function()
    parser = vim.treesitter.get_parser(bufnr)
  end)

  if status == false or parser == nil then
    return false
  end

  local tree = parser:parse()[1]
  if not tree then
    return false
  end
  local lang = parser:lang()
  if not lang then
    return false
  end

  -- Build a safe query without dynamic content in the predicate
  -- We'll filter matches programmatically instead
  local query_text = "(identifier) @node_txt"
  local ok, query = pcall(vim.treesitter.query.parse, lang, query_text)

  if not ok or not query then
    return false
  end

  local m = false
  for pattern, match, metadata in query:iter_matches(tree:root(), bufnr) do
    -- match is an array of captured nodes
    for id, node in ipairs(match) do
      -- Validate node exists and has the range method
      if node and type(node.range) == "function" then
        -- Get the text of this identifier node safely
        local ok, captured_text = pcall(vim.treesitter.get_node_text, node, bufnr)

        if ok and captured_text then
          -- Only highlight if it matches our target node_text
          if captured_text == node_text then
            local row1, col1, row2, col2 = node:range()
            vim.api.nvim_buf_add_highlight(bufnr, constants.ns_id, hl_group, row1, col1, col2)
            m = true
          end
        end
      end
    end
  end
  return m
end

--- Wrapper that applies treesitter highlighting to all visible windows
---@param node_text string
---@param hl_group string
---@return boolean ok
local hl_with_treesitter = function(node_text, hl_group)
  -- Get all visible windows in the current tabpage
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local any_success = false

  for _, winid in ipairs(windows) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    -- Only highlight in normal buffers (skip special buffers)
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    if buftype == "" then
      local success = hl_with_treesitter_in_buffer(node_text, hl_group, bufnr)
      any_success = any_success or success
    end
  end

  return any_success
end

--[[
Function to bind
--]]
---@param hl_group string
---@return Job?
M.treesitter = function(hl_group)
  local node_text = nil
  local status, result = pcall(function()
    local node = vim.treesitter.get_node({})
    if not node then
      return nil
    end
    return vim.treesitter.get_node_text(node, 0)
  end)

  if not status or not result then
    return nil
  end

  node_text = result

  -- Validate node_text is not empty or just whitespace
  if not node_text or node_text:match("^%s*$") then
    return nil
  end

  local success = hl_with_treesitter(node_text, hl_group)
  if success then
    return { fcn = hl_with_treesitter, args = { node_text, hl_group } }
  end
  return nil
end
return M
