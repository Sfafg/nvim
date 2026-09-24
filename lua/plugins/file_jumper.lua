local M = {}

local jump_list_dir = vim.fn.stdpath("data") .. "/project_jump_lists/"

if vim.fn.isdirectory(jump_list_dir) == 0 then
	vim.fn.mkdir(jump_list_dir, "p")
end

local function bfs_files(root)
	local queue = { root }
	local out = {}

	while #queue > 0 do
		local dir = table.remove(queue, 1) -- FIFO

		table.insert(out, dir)

		local iter = vim.loop.fs_scandir(dir)
		if iter then
			while true do
				local name, t = vim.loop.fs_scandir_next(iter)
				if not name then
					break
				end

				if t == "directory" then
					table.insert(queue, dir .. "/" .. name)
				end
			end
		end
	end

	return out
end

local function save_jump_list(list)
	local project_name = vim.fn.getcwd():match("^.*/(.*)$") or vim.fn.getcwd()
	local jump_list = jump_list_dir .. project_name .. ".json"
	local f = assert(io.open(jump_list, "w"))
	f:write(vim.fn.json_encode(list))
	f:close()
end

local function load_jump_list()
	local project_name = vim.fn.getcwd():match("^.*/(.*)$") or vim.fn.getcwd()
	local jump_list = jump_list_dir .. project_name .. ".json"
	local f = io.open(jump_list, "r")
	if not f then
		return {}
	end
	local data = f:read("*a")
	f:close()
	local ok, decoded = pcall(vim.fn.json_decode, data)
	return ok and decoded or {}
end

local function jump_to_index(index)
	local list = load_jump_list()
	if index > #list then
		return
	end
	if list[index] == nil then
		return
	end

	local file_dir = list[index][1]
	local line_number = list[index][2]
	local column_number = list[index][3]

	vim.cmd("silent! edit " .. file_dir)
	-- vim.api.nvim_win_set_cursor(0, {line_number, column_number})
end

local function set_jump_to_file_at_index(index)
	local list = load_jump_list()

	local buf = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(buf)
	if path == "" then
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	list[index] = { path, row, col }
	save_jump_list(list)
end

function M.jump_to_alternative(pattern, replacement)
	local dir = vim.loop.cwd()
	local buff_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	if buff_name == "" then
		return false
	end

	buff_name = vim.fn.fnamemodify(buff_name, ":t")
	local file_name = buff_name:gsub(pattern, replacement)
	print(file_name)

	local jump_file = ""
	local files = vim.fn.glob(dir .. "/**/*", true, true)
	for _, p in ipairs(files) do
		if vim.fn.isdirectory(p) == 1 and vim.loop.fs_stat(p .. "/" .. file_name) then
			jump_file = p .. "/" .. file_name
			break
		end
	end

	if jump_file ~= "" then
		vim.cmd("silent! edit " .. jump_file)
		return true
	else
		return false
	end
end
function M.jump_based_on_extension(config)
	local current = vim.api.nvim_buf_get_name(0)

	if current == "" then
		vim.notify("Current buffer has no file name", vim.log.levels.WARN)
		return
	end

	local filename = vim.fs.basename(current)
	local dir = vim.fs.dirname(current)

	local stem, ext = filename:match("^(.*)%.([^%.]+)$")

	if not stem or not ext then
		vim.notify("Could not determine file extension", vim.log.levels.WARN)
		return
	end

	-- Find the extension group.
	local group

	for _, extensions in ipairs(config.extensions) do
		for _, candidate in ipairs(extensions) do
			if candidate == ext then
				group = extensions
				break
			end
		end

		if group then
			break
		end
	end

	if not group then
		vim.notify("No related extensions configured for ." .. ext, vim.log.levels.WARN)
		return
	end

	-- Preferred extensions for the current extension.
	local targets = config.targets[ext] or {}

	-- If no explicit targets were configured, use the rest of the group.
	if #targets == 0 then
		for _, candidate in ipairs(group) do
			if candidate ~= ext then
				table.insert(targets, candidate)
			end
		end
	end

	---------------------------------------------------------------------------
	-- Search.
	--
	-- IMPORTANT:
	-- Directory proximity takes priority over extension preference.
	--
	-- current directory:
	--   foo.h
	--   foo.hpp
	--   foo.c
	--
	-- then parent directory:
	--   foo.h
	--   foo.hpp
	--   foo.c
	--
	---------------------------------------------------------------------------

	local search_dir = dir

	while search_dir do
		for _, target_ext in ipairs(targets) do
			local candidate = vim.fs.joinpath(search_dir, stem .. "." .. target_ext)

			if vim.uv.fs_stat(candidate) then
				vim.cmd.edit(vim.fn.fnameescape(candidate))
				return
			end
		end

		local parent = vim.fs.dirname(search_dir)

		if parent == search_dir then
			break
		end

		search_dir = parent
	end

	---------------------------------------------------------------------------
	-- Nothing found.
	---------------------------------------------------------------------------

	local target_ext = targets[1]

	if not target_ext then
		vim.notify("No target extension configured", vim.log.levels.WARN)
		return
	end

	local default_path = vim.fs.joinpath(dir, stem .. "." .. target_ext)

	vim.ui.input({
		prompt = "Create related file: ",
		default = default_path,
	}, function(path)
		if not path or path == "" then
			return
		end

		path = vim.fn.expand(path)

		local parent = vim.fs.dirname(path)

		if not vim.uv.fs_stat(parent) then
			vim.fn.mkdir(parent, "p")
		end

		local new_ext = path:match("%.([^%.]+)$")

		local contents = ""

		if config.defaults[new_ext] then
			contents = config.defaults[new_ext](filename)
		end

		local file = io.open(path, "w")

		if not file then
			vim.notify("Could not create file: " .. path, vim.log.levels.ERROR)
			return
		end

		file:write(contents)
		file:close()

		vim.cmd.edit(vim.fn.fnameescape(path))
	end)
end

function M.jump_to_alternative_match(pattern)
	local dir = vim.loop.cwd()

	local jump_file = ""
	local files = vim.fs.find(function(name)
		return name:match(pattern)
	end, { path = dir, type = "file" })

	jump_file = files[1]

	if jump_file and jump_file ~= "" then
		vim.cmd("silent! edit " .. jump_file)
		return true
	else
		return false
	end
end

function M.jump_to_alternative_function(f)
	local dir = vim.loop.cwd()
	local buff_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	if buff_name == "" then
		return
	end

	buff_name = vim.fn.fnamemodify(buff_name, ":t")
	local file_name = f(buff_name)

	local jump_file = ""
	local files = bfs_files(dir)

	for _, p in ipairs(files) do
		if vim.fn.isdirectory(p) == 1 and vim.loop.fs_stat(p .. "/" .. file_name) then
			jump_file = p .. "/" .. file_name
			break
		end
	end

	if jump_file ~= "" then
		vim.cmd("silent! edit " .. jump_file)
	else
		print(file_name .. " not found")
	end
end

local function show_jump_list()
	local list = load_jump_list()

	local jumps = {}
	local longest = 0
	local longest_row = 0

	for index = 1, #list do
		local sublist = list[index]
		if sublist ~= nil and type(sublist) == "table" then
			local cwd = vim.loop.cwd()
			local relative_path = sublist[1]:gsub("^" .. vim.pesc(cwd) .. "/?", "")
			local row_length = "" .. sublist[2] .. ""
			if #relative_path > longest then
				longest = #relative_path
			end
			if #row_length > longest_row then
				longest_row = #row_length
			end
		end
	end

	for index = 1, #list do
		local sublist = list[index]
		if sublist ~= nil and type(sublist) == "table" then
			local cwd = vim.loop.cwd()
			local relative_path = sublist[1]:gsub("^" .. vim.pesc(cwd) .. "/?", "")
			local spacing = longest - #relative_path + 2
			local row_spacing = longest_row - #(sublist[2] .. "") + 2
			table.insert(
				jumps,
				"Index:"
					.. index
					.. ((index < 10) and "  " or " ")
					.. relative_path
					.. string.rep(" ", spacing)
					.. "Row:"
					.. sublist[2]
					.. string.rep(" ", row_spacing)
					.. "Column:"
					.. sublist[3]
			)
			index = index + 1
		end
	end

	local ok, telescope = pcall(require, "telescope.pickers")
	if not ok then
		print("Telescope required!")
		return
	end

	telescope
		.new({}, {
			prompt_title = "Select Jump",
			finder = require("telescope.finders").new_table({ results = jumps }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					require("telescope.actions").close(prompt_bufnr)
					if not selection then
						return
					end

					jump_to_index(selection.index)
				end)

				return true
			end,
		})
		:find()
end

vim.keymap.set("n", "<leader>jj", function()
	M.jump_based_on_extension({
		extensions = {
			{ "c", "cpp", "h", "hpp" },
			{ "frag", "vert" },
		},

		targets = {
			c = { "h", "hpp", "cpp" },
			cpp = { "h", "hpp", "c" },

			h = { "cpp", "c" },
			hpp = { "cpp", "c" },

			frag = { "vert" },
			vert = { "frag" },
		},

		defaults = {
			h = function()
				return "#pragma once\n"
			end,

			hpp = function()
				return "#pragma once\n"
			end,

			c = function(original_file)
				return '#include "' .. original_file .. '"\n'
			end,

			cpp = function(original_file)
				return '#include "' .. original_file .. '"\n'
			end,

			frag = function()
				return ""
			end,

			vert = function()
				return ""
			end,
		},
	})
end, { desc = "Jump based on extension" })

vim.keymap.set("n", "<leader>lj", function()
	show_jump_list()
end, { desc = "Show Jump List" })

vim.keymap.set("n", "<leader>1", function()
	jump_to_index(1)
end, { desc = "Jump list at index 1" })
vim.keymap.set("n", "<leader>2", function()
	jump_to_index(2)
end, { desc = "Jump list at index 2" })
vim.keymap.set("n", "<leader>3", function()
	jump_to_index(3)
end, { desc = "Jump list at index 3" })
vim.keymap.set("n", "<leader>4", function()
	jump_to_index(4)
end, { desc = "Jump list at index 4" })
vim.keymap.set("n", "<leader>5", function()
	jump_to_index(5)
end, { desc = "Jump list at index 5" })
vim.keymap.set("n", "<leader>6", function()
	jump_to_index(6)
end, { desc = "Jump list at index 6" })
vim.keymap.set("n", "<leader>7", function()
	jump_to_index(7)
end, { desc = "Jump list at index 7" })
vim.keymap.set("n", "<leader>8", function()
	jump_to_index(8)
end, { desc = "Jump list at index 8" })
vim.keymap.set("n", "<leader>9", function()
	jump_to_index(9)
end, { desc = "Jump list at index 9" })
vim.keymap.set("n", "<leader>0", function()
	jump_to_index(10)
end, { desc = "Jump list at index 10" })

vim.keymap.set("n", "<leader>s1", function()
	set_jump_to_file_at_index(1)
end, { desc = "Jump list at index 1" })
vim.keymap.set("n", "<leader>s2", function()
	set_jump_to_file_at_index(2)
end, { desc = "Jump list at index 2" })
vim.keymap.set("n", "<leader>s3", function()
	set_jump_to_file_at_index(3)
end, { desc = "Jump list at index 3" })
vim.keymap.set("n", "<leader>s4", function()
	set_jump_to_file_at_index(4)
end, { desc = "Jump list at index 4" })
vim.keymap.set("n", "<leader>s5", function()
	set_jump_to_file_at_index(5)
end, { desc = "Jump list at index 5" })
vim.keymap.set("n", "<leader>s6", function()
	set_jump_to_file_at_index(6)
end, { desc = "Jump list at index 6" })
vim.keymap.set("n", "<leader>s7", function()
	set_jump_to_file_at_index(7)
end, { desc = "Jump list at index 7" })
vim.keymap.set("n", "<leader>s8", function()
	set_jump_to_file_at_index(8)
end, { desc = "Jump list at index 8" })
vim.keymap.set("n", "<leader>s9", function()
	set_jump_to_file_at_index(9)
end, { desc = "Jump list at index 9" })
vim.keymap.set("n", "<leader>s0", function()
	set_jump_to_file_at_index(10)
end, { desc = "Jump list at index 10" })

return M
