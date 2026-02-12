local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
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

-- Test setup functionality
T["setup"] = MiniTest.new_set()

T["setup"]["works without config"] = function()
  -- Should not error when called without arguments
  child.lua([[M.setup()]])
  -- Check that usable_hl_groups were created
  local result = child.lua_get([[vim.fn.hlexists('ConfettiHLGroup1')]])
  eq(result, 1) -- highlight group should exist
end

T["setup"]["creates default highlight groups"] = function()
  child.lua([[M.setup()]])
  -- Check that multiple highlight groups were created
  local count = 0
  for i = 1, 20 do
    local exists = child.lua_get(string.format([[vim.fn.hlexists('ConfettiHLGroup%d')]], i))
    if exists == 1 then
      count = count + 1
    end
  end
  expect.no_equality(count, 0) -- At least some groups should exist
end

T["setup"]["accepts custom colors"] = function()
  child.lua([[
    M.setup({
      colors = {
        { guifg = "black", guibg = "red" },
        { guifg = "white", guibg = "blue" }
      }
    })
  ]])
  -- Should create 2 highlight groups
  local exists1 = child.lua_get([[vim.fn.hlexists('ConfettiHLGroup1')]])
  local exists2 = child.lua_get([[vim.fn.hlexists('ConfettiHLGroup2')]])
  eq(exists1, 1)
  eq(exists2, 1)
end

-- Test highlight_at_cursor functionality
T["highlight_at_cursor"] = MiniTest.new_set()

T["highlight_at_cursor"]["runs without error on word"] = function()
  child.lua([[
    M.setup()
    -- Create a buffer with some text
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'test word test', 'another test line'})
    vim.api.nvim_win_set_cursor(0, {1, 0})
  ]])

  -- Should not error
  child.lua([[M.highlight_at_cursor()]])
  -- If we got here, no error occurred
  eq(1, 1)
end

T["highlight_at_cursor"]["highlights cword"] = function()
  child.lua([[
    M.setup()
    -- Create a buffer with repeated word
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'test word test', 'test again'})
    vim.api.nvim_win_set_cursor(0, {1, 0}) -- cursor on 'test'
    M.highlight_at_cursor()
  ]])

  -- Check that highlights were added
  child.lua([[
    _G.ns_id = require('confetti.constants').ns_id
    _G.marks = vim.api.nvim_buf_get_extmarks(0, _G.ns_id, 0, -1, {})
  ]])
  local mark_count = child.lua_get([[#_G.marks]])
  expect.no_equality(mark_count, 0) -- Should have highlights
end

-- Test clear_highlights functionality
T["clear_highlights"] = MiniTest.new_set()

T["clear_highlights"]["clears highlights"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'test word test', 'another line'})
    vim.api.nvim_win_set_cursor(0, {1, 0})
    M.highlight_at_cursor()
  ]])

  -- Now clear
  child.lua([[M.clear_highlights()]])

  -- Check that highlights were removed
  child.lua([[
    _G.ns_id = require('confetti.constants').ns_id
    _G.marks = vim.api.nvim_buf_get_extmarks(0, _G.ns_id, 0, -1, {})
  ]])
  local mark_count = child.lua_get([[#_G.marks]])
  eq(mark_count, 0)
end

-- Test module structure
T["module structure"] = MiniTest.new_set()

T["module structure"]["exports setup function"] = function()
  local has_setup = child.lua_get([[type(M.setup)]])
  eq(has_setup, "function")
end

T["module structure"]["exports highlight_at_cursor function"] = function()
  local has_fn = child.lua_get([[type(M.highlight_at_cursor)]])
  eq(has_fn, "function")
end

T["module structure"]["exports clear_highlights function"] = function()
  local has_fn = child.lua_get([[type(M.clear_highlights)]])
  eq(has_fn, "function")
end

T["module structure"]["exports reload function"] = function()
  local has_fn = child.lua_get([[type(M.reload)]])
  eq(has_fn, "function")
end

-- Test utility functions
T["utils module"] = MiniTest.new_set()

T["utils module"]["can be required"] = function()
  child.lua([[_G.utils = require('confetti.utils')]])
  local can_require = child.lua_get([[_G.utils ~= nil]])
  eq(can_require, true)
end

T["utils module"]["create_hl_groups function exists"] = function()
  child.lua([[_G.utils = require('confetti.utils')]])
  local has_fn = child.lua_get([[type(_G.utils.create_hl_groups)]])
  eq(has_fn, "function")
end

T["utils module"]["create_hl_groups creates groups"] = function()
  child.lua([[
    _G.utils = require('confetti.utils')
    _G.groups = _G.utils.create_hl_groups({{ guifg = "black", guibg = "red" }})
  ]])
  local group_count = child.lua_get([[#_G.groups]])
  local exists = child.lua_get([[vim.fn.hlexists(_G.groups[1])]])
  expect.no_equality(group_count, 0) -- Should have groups
  eq(exists, 1)
end

-- Test constants module
T["constants module"] = MiniTest.new_set()

T["constants module"]["has namespace id"] = function()
  child.lua([[_G.constants = require('confetti.constants')]])
  local has_ns = child.lua_get([[type(_G.constants.ns_id)]])
  eq(has_ns, "number")
end

T["constants module"]["has default colors"] = function()
  child.lua([[_G.constants = require('confetti.constants')]])
  local has_colors = child.lua_get([[type(_G.constants.default_colors)]])
  local color_count = child.lua_get([[#_G.constants.default_colors]])
  eq(has_colors, "table")
  expect.no_equality(color_count, 0) -- Should have colors
end

-- Test hllogic module
T["hllogic module"] = MiniTest.new_set()

T["hllogic module"]["cword function exists"] = function()
  child.lua([[_G.hllogic = require('confetti.hllogic')]])
  local has_fn = child.lua_get([[type(_G.hllogic.cword)]])
  eq(has_fn, "function")
end

T["hllogic module"]["treesitter function exists"] = function()
  child.lua([[_G.hllogic = require('confetti.hllogic')]])
  local has_fn = child.lua_get([[type(_G.hllogic.treesitter)]])
  eq(has_fn, "function")
end

T["hllogic module"]["visual_selection function exists"] = function()
  child.lua([[_G.hllogic = require('confetti.hllogic')]])
  local has_fn = child.lua_get([[type(_G.hllogic.visual_selection)]])
  eq(has_fn, "function")
end

-- Test treesitter with Lua code
T["treesitter functionality"] = MiniTest.new_set()

T["treesitter functionality"]["handles lua file with function keyword"] = function()
  child.lua([[
    M.setup()
    -- Create a Lua buffer with 'function' keyword
    vim.api.nvim_buf_set_option(0, 'filetype', 'lua')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'local function test()',
      '  return true',
      'end'
    })
    vim.api.nvim_win_set_cursor(0, {1, 15}) -- cursor on 'test'
    _G.test_result = pcall(M.highlight_at_cursor)
  ]])

  -- Should not error with special keyword
  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

T["treesitter functionality"]["handles identifiers with special chars in context"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_option(0, 'filetype', 'lua')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'local value = "quoted string"',
      'local value = 123'
    })
    vim.api.nvim_win_set_cursor(0, {1, 6}) -- cursor on 'value'
    _G.test_result = pcall(M.highlight_at_cursor)
  ]])

  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

T["treesitter functionality"]["handles code with parentheses"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_option(0, 'filetype', 'lua')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      'print("hello")',
      'print(123)'
    })
    vim.api.nvim_win_set_cursor(0, {1, 0}) -- cursor on 'print'
    _G.test_result = pcall(M.highlight_at_cursor)
  ]])

  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

T["treesitter functionality"]["gracefully fails without treesitter parser"] = function()
  child.lua([[
    M.setup()
    -- Use a filetype that likely doesn't have a parser
    vim.api.nvim_buf_set_option(0, 'filetype', 'unknownfiletype999')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'test word test'})
    vim.api.nvim_win_set_cursor(0, {1, 0})
    _G.test_result = pcall(M.highlight_at_cursor)
  ]])

  -- Should not crash, just fall back to cword
  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

-- Test edge cases
T["edge cases"] = MiniTest.new_set()

T["edge cases"]["handles empty buffer"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
    vim.api.nvim_win_set_cursor(0, {1, 0})
    _G.test_result = pcall(function() M.highlight_at_cursor() end)
  ]])

  -- Should not crash
  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

T["edge cases"]["handles single line buffer"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'single'})
    vim.api.nvim_win_set_cursor(0, {1, 0})
  ]])

  -- Should not crash
  child.lua([[M.highlight_at_cursor()]])
  eq(1, 1)
end

T["edge cases"]["handles buffer with no word under cursor"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'   ', 'spaces only'})
    vim.api.nvim_win_set_cursor(0, {1, 0})
    _G.test_result = pcall(function() M.highlight_at_cursor() end)
  ]])

  -- Should not crash even if no word
  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

T["edge cases"]["handles last line highlighting"] = function()
  child.lua([[
    M.setup()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {'first', 'last'})
    vim.api.nvim_win_set_cursor(0, {2, 0}) -- cursor on last line
    _G.test_result = pcall(M.highlight_at_cursor)
  ]])

  -- Should not crash (this was the original bug)
  local ok = child.lua_get([[_G.test_result]])
  eq(ok, true)
end

return T
