local M = {}

local project_file = vim.fn.stdpath("data") .. "/projects.json"
local sessions_dir = vim.fn.stdpath("data") .. "/project_sessions/"

if vim.fn.isdirectory(sessions_dir) == 0 then
    vim.fn.mkdir(sessions_dir, "p")
end

local function save_session()
    local project_name = vim.fn.getcwd():match("^.*/(.*)$") or vim.fn.getcwd()
	local session = sessions_dir .. project_name .. ".vim"
	vim.cmd("silent! mksession! " .. session)
end

local function save_projects(list)
	local f = assert(io.open(project_file, "w"))
	f:write(vim.fn.json_encode(list))
	f:close()
end

local function load_projects()
	local f = io.open(project_file, "r")
	if not f then return {} end
	local data = f:read("*a")
	f:close()
	local ok, decoded = pcall(vim.fn.json_decode, data)
	local list = ok and decoded or {}

    for i = #list, 1, -1 do
        if vim.fn.isdirectory(list[i]) == 0 then
            table.remove(list, i)
        end
    end
    save_projects(list)
    return list
end

local function open_project(project)
	if vim.fn.isdirectory(project) == 0 then
        return
	end
	local list = load_projects()
	if not vim.tbl_contains(list, project) then
        return
	end
    save_session()

    local project_name = project:match("^.*/(.*)$") or project
	local session = sessions_dir .. project_name .. ".vim"

    vim.cmd("silent! bufdo bwipeout!")
    vim.api.nvim_set_current_dir(project)
    if vim.fn.filereadable(session) == 1 then
        vim.cmd("silent! source " .. session)
    end

    local index = 0
    for i = #list, 1, -1 do
        if list[i] == project then
            index = i
            break
        end
    end

    local value = table.remove(list, index)
    table.insert(list, 1, value) 
    save_projects(list)
end

local function create_or_add_project()
    local default = vim.fn.getcwd()
    local project_dir = vim.fn.input("Project directory: ", default, "dir")
    project_dir = project_dir:gsub("/+$", "")
    if project_dir == nil or project_dir == "" then
		return
	end
	
	if vim.fn.isdirectory(project_dir) == 0 then
	    vim.fn.mkdir(project_dir, "p")
	end

	local list = load_projects()

	if not vim.tbl_contains(list, project_dir) then
		table.insert(list, project_dir)
		save_projects(list)
	end
    print(project_dir)
    open_project(project_dir)
end

local function add_project()
    local default = vim.fn.getcwd()
    local project_dir = vim.fn.input("Project directory: ", default, "dir")
    project_dir = project_dir:gsub("/+$", "")
    if project_dir == nil or project_dir == "" then
		return
	end
	
	if vim.fn.isdirectory(project_dir) == 0 then
        print("Project does not exist")
        return
	end

	local list = load_projects()

	if not vim.tbl_contains(list, project_dir) then
		table.insert(list, project_dir)
		save_projects(list)
	end
    open_project(project_dir)
end

local function delete_project(project)
	local list = load_projects()
    for i = #list, 1, -1 do
        if list[i] == project then
            table.remove(list, i)
            save_projects(list)
            return
        end
    end
end

local function picker()
	local list = load_projects()
    local filenames={}
    for _, path in ipairs(list) do
        local name = path:match("^.*/(.*)$") or path
        table.insert(filenames, name)
    end

	table.insert(filenames, "-Create new project-")
	table.insert(filenames, "-Add project-")

	local ok, telescope = pcall(require, "telescope.pickers")
    if not ok then
        print("Telescope required!")
        return
    end

	telescope.new({}, {
        prompt_title = "Select Project",
        finder = require("telescope.finders").new_table({ results = filenames }),
        sorter = require("telescope.config").values.generic_sorter({}),
        attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
            local selection = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(prompt_bufnr)
            if not selection then
                return
            end

            if selection.value == "-Create new project-"then
                create_or_add_project()
                return
            end

            if selection.value == "-Add project-"then
                add_project()
                return
            end

            open_project(list[selection.index])
        end)

        map("n", "dd", function(prompt_bufnr)
            local selection = require("telescope.actions.state").get_selected_entry()
            if selection and selection.value ~= "-Create new project-" and selection.value ~= "-Add project-" then
                delete_project(list[selection.index])
                require("telescope.actions").close(prompt_bufnr)
                picker()
            end
        end)

        return true
        end,
    }) :find()
end

local function get_project_type()
    local dir = vim.fn.getcwd()

    if vim.fn.filereadable(dir .. "/CMakeLists.txt") == 1 then
        return "cmake"
    end

    if vim.fn.globpath(dir, "*.tex") ~= "" then
        return "latex"
    end

    if vim.fn.globpath(dir, "*.csproj") ~= "" then
        return "dotnet"
    end

    if vim.fn.globpath(dir, "*.csproj") ~= "" then
        return "dotnet"
    end

    if vim.fn.expand("%:t"):match("^.+%.(.+)$") == "lua" then
        return "lua"
    end

    return nil
end

local function project_build()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").build()
    elseif type == "latex" then
        vim.cmd("VimtexCompile")
    elseif type == "dotnet" then
        vim.cmd("!dotnet build")
    elseif type == "lua" then
        vim.cmd("so")
    end
end

local function project_run()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").run()
    elseif type == "dotnet" then
        vim.cmd("!dotnet run")
    elseif type == "lua" then
        vim.cmd("so")
    end
end

local function project_debug()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").debug()
    end
end

local function project_f2()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").select_build_type()
    end
end

local function project_f3()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").select_launch_target()
    end
end

local function project_f4()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").select_buid_target()
    end
end

vim.keymap.set("n", "<leader>sp", function()
    picker()
end, { desc = "Project picker" })
vim.keymap.set("n", "<leader>ps", function()
    save_session()
end, { desc = "Save project session" })

vim.keymap.set("n", "<S-F5>", project_build, { desc = "Build project" })
vim.keymap.set("n", "<C-F5>", project_debug, { desc = "Debug project" })
vim.keymap.set("n", "<F5>", function() project_build() project_run() end, { desc = "Build and Run project" })
vim.keymap.set("n", "<F2>", project_f2, { desc = "Select Build Type" })
vim.keymap.set("n", "<F3>", project_f3, { desc = "Select Launch Target" })
vim.keymap.set("n", "<F4>", project_f4, { desc = "Select Build Target" })

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        save_session()
    end,
})

if vim.fn.filereadable(project_file) == 1 then
	local list = load_projects()
    if list[1] ~= nil then
        open_project(list[1])
    end
end

function M.setup()
end
return M
