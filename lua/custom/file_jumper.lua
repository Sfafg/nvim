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
		return
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
	else
		print(file_name .. " not found")
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

vim.keymap.set("n", "<leader>jl", function()
	show_jump_list()
end, { desc = "Show Jump List" })

vim.keymap.set("n", "<leader>j1", function()
	jump_to_index(1)
end, { desc = "Jump list at index 1" })
vim.keymap.set("n", "<leader>j2", function()
	jump_to_index(2)
end, { desc = "Jump list at index 2" })
vim.keymap.set("n", "<leader>j3", function()
	jump_to_index(3)
end, { desc = "Jump list at index 3" })
vim.keymap.set("n", "<leader>j4", function()
	jump_to_index(4)
end, { desc = "Jump list at index 4" })
vim.keymap.set("n", "<leader>j5", function()
	jump_to_index(5)
end, { desc = "Jump list at index 5" })
vim.keymap.set("n", "<leader>j6", function()
	jump_to_index(6)
end, { desc = "Jump list at index 6" })
vim.keymap.set("n", "<leader>j7", function()
	jump_to_index(7)
end, { desc = "Jump list at index 7" })
vim.keymap.set("n", "<leader>j8", function()
	jump_to_index(8)
end, { desc = "Jump list at index 8" })
vim.keymap.set("n", "<leader>j9", function()
	jump_to_index(9)
end, { desc = "Jump list at index 9" })
vim.keymap.set("n", "<leader>j0", function()
	jump_to_index(10)
end, { desc = "Jump list at index 10" })

vim.keymap.set("n", "<leader>js1", function()
	set_jump_to_file_at_index(1)
end, { desc = "Jump list at index 1" })
vim.keymap.set("n", "<leader>js2", function()
	set_jump_to_file_at_index(2)
end, { desc = "Jump list at index 2" })
vim.keymap.set("n", "<leader>js3", function()
	set_jump_to_file_at_index(3)
end, { desc = "Jump list at index 3" })
vim.keymap.set("n", "<leader>js4", function()
	set_jump_to_file_at_index(4)
end, { desc = "Jump list at index 4" })
vim.keymap.set("n", "<leader>js5", function()
	set_jump_to_file_at_index(5)
end, { desc = "Jump list at index 5" })
vim.keymap.set("n", "<leader>js6", function()
	set_jump_to_file_at_index(6)
end, { desc = "Jump list at index 6" })
vim.keymap.set("n", "<leader>js7", function()
	set_jump_to_file_at_index(7)
end, { desc = "Jump list at index 7" })
vim.keymap.set("n", "<leader>js8", function()
	set_jump_to_file_at_index(8)
end, { desc = "Jump list at index 8" })
vim.keymap.set("n", "<leader>js9", function()
	set_jump_to_file_at_index(9)
end, { desc = "Jump list at index 9" })
vim.keymap.set("n", "<leader>js0", function()
	set_jump_to_file_at_index(10)
end, { desc = "Jump list at index 10" })

function M.setup() end
return M
