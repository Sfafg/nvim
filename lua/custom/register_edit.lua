local M = {}

local buf = nil
local lastRegister = nil

local function on_buffer_change()
	if not buf then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local r = lines[1][1]
	print(r)
	if not r == lastRegister then
		local content = vim.fn.getreg(r)

		local lines = vim.split(content, "\n", { plain = true })
		lines[1] = r .. ":" .. lines[1]
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		r = lastRegister
	else
		lines[1] = lines[1]:sub(3)
		vim.fn.setreg(lastRegister, lines)
	end
end
local function open_register_edit_buffer()
	if buf then
		vim.api.nvim_buf_delete(buf, { force = true })
	end

	local key = vim.fn.getcharstr()
	local content = vim.fn.getreg(key)
	lastRegister = key

	local lines = vim.split(content, "\n", { plain = true })
	lines[1] = key .. ":" .. lines[1]

	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "[Register Preview: " .. key .. "]")
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = math.floor(vim.o.columns * 0.4)
	local height = math.floor(vim.o.lines * 0.3)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
	})
	vim.wo[win].list = true
	vim.wo[win].listchars = "tab:>-,trail:·,extends:>,precedes:<,nbsp:␣,eol:¬,space:·,leadmultispace:│"

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = buf,
		callback = function()
			on_buffer_change()
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload", "BufDelete" }, {
		buffer = buf,
		once = true,
		callback = function()
			buf = nil
		end,
	})
end

vim.keymap.set("n", "<C-2>", function()
	open_register_edit_buffer()
end, {})

return M
