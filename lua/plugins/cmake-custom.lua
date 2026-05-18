local M = {}

local status_buffer
local status_window
local timer
local current_job
local forced_quit
local output_buffer
local output_window
local settings = { buildType = "Debug", buildTarget = "all", launchTarget = "" }
local configuredSettings = { buildType = "", buildTarget = "", launchTarget = "" }

local cmake_settings_dir = vim.fn.stdpath("data") .. "/project_settings/"

if vim.fn.isdirectory(cmake_settings_dir) == 0 then
	vim.fn.mkdir(cmake_settings_dir, "p")
end

local function save_settings()
	local project_name = vim.fn.getcwd():match("^.*/(.*)$") or vim.fn.getcwd()
	local settings_path = cmake_settings_dir .. project_name .. ".json"
	local f = assert(io.open(settings_path, "w"))
	f:write(vim.fn.json_encode(settings))
	f:close()
end

local function load_settings()
	local project_name = vim.fn.getcwd():match("^.*/(.*)$") or vim.fn.getcwd()
	local settings_path = cmake_settings_dir .. project_name .. ".json"
	local f = io.open(settings_path, "r")
	if not f then
		return {}
	end
	local data = f:read("*a")
	f:close()
	local ok, decoded = pcall(vim.fn.json_decode, data)
	if ok then
		settings = decoded
	end
end

local function close_status(delay_ms)
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	if delay_ms ~= 0 then
		vim.defer_fn(function()
			if status_window and vim.api.nvim_win_is_valid(status_window) then
				vim.api.nvim_win_close(status_window, true)
			end
			status_window = nil
			status_buffer = nil
		end, delay_ms or 1000)
	else
		if status_window and vim.api.nvim_win_is_valid(status_window) then
			vim.api.nvim_win_close(status_window, true)
		end
		status_window = nil
		status_buffer = nil
	end
end

local function open_status()
	close_status(0)

	local w, h = 22, 1
	status_buffer = vim.api.nvim_create_buf(false, true)
	status_window = vim.api.nvim_open_win(status_buffer, false, {
		relative = "editor",
		width = w,
		height = h,
		row = vim.o.lines - h,
		col = vim.o.columns - w,
		border = "single",
	})

	vim.api.nvim_win_set_option(status_window, "number", false)
	vim.api.nvim_win_set_option(status_window, "relativenumber", false)
	vim.api.nvim_buf_set_option(status_buffer, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(status_buffer, "modifiable", false)
end

local function open_output()
	output_buffer = vim.fn.bufnr("Program Output")
	local prev = vim.fn.win_getid()
	if output_buffer ~= -1 then
		local windows = vim.tbl_filter(function(win)
			return vim.api.nvim_win_get_buf(win) == output_buffer
		end, vim.api.nvim_list_wins())
		if #windows > 0 then
			output_window = windows[1]
		end

		if not output_window or not vim.api.nvim_win_is_valid(output_window) then
			vim.api.nvim_buf_delete(output_buffer, { force = true })
			output_buffer = -1
		end
	end

	if output_buffer ~= -1 then
		if vim.api.nvim_buf_is_valid(output_buffer) then
			vim.bo[output_buffer].bufhidden = "wipe"
			vim.bo[output_buffer].buftype = "nofile"
			vim.bo[output_buffer].swapfile = false
			vim.bo[output_buffer].buflisted = false
			vim.bo[output_buffer].modifiable = true
			vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, {})
		end
		return
	end

	output_buffer = vim.api.nvim_create_buf(false, false)

	vim.bo[output_buffer].bufhidden = "wipe"
	vim.bo[output_buffer].buftype = "nofile"
	vim.bo[output_buffer].swapfile = false
	vim.bo[output_buffer].buflisted = false
	vim.bo[output_buffer].modifiable = true

	vim.cmd("topleft 7split")
	output_window = vim.api.nvim_get_current_win()
	vim.api.nvim_buf_set_name(output_buffer, "Program Output")
	vim.api.nvim_win_set_buf(output_window, output_buffer)
	vim.wo[output_window].winfixheight = true
	vim.fn.win_gotoid(prev)
end

local function close_output()
	if output_window and vim.api.nvim_win_is_valid(output_window) then
		vim.api.nvim_win_close(output_window, true)
	end
	output_window = nil
	output_buffer = nil
end

local function set_status_contents(text)
	if not status_buffer then
		return
	end
	local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
	local i, elapsed = 1, 0

	if timer then
		timer:stop()
		timer:close()
	end

	timer = vim.loop.new_timer()
	timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			if not status_buffer or not vim.api.nvim_buf_is_valid(status_buffer) then
				timer:stop()
				timer:close()
				timer = nil
				return
			end
			i = (i % #frames) + 1
			elapsed = elapsed + 0.1
			vim.api.nvim_buf_set_option(status_buffer, "modifiable", true)
			vim.api.nvim_buf_set_lines(
				status_buffer,
				0,
				-1,
				false,
				{ string.format("%s %s %.1fs", frames[i], text, elapsed) }
			)
			vim.api.nvim_buf_set_option(status_buffer, "modifiable", false)
		end)
	)
end

local function run_job(cmd, on_exit, on_stderr)
	if current_job then
		forced_quit = true
		vim.fn.jobstop(current_job)
		current_job = nil
	end

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if on_stderr then
				for _, line in ipairs(data) do
					if line ~= "" then
						on_stderr(line, "out")
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if on_stderr then
				for _, line in ipairs(data) do
					if line ~= "" then
						on_stderr(line, "err")
					end
				end
			end
		end,
		on_exit = function(_, code)
			current_job = nil

			if not forced_quit and on_exit then
				vim.schedule(function()
					on_exit(code)
				end)
			end
			forced_quit = false
		end,
	})
end

local function read_file(path)
	local f = io.open(vim.fn.glob(vim.fn.getcwd() .. path), "r")

	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function put_query_file()
	local query = "./build/" .. settings["buildType"] .. "/.cmake/api/v1/query"
	vim.fn.mkdir(query, "p")
	local f = io.open(query .. "/codemodel-v2", "w")
	if f then
		f:close()
	end
end

local function get_build_targets()
	local targets_ = {}
	local file_content = read_file("/build/" .. settings["buildType"] .. "/.cmake/api/v1/reply/codemodel-v2*.json")
	if not file_content then
		return targets_
	end

	local codemodel_data = vim.fn.json_decode(file_content)
	local targets = codemodel_data["configurations"][1]["targets"]

	for _, target in ipairs(targets) do
		file_content = read_file(
			"/build/" .. settings["buildType"] .. "/.cmake/api/v1/reply/target-" .. target["name"] .. "-*.json"
		)
		if file_content then
			local target_data = vim.fn.json_decode(file_content)
			table.insert(targets_, { target["name"], target_data["type"] })
		end
	end
	return targets_
end

function M.conigure(f, force)
	load_settings()

	force = force or false
	if not force then
		local same = configuredSettings.buildType == settings.buildType
			and configuredSettings.buildTarget == settings.buildTarget

		if same then
			if f then
				f(0)
			end
			return
		end
	end

	open_status()
	set_status_contents("CMake Config")

	run_job({
		"cmake",
		"-S",
		".",
		"-B",
		"./build/" .. settings["buildType"],
		"-G",
		"Ninja",
		"-DCMAKE_BUILD_TYPE=" .. settings["buildType"],
		"-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
		"-DFETCHCONTENT_BASE_DIR=./build/_deps",
	}, function(code)
		if code == 0 then
			configuredSettings.buildType = settings.buildType
			configuredSettings.buildTarget = settings.buildTarget
		end
		if f then
			f(code)
		end
	end)
end

function M.select_build_target()
	load_settings()
	put_query_file()

	M.conigure(function()
		close_status(1000)
		local targets = get_build_targets()
		local t = { "all" }
		for _, target in ipairs(targets) do
			table.insert(t, target[1] .. " \t" .. target[2])
		end

		if #t == 1 then
			settings["buildTarget"] = "all"
			save_settings()
		end

		vim.ui.select(t, {
			prompt = "Select build target:",
		}, function(choice)
			if choice then
				settings["buildTarget"] = choice:match("^(%S+)")
				save_settings()
			end
		end)
	end)
end

function M.select_launch_target()
	load_settings()
	put_query_file()

	M.conigure(function()
		close_status(1000)
		local targets = get_build_targets()

		local t = {}
		for _, target in ipairs(targets) do
			if target[2] == "EXECUTABLE" then
				table.insert(t, target[1])
			end
		end

		if #t == 1 then
			settings["launchTarget"] = t[1]
			save_settings()
		end

		vim.ui.select(t, {
			prompt = "Select launch target:",
		}, function(choice)
			if choice then
				settings["launchTarget"] = choice
				save_settings()
			end
		end)
	end)
end

function M.select_build_type()
	load_settings()
	local types = { "Debug", "Release" }

	vim.ui.select(types, {
		prompt = "Select build type:",
	}, function(choice)
		if choice then
			settings["buildType"] = choice
			save_settings()
		end
	end)
end

function M.build(f)
	load_settings()
	open_status()
	local qf_lines = {}
	M.conigure(function()
		set_status_contents("CMake Build")
		vim.fn.setqflist({})
		run_job(
			{ "cmake", "--build", "./build/" .. settings["buildType"], "-j12", "--target", settings["buildTarget"] },
			function(code)
				vim.schedule(function()
					vim.fn.setqflist({}, " ", {
						title = "CMake Build",
						lines = qf_lines,
					})

					if code ~= 0 then
						vim.cmd("copen ")
						vim.cmd("cfirst")
					else
						vim.cmd("cclose")
					end

					vim.loop.fs_symlink(
						"./build/" .. settings["buildType"] .. "/compile_commands.json",
						"./compile_commands.json"
					)

					close_status(1000)
					if f then
						f(code == 0)
					end
				end)
			end,
			function(line, src)
				if line == "" then
					return
				end

				if not line:match("^%[") then
					table.insert(qf_lines, line)
				end
			end
		)
	end)
end

function M.run()
	load_settings()
	if settings["launchTarget"] == "" then
		M.select_launch_target()
	end

	-- open_status()

	if output_buffer and vim.api.nvim_buf_is_valid(output_buffer) then
		vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, {})
	end
	-- set_status_contents("Running")

	local handle
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	handle = vim.loop.spawn("./" .. settings["launchTarget"], {
		cwd = "./build/" .. settings["buildType"],
		args = {},
		stdio = { nil, stdout, stderr },
	}, function(code, signal)
		stdout:close()
		stderr:close()
		handle:close()

		vim.schedule(function()
			if
				output_buffer
				and vim.api.nvim_buf_is_valid(output_buffer)
				and vim.api.nvim_buf_line_count(output_buffer) == 1
				and vim.api.nvim_buf_get_lines(output_buffer, 0, 1, false)[1] == ""
			then
				close_output()
			end
		end)
		close_status(1000)
	end)
	if not handle then
		close_status(0)
	end

	stdout:read_start(function(err, data)
		if not data then
			return
		end

		vim.schedule(function()
			if not output_buffer or not vim.api.nvim_buf_is_valid(output_buffer) then
				open_output()
			end
		end)

		for line in data:gmatch("[^\r\n]+") do
			vim.schedule(function()
				local line_count = vim.api.nvim_buf_line_count(output_buffer)
				if line_count == 1 and vim.api.nvim_buf_get_lines(output_buffer, 0, 1, false)[1] == "" then
					vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, { line })
				else
					vim.api.nvim_buf_set_lines(output_buffer, -1, -1, false, { line })
				end
			end)
		end
	end)

	stderr:read_start(function(err, data)
		if not data then
			return
		end

		vim.schedule(function()
			if not output_buffer or not vim.api.nvim_buf_is_valid(output_buffer) then
				open_output()
			end
		end)

		for line in data:gmatch("[^\r\n]+") do
			vim.schedule(function()
				local line_count = vim.api.nvim_buf_line_count(output_buffer)
				if line_count == 1 and vim.api.nvim_buf_get_lines(output_buffer, 0, 1, false)[1] == "" then
					vim.api.nvim_buf_set_lines(output_buffer, 0, -1, false, { line })
				else
					vim.api.nvim_buf_set_lines(output_buffer, -1, -1, false, { line })
				end
			end)
		end
	end)
end

function M.build_and_run()
	M.build(function(success)
		if success then
			M.run()
		end
		close_status(1000)
	end)
end

function M.debug()
	load_settings()

	if not settings["launchTarget"] or settings["launchTarget"] == "" then
		M.select_launch_target()
		return
	end

	local dap = require("dap")
	local dapui = require("dapui")

	dapui.setup()

	local cwd = vim.fn.getcwd() .. "/build/" .. settings.buildType .. "/"
	local executable = cwd .. settings.launchTarget

	dap.listeners.after.event_initialized["cmake_dap"] = function()
		vim.schedule(function()
			dapui.open()
		end)
	end

	dap.listeners.before.event_terminated["cmake_dap"] = function()
		vim.schedule(function()
			dapui.close()
		end)
	end

	dap.listeners.before.event_exited["cmake_dap"] = function()
		vim.schedule(function()
			dapui.close()
		end)
	end

	M.build(function(success)
		if not success then
			close_status(0)
			return
		end

		if vim.fn.filereadable(executable) == 0 then
			close_status(0)
			vim.notify("Executable not found:\n" .. executable, vim.log.levels.ERROR)
			return
		end
		close_status(1000)

		local config = {
			name = "CMake Debug",
			type = "gdb",
			request = "launch",
			program = executable,
			cwd = cwd,
		}
		dap.run(config)
	end)
end

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "CMakeLists.txt",
	callback = function()
		M.conigure(function()
			close_status(1000)
		end, true)
	end,
})

-- vim.keymap.set("n", "<F7>", M.build_and_run, { desc = "Build CMake" })
-- vim.keymap.set("n", "<F8>", M.select_build_target, { desc = "Get CMake Build Targets" })
-- vim.keymap.set("n", "<F9>", M.select_launch_target, { desc = "Get CMake Build Targets" })
-- vim.keymap.set("n", "<F10>", M.select_build_type, { desc = "Get CMake Build Targets" })

return M
