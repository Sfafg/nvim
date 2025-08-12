local dap = require('dap')

dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
  options={detached=false },
setupCommands = {
    {
        text = "-enable-pretty-printing",
        description = "enable pretty printing",
        ignoreFailures = false
    },
    {
        text = "catch throw",
        description = "break on C++ throw",
        ignoreFailures = false
    }
}
}

dap.adapters.codelldb = {
  type = 'server',
  port = 13000,
  executable = {
    command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
    args = { "--port", "13000" },
  },
}
dap.adapters.gdb = {
  type = 'executable',
  command = 'gdb',
  name = 'gdb',
    args = { '--quiet', '--interpreter=dap' },
}

dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/Debug/' ..  vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. '.exe', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopAtEntry = true,
    setupCommands = {
      { text = "-enable-pretty-printing -exec catch throw", description = "Enable GDB pretty printing", ignoreFailures = false },
    },
  },
}
-- Make sure C configurations are the same as C++
dap.configurations.c = dap.configurations.cpp

local dapui = require("dapui")
dapui.setup()

--  Auto open/close the UI when debugging starts/stops
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

require("nvim-dap-virtual-text").setup()

vim.keymap.set("n", "<F9>", function()
	dap.continue()
end, { desc = "Start Debugging" })
vim.keymap.set("n", "<F10>", function()
	dap.step_over()
end, { desc = "Step Over" })
vim.keymap.set("n", "<F11>", function()
	dap.step_into()
end, { desc = "Step Into" })
vim.keymap.set("n", "<F12>", function()
	dap.step_out()
end, { desc = "Step Out" })
vim.keymap.set("n", "<Leader>b", function()
	dap.toggle_breakpoint()
end, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<Leader>B", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional Breakpoint" })
vim.keymap.set("n", "<Leader>dr", function()
	dap.repl.open()
end, { desc = "Open Debug Console" })
vim.keymap.set("n", "<Leader>du", function()
	dapui.toggle()
end, { desc = "Toggle Debug UI" })
