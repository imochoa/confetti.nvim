local M = {}

---@require "confetti.types"

local constants = require("confetti.constants")
local utils = require("confetti.utils")
local hllogic = require("confetti.hllogic")

-- Before:
--
-- function My_utils.get_node_text(node)
--   return table.concat(get_node_text(node), '\n')
-- end
--
-- After:
--
-- function My_utils.get_node_text(node, bufnr)
--   return get_node_text(node, bufnr or 0)
-- end

-- Private vars & fcns
---@type Job[]
local jobs = {} -- Keep track of what has been highlighted
local new_hlgroups = {}
local usable_hl_groups = {}
local current_hl_group_idx = 1
local _fwd_config = {} -- For debugging

--- Augroup name for confetti autocommands
local augroup_name = "ConfettiAutoHighlight"

--- Get the next hl group and update the global tracker
---@return string hl_group
---@private
local next_hl_group = function()
  local hl_group = usable_hl_groups[current_hl_group_idx]
  current_hl_group_idx = current_hl_group_idx % #usable_hl_groups + 1
  return hl_group
end

--- Reload this module (for debugging)
M.reload = function()
  package.loaded["confetti"] = nil
  -- require("confetti").setup({})
  require("confetti").setup(_fwd_config)
  -- TODO: need to store more cache: current idx, usable hl_groups, new_hlgroups
  vim.notify("Reloaded Confetti")
end

--- Re-apply all tracked highlight jobs across visible buffers
---@private
local reapply_highlights = function()
  -- Clear existing highlights from all visible buffers
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local cleared_buffers = {}

  for _, winid in ipairs(windows) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if not cleared_buffers[bufnr] then
      vim.api.nvim_buf_clear_namespace(bufnr, constants.ns_id, 0, -1)
      cleared_buffers[bufnr] = true
    end
  end

  -- Re-run each job
  for _, job in ipairs(jobs) do
    if job.fcn and job.args then
      pcall(job.fcn, unpack(job.args))
    end
  end
end

--- Set up autocommands to reapply highlights on relevant events
---@private
local setup_autocommands = function()
  -- Clear any existing autocommands in our group
  vim.api.nvim_create_augroup(augroup_name, { clear = true })

  -- Reapply when a buffer is displayed in a window (new splits, tabs, etc.)
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
    group = augroup_name,
    callback = function()
      if #jobs > 0 then
        -- Defer to ensure the window/buffer is fully set up
        vim.defer_fn(reapply_highlights, 10)
      end
    end,
    desc = "Confetti: reapply highlights to new windows/buffers",
  })

  -- Reapply after text changes (buffer content shifted)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup_name,
    callback = function()
      if #jobs > 0 then
        -- Debounce slightly to avoid excessive reapplication during rapid edits
        vim.defer_fn(reapply_highlights, 50)
      end
    end,
    desc = "Confetti: reapply highlights after text changes",
  })

  -- Re-setup when colorscheme changes (light/dark switch)
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup_name,
    callback = function()
      -- Only re-setup with fresh colors if user didn't provide custom ones
      local prev_jobs = jobs
      M.setup(_fwd_config)
      -- Restore jobs and reapply them with the new highlight groups
      jobs = prev_jobs
      if #jobs > 0 then
        vim.defer_fn(reapply_highlights, 10)
      end
    end,
    desc = "Confetti: recreate highlight groups when colorscheme changes",
  })
end

--[[
 Function to bind
 --]]
M.highlight_at_cursor = function()
  if #(usable_hl_groups or {}) == 0 then
    -- setup() has not been called or did not create hl groups! Use the defaults
    constants.log("Performing default setup...")

    M.setup()
  end

  local hl_group = next_hl_group()
  constants.log("Using: " .. hl_group)

  -- Go through priorities
  -- (1) Visual selection?
  local job = hllogic.visual_selection(hl_group)
  if job == nil then
    -- (2) treesitter?
    job = hllogic.treesitter(hl_group)
    if job == nil then
      -- (3) Word under cursor?
      job = hllogic.cword(hl_group)
    end
  end

  if job ~= nil then
    table.insert(jobs, job)
    constants.log("Tracked jobs:" .. vim.inspect(jobs))
  else
    vim.notify("No highlighting method passed", vim.log.levels.WARN)
  end
end

--[[
 Clear highlights in the module-specific namespace from all visible buffers
 --]]
M.clear_highlights = function()
  jobs = {}
  -- Get all visible windows and clear highlights from their buffers
  local windows = vim.api.nvim_tabpage_list_wins(0)
  local cleared_buffers = {}

  for _, winid in ipairs(windows) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    -- Only clear once per buffer (in case multiple windows show same buffer)
    if not cleared_buffers[bufnr] then
      vim.api.nvim_buf_clear_namespace(bufnr, constants.ns_id, 0, -1)
      cleared_buffers[bufnr] = true
    end
  end
end

--- Manually reapply all highlights (useful after switching tabs, etc.)
M.reapply = function()
  reapply_highlights()
end

---@class ConfettiConfig
---@field reused_hlgroups string[] List of existing highlight groups to use
---@field colors GuiHighlight[] New highlights to create with a lua interface
---@field log_level number|nil Logging level (vim.log.levels.DEBUG, INFO, WARN, ERROR, OFF). Default: WARN

--   config = {
--   hl_groups = {#hex1,#hex2,hlgroup1}
-- }
---@param config Config
M.setup = function(config)
  -- Reset
  _fwd_config = config
  jobs = {}
  utils.remove_hl_groups(new_hlgroups or {})
  new_hlgroups = {}

  -- handle nil
  config = (config == nil) and {} or config
  config.reused_hlgroups = (config.reused_hlgroups == nil) and {} or config.reused_hlgroups
  config.colors = (config.colors == nil) and {} or config.colors
  -- Set log level (default to WARN if not specified)
  if config.log_level ~= nil then
    constants.log_level = config.log_level
  end
  -- handle empty
  config.colors = (#config.colors == 0) and constants.get_default_colors() or config.colors

  -- Existing groups?
  local reused_hlgroups = {}
  for _, el in ipairs(config.reused_hlgroups) do
    if constants.nvim_global_hl_groups[el] ~= nil then
      -- Was an existing highlight group
      table.insert(reused_hlgroups, el)
    end
  end
  table.sort(reused_hlgroups)

  -- New groups?
  new_hlgroups = utils.create_hl_groups(config.colors)

  -- Concat valid & new hl groups
  usable_hl_groups = reused_hlgroups
  for _, v in pairs(new_hlgroups) do
    table.insert(usable_hl_groups, v)
  end

  if #usable_hl_groups == 0 then
    vim.notify("No hl_groups to use!", vim.log.levels.ERROR)
    return nil
  end

  -- Set up autocommands for auto-reapplication
  setup_autocommands()

  constants.log("Using the following HL groups: " .. vim.inspect(usable_hl_groups))
  return M
end

--- Show all Confetti highlight groups with their color values
M.show_highlights = function()
  print("\n=== Confetti Highlight Groups ===\n")

  local found_any = false
  for i = 1, 50 do
    local group_name = "ConfettiHLGroup" .. i
    if vim.fn.hlexists(group_name) == 1 then
      found_any = true
      local hl = vim.api.nvim_get_hl(0, { name = group_name })
      print(
        string.format(
          "%s: fg=%s bg=%s",
          group_name,
          hl.fg and string.format("#%06x", hl.fg) or "none",
          hl.bg and string.format("#%06x", hl.bg) or "none"
        )
      )
    end
  end

  if not found_any then
    print("No Confetti highlight groups found. Run :lua require('confetti').setup() first.")
  end

  print("\n")
end

--- Create a test buffer showing all Confetti highlights visually
M.test_highlights = function()
  -- Ensure setup has been called
  if #usable_hl_groups == 0 then
    vim.notify("Running setup first...", vim.log.levels.INFO)
    M.setup()
  end

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_name(buf, "Confetti Highlight Test")

  -- Create namespace for highlights
  local ns_id = vim.api.nvim_create_namespace("confetti_test")

  -- Add header
  local lines = {
    "=== Confetti Highlight Groups ===",
    "",
    "This buffer shows all active Confetti highlight groups.",
    "Each line below is highlighted with its corresponding group.",
    "",
  }

  -- Add a line for each highlight group
  for _, group in ipairs(usable_hl_groups) do
    if vim.fn.hlexists(group) == 1 then
      local hl = vim.api.nvim_get_hl(0, { name = group })
      local fg = hl.fg and string.format("#%06x", hl.fg) or "none"
      local bg = hl.bg and string.format("#%06x", hl.bg) or "none"

      local text = string.format("%s  →  fg: %s, bg: %s  ←  Example highlighted text", group, fg, bg)
      table.insert(lines, text)
    end
  end

  -- Add footer
  table.insert(lines, "")
  table.insert(lines, string.format("Total groups: %d", #usable_hl_groups))
  table.insert(lines, "")
  table.insert(lines, "Press 'q' to close this buffer")

  -- Set all lines at once
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights (skip header lines)
  local line_num = 5 -- Start after header
  for _, group in ipairs(usable_hl_groups) do
    if vim.fn.hlexists(group) == 1 then
      vim.api.nvim_buf_add_highlight(buf, ns_id, group, line_num, 0, -1)
      line_num = line_num + 1
    end
  end

  -- Make buffer read-only
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Add keybinding to close with 'q'
  vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = buf, silent = true })

  vim.notify("Showing " .. #usable_hl_groups .. " Confetti highlight groups", vim.log.levels.INFO)
end

return M
