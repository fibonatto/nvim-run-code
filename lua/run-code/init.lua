local M = {}

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
	commands = {}, -- User overrides
}

M.config = vim.deepcopy(M.defaults)

M.run_commands_dev = {
	agda = "agda-cli check %",
	bend = "bend run %",
	c = get_c_command,
	caramel = "mel main",
	coc = "coc type %:r && coc norm %:r",
	cpp = "clang++ -std=c++17 % -o %:r && ./%:r",
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

M.run_commands_opt = {
	agda = "agda-cli run %",
	bend = "bend run %",
	c = "make && ./$(basename %:r)",
	cpp = "clang++ -O3 -march=native -std=c++20 % -o %:r && ./%:r",
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
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Register commands
	vim.api.nvim_create_user_command("RunCodeDev", function()
		M.run(false)
	end, {})
	vim.api.nvim_create_user_command("RunCodeOpt", function()
		M.run(true)
	end, {})
	vim.api.nvim_create_user_command("RunCodeSet", function(args)
		local ft, cmd = args.args:match("^(%S+)%s+(.+)$")
		if ft and cmd then
			M.set_command(ft, cmd)
		else
			vim.notify("Usage: RunCodeSet <ft> <cmd>", vim.log.levels.ERROR)
		end
	end, { nargs = "+" })
	vim.api.nvim_create_user_command("RunCodeList", M.list_languages, {})
	vim.api.nvim_create_user_command("RunCodeConfig", M.show_config, {})

	-- Default Mappings
	if not M.config.no_default_mappings then
		vim.keymap.set("n", "r", ":RunCodeDev<CR>", { silent = true, desc = "Run Code (Dev)" })
		vim.keymap.set("n", "R", ":RunCodeOpt<CR>", { silent = true, desc = "Run Code (Opt)" })
	end
end

function M.run(optimized)
	local file = vim.fn.expand("%")
	if file == "" or vim.fn.filereadable(file) == 0 then
		vim.notify("File not found", vim.log.levels.ERROR)
		return
	end

	if M.config.auto_save and vim.bo.modified then
		vim.cmd("write")
	end

	local ft = vim.bo.filetype
	local commands = optimized and M.run_commands_opt or M.run_commands_dev
	local cmd = ""

	if M.config.commands[ft] then
		cmd = M.config.commands[ft]
	elseif commands[ft] then
		cmd = commands[ft]
	elseif optimized and M.run_commands_dev[ft] then
		cmd = M.run_commands_dev[ft]
	else
		cmd = "clear"
	end

	if type(cmd) == "function" then
		cmd = cmd()
	end

	local exec_cmd = ""
	if M.config.clear_terminal then
		exec_cmd = "clear && "
	end

	if M.config.timeout > 0 then
		exec_cmd = exec_cmd .. string.format("time timeout %ds %s", M.config.timeout, cmd)
	else
		exec_cmd = exec_cmd .. "time " .. cmd
	end

	if M.config.show_feedback then
		print(string.format("Running %s...", (optimized and "optimized" or "dev")))
	end

	if M.config.terminal_mode then
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
	else
		-- Use :! for parity with original behavior
		vim.cmd("!" .. exec_cmd)
	end
end

function M.set_command(ft, cmd)
	M.config.commands[ft] = cmd
end

function M.list_languages()
	local langs = {}
	for k, _ in pairs(M.run_commands_dev) do
		langs[#langs + 1] = k
	end
	for k, _ in pairs(M.run_commands_opt) do
		local found = false
		for _, v in ipairs(langs) do
			if v == k then
				found = true
				break
			end
		end
		if not found then
			langs[#langs + 1] = k
		end
	end
	table.sort(langs)
	print("Supported languages: " .. table.concat(langs, ", "))
end

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
end

return M
