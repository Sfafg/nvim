vim.g.mapleader = " "
vim.keymap.set("n", "<leader>d", "Vyp")

vim.keymap.set("n", "<Tab>", ":bprev<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<S-Tab>", ":bnext<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>j", ":cnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>k", ":cprev<CR>", { noremap = true, silent = true })

vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")
vim.keymap.set("i", "<C-l>", "<Right>")

vim.keymap.set("i", "<C-b>", "<C-o>b")
vim.keymap.set("i", "<C-w>", "<C-o>w")
vim.keymap.set("i", "<C-d>w", "<C-o>dw")
vim.keymap.set("i", "<C-d>d", "<C-o>dd")
vim.keymap.set("i", "<C-u>", "<C-o>u")

vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-S-s>", ":wa<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>c", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>v", '"+p', { noremap = true, silent = true })
vim.keymap.set("v", "<leader>c", '"+y', { noremap = true, silent = true })
vim.keymap.set("v", "<leader>v", '"+p', { noremap = true, silent = true })

vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>ss", ":SessionSearch<CR>", { noremap = true, silent = true })

vim.keymap.set("t", "<Esc>","<C-\\><C-n>" , { noremap = true, silent = true })

vim.keymap.set("n", "<leader>nn", function()
	require("custom.sticky_notes").toggle_note()
end, { desc = "Toggle Sticky Note" })

vim.keymap.set("n", "<leader>nf", function()
	require("custom.sticky_notes").pick_note()
end, { desc = "Pick or Create Sticky Note" })

vim.keymap.set("n", "<leader>ne", function()
	require("custom.sticky_notes").open_notes_explorer()
end, { desc = "Toggle Sticky Note" })

