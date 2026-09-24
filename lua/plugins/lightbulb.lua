return {
	"kosayoda/nvim-lightbulb",
	event = "LspAttach",
	opts = {
		autocmd = {
			enabled = true,
			updatetime = 200,
			events = { "CursorHold", "CursorHoldI" },
		},
	},
}
