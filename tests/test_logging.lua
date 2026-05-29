-- Test to verify logging level configuration
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/init.lua" })
      child.lua([[M = require('confetti')]])
    end,
    post_once = child.stop,
  },
})

T["logging"] = MiniTest.new_set()

T["logging"]["defaults to WARN level"] = function()
  child.lua([[M.setup()]])
  local log_level = child.lua_get([[require('confetti.constants').log_level]])
  -- vim.log.levels.WARN = 3
  eq(log_level, 3)
end

T["logging"]["accepts DEBUG level"] = function()
  child.lua([[M.setup({ log_level = vim.log.levels.DEBUG })]])
  local log_level = child.lua_get([[require('confetti.constants').log_level]])
  -- vim.log.levels.DEBUG = 1
  eq(log_level, 1)
end

T["logging"]["accepts ERROR level"] = function()
  child.lua([[M.setup({ log_level = vim.log.levels.ERROR })]])
  local log_level = child.lua_get([[require('confetti.constants').log_level]])
  -- vim.log.levels.ERROR = 4
  eq(log_level, 4)
end

T["logging"]["accepts OFF level"] = function()
  child.lua([[M.setup({ log_level = vim.log.levels.OFF })]])
  local log_level = child.lua_get([[require('confetti.constants').log_level]])
  -- vim.log.levels.OFF = 5
  eq(log_level, 5)
end

return T
