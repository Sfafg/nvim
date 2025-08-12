local format_file = vim.fn.stdpath("config") .. "/after/plugin/ccpp.clang-format"

require("conform").setup({
	log_level = vim.log.levels.TRACE,
	formatters = {
		clang_format = {
			prepend_args = { "-style=file:" .. format_file },
		},
        prettier = {
            prepend_args = { "--use-tabs" }
        },
	},
	formatters_by_ft = {
		lua = { "stylua" },
		cpp = { "clang_format" },
		c = { "clang_format" },
		python = { "black" },
		tex = { "latexindent" },
		js = { "prettier" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.ini","*.tex","*.py","*.c", "*.cpp", "*.h", "*.hpp", "*.js"}, -- Apply only to C/C++ files
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})
