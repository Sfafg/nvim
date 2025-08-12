local M = {}

local note_buf = nil
local note_win = nil
local notes_dir = vim.fn.stdpath("data") .. "/sticky_notes/"
local current_note = nil -- Start with no note

-- Ensure the notes directory exists
if vim.fn.isdirectory(notes_dir) == 0 then
	vim.fn.mkdir(notes_dir, "p")
end

-- Function to toggle the sticky note window
M.toggle_note = function()
	if not current_note then
		M.pick_note()
	else
		if note_win and vim.api.nvim_win_is_valid(note_win) then
			M.close_note() -- Close if already open
		else
			M.open_note() -- Open the last picked note
		end
	end
end

-- Function to open the sticky note
M.open_note = function()
	local note_to_open = current_note
	if not note_to_open then
		print("No note selected. Please pick or create a note.")
		return
	end

	local note_path = notes_dir .. note_to_open

	-- Create a new buffer if it doesn't exist
	if not note_buf or not vim.api.nvim_buf_is_valid(note_buf) then
		note_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(note_buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(note_buf, "filetype", "markdown") -- Optional: Enables syntax highlighting
	end

	-- Read existing notes from file
	local notes = {}
	local file = io.open(note_path, "r")
	if file then
		for line in file:lines() do
			table.insert(notes, line)
		end
		file:close()
	end

	vim.api.nvim_buf_set_lines(note_buf, 0, -1, false, notes)

	-- Set up a full-screen floating window
	local width = vim.o.columns
	local height = vim.o.lines
	local win_width = math.max(50, math.floor(width * 0.2)) -- 90% of screen width
	local win_height = math.floor(height) -- 90% of screen height

	local opts = {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = math.floor((height - win_height)),
		col = math.floor((width - win_width)),
		style = "minimal",
		border = "rounded",
	}

	note_win = vim.api.nvim_open_win(note_buf, true, opts)

	-- Auto-save the note on buffer leave
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = note_buf,
		callback = function()
			M.save_note(current_note)
		end,
	})
end

-- Function to save the sticky note
M.save_note = function(filename)
	if not filename or not note_buf or not vim.api.nvim_buf_is_valid(note_buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(note_buf, 0, -1, false)
	local file = io.open(notes_dir .. filename, "w")
	if file then
		for _, line in ipairs(lines) do
			file:write(line .. "\n")
		end
		file:close()
	end
end

-- Function to close the sticky note
M.close_note = function()
	if note_win and vim.api.nvim_win_is_valid(note_win) then
		M.save_note(current_note)
		vim.api.nvim_win_close(note_win, true)
		note_win = nil
	end
end

-- Function to pick a sticky note
M.pick_note = function()
	local notes = {}
	if vim.fn.isdirectory(notes_dir) == 1 then
		for _, filename in ipairs(vim.fn.readdir(notes_dir)) do
			table.insert(notes, filename)
		end
	end
	-- Add option for creating a new note
	table.insert(notes, "Create new note")

	if #notes == 0 then
		print("No sticky notes found! Creating a new one.")
		M.create_new_note()
		return
	end

	-- Use Telescope if available
	local ok, telescope = pcall(require, "telescope.pickers")
	if ok then
		require("telescope.pickers")
			.new({}, {
				prompt_title = "Select a Sticky Note",
				finder = require("telescope.finders").new_table({ results = notes }),
				sorter = require("telescope.config").values.generic_sorter({}),
				attach_mappings = function(_, map)
					map("i", "<CR>", function(prompt_bufnr)
						local selection = require("telescope.actions.state").get_selected_entry()
						require("telescope.actions").close(prompt_bufnr)
						if selection then
							if selection[1] == "Create new note" then
								M.create_new_note()
							else
								current_note = selection[1]
								M.open_note()
							end
						end
					end)

                    map("n", "dd", function(prompt_bufnr)
                        local selection = require("telescope.actions.state").get_selected_entry()
                        if selection and selection[1] ~= "Create new note" and selection[1] ~= "Delete note" then
                            -- require("telescope.actions").close(prompt_bufnr)
                            M.delete_note(selection[1]:gsub(".txt$", "")) -- strip ".txt" just in case
                        else
                            vim.notify("Cannot delete this item.", vim.log.levels.WARN)
                        end
                    end)

                    return true
				end,
			})
			:find()
	else
		-- Fallback to manual input if Telescope is not installed
		local choice = vim.fn.input("Enter note name (or 'Create new note'): ")
		if choice == "Create new note" then
			M.create_new_note()
		elseif choice ~= "" then
			current_note = choice
			M.open_note()
		else
			print("No note selected. Cancelling.")
		end
	end
end

-- Function to create a new note
M.create_new_note = function()
	local note_name = vim.fn.input("Enter new note name: ")
	if note_name ~= "" then
		current_note = note_name .. ".txt"
		M.open_note()
	else
		print("Note name cannot be empty.")
	end
end
--
-- Function to create a new note
M.delete_note = function(note_name)
	if note_name ~= "" then
        local filepath = notes_dir .. note_name .. ".txt"
        local ok, err = os.remove(filepath)

        if not ok then
            vim.notify("Failed to delete note: " .. err, vim.log.levels.ERROR)
        else
            vim.notify("Note deleted: " .. note_name)
        end
	else
		print("Note name cannot be empty.")
	end
end

M.open_notes_explorer = function()
	vim.cmd("Hex " .. notes_dir) -- Opens the explorer in the current directory
end

return M
