local M = {}

---@type number
M.ns_id = vim.api.nvim_create_namespace("ConfettiHighlights") -- highlight group for this plugin

---@type table<string,table>
M.nvim_global_hl_groups = vim.api.nvim_get_hl(0, {}) -- Known highlight groups

---@type number
M.log_level = vim.log.levels.WARN -- Default to WARN (less verbose)

--- Log a debug message (only shown if log_level is DEBUG)
---@param txt string
---@returns nil
M.log = function(txt)
  if M.log_level <= vim.log.levels.DEBUG then
    vim.notify("[Confetti] " .. vim.inspect(txt), vim.log.levels.DEBUG)
  end
end
--- Colors optimized for dark backgrounds (vibrant, saturated)
--- Foreground is auto-detected by utils.create_hl_groups based on brightness
M.dark_theme_colors = {
  -- Warm tones
  { guibg = "#ebac23" }, -- golden yellow
  { guibg = "#ff9287" }, -- salmon
  { guibg = "#ff6b6b" }, -- coral red
  { guibg = "#ffa07a" }, -- light salmon
  { guibg = "#ffb347" }, -- pastel orange
  { guibg = "#f4a460" }, -- sandy brown
  { guibg = "#e8a87c" }, -- peach
  { guibg = "#ff8c69" }, -- salmon2
  -- Cool tones
  { guibg = "#008cf9" }, -- bright blue
  { guibg = "#00c6f8" }, -- sky blue
  { guibg = "#5954d6" }, -- indigo
  { guibg = "#7b68ee" }, -- medium slate blue
  { guibg = "#87ceeb" }, -- sky blue light
  { guibg = "#69d2e7" }, -- soft cyan
  { guibg = "#48d1cc" }, -- medium turquoise
  { guibg = "#40e0d0" }, -- turquoise
  -- Greens
  { guibg = "#00bbad" }, -- teal
  { guibg = "#00a76c" }, -- emerald
  { guibg = "#77dd77" }, -- pastel green
  { guibg = "#98fb98" }, -- pale green
  { guibg = "#50c878" }, -- emerald green
  { guibg = "#adff2f" }, -- green yellow
  -- Purples & Pinks
  { guibg = "#d163e6" }, -- orchid
  { guibg = "#b80058" }, -- deep pink
  { guibg = "#da70d6" }, -- orchid light
  { guibg = "#ff69b4" }, -- hot pink
  { guibg = "#dda0dd" }, -- plum
  { guibg = "#c39bd3" }, -- wisteria
  { guibg = "#e6a8d7" }, -- pastel magenta
  { guibg = "#b19cd9" }, -- pastel purple
  -- Neutrals & Misc
  { guibg = "#bdbdbd" }, -- silver
  { guibg = "#d4a574" }, -- tan
  { guibg = "#b24502" }, -- burnt orange
  { guibg = "#878500" }, -- olive
  { guibg = "#006e00" }, -- forest green
  -- Styled variants
  { guibg = "#ffeb3b", bold = true }, -- bold yellow
  { guibg = "#ff4081", italic = true }, -- italic pink
  { guibg = "#18ffff", underline = true }, -- underline cyan
  { guibg = "#b388ff", undercurl = true }, -- undercurl lavender
  { guibg = "#69f0ae", underdotted = true }, -- underdotted mint
  { guibg = "#ff6e40", strikethrough = true }, -- strikethrough orange
}

--- Colors optimized for light backgrounds (muted, pastel, with dark text)
M.light_theme_colors = {
  -- Warm pastels
  { guifg = "#000000", guibg = "#fff176" }, -- soft yellow
  { guifg = "#000000", guibg = "#ffcc80" }, -- light orange
  { guifg = "#000000", guibg = "#ffab91" }, -- light deep orange
  { guifg = "#000000", guibg = "#ef9a9a" }, -- light red
  { guifg = "#000000", guibg = "#ffe082" }, -- light amber
  { guifg = "#000000", guibg = "#ffcdd2" }, -- pink tint
  { guifg = "#000000", guibg = "#f8bbd0" }, -- pink light
  { guifg = "#000000", guibg = "#ffe0b2" }, -- peach cream
  -- Cool pastels
  { guifg = "#000000", guibg = "#90caf9" }, -- light blue
  { guifg = "#000000", guibg = "#80deea" }, -- light cyan
  { guifg = "#000000", guibg = "#81d4fa" }, -- sky blue
  { guifg = "#000000", guibg = "#b3e5fc" }, -- pale blue
  { guifg = "#000000", guibg = "#80cbc4" }, -- light teal
  { guifg = "#000000", guibg = "#b2ebf2" }, -- ice blue
  { guifg = "#000000", guibg = "#b2dfdb" }, -- teal tint
  { guifg = "#000000", guibg = "#84ffff" }, -- bright cyan
  -- Greens
  { guifg = "#000000", guibg = "#a5d6a7" }, -- light green
  { guifg = "#000000", guibg = "#c5e1a5" }, -- lime green
  { guifg = "#000000", guibg = "#dcedc8" }, -- pale lime
  { guifg = "#000000", guibg = "#b9f6ca" }, -- mint
  { guifg = "#000000", guibg = "#69f0ae" }, -- bright mint
  { guifg = "#000000", guibg = "#e6ee9c" }, -- light lime yellow
  -- Purples & Pinks
  { guifg = "#000000", guibg = "#ce93d8" }, -- light purple
  { guifg = "#000000", guibg = "#b39ddb" }, -- light deep purple
  { guifg = "#000000", guibg = "#e1bee7" }, -- lavender
  { guifg = "#000000", guibg = "#d1c4e9" }, -- pale purple
  { guifg = "#000000", guibg = "#f48fb1" }, -- medium pink
  { guifg = "#000000", guibg = "#ea80fc" }, -- bright purple
  { guifg = "#000000", guibg = "#e1bee7" }, -- soft violet
  { guifg = "#000000", guibg = "#f0bbf0" }, -- pastel magenta
  -- Neutrals & Misc
  { guifg = "#000000", guibg = "#bcaaa4" }, -- light brown
  { guifg = "#000000", guibg = "#eeeeee" }, -- light grey
  { guifg = "#000000", guibg = "#d7ccc8" }, -- warm grey
  { guifg = "#000000", guibg = "#cfd8dc" }, -- blue grey
  { guifg = "#000000", guibg = "#f0f4c3" }, -- pale yellow green
  -- Styled variants
  { guifg = "#000000", guibg = "#fff59d", bold = true }, -- bold pale yellow
  { guifg = "#000000", guibg = "#f48fb1", italic = true }, -- italic pink
  { guifg = "#000000", guibg = "#80deea", underline = true }, -- underline cyan
  { guifg = "#000000", guibg = "#b39ddb", undercurl = true }, -- undercurl purple
  { guifg = "#000000", guibg = "#a5d6a7", underdotted = true }, -- underdotted green
  { guifg = "#000000", guibg = "#ffab91", strikethrough = true }, -- strikethrough peach
}

--- Returns the appropriate default color palette based on the current background setting
---@return GuiHighlight[]
M.get_default_colors = function()
  if vim.o.background == "light" then
    return M.light_theme_colors
  end
  return M.dark_theme_colors
end

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
