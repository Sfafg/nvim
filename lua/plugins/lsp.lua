return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		{
			"saghen/blink.cmp",
			dependencies = {
				"saghen/blink.lib",
				"L3MON4D3/LuaSnip",
				"rafamadriz/friendly-snippets",
			},
			build = function()
				require("blink.cmp").build():pwait()
			end,
		},
	},

	config = function()
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "clangd", "pylsp", "texlab", "ts_ls" },
			automatic_installation = true,
		})

		local on_attach = function(_, _)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
			vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to Type Definition" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
			vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, { desc = "LSP References" })
			vim.keymap.set("n", "K", function()
				vim.lsp.buf.hover({ border = "double" })
			end, { desc = "Hover Documentation" })
		end

		vim.keymap.del("n", "grt")
		vim.keymap.del("n", "gri")
		vim.keymap.del("n", "grr")
		vim.keymap.del("n", "grx")
		vim.keymap.del("n", "gra")
		vim.keymap.del("n", "grn")

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
					},
				},
			},
			on_attach = on_attach,
		})
		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--all-scopes-completion",
				"--completion-style=detailed",
			},
			on_attach = on_attach,
		})

		require("luasnip.loaders.from_vscode").lazy_load()
		require("blink.cmp").setup({
			signature = { enabled = true },
			keymap = { preset = "enter" },
			completion = {
				ghost_text = {
					enabled = true,
				},
			},
		})
	end,
}
