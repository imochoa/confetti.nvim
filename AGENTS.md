# AGENTS.md

This document provides guidelines for AI coding agents working on the confetti.nvim plugin.

## Overview

confetti.nvim is a Neovim plugin that highlights words with colorful backgrounds, creating a "party-like" visual effect. It's written in Lua and uses the mini.nvim testing framework.

## Project Structure

```
confetti.nvim/
├── lua/confetti/          # Main plugin source code
│   ├── init.lua          # Entry point, setup, and public API
│   ├── types.lua         # Type annotations (using LuaLS format)
│   ├── constants.lua     # Namespace, log levels, default colors
│   ├── utils.lua         # Utility functions (color conversion, hl group creation)
│   └── hllogic.lua       # Highlighting logic (visual, treesitter, cword)
├── tests/                # Test files
│   └── test_example.lua  # Example tests using mini.test
├── scripts/
│   └── init.lua          # Test initialization script
├── deps/                 # Git dependencies (mini.nvim)
├── doc/                  # Generated documentation
├── justfile              # Task runner commands
├── .stylua.toml          # Code formatting config
└── .pre-commit-config.yaml # Git hooks config

```

## Build, Test & Development Commands

### Using Just (preferred)

```bash
# List all available commands
just

# Setup dependencies (mini.nvim, mini.doc)
just setup

# Run all tests
just test-all

# Run a single test file
just test-file ./tests/test_example.lua
just test-file file=./tests/test_example.lua

# Generate documentation
just docs

# Format justfile
just fmt-just
```

### Manual Commands

```bash
# Run all tests
nvim --headless --noplugin -u "./scripts/init.lua" -c "lua MiniTest.run()"

# Run single test file
nvim --headless --noplugin -u "./scripts/init.lua" -c "lua MiniTest.run_file('./tests/test_example.lua')"

# Generate docs
nvim --headless --noplugin -u "./scripts/init.lua" -c "lua require('mini.doc').generate()"
nvim --headless --noplugin -u "./scripts/init.lua" -c ":helptags ./doc"
```

### Code Quality

```bash
# Format Lua code (installed via pre-commit or cargo)
stylua .

# Run pre-commit hooks
pre-commit run --all-files
```

## Code Style Guidelines

### Formatting

- **Indentation**: 2 spaces (not tabs)
- **Line width**: 120 characters maximum
- **Line endings**: Unix (LF)
- **Quote style**: Auto-prefer double quotes
- **Function calls**: Always use parentheses (no_call_parentheses = false)
- **Formatter**: StyLua (config in `.stylua.toml`)

### Imports

- Place `require()` statements at the top of modules
- Store required modules in local variables
- Use relative module paths: `require("confetti.utils")` not `require("utils")`
- Order: constants first, then utilities, then logic modules

Example:
```lua
local M = {}

local constants = require("confetti.constants")
local utils = require("confetti.utils")
local hllogic = require("confetti.hllogic")
```

### Module Pattern

- Use the standard Neovim Lua module pattern
- Declare `local M = {}` at the top
- Define private functions/variables as `local` before the module table
- Export public functions via the module table
- Return the module table at the end

Example:
```lua
local M = {}

-- Private function
local private_helper = function()
  -- ...
end

-- Public API
M.public_function = function()
  -- ...
end

return M
```

### Type Annotations

- Use LuaLS (Lua Language Server) annotations format
- Define types in `types.lua` with `---@meta` directive
- Use `---@class`, `---@field`, `---@param`, `---@return`, `---@type`
- Mark private functions with `---@private`
- Use exact classes when appropriate: `---@class (exact) Config`

Example:
```lua
---@class GuiHighlight
---@field guifg string|nil Text color
---@field guibg string|nil Background color

---@param highlights GuiHighlight[]
---@return string[] new_hl_groups
M.create_hl_groups = function(highlights)
  -- ...
end
```

### Naming Conventions

- **Modules**: lowercase with underscores (e.g., `hllogic.lua`)
- **Variables**: snake_case (e.g., `current_hl_group_idx`, `hl_group`)
- **Functions**: snake_case (e.g., `highlight_at_cursor`, `clear_highlights`)
- **Private functions**: prefix with underscore or make local (e.g., `local next_hl_group`)
- **Constants**: UPPER_SNAKE_CASE or regular case if in constants module
- **Classes/Types**: PascalCase (e.g., `GuiHighlight`, `ConfettiConfig`)
- **Highlight groups**: PascalCase with plugin prefix (e.g., `ConfettiHLGroup1`)

### Error Handling

- Use `pcall()` for operations that may fail (e.g., treesitter operations)
- Return `nil` from functions when operations fail gracefully
- Use `vim.notify()` for user-facing messages with appropriate log levels
- Use `constants.log()` for debug messages (controlled by `constants.log_level`)

Example:
```lua
local status, _ = pcall(function()
  parser = vim.treesitter.get_parser()
end)

if status == false or parser == nil then
  return nil
end
```

### Comments

- Use `---` for documentation comments (LuaLS format)
- Use `--` for inline/explanatory comments
- Use `--[[  ]]` for multi-line block comments
- Document all public functions with params and return types
- Explain non-obvious logic with inline comments

### Vim API Usage

- Use `vim.api.*` for lower-level Neovim API calls
- Use `vim.fn.*` for Vim functions
- Use `vim.cmd()` for Ex commands (prefer API when available)
- Prefer `vim.notify()` over `print()` for user messages
- Use namespaces for highlights: `vim.api.nvim_create_namespace()`

### Table Operations

- Use `ipairs()` for array-like tables (sequential indices)
- Use `pairs()` for dictionary-like tables (any keys)
- Use `table.insert()` to add elements to arrays
- Initialize tables appropriately: `{}` for empty, `{1, 2, 3}` for arrays

### Testing

- Use mini.test framework (similar to Jest/RSpec)
- Create test sets with `MiniTest.new_set()`
- Use child Neovim processes for isolated testing
- Structure tests with hooks: `pre_case`, `post_case`, `pre_once`, `post_once`
- Use `eq()` for equality assertions, `expect()` for general expectations

Example:
```lua
local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/init.lua" })
      child.lua([[M = require('confetti')]])
    end,
    post_once = child.stop,
  },
})

T["in child"]["works"] = function()
  eq(child.lua_get([[M.add(2, 3)]]), 5)
end
```

## Pre-commit Hooks

The repository uses pre-commit hooks (`.pre-commit-config.yaml`):
- YAML/JSON/TOML/XML validation
- Mixed line ending detection
- Trailing whitespace removal
- End-of-file fixer
- Large file detection (max 500KB)
- StyLua formatting (v2.3.1)

Always run `pre-commit run --all-files` before committing.

## Documentation

- Documentation is generated from source code using mini.doc
- Use special comment formats recognized by mini.doc
- Regenerate docs after API changes: `just docs`
- Help tags are automatically generated in `./doc`

## Development Workflow

1. Make code changes in `lua/confetti/`
2. Format code: `stylua .`
3. Run tests: `just test-all`
4. Update docs if needed: `just docs`
5. Commit with descriptive messages
6. Pre-commit hooks run automatically

## Plugin Reload

For live development, use the reload function:
```lua
require("confetti").reload()
```

Or bind it to a key:
```lua
vim.keymap.set("n", "<leader>cr", function()
  require("confetti").reload()
end, { desc = "Reload confetti plugin" })
```

## Important Notes

- The plugin uses a single namespace for all highlights: `ConfettiHighlights`
- Highlight groups are created dynamically based on config
- Default colors use a scientifically optimized palette (see constants.lua)
- The module maintains internal state (jobs, hl groups, indices)
- Setup must be called before using highlight functions
