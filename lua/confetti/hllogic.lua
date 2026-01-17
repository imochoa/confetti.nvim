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
---@return boolean
local hl_with_pattern_search = function(regexp, hl_group)
	local bufnr = 0 -- current buffer
	local cursor_pos = vim.api.nvim_win_get_cursor(0) -- remember cursor position
	-- TODO: remember and recover visible screen?

	constants.log("Pattern: <" .. regexp .. ">")
	vim.api.nvim_win_set_cursor(0, { 1, 0 })

	local line_txt
	local start, final
	local lnum, col = 1, 0
	-- local dont_wrap = "W"
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
				-- vim.api.nvim_buf_add_highlight(
				-- 	0, -- bufnr
				-- 	constants.ns_id, -- ns
				-- 	hl_group, -- hl_group
				-- 	lnum - 1, -- line
				-- 	start, -- col_start
				-- 	final -- col_end
				-- )

				local range_clear = vim.hl.range(
					bufnr,
					constants.ns_id,
					hl_group,
					{ lnum - 1, start },
					{ lnum - 1, final },
					{}
				)
				-- vim.api.nvim_buf_set_extmark(
				-- 	0, -- current buffer
				-- 	constants.ns_id,
				-- 	lnum - 1, -- start line
				-- 	start, -- col_start
				-- 	{ -- end_row = start,
				-- 		end_col = final,
				-- 		hl_group = hl_group,
				-- 	}
				-- )

				start = final
			end
		end
		vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
	end
	-- Recover cursor position
	vim.api.nvim_win_set_cursor(0, cursor_pos)
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
---@return boolean ok
local hl_with_treesitter = function(node_text, hl_group)
	local parser = nil
	local status, _ = pcall(function()
		parser = vim.treesitter.get_parser()
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
	-- local curr_node = ts_utils.get_node_at_cursor()
	-- local node_text = vim.treesitter.get_node_text(curr_node, 0)
	local query_text = string.format('((identifier) @node_txt (#eq? @node_txt "%s"))', node_text)
	local query = vim.treesitter.query.parse(lang, query_text)

	local m = false
	for pattern, match, metadata in query:iter_matches(tree:root(), 0) do
		for id, nodes in ipairs(match) do
			local name = query.captures[id]
			-- `node` was captured by the `name` capture in the match
			for _, node in ipairs(nodes) do
				local node_data = metadata[id] -- Node level metadata
				-- ... use the info here ...
				-- local type = node:type() -- type of the captured node
				vim.print(node_data)
				local row1, col1, row2, col2 = node:range() -- range of the capture
				vim.api.nvim_buf_add_highlight(0, constants.ns_id, hl_group, row1, col1, col2)
				m = true
			end
		end
	end
	return m
end

--[[
Function to bind
--]]
---@param hl_group string
---@return Job?
M.treesitter = function(hl_group)
	local node_text = nil
	local status, _ = pcall(function()
		node_text = vim.treesitter.get_node_text(vim.treesitter.get_node({}), 0)
		-- node_text = vim.treesitter.get_node_text(ts_utils.get_node_at_cursor(), 0)
	end)
	if not node_text then
		return nil
	end

	if hl_with_treesitter(node_text, hl_group) then
		return { fcn = hl_with_treesitter, args = { node_text, hl_group } }
	end
	return nil
end
return M
