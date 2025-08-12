-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])
return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"ellisonleao/gruvbox.nvim",
		as = "gruvbox",
		config = function()
			vim.cmd("colorscheme palenight")
		end,
	})

    use({ "nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" } })
    use("ThePrimeagen/harpoon")
    use("mbbill/undotree")
    use("tpope/vim-fugitive")
    use("hrsh7th/nvim-cmp") -- Completion engine
    use("hrsh7th/cmp-nvim-lsp") -- LSP source for nvim-cmp
    use("saadparwaiz1/cmp_luasnip") -- Snippet completions
    use("L3MON4D3/LuaSnip") -- Snippet engine
    use("williamboman/mason.nvim") -- Mason for LSP management
    use("neovim/nvim-lspconfig") -- LSP configuration
    use({"williamboman/mason-lspconfig.nvim",requires = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"}}) -- Mason LSP config helper
    use("stevearc/conform.nvim")
    use("hrsh7th/cmp-buffer") -- Buffer completions
    use("hrsh7th/cmp-path") -- Path completions
    use({ "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } })
    use("theHamsta/nvim-dap-virtual-text") -- Virtual text for variable values
    use("jay-babu/mason-nvim-dap.nvim") -- Auto-install DAP adapters
    use({ "Civitasv/cmake-tools.nvim", requires = { "nvim-lua/plenary.nvim" } })
    use("echasnovski/mini.ai")
    use("windwp/nvim-autopairs")
    use("rmagatti/auto-session")
    use({ "kevinhwang91/nvim-ufo", requires = "kevinhwang91/promise-async" })
    use("terrortylor/nvim-comment")
    use("terryma/vim-multiple-cursors")
    use ({ 'jakemason/ouroboros', requires =  {'nvim-lua/plenary.nvim'}} )
    use("lervag/vimtex")
    -- use("airblade/vim-gitgutter")
    use("rbong/vim-flog")
    use("junegunn/vim-easy-align")
    use("ray-x/lsp_signature.nvim")
    use('drewtempelmeyer/palenight.vim')
    use( "stevearc/oil.nvim" )
    use("folke/zen-mode.nvim")
    use("vim-scripts/DoxygenToolkit.vim")
end)
