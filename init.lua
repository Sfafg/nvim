require("custom")

vim.o.autoread = true
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  command = "silent! wall",
})
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter"}, {command = "checktime"})
vim.api.nvim_create_autocmd("User", {
    pattern = "CMakeToolsLoaded",
    callback = function()
        vim.api.nvim_create_autocmd("DirChanged", {
          pattern = "*",
          callback = function()
              _G.init()
          end,
    })
    end,
})
