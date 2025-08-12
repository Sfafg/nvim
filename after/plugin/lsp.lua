require("mason").setup()
-- require("mason-lspconfig").setup({
-- 	ensure_installed = { "lua_ls", "clangd", "cmake", "pylsp", "texlab", "ts_ls" },
-- 	automatic_installation = true,
-- })

local on_attach = function(_, _)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
	vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, {})
	vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
end


local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")
local servers = { "clangd", "lua_ls", "cmake", "pylsp", "texlab", "ts_ls" }
for _, lsp in ipairs(servers) do
    if lsp == "clangd" then
        lspconfig.clangd.setup({
            cmd = { "clangd", "--completion-style=detailed", },
            on_attach = on_attach,
            capabilities = capabilities,
        })
    else
        lspconfig[lsp].setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })
    end
end

require('lsp_signature').on_attach({
  bind = true,
  handler_opts = {
    border = "rounded"
  }
})
-- luasnip setup
local luasnip = require("luasnip")

-- nvim-cmp setup
local cmp = require("cmp")
cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-u>"] = cmp.mapping.scroll_docs(-4), -- Up
		["<C-d>"] = cmp.mapping.scroll_docs(4), -- Down
		-- C-b (back) C-f (forward) for snippet placeholder navigation.
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		}),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "pylsp"},
		{ name = "texlab"},
		{ name = "ts_ls"},
	},
})
