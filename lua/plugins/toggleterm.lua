return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			require("toggleterm").setup({
				size = 80,
				open_mapping = [[<C-t>]],
				direction = "vertical",
				close_on_exit = true,
			})
		end,
	},
}
