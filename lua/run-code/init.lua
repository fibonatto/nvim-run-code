local M = {}

-- =============================================================================
-- Placeholder expansion
-- =============================================================================
--
-- Commands are templates. `%`, `%:r`, `%:t:r`, `%:h`, `%<` ... are expanded here
-- (same semantics as Vim's `%` with modifiers) and shell-escaped, so filenames
-- with spaces or `#`/`%` work. Use `%%` for a literal percent sign.
-- Nothing else is expanded: `$VAR`, `$(...)` etc. are left to the shell.

local function expand_placeholders(cmd)
	local base = vim.fn.expand("%")
	local out = {}
	local i = 1

	while i <= #cmd do
		local c = cmd:sub(i, i)

		if c ~= "%" then
			out[#out + 1] = c
			i = i + 1
		elseif cmd:sub(i + 1, i + 1) == "%" then
			out[#out + 1] = "%"
			i = i + 2
		else
			local j = i + 1
			local mods = ""

			if cmd:sub(j, j) == "<" then
				mods = ":r"
				j = j + 1
			else
				while cmd:sub(j, j) == ":" and cmd:sub(j + 1, j + 1):match("[phtre]") do
					mods = mods .. cmd:sub(j, j + 1)
					j = j + 2
				end
			end

			out[#out + 1] = vim.fn.shellescape(vim.fn.fnamemodify(base, mods))
			i = j
		end
	end

	local expanded = table.concat(out)

	-- "./%:r" becomes ".//abs/path" when the file lives outside the cwd
	-- (Vim expands `%` to an absolute path in that case).
	return (expanded:gsub("%./'/", "'/"))
end

-- =============================================================================
-- Command generators
-- =============================================================================

local function buffer_text()
	return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

local function has_makefile()
	for _, name in ipairs({ "Makefile", "makefile", "GNUmakefile" }) do
		if vim.fn.filereadable(name) == 1 then
			return true
		end
	end

	return false
end

local function c_extra_flags()
	if buffer_text():match("#include%s*<cs50%.h>") then
		return " -I/usr/local/include -L/usr/local/lib -lcs50"
	end

	return ""
end

local function get_c_command()
	if has_makefile() then
		return "make run"
	end

	return "clang %" .. c_extra_flags() .. " -o %:r && ./%:r"
end

local function get_c_opt_command()
	if has_makefile() then
		return "make && ./$(basename %:r)"
	end

	return "clang -O2 %" .. c_extra_flags() .. " -o %:r && ./%:r"
end

local function get_cpp_command(optimized)
	local flags = "-std=c++17" .. (optimized and " -O2" or "")
	local llvm = ""

	-- Only link against LLVM when the source actually uses it.
	if buffer_text():match('#include%s*[<"]llvm/') then
		llvm = " $(llvm-config --cxxflags --ldflags --system-libs --libs all)"
	end

	return "clang++ " .. flags .. " %" .. llvm .. " -o %:r && ./%:r"
end

-- =============================================================================
-- Configuration
-- =============================================================================

M.defaults = {
	auto_save = true,
	clear_terminal = true,
	show_feedback = true,
	timeout = 0,
	temp_dir = "/tmp",
	no_default_mappings = false,

	terminal_mode = true,
	terminal_position = "horizontal",
	terminal_height = 10,
	terminal_width = 40,

	tmux_enabled = true,
	tmux_target = "",

	commands = {},
	test_commands = {},
}

M.config = vim.deepcopy(M.defaults)

-- =============================================================================
-- Development commands
-- =============================================================================

M.run_commands_dev = {
	agda = "agda-cli check %",
	bend = "bend %",
	c = get_c_command,
	caramel = "mel main",
	coc = "coc type %:r && coc norm %:r",
	cpp = function()
		return get_cpp_command(false)
	end,
	cs = "mcs % -out:%:r.exe && mono %:r.exe",
	cuda = "nvcc % -o %:r && ./%:r",
	dart = "dart %",
	dvl = "dvl run %",
	eac = "eac %:r",
	eatt = "eatt %:r",
	elm = "elm make % --output=%:r.js",
	erlang = "escript %",
	fibo = "fibo %",
	formality = "fm %",
	formcore = "fmcjs %:r",
	go = "go run %",
	haskell = "stack run",
	html = "npm run dev",
	http = "httpyac --all route.http",
	hvm = "hvm run %",
	["hvm-lang"] = "hvm-lang %",
	hvml = "hvml run % -s",
	hvms = "hvms run %",
	ic = "ic %",
	icvm = "ic %",
	idris2 = "idris2 % -o %:r && ./%:r",
	java = "javac % && java -cp %:h %:t:r",
	javascript = "bun run %",
	javascriptreact = "npm run dev",
	julia = "julia %",
	kind = "kind check %",
	kindc = "kind check %",
	kind2 = "kind2 check %",
	kotlin = "kotlinc % -include-runtime -d %:r.jar && java -jar %:r.jar",
	ksc = "kindelia-cli local eval --file %",
	lambda = "absal -s %",
	livescript = "lsc -c % && node %:r.js",
	lua = "lua %",
	moon = "moon run %:r",
	morte = "echo $(cat %) | morte",
	nim = "nim compile --run %",
	ocaml = "ocamlc -o %:r % && ./%:r",
	pascal = "fpc % && ./%:r",
	perl = "perl -w %",
	phi = "phi %",
	php = "php %",
	purescript = "pulp run",
	python = "python3 -u %",
	praxis = "praxis %",
	r = "Rscript %",
	racket = "racket %",
	ruby = "ruby %",
	rust = "rustc -O % -o %:r && ./%:r",
	scala = "scala %",
	scheme = "csc % && ./%:r",
	sh = "bash -x %",
	sic = "sic -s -B %",
	solidity = "truffle deploy",
	swift = "swift %",
	typescript = "bun run %",
	typescriptreact = "npm run dev",
	zig = "zig run %",
}

-- =============================================================================
-- Optimized commands
-- =============================================================================

M.run_commands_opt = {
	agda = "agda-cli run %",
	bend = "bend %",
	c = get_c_opt_command,
	cpp = function()
		return get_cpp_command(true)
	end,
	cuda = "nvcc -O3 % -o %:r && ./%:r",
	dart = "dart compile exe % -o %:r && ./%:r",
	go = 'go build -ldflags="-s -w" -o %:r % && ./%:r',
	haskell = function()
		-- Runs inside `sh -c`, so POSIX syntax is fine here.
		local exe = vim.fn.shellescape(M.config.temp_dir .. "/.run_code_" .. vim.fn.getpid())

		return "ghc -O2 -threaded % -o "
			.. exe
			.. " && "
			.. exe
			.. "; rc=$?; rm -f "
			.. exe
			.. " %:r.hi %:r.o; exit $rc"
	end,
	html = "python3 -m http.server 8000",
	hvm = "hvm run-c %",
	java = "javac % && java -server -XX:+UseG1GC -cp %:h %:t:r",
	javascript = "node %",
	julia = "julia -O3 %",
	kind = "kind run %",
	kindc = "kind run %",
	kind2 = "kind2 normal %",
	kotlin = "kotlinc % -include-runtime -d %:r.jar && java -server -jar %:r.jar",
	nim = "nim compile --opt:speed --run %",
	ocaml = "ocamlopt -O3 -o %:r % && ./%:r",
	pascal = "fpc -O3 % && ./%:r",
	phi = "phi % -t -s -c",
	python = "python3 -O %",
	rust = "cargo run --release",
	scala = "scalac % && scala -J-server %:r",
	typescript = function()
		local out = vim.fn.shellescape(M.config.temp_dir)

		return "tsc % --outDir " .. out .. " && node " .. out .. "/%:t:r.js"
	end,
	zig = "zig run -O ReleaseFast %",
}

-- =============================================================================
-- Test commands
-- =============================================================================

M.run_commands_test = {
	c = "make test",
	cpp = "make test",
	dart = "dart test",
	go = "go test ./...",
	haskell = "stack test",
	java = "mvn test",
	javascript = "bun test",
	julia = "julia -e 'using Pkg; Pkg.test()'",
	kotlin = "gradle test",
	nim = "nimble test",
	ocaml = "dune test",
	python = "pytest",
	rust = "cargo test",
	scala = "sbt test",
	swift = "swift test",
	typescript = "bun test",
	zig = "zig build test",
}

-- =============================================================================
-- Command resolution
-- =============================================================================

local function resolve_command(commands, ft)
	local cmd = commands[ft]

	if type(cmd) == "function" then
		cmd = cmd()
	end

	return cmd
end

local function get_command(mode)
	local ft = vim.bo.filetype

	if mode == "test" then
		-- No fallback to dev/opt: "test" must never silently run the program.
		return resolve_command(M.config.test_commands, ft) or resolve_command(M.run_commands_test, ft)
	end

	if M.config.commands[ft] then
		return resolve_command(M.config.commands, ft)
	end

	if mode == "dev" then
		return resolve_command(M.run_commands_dev, ft)
	end

	if mode == "opt" then
		return resolve_command(M.run_commands_opt, ft)
	end

	return nil
end

local function has_command(ft)
	return M.run_commands_dev[ft] ~= nil
		or M.run_commands_opt[ft] ~= nil
		or M.run_commands_test[ft] ~= nil
		or M.config.commands[ft] ~= nil
		or M.config.test_commands[ft] ~= nil
end

-- =============================================================================
-- Common helpers
-- =============================================================================

local function check_file()
	local file = vim.fn.expand("%")

	if file == "" or vim.fn.filereadable(file) == 0 then
		vim.notify("File not found", vim.log.levels.ERROR)
		return false
	end

	if M.config.auto_save and vim.bo.modified then
		vim.cmd("write")
	end

	return true
end

-- The whole (expanded) command runs inside `sh -c`, so `time` and `timeout`
-- apply to the entire `a && b` chain, not only to its first command, and the
-- command syntax does not depend on the user's interactive shell.
local function build_exec_command(cmd)
	local body = "sh -c " .. vim.fn.shellescape(expand_placeholders(cmd))
	local prefix = M.config.clear_terminal and "clear && " or ""

	if M.config.timeout > 0 then
		return prefix .. string.format("time timeout %ds %s", M.config.timeout, body)
	end

	return prefix .. "time " .. body
end

-- =============================================================================
-- Neovim terminal
-- =============================================================================

local function run_terminal(exec_cmd)
	if M.config.terminal_position == "vertical" then
		vim.cmd(string.format("botright %dvnew", M.config.terminal_width))
	else
		vim.cmd(string.format("botright %dnew", M.config.terminal_height))
	end

	-- jobstart/termopen take the command as-is: no Ex-command re-expansion of
	-- `%`, `#` or `|`.
	if vim.fn.has("nvim-0.11") == 1 then
		vim.fn.jobstart(exec_cmd, { term = true })
	else
		vim.fn.termopen(exec_cmd)
	end

	vim.cmd("startinsert")
end

-- Plain `:!` fallback (terminal_mode = false). `:!` expands `%`, `#` and `!`
-- itself, so escape them.
local function run_bang(exec_cmd)
	vim.cmd("!" .. exec_cmd:gsub("[%%#!]", "\\%0"))
end

-- =============================================================================
-- tmux
-- =============================================================================

local function tmux_available()
	return vim.fn.executable("tmux") == 1
end

local function run_tmux(exec_cmd)
	if not tmux_available() then
		vim.notify("tmux is not installed", vim.log.levels.ERROR)
		return
	end

	if vim.env.TMUX == nil and M.config.tmux_target == "" then
		vim.notify("Not running inside tmux (set tmux_target to use a session from outside)", vim.log.levels.ERROR)
		return
	end

	-- The wrapper is POSIX `sh` (so `rc=$?` etc. also work when the user's shell
	-- is zsh, where `status` is read-only, or fish). The command itself still
	-- runs in the user's shell.
	local script = vim.fn.shellescape(vim.o.shell)
		.. " -c "
		.. vim.fn.shellescape(exec_cmd)
		.. "; rc=$?; printf '\\n\\n[run-code] exit code: %s\\n' \"$rc\""
		.. "; printf '[run-code] press Enter to close... '; read _"

	local command = "sh -c " .. vim.fn.shellescape(script)

	-- `-h` creates a left/right split, `-p 50` gives the new pane 50%.
	-- `-c` makes the pane start in Neovim's cwd (tmux otherwise uses the
	-- session's directory, which breaks every relative path).
	local args = { "tmux", "split-window" }

	if M.config.tmux_target ~= "" then
		vim.list_extend(args, { "-t", M.config.tmux_target })
	end

	vim.list_extend(args, { "-h", "-p", "50", "-c", vim.fn.getcwd(), command })

	local output = vim.fn.system(args)

	if vim.v.shell_error ~= 0 then
		vim.notify("tmux failed: " .. vim.trim(output), vim.log.levels.ERROR)
	end
end

-- =============================================================================
-- Public runner
-- =============================================================================

function M.run(mode, backend)
	if backend == "tmux" and not M.config.tmux_enabled then
		vim.notify("tmux execution is disabled", vim.log.levels.WARN)
		return
	end

	if not check_file() then
		return
	end

	local cmd = get_command(mode)

	if not cmd then
		vim.notify(
			string.format("No %s command configured for filetype: %s", mode, vim.bo.filetype),
			vim.log.levels.ERROR
		)
		return
	end

	local exec_cmd = build_exec_command(cmd)

	if M.config.show_feedback then
		local mode_name = {
			dev = "dev",
			opt = "optimized",
			test = "test",
		}

		print(string.format("Running %s in %s...", mode_name[mode] or mode, backend == "tmux" and "tmux" or "terminal"))
	end

	if backend == "tmux" then
		run_tmux(exec_cmd)
	elseif M.config.terminal_mode then
		run_terminal(exec_cmd)
	else
		run_bang(exec_cmd)
	end
end

-- =============================================================================
-- Mappings
-- =============================================================================

-- Buffer-local, and only for normal file buffers whose filetype has a command.
-- Global `r`/`R`/`t`/`T` mappings also hijacked replace and till-motions in
-- terminals, help, netrw, etc. (including the run terminal itself).
local function set_buffer_mappings(buf)
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
		return
	end

	if not has_command(vim.bo[buf].filetype) then
		return
	end

	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
	end

	map("r", "<Cmd>RunCodeDev<CR>", "Run Code (Dev)")
	map("R", "<Cmd>RunCodeOpt<CR>", "Run Code (Opt)")
	map("t", "<Cmd>RunCodeTmux<CR>", "Run Code (tmux)")
	map("T", "<Cmd>RunCodeTmuxTest<CR>", "Run Tests (tmux)")
end

-- =============================================================================
-- User commands
-- =============================================================================

function M.set_command(ft, cmd)
	M.config.commands[ft] = cmd
end

function M.set_test_command(ft, cmd)
	M.config.test_commands[ft] = cmd
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("RunCodeDev", function()
		M.run("dev", "terminal")
	end, {})

	vim.api.nvim_create_user_command("RunCodeOpt", function()
		M.run("opt", "terminal")
	end, {})

	vim.api.nvim_create_user_command("RunCodeTest", function()
		M.run("test", "terminal")
	end, {})

	vim.api.nvim_create_user_command("RunCodeTmux", function()
		M.run("dev", "tmux")
	end, {})

	vim.api.nvim_create_user_command("RunCodeTmuxOpt", function()
		M.run("opt", "tmux")
	end, {})

	vim.api.nvim_create_user_command("RunCodeTmuxTest", function()
		M.run("test", "tmux")
	end, {})

	vim.api.nvim_create_user_command("RunCodeSet", function(args)
		local ft, cmd = args.args:match("^(%S+)%s+(.+)$")

		if ft and cmd then
			M.set_command(ft, cmd)
		else
			vim.notify("Usage: RunCodeSet <ft> <cmd>", vim.log.levels.ERROR)
		end
	end, { nargs = "+" })

	vim.api.nvim_create_user_command("RunCodeSetTest", function(args)
		local ft, cmd = args.args:match("^(%S+)%s+(.+)$")

		if ft and cmd then
			M.set_test_command(ft, cmd)
		else
			vim.notify("Usage: RunCodeSetTest <ft> <cmd>", vim.log.levels.ERROR)
		end
	end, { nargs = "+" })

	vim.api.nvim_create_user_command("RunCodeList", M.list_languages, {})

	vim.api.nvim_create_user_command("RunCodeConfig", M.show_config, {})

	if not M.config.no_default_mappings then
		local group = vim.api.nvim_create_augroup("RunCodeMappings", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			callback = function(args)
				set_buffer_mappings(args.buf)
			end,
		})

		-- Buffers that already exist when setup() runs.
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				set_buffer_mappings(buf)
			end
		end
	end
end

-- =============================================================================
-- Language listing
-- =============================================================================

function M.list_languages()
	local languages = {}

	local function add_languages(commands)
		for ft, _ in pairs(commands) do
			languages[ft] = true
		end
	end

	add_languages(M.run_commands_dev)
	add_languages(M.run_commands_opt)
	add_languages(M.run_commands_test)
	add_languages(M.config.commands)
	add_languages(M.config.test_commands)

	local langs = {}

	for ft, _ in pairs(languages) do
		langs[#langs + 1] = ft
	end

	table.sort(langs)

	print("Supported languages: " .. table.concat(langs, ", "))
end

-- =============================================================================
-- Configuration display
-- =============================================================================

function M.show_config()
	print("Run Code Config:")
	print("  Auto-save: " .. tostring(M.config.auto_save))
	print("  Clear terminal: " .. tostring(M.config.clear_terminal))
	print("  Show feedback: " .. tostring(M.config.show_feedback))
	print("  Timeout: " .. tostring(M.config.timeout))
	print("  Temp dir: " .. M.config.temp_dir)

	print("  Terminal mode: " .. tostring(M.config.terminal_mode))
	print("  Terminal position: " .. M.config.terminal_position)
	print("  Terminal height: " .. M.config.terminal_height)
	print("  Terminal width: " .. M.config.terminal_width)

	print("  tmux enabled: " .. tostring(M.config.tmux_enabled))
	print("  tmux target: " .. (M.config.tmux_target == "" and "<current pane>" or M.config.tmux_target))
end

return M
