-- Test script to verify treesitter highlighting works in real scenarios
-- Run with: nvim --headless -u scripts/init.lua -c "luafile tests/manual_treesitter_test.lua"

local M = require("confetti")
M.setup()

print("\n=== Manual Treesitter Test ===\n")

-- Test 1: Simple Lua file
print("Test 1: Simple Lua identifier")
vim.api.nvim_buf_set_option(0, "filetype", "lua")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "local test = 1",
  "local test = 2",
  "print(test)",
})
vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- cursor on 'test'

local ok1, err1 = pcall(M.highlight_at_cursor)
if ok1 then
  print("✓ Test 1 passed: Simple identifier")
else
  print("✗ Test 1 failed:", err1)
end

-- Test 2: Function keyword
vim.cmd("enew!")
print("\nTest 2: Function keyword")
vim.api.nvim_buf_set_option(0, "filetype", "lua")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "function test()",
  "  return true",
  "end",
  "function another()",
})
vim.api.nvim_win_set_cursor(0, { 1, 9 }) -- cursor on first 'test'

local ok2, err2 = pcall(M.highlight_at_cursor)
if ok2 then
  print("✓ Test 2 passed: Function keyword")
else
  print("✗ Test 2 failed:", err2)
end

-- Test 3: Identifier with special chars nearby
vim.cmd("enew!")
print("\nTest 3: Identifier with special chars nearby")
vim.api.nvim_buf_set_option(0, "filetype", "lua")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  'local value = "string"',
  "print(value)",
  'value = value .. "more"',
})
vim.api.nvim_win_set_cursor(0, { 1, 6 }) -- cursor on 'value'

local ok3, err3 = pcall(M.highlight_at_cursor)
if ok3 then
  print("✓ Test 3 passed: Special chars nearby")
else
  print("✗ Test 3 failed:", err3)
end

-- Test 4: No treesitter (fallback to cword)
vim.cmd("enew!")
print("\nTest 4: No treesitter parser (should fallback)")
vim.api.nvim_buf_set_option(0, "filetype", "unknownlang999")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "word word word",
})
vim.api.nvim_win_set_cursor(0, { 1, 0 })

local ok4, err4 = pcall(M.highlight_at_cursor)
if ok4 then
  print("✓ Test 4 passed: Fallback to cword")
else
  print("✗ Test 4 failed:", err4)
end

-- Test 5: Complex nested structure
vim.cmd("enew!")
print("\nTest 5: Complex nested structure")
vim.api.nvim_buf_set_option(0, "filetype", "lua")
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "local function process(data)",
  "  if data then",
  "    return data.value",
  "  end",
  "  return nil",
  "end",
})
vim.api.nvim_win_set_cursor(0, { 1, 15 }) -- cursor on 'process'

local ok5, err5 = pcall(M.highlight_at_cursor)
if ok5 then
  print("✓ Test 5 passed: Complex structure")
else
  print("✗ Test 5 failed:", err5)
end

print("\n=== All manual tests completed ===\n")

-- Quit
vim.cmd("qall!")
