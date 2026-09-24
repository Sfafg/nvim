return {
	"jackplus-xyz/player-one.nvim",
	---@type PlayerOne.Config
	opts = {
		theme = "chiptune",
		master_volume = 0.02,
		min_interval = 0.05,
		theme_config = {
			chiptune = {
				CursorMoved = true,
				TextChangedI = true,
			},
		},
	},
}
