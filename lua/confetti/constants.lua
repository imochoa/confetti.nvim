local M = {}

---@type number
M.ns_id = vim.api.nvim_create_namespace("ConfettiHighlights") -- highlight group for this plugin
---@type table<string,table>
M.nvim_global_hl_groups = vim.api.nvim_get_hl(0, {}) -- Known highlight groups
---@type vim.log.levels
M.log_level = vim.log.levels.DEBUG
-- M.log_level = vim.log.levels.INFO
-- M.default_colors = {
-- 	{ guifg = "black", guibg = "white" },
-- 	{ guifg = "black", guibg = "magenta", altfont = true },
-- 	{ guifg = "black", guibg = "lime", bold = true },
-- 	{ guifg = "black", guibg = "yellow", italic = true },
-- 	{ guifg = "black", guibg = "red", nocombine = true }, -- what does nocombine do?
-- 	{ guifg = "black", guibg = "darkviolet", standout = true },
-- 	{ guifg = "black", guibg = "chocolate", strikethrough = true },
-- 	{ guifg = "black", guibg = "thistle", undercurl = true },
-- 	{ guifg = "black", guibg = "orangered", underdashed = true },
-- 	{ guifg = "black", guibg = "greenyellow", underdotted = true },
-- 	{ guifg = "black", guibg = "acqua", underdouble = true },
-- 	{ guifg = "black", guibg = "hotpink", underline = true },
-- }
---@param txt string
---@returns nil
M.log = function(txt)
	vim.notify(vim.inspect(txt), M.log_level)
end
M.default_colors = {
	{ guibg = "#ebac23" },
	{ guibg = "#b80058" },
	{ guibg = "#008cf9" },
	{ guibg = "#006e00" },
	{ guibg = "#00bbad" },
	{ guibg = "#d163e6" },
	{ guibg = "#b24502" },
	{ guibg = "#ff9287" },
	{ guibg = "#5954d6" },
	{ guibg = "#00c6f8" },
	{ guibg = "#878500" },
	{ guibg = "#00a76c" },
	{ guibg = "#bdbdbd" },
}

-- https://tsitsul.in/blog/coloropt/
-- 							*tui-colors*
-- Nvim uses 256 colours by default, ignoring |terminfo| for most terminal types,
-- including "linux" (whose virtual terminals have had 256-colour support since
-- 4.8) and anything claiming to be "xterm".  Also when $COLORTERM or $TERM
-- contain the string "256".

-- named colors
-- From the help for 'termguicolors':
--
--     Note that the cterm attributes are still used, not the gui ones.
--
-- Read more:
--
--     :h highlight-args
--     :h cterm-colors

-- https://upload.wikimedia.org/wikipedia/commons/e/e7/SVG1.1_Color_Swatch.svg

return M
