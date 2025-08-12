-- Set SumatraPDF as the PDF viewer
vim.g.vimtex_view_method = 'general'  -- Use general method
vim.g.vimtex_view_general_viewer = 'SumatraPDF.exe'  -- Correct path to SumatraPDF
vim.g.vimtex_view_general_options = '-reuse-instance -forward-search %f %l'  -- Optional flags for forward search

-- Set latexmk as the compiler method
vim.g.vimtex_compiler_method = 'latexmk'  -- Auto-compiles changes

-- Disable error popups
vim.g.vimtex_quickfix_mode = 0  -- No error popups
