return {
	"rcarriga/nvim-dap-ui",
	dependencies = {
		"mfussenegger/nvim-dap",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	lazy = false,
	keys = {
		{
			"<F9>",
			function()
				require("dap").continue()
			end,
			desc = "Start Debugging",
		},
		{
			"<F10>",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<F11>",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into",
		},
		{
			"<F12>",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<Leader>b",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint",
		},
		{
			"<Leader>B",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Conditional Breakpoint",
		},
		{
			"<Leader>dr",
			function()
				require("dap").repl.open()
			end,
			desc = "Open Debug Console",
		},
		{
			"<Leader>du",
			function()
				require("dapui").toggle()
			end,
			desc = "Toggle Debug UI",
		},
	},
	config = function()
		local dap = require("dap")

		dap.adapters.cppdbg = {
			id = "cppdbg",
			type = "executable",
			command = vim.fn.stdpath("data") .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
			options = { detached = false },
			setupCommands = {
				{ text = "catch throw", description = "break on C++ throw", ignoreFailures = false },
			},
		}

		dap.adapters.gdb = {
			type = "executable",
			command = "gdb",
			name = "gdb",
			args = { "--quiet", "--interpreter=dap" },
		}

		dap.configurations.cpp = {
			{
				name = "Launch current file",
				type = "gdb",
				request = "launch",
				program = function()
					local file = vim.fn.expand("%:r")
					return file
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
				runInTerminal = false,
			},
		}

		local dapui = require("dapui")
		dapui.setup()
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		require("nvim-dap-virtual-text").setup()
	end,
}
