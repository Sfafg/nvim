require("mason").setup()
require("mason-nvim-dap").setup({
	ensure_installed = { "cppdbg" }, -- Add more as needed
	automatic_installation = true,
})
