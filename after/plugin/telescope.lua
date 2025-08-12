local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>st', builtin.live_grep, { desc = 'Telescope find phrase' })
vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Telescope find files' })
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {
      "node_modules",      -- ignore node_modules
      "%.git/",            -- ignore .git directory
      "%.lock",            -- ignore .lock files
      "%.jpg", "%.png",    -- ignore image files
      "__pycache__",       -- ignore Python cache
      "__pycache__",       -- ignore Python cache
      "%.o",       -- ignore Python cache
      "%.out",       -- ignore Python cache
      "CMakeFiles\\",       -- ignore Python cache
      ".cmake\\",       -- ignore Python cache
      ".cache\\",       -- ignore Python cache
      "%.cmake",       -- ignore Python cache
    }
  }
}
