local format_file = vim.fn.stdpath("config") .. "/after/plugin/ccpp.clang-format"

vim.cmd("hi Normal ctermbg=none guibg=none")
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
		cs = { "csharpier" },
		python = { "black" },
		tex = { "latexindent" },
		js = { "prettier" },
        javascript = { "prettier" },
        ts = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },
        glsl = { "clang_format" },
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = {"*.vert","*.frag","*.comp","*.nvim", "*.ini","*.tex","*.py", "*.tsx", "*.cs","*.c", "*.cpp", "*.h", "*.hpp", "*.js"}, -- Apply only to C/C++ files
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})
