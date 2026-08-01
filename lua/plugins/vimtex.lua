return {
	"lervag/vimtex",
	dependencies = {
		"folke/snacks.nvim",
	},
	config = function()
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_general_viewer = "zathura"
		vim.g.vimtex_view_general_options = "-reuse-instance -forward-search %f %l"

		vim.g.vimtex_compiler_method = "latexmk"
	end,
}
