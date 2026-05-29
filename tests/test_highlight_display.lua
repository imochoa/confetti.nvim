-- Manual test for the new highlight display functions
-- Run with: nvim -u scripts/init.lua -c "luafile tests/test_highlight_display.lua"

local M = require("confetti")

print("\n=== Testing Highlight Display Functions ===\n")

-- Setup first
print("1. Running setup...")
M.setup()
print("   ✓ Setup complete\n")

-- Test show_highlights
print("2. Testing show_highlights()...")
M.show_highlights()
print("   ✓ show_highlights() complete\n")

-- Test test_highlights
print("3. Testing test_highlights()...")
print("   This will create a visual buffer showing all highlight groups")
print("   The buffer should have colored lines and be read-only")
print("   Press 'q' to close the buffer\n")

M.test_highlights()

print("\n=== All tests complete ===")
print("Inspect the buffer above to see the highlight groups visually")
print("Press 'q' to close the buffer\n")
