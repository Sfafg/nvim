return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{
			"<leader>sf",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "Telescope find files",
		},
		{
			"<leader>st",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "Telescope find phrase",
		},
	},
	config = function()
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = {
					"node_modules",
					"%.git/",
					".build/",
					"%.lock",
					"%.jpg",
					"%.png",
					"__pycache__",
					"__pycache__",
					"%.o",
					"%.out",
					"CMakeFiles\\",
					".cmake\\",
					".cache\\",
					"%.cmake",
				},
			},
		})
	end,
}
