# nvim-run-code

A context-aware, filetype-based execution engine for Neovim, written in Lua. It allows you to compile, run, and test source code directly from the editor using Neovim's built-in terminal emulator, native shell execution, or an external `tmux` pane. The plugin supports multiple execution profiles (development, optimized, and test) and utilizes a custom placeholder expansion system to safely handle file paths.

## Features

* **Execution Modes:** Supports three distinct execution profiles:
* *Dev:* Default execution. Compiles or runs the code with standard flags.
* *Opt:* Compiles or runs the code with performance optimization flags (e.g., `-O2`, `-O3`, `--release`).
* *Test:* Executes the testing suite or test command associated with the current filetype (e.g., `cargo test`, `pytest`, `make test`).


* **Placeholder Expansion:** Commands are defined as string templates. Vim-style filename modifiers (e.g., `%`, `%:r`, `%:h`) are safely shell-escaped before execution. Environment variables and shell substitutions (`$(...)`) are ignored by the internal parser and passed directly to the shell.
* **Dynamic Command Generation:** Commands can be defined as static strings or dynamic Lua functions evaluated at runtime. For example, the default C/C++ generators detect Makefiles and specific headers (like `llvm/`) to adapt compilation flags automatically.
* **Execution Backends:** Commands are wrapped in `sh -c` for POSIX compliance. Supported backends include:
* *Terminal:* Opens a Neovim split window and runs the command using the `:terminal` emulator.
* *Tmux:* Spawns a new tmux pane (50% horizontal split by default) and sends the command via `tmux send-keys`.
* *Bang:* Falls back to Vim's native `:!` command.



## Installation

Install using your preferred package manager.

**lazy.nvim:**

```lua
{
    "fibonatto/nvim-run-code",
    config = function()
        require("runcode").setup()
    end
}

```

**packer.nvim:**

```lua
use {
    "fibonatto/nvim-run-code",
    config = function()
        require("runcode").setup()
    end
}

```

## Configuration

To override default settings, pass a table to the `setup` function. The default configuration is shown below:

```lua
require("runcode").setup({
    auto_save = true,
    clear_terminal = true,
    show_feedback = true,
    timeout = 0,
    temp_dir = "/tmp",
    no_default_mappings = false,

    terminal_mode = true,
    terminal_position = "horizontal", -- Options: "horizontal", "vertical"
    terminal_height = 10,
    terminal_width = 40,

    tmux_enabled = true,
    tmux_target = "", -- Specify target session/window if executing from outside tmux

    commands = {},      -- Table of custom filetype -> command strings/functions
    test_commands = {}, -- Table of custom filetype -> test command strings/functions
})

```

### Configuration Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `auto_save` | `boolean` | `true` | Automatically writes the buffer to disk before executing if modified. |
| `clear_terminal` | `boolean` | `true` | Prepends `clear &&` to the execution chain to clear previous outputs. |
| `show_feedback` | `boolean` | `true` | Prints an informational message in Neovim before execution. |
| `timeout` | `number` | `0` | If > 0, wraps the execution in the Unix `timeout` command (in seconds). |
| `temp_dir` | `string` | `"/tmp"` | Directory used for intermediate compilation artifacts. |
| `no_default_mappings` | `boolean` | `false` | If true, disables the creation of default buffer-local keymaps. |
| `terminal_mode` | `boolean` | `true` | Uses Neovim's built-in terminal. If false, falls back to `:!`. |
| `terminal_position` | `string` | `"horizontal"` | Window split direction for the terminal. |
| `terminal_height` | `number` | `10` | Height of the terminal window (used if position is horizontal). |
| `terminal_width` | `number` | `40` | Width of the terminal window (used if position is vertical). |
| `tmux_enabled` | `boolean` | `true` | Allows execution inside an external tmux multiplexer. |
| `tmux_target` | `string` | `""` | Specific tmux target pane/window. Empty defaults to the current session. |
| `commands` | `table` | `{}` | User-defined overrides for development commands, keyed by filetype. |
| `test_commands` | `table` | `{}` | User-defined overrides for test commands, keyed by filetype. |

## Usage

### Default Mappings

By default, the plugin assigns buffer-local normal mode mappings upon `FileType` and `BufEnter` events. These are exclusively applied to standard file buffers that possess a registered run command.

| Key | Action | Description |
| --- | --- | --- |
| `r` | `<Cmd>RunCodeDev<CR>` | Executes the Dev profile via terminal. |
| `R` | `<Cmd>RunCodeOpt<CR>` | Executes the Opt profile via terminal. |
| `t` | `<Cmd>RunCodeTmux<CR>` | Executes the Dev profile via tmux. |
| `T` | `<Cmd>RunCodeTmuxTest<CR>` | Executes the Test profile via tmux. |

### User Commands

The plugin provides the following global Ex commands:

**Execution:**

* `:RunCodeDev` - Runs the development command in the configured Neovim terminal/bang backend.
* `:RunCodeOpt` - Runs the optimized command in the Neovim terminal/bang backend.
* `:RunCodeTest` - Runs the testing command in the Neovim terminal/bang backend.
* `:RunCodeTmux` - Runs the development command in a tmux pane.
* `:RunCodeTmuxOpt` - Runs the optimized command in a tmux pane.
* `:RunCodeTmuxTest` - Runs the testing command in a tmux pane.

**Configuration and Utility:**

* `:RunCodeSet <filetype> <command>` - Sets or overrides the development command for a specific filetype dynamically.
* `:RunCodeSetTest <filetype> <command>` - Sets or overrides the test command for a specific filetype dynamically.
* `:RunCodeList` - Prints a sorted list of all filetypes currently supported by the active configuration and built-in defaults.
* `:RunCodeConfig` - Prints the current internal state of the configuration variables.

## Command Resolution Protocol

When an execution command is invoked, the plugin resolves the command string using the following priority order:

**For Dev/Opt modes:**

1. Check `M.config.commands[filetype]`.
2. Check built-in `M.run_commands_dev[filetype]` (or `opt`).
3. Evaluate the function if a generator is returned.
4. Abort with an error notification if no configuration is found.

**For Test mode:**

1. Check `M.config.test_commands[filetype]`.
2. Check built-in `M.run_commands_test[filetype]`.
3. Abort if no configuration is found. Test commands do not fall back to `dev` or `opt` commands to prevent silent execution of the main program instead of the test suite.
