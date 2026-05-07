# nvim-run-code

Neovim plugin (Lua version) to execute code based on filetype with development and optimized modes. 
Adapted from `vim-run-code`.

## Installation

### lazy.nvim
```lua
{
    'bonatto/nvim-run-code',
    config = function()
        require('run-code').setup({
            -- your configuration here
        })
    end
}
```

## Default Mappings
- `r`: Execute current file in development mode.
- `R`: Execute current file in optimized mode.

To disable default mappings:
```lua
require('run-code').setup({
    no_default_mappings = true
})
```

## Configuration

Default options:
```lua
require('run-code').setup({
    auto_save = true,
    clear_terminal = true,
    show_feedback = true,
    timeout = 0,
    temp_dir = "/tmp",
    no_default_mappings = false,
    commands = {}, -- User overrides
})
```

## Commands
- `:RunCodeDev`: Run development mode.
- `:RunCodeOpt`: Run optimized mode.
- `:RunCodeSet <ft> <cmd>`: Define custom command for filetype.
- `:RunCodeList`: List supported languages.
- `:RunCodeConfig`: Show current configuration.

## Custom Commands
You can override or add commands in your setup:
```lua
require('run-code').setup({
    commands = {
        python = "python3 %",
        rust = "cargo run"
    }
})
```

Alternatively, use the command:
```vim
:RunCodeSet python "python3 %"
```
