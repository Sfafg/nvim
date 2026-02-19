return {
	"L3MON4D3/LuaSnip",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"kleber-swf/vscode-unity-code-snippets",
	},
	config = function()
		require("luasnip.loaders.from_vscode").lazy_load()

		require("luasnip").config.setup({
			history = true,
			updateevents = "TextChanged,TextChangedI",
		})

		require("luasnip").filetype_extend("cs", { "csharp" })
	end,
}
