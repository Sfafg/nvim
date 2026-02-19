vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.clipboard = unnamedplus

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 10
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.colorcolumn = "1000"
vim.g.mapleader = " "
vim.o.hidden = true
vim.o.autoread = true

vim.g.dotnet_errors_only = true
vim.g.dotnet_show_project_file = false

if vim.g.neovide then
	vim.api.nvim_set_hl(0, "Normal", { bg = "#202020" })
	vim.o.guifont = "JetBrainsMono Nerd Font Mono:h14"
	vim.g.neovide_opacity = 0.9
	vim.g.neovide_cursor_animation_length = 0.07
	vim.g.neovide_cursor_trail_size = 0
	vim.g.neovide_cursor_animate_in_insert_mode = false
	vim.g.neovide_cursor_animate_command_line = false

	vim.g.neovide_position_animation_length = 0.1
	vim.g.neovide_scroll_animation_length = 0.1
	vim.g.neovide_scroll_animation_far_lines = 0.1
	vim.g.neovide_frameless = true
end
