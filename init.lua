-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
    "wbthomason/packer.nvim",

    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    { "ellisonleao/gruvbox.nvim", name = "gruvbox" },

    {
     "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        require('nvim-treesitter.configs').setup {
          ensure_installed = { "cpp", "cmake", "c", "lua","python", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
          sync_install = false,
          auto_install = false,
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
        }
      end},

    "ThePrimeagen/harpoon",
    "mbbill/undotree",
    "tpope/vim-fugitive",

    -- Completion
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "saadparwaiz1/cmp_luasnip",
    "L3MON4D3/LuaSnip",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",

    -- LSP
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    },

    "stevearc/conform.nvim",

    -- DAPlaz
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    },
    "theHamsta/nvim-dap-virtual-text",
    "jay-babu/mason-nvim-dap.nvim",

    -- Utilities
    { "Civitasv/cmake-tools.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    "echasnovski/mini.ai",
    "windwp/nvim-autopairs",
    { "kevinhwang91/nvim-ufo", dependencies = "kevinhwang91/promise-async" },
    "terrortylor/nvim-comment",
    "terryma/vim-multiple-cursors",
    {
        "jakemason/ouroboros",
        dependencies = { "nvim-lua/plenary.nvim" },
        ft = { "cpp", "glsl", "c" },
        config = function()
            require("ouroboros").setup({
                extension_preferences_table = {
                    vert = { frag = 1 },
                    frag = { vert = 1 },
                    c = { h = 2, hpp = 1 },
                    h = { c = 2, cpp = 3 },
                    cpp = { hpp = 2, h = 3 },
                    hpp = { cpp = 1, c = 2 },
                },
                switch_to_open_pane_if_possible = true,
            })
        end,
    },
    "lervag/vimtex",
    "rbong/vim-flog",
    "junegunn/vim-easy-align",
    "ray-x/lsp_signature.nvim",
    "drewtempelmeyer/palenight.vim",
    "stevearc/oil.nvim",
    "folke/zen-mode.nvim",
    "vim-scripts/DoxygenToolkit.vim",
    "github/copilot.vim",
    {
  "windwp/nvim-ts-autotag",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "javascriptreact", "typescriptreact", "javascript", "typescript", "jsx", "tsx" },
  opts = {
    filetypes = {
      "html", "javascript", "typescript", "javascriptreact", "typescriptreact", 
      "jsx", "tsx", "svelte", "vue", "rescript", "xml", "php", "markdown"
    },
  },
  config = function(_, opts)
    require("nvim-ts-autotag").setup(opts)
  end,
}
})

require("custom")
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  command = "silent! wall",
})
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter"}, {command = "checktime"})

if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font Mono:h12"
    vim.g.neovide_opacity = 0.94
    vim.g.neovide_cursor_animation_length = 0.07
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false

    vim.g.neovide_position_animation_length = 0.1
    vim.g.neovide_scroll_animation_length = 0.1
    vim.g.neovide_scroll_animation_far_lines = 0.1
    vim.g.neovide_frameless = true
end


