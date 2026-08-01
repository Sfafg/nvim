return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"nvim-telescope/telescope.nvim",
		},
		opts = { inlay_hints = { enabled = true } },
		config = function()
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
				vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
			end
			vim.keymap.del("n", "grt")
			vim.keymap.del("n", "gri")
			vim.keymap.del("n", "grr")
			vim.keymap.del("n", "grx")
			vim.keymap.del("n", "gra")
			vim.keymap.del("n", "grn")

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local servers = { "omnisharp", "clangd", "lua_ls", "pylsp", "texlab", "ts_ls" }
			for _, lsp in ipairs(servers) do
				local opts = {
					on_attach = on_attach,
					capabilities = capabilities,
				}

				if lsp == "clangd" then
					opts.cmd = {
						"clangd",
						"--all-scopes-completion",
						"--completion-style=detailed",
					}
				end

				if lsp == "lua_ls" then
					opts.settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
							},
						},
					}
				end

				vim.lsp.config(lsp, opts)
				vim.lsp.enable(lsp)
			end
		end,
	},
}
