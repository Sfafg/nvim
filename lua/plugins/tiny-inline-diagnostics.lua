return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		-- event = "VeryLazy",
		priority = 1000,
		opts = {},
		config = function()
			require("tiny-inline-diagnostic").setup({})
		end,
	},
}
