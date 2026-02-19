local M = {}

local colorscheme_file = vim.fn.stdpath("data") .. "/colorscheme.txt"
local opacity_file = vim.fn.stdpath("data") .. "/opacity.txt"

local function save_colorscheme(scheme)
	local f = assert(io.open(colorscheme_file, "w"))
	f:write(scheme)
	f:close()
end

local function save_opacity(op)
	local f = assert(io.open(opacity_file, "w"))
	f:write(op)
	f:close()
end

local function set_colorscheme(scheme)
	vim.cmd.colorscheme(scheme)
	vim.cmd.colorscheme(scheme)
end

local function set_opacity(op)
	if vim.g.neovide then
		vim.g.neovide_opacity = op
	end
end

function M.load_colorscheme()
	local f = io.open(colorscheme_file, "r")
	if not f then
		return
	end
	local data = f:read("*a")
	f:close()
	set_colorscheme(data)
end

function M.load_opacity()
	local f = io.open(opacity_file, "r")
	if not f then
		return
	end
	local data = f:read("*a")
	f:close()
	set_opacity(data)
end

local function color_picker()
	local list = vim.fn.getcompletion("", "color")

	local ok, telescope = pcall(require, "telescope.pickers")
	if not ok then
		print("Telescope required!")
		return
	end

	telescope
		.new({}, {
			prompt_title = "Select colorscheme",
			finder = require("telescope.finders").new_table({ results = list }),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					require("telescope.actions").close(prompt_bufnr)

					if not selection then
						return
					end

					set_colorscheme(selection.value)
					save_colorscheme(selection.value)
				end)

				return true
			end,

			previewer = require("telescope.previewers").new({
				teardown = function(self)
					M.load_colorscheme()
				end,

				preview_fn = function(self, entry, status)
					set_colorscheme(entry.value)
				end,
			}),
			layout_config = {
				anchor = "NE",
				width = 0.1,
				height = 0.3,
				preview_width = 1,
			},
		})
		:find()
end

vim.api.nvim_create_user_command("ColorschemeSelect", function()
	color_picker()
end, {})

vim.api.nvim_create_user_command("ColorschemeOpacity", function(opts)
	local n = tonumber(opts.args)
	set_opacity(n)
	save_opacity(n)
end, { nargs = 1 })

function M.setup() end
return M
