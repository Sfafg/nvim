local M = {}

local project_file = vim.fn.stdpath("data") .. "/projects.json"
local sessions_dir = vim.fn.stdpath("data") .. "/project_sessions/"

if vim.fn.isdirectory(sessions_dir) == 0 then
    vim.fn.mkdir(sessions_dir, "p")
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

local function load_keymaps()
    local jumper = require("custom.file_jumper")

    vim.keymap.set("n", "<leader>jp", function()
        local type = get_project_type()
        if type == "dotnet" then
            jumper.jump_to_alternative("^([a-zA-Z][a-z]*).*", "%1Profile.cs")
        end
    end, { desc = "Jump to Profile.cs" })

    vim.keymap.set("n", "<leader>jm", function()
        local type = get_project_type()
        if type == "dotnet" then
            jumper.jump_to_alternative("^([a-zA-Z][a-z]*).*", "%1.cs")
        end
    end, { desc = "Jump to Model.cs" })


    vim.keymap.set("n", "<leader>jc", function()
        local type = get_project_type()
        if type == "dotnet" then
            jumper.jump_to_alternative("^([a-zA-Z][a-z]*).*", "%1Controller.cs")
        end
    end, { desc = "Jump to Controller.cs" })

    vim.keymap.set("n", "<leader>jd", function()
        local type = get_project_type()
        if type == "dotnet" or true then

            -- Find profile file.
            local dir = vim.loop.cwd()
            local buff_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
            if buff_name == "" then
                return 
            end

            buff_name = vim.fn.fnamemodify(buff_name, ":t")
            local class_name =buff_name:match("^([a-zA-Z][a-z]*).*")
            local file_name = class_name .. "Profile.cs"

            local profile_file=""
            local files = vim.fn.glob(dir .. "/**/*", true, true)
            for _, p in ipairs(files) do
                if vim.fn.isdirectory(p) == 1 and vim.loop.fs_stat(p .. "/" .. file_name) then
                    profile_file = p .. "/" .. file_name
                    break
                end
            end

            if profile_file == "" then
                return
            end

            -- Extract dto data from profile.
            local matches = {}

            local file = io.open(profile_file, "r")
            if not file then error("Cannot open file: " .. profile_file) end
            local content = file:read("*a")
            file:close()

            for g1, g2 in content:gmatch("CreateMap<([_a-zA-Z]*)[ ,]*([_a-zA-Z]*)>") do
                if g1 == class_name then
                    table.insert(matches, g2 .. ".cs")
                else
                    table.insert(matches, g1 .. ".cs")
                end
            end
            if #matches == 0 then return end

            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local sorters = require("telescope.config").values.generic_sorter
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")

            pickers.new({}, {
                prompt_title = "Select Data Transfer Unit",
                finder = finders.new_table({ results = matches }),
                sorter = sorters({}),
                attach_mappings = function(_, map)
                    map("i", "<CR>", function(prompt_bufnr)
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if not selection then return end
                        jumper.jump_to_alternative("^.*", selection.value)
                    end)

                    return true
                end,
            }):find()
        end
    end, { desc = "Jump to Data transfer unit" })
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
    load_keymaps()
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


local function project_build()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").build()

    elseif type == "latex" then
        vim.cmd("VimtexCompile")

    elseif type == "dotnet" then
        vim.cmd("cclose")
        vim.cmd("compiler dotnet")
        vim.cmd("silent make")

        if vim.fn.getqflist({size = 0}).size > 0 then
            vim.cmd("copen")
            return false
        end

    elseif type == "lua" then
        vim.cmd("so")
    end
    return true
end

local run_job = 0
local function project_run()
    local type = get_project_type()
    if type == "cmake" then
        require("cmake-tools").run()
    elseif type == "dotnet" then
        -- vim.cmd("terminal dotnet run")
        vim.cmd(11 .. " split")
        local term_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(0, term_buf)

        if run_job ~= 0 then
            vim.fn.jobstop(run_job)
        end
         run_job = vim.fn.termopen("dotnet run", {
            on_exit = function(_, code, _)
            end
         })

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
vim.keymap.set("n", "<F5>", function() if project_build() then project_run()end end, { desc = "Build and Run project" })
vim.keymap.set("n", "<F2>", project_f2, { desc = "Select Build Type" })
vim.keymap.set("n", "<F3>", project_f3, { desc = "Select Launch Target" })
vim.keymap.set("n", "<F4>", project_f4, { desc = "Select Build Target" })

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        save_session()
    end,
})

-- if vim.fn.filereadable(project_file) == 1 then
-- 	local list = load_projects()
    -- if list[1] ~= nil then
    --     open_project(list[1])
    -- end
-- end

function M.setup()
end
return M
