local M = {}

-- ============================================================================
-- Command generators
-- ============================================================================

local function get_c_command()
	if vim.fn.filereadable("Makefile") == 1 then
		return "make run"
	end

	local file = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")
	local content = table.concat(vim.fn.readfile(file), "\n")

	local flags = ""

	if content:match("#include%s*<cs50%.h>") then
		flags = " -I/usr/local/include -L/usr/local/lib -lcs50"
	end

	return string.format(
		"clang %s%s -o %s && %s",
		vim.fn.shellescape(file),
		flags,
		vim.fn.shellescape(output),
		vim.fn.shellescape(output)
	)
end

local function get_cpp_command()
	local file = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")

	return string.format(
		"clang++ -std=c++17 %s -o %s && %s",
		vim.fn.shellescape(file),
		vim.fn.shellescape(output),
		vim.fn.shellescape(output)
	)
end

local function get_cpp_llvm_command()
	local file = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")

	return string.format(
		"clang++ -std=c++17 %s $(llvm-config --cxxflags --ldflags --system-libs --libs all) -o %s && %s",
		vim.fn.shellescape(file),
		vim.fn.shellescape(output),
		vim.fn.shellescape(output)
	)
end

-- ============================================================================
-- Configuration
-- ============================================================================

M.defaults = {
	auto_save = true,
	clear_terminal = true,
	show_feedback = true,
	timeout = 0,
	temp_dir = "/tmp",

	no_default_mappings = false,

	-- Neovim terminal
	terminal_mode = true,
	terminal_position = "horizontal",
	terminal_height = 10,
	terminal_width = 40,

	-- tmux
	tmux_enabled = true,
	tmux_position = "horizontal",
	tmux_size = 10,
	tmux_target = "",
	tmux_reuse = false,

	-- User overrides
	commands = {},
	test_commands = {},
}

M.config = vim.deepcopy(M.defaults)

-- ============================================================================
-- Development commands
-- ============================================================================

M.run_commands_dev = {
	agda = "agda-cli check %",
	bend = "bend %",
	c = get_c_command,
	caramel = "mel main",
	coc = "coc type %:r && coc norm %:r",
	cpp = get_cpp_command,
	csharp = "mcs % && mono %:r.exe",
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
	java = "javac % && java %:r",
	javascript = "bun run %",
	jsx = "npm run dev",
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
	rust = "rustc -O % && ./%<",
	scala = "scala %",
	scheme = "csc % && ./%:r",
	sh = "bash -x %",
	sic = "sic -s -B %",
	solidity = "truffle deploy",
	swift = "swift %",
	typescript = "bun run %",
	tsx = "npm run dev",
	zig = "zig run %",
}

-- ============================================================================
-- Optimized commands
-- ============================================================================

M.run_commands_opt = {
	agda = "agda-cli run %",
	bend = "bend %",
	c = "make && ./$(basename %:r)",
	cpp = get_cpp_llvm_command,
	cuda = "nvcc -O3 % -o %:r && ./%:r",
	dart = "dart compile exe % -o %:r && ./%:r",
	go = 'go build -ldflags="-s -w" % && ./%:r',
	haskell = function()
		local temp = M.config.temp_dir

		return string.format(
			"ghc -O2 -threaded %% -o %s/.tmp_exec && %s/.tmp_exec && rm -f %s/.tmp_exec %%:r.hi %%:r.o",
			temp,
			temp,
			temp
		)
	end,
	html = "python3 -m http.server 8000",
	hvm = "hvm run-c %",
	java = "javac % && java -server -XX:+UseG1GC %:r",
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
		local temp = M.config.temp_dir

		return string.format("tsc %% --outDir %s && node %s/%%:r.js", temp, temp)
	end,
	zig = "zig run -O ReleaseFast %",
}

-- ============================================================================
-- Test commands
--
-- These are intentionally separate from dev/opt.
--
-- A missing test command falls back to the optimized command.
-- ============================================================================

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

-- ============================================================================
-- Helpers
-- ============================================================================

local function resolve_command(commands, ft)
	local cmd = commands[ft]

	if type(cmd) == "function" then
		cmd = cmd()
	end

	return cmd
end

local function get_command(mode)
	local ft = vim.bo.filetype

	-- User override always wins.
	if mode ~= "test" and M.config.commands[ft] then
		return resolve_command(M.config.commands, ft)
	end

	if mode == "test" and M.config.test_commands[ft] then
		return resolve_command(M.config.test_commands, ft)
	end

	if mode == "dev" then
		return resolve_command(M.run_commands_dev, ft)
	end

	if mode == "opt" then
		return resolve_command(M.run_commands_opt, ft)
	end

	-- Test fallback:
	--
	-- test command -> optimized command -> development command
	--
	-- This means every language can participate in `T` without
	-- requiring an explicit test command.
	if mode == "test" then
		return resolve_command(M.run_commands_opt, ft) or resolve_command(M.run_commands_dev, ft)
	end

	return nil
end

local function build_exec_command(cmd)
	if not cmd or cmd == "" then
		return "clear"
	end

	local prefix = ""

	if M.config.clear_terminal then
		prefix = "clear && "
	end

	if M.config.timeout > 0 then
		return prefix .. string.format("time timeout %ds %s", M.config.timeout, cmd)
	end

	return prefix .. "time " .. cmd
end

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

local function tmux_available()
	return vim.fn.executable("tmux") == 1
end

local function tmux_inside()
	return vim.env.TMUX ~= nil and vim.env.TMUX ~= ""
end

local function get_tmux_target()
	if M.config.tmux_target ~= "" then
		return M.config.tmux_target
	end

	return ""
end

-- ============================================================================
-- Neovim terminal
-- ============================================================================

local function run_terminal(exec_cmd)
	local pos = M.config.terminal_position == "vertical" and "vsplit" or "split"

	local size = M.config.terminal_position == "vertical" and M.config.terminal_width or M.config.terminal_height

	vim.cmd(string.format("botright %s", pos))

	if M.config.terminal_position == "vertical" then
		vim.cmd(string.format("vertical resize %d", size))
	else
		vim.cmd(string.format("resize %d", size))
	end

	vim.cmd("term " .. exec_cmd)
	vim.cmd("startinsert")
end

-- ============================================================================
-- tmux
-- ============================================================================

local function run_tmux(exec_cmd)
	if not tmux_available() then
		vim.notify("tmux is not installed", vim.log.levels.ERROR)
		return
	end

	local orientation = M.config.tmux_position == "vertical" and "-h" or "-v"

	local size_flag = M.config.tmux_position == "vertical" and "-l " .. M.config.tmux_size
		or "-l " .. M.config.tmux_size

	local target = get_tmux_target()

	-- tmux split-window executes through the user's shell.
	--
	-- shellescape() is deliberately applied to the complete command,
	-- rather than trying to escape individual pieces after interpolation.
	local command = vim.fn.shellescape(exec_cmd)

	local args = string.format("split-window %s %s %s", orientation, size_flag, command)

	if target ~= "" then
		args = string.format("split-window -t %s %s %s %s", vim.fn.shellescape(target), orientation, size_flag, command)
	end

	local result = vim.fn.system("tmux " .. args)

	if vim.v.shell_error ~= 0 then
		vim.notify("tmux failed: " .. vim.trim(result), vim.log.levels.ERROR)
		return
	end
end

-- ============================================================================
-- Public runner
-- ============================================================================

function M.run(mode, backend)
	if not check_file() then
		return
	end

	local cmd = get_command(mode)

	if not cmd then
		vim.notify("No command configured for filetype: " .. vim.bo.filetype, vim.log.levels.ERROR)
		return
	end

	local exec_cmd = build_exec_command(cmd)

	if M.config.show_feedback then
		local labels = {
			dev = "dev",
			opt = "optimized",
			test = "test",
		}

		local target = backend == "tmux" and "tmux" or "terminal"

		print(string.format("Running %s in %s...", labels[mode] or mode, target))
	end

	if backend == "tmux" then
		if not M.config.tmux_enabled then
			vim.notify("tmux execution is disabled", vim.log.levels.WARN)
			return
		end

		run_tmux(exec_cmd)
		return
	end

	if M.config.terminal_mode then
		run_terminal(exec_cmd)
	else
		vim.cmd("!" .. exec_cmd)
	end
end

-- ============================================================================
-- User commands
-- ============================================================================

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command("RunCodeDev", function()
		M.run("dev", "terminal")
	end, {})

	vim.api.nvim_create_user_command("RunCodeOpt", function()
		M.run("opt", "terminal")
	end, {})

	vim.api.nvim_create_user_command("RunCodeTmux", function()
		M.run("dev", "tmux")
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
		vim.keymap.set("n", "r", ":RunCodeDev<CR>", {
			silent = true,
			desc = "Run Code (Dev)",
		})

		vim.keymap.set("n", "R", ":RunCodeOpt<CR>", {
			silent = true,
			desc = "Run Code (Opt)",
		})

		vim.keymap.set("n", "t", ":RunCodeTmux<CR>", {
			silent = true,
			desc = "Run Code (tmux)",
		})

		vim.keymap.set("n", "T", ":RunCodeTmuxTest<CR>", {
			silent = true,
			desc = "Run Tests (tmux)",
		})
	end
end

-- ============================================================================
-- User command configuration
-- ============================================================================

function M.set_command(ft, cmd)
	M.config.commands[ft] = cmd
end

function M.set_test_command(ft, cmd)
	M.config.test_commands[ft] = cmd
end

-- ============================================================================
-- Language listing
-- ============================================================================

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

-- ============================================================================
-- Configuration display
-- ============================================================================

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
	print("  tmux position: " .. M.config.tmux_position)
	print("  tmux size: " .. tostring(M.config.tmux_size))
	print("  tmux target: " .. (M.config.tmux_target == "" and "<current pane>" or M.config.tmux_target))
end

return M
