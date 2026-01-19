---@meta

---@class (exact) Config
---@field x number
---@field y number

---@class GuiHighlight More info with 'help: highlight', 'help: highlight-args'
---@field guifg string|nil Text color (eg. "white", "#a89984" )
---@field guibg string|nil Background color (eg. "black", "#d79921" )
---@field altfont boolean|nil Tui highlight arg
---@field bold boolean|nil  Tui highlight arg
---@field inverse boolean|nil Flips bg & fg colors
---@field italic boolean|nil  Tui highlight arg
---@field nocombine boolean|nil  Tui highlight arg
---@field standout boolean|nil  Tui highlight arg
---@field strikethrough boolean|nil  Tui highlight arg
---@field undercurl boolean|nil  Tui highlight arg
---@field underdashed boolean|nil  Tui highlight arg
---@field underdotted boolean|nil  Tui highlight arg
---@field underdouble boolean|nil  Tui highlight arg
---@field underline boolean|nil  Tui highlight arg

---@class Job More info with 'help: highlight', 'help: highlight-args'
---@field fcn function what to call
---@field args string|nil

---@alias uint8 number (0-255) integers

---@alias hexcolor string Hex color string, eg. "#aabbcc"

---@alias hl_group string Named highlight group
