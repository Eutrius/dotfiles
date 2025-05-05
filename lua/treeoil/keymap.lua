local M = {}
local state = require("treeoil.state")
local actions = require("treeoil.actions")

function M.setup_keymaps(buf)
	M.buf = buf
end

function M.setup_enter_keymap(callback)
	vim.keymap.set("n", "<CR>", callback, { buffer = M.buf, nowait = true })
end

function M.setup_close_keymap(callback)
	vim.keymap.set("n", "q", callback, { buffer = M.buf, nowait = true })
end

function M.setup_refresh_keymap(callback)
	vim.keymap.set("n", "R", callback, { buffer = M.buf, nowait = true })
end

local function find_end_of_indent_block(bufnr, start_row)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start_line = lines[start_row + 1]
	local start_indent = start_line:match("^(%s*)")
	local start_indent_level = #start_indent

	local end_row = start_row

	for i = start_row + 1, #lines do
		local line = lines[i]
		if line and line ~= "" then
			local indent = line:match("^(%s*)")
			local indent_level = #indent

			if indent_level == start_indent_level then
				end_row = i - 1
			elseif indent_level < start_indent_level then
				break
			end
		end
	end

	return end_row
end

function find_end_of_indent_block(bufnr, start_row)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local start_line = lines[start_row + 1]
	local start_indent = start_line:match("^(%s*)")
	local start_indent_level = #start_indent

	local end_row = start_row

	for i = start_row + 1, #lines do
		local line = lines[i]
		if line and line ~= "" then
			local indent = line:match("^(%s*)")
			local indent_level = #indent

			if indent_level == start_indent_level then
				end_row = i - 1
			elseif indent_level < start_indent_level then
				break
			end
		end
	end

	return end_row
end

vim.api.nvim_buf_set_keymap(state.buf, "n", "o", "", {
	noremap = true,
	callback = function()
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local row = cursor_pos[1] - 1

		local end_row = find_end_of_indent_block(state.buf, row)

		vim.api.nvim_win_set_cursor(0, { end_row + 1, 0 })

		local current_line = vim.api.nvim_buf_get_lines(state.buf, end_row, end_row + 1, false)[1]
		local indent = current_line:match("^(%s*)")

		vim.api.nvim_buf_set_lines(state.buf, end_row + 1, end_row + 1, false, { indent })

		vim.api.nvim_win_set_cursor(0, { end_row + 2, #indent })
		vim.cmd("startinsert")
	end,
})

vim.api.nvim_buf_set_keymap(state.buf, "n", "O", "", {
	noremap = true,
	callback = function()
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local row = cursor_pos[1] - 1

		local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
		local current_line = lines[row + 1]
		local current_indent = current_line:match("^(%s*)")
		local current_indent_level = #current_indent

		local target_row = row
		for i = row - 1, 0, -1 do
			local line = lines[i + 1]
			if line and line ~= "" then
				local indent = line:match("^(%s*)")
				local indent_level = #indent

				if indent_level < current_indent_level then
					target_row = i
					break
				end
			end
		end

		local target_line = vim.api.nvim_buf_get_lines(state.buf, target_row, target_row + 1, false)[1]
		local indent = target_line:match("^(%s*)")

		vim.api.nvim_buf_set_lines(state.buf, target_row, target_row, false, { indent })

		vim.api.nvim_win_set_cursor(0, { target_row + 1, #indent })
		vim.cmd("startinsert")
	end,
})

function M.setup_buffer_autocmds(buf)
	local augroup = vim.api.nvim_create_augroup("TreeOilGroup", { clear = true })

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = augroup,
		buffer = buf,
		callback = function()
			actions.save_changes()
			return true
		end,
	})

	vim.api.nvim_create_autocmd("BufHidden", {
		group = augroup,
		buffer = buf,
		callback = function()
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_set_option(buf, "modified", false)
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("TextChanged", {
		group = augroup,
		buffer = buf,
		callback = function()
			state.buffer_changed = true
		end,
	})

	vim.api.nvim_create_autocmd("TextChangedI", {
		group = augroup,
		buffer = buf,
		callback = function()
			state.buffer_changed = true

			local pos = vim.fn.getcurpos()
			local row = pos[2] - 1
			local col = pos[3] - 1

			local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]

			local prefix_width = #line:match("^%s*")

			if col < prefix_width then
				vim.notify("hello")
				vim.api.nvim_win_set_cursor(0, { row + 1, prefix_width })
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "InsertCharPre" }, {
		buffer = state.buf,
		callback = function()
			local pos = vim.fn.getcurpos()
			local row = pos[2] - 1
			local col = pos[3] - 1

			local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]

			local prefix_width = #line:match("^%s*")

			if col < prefix_width then
				vim.notify("hello")
				vim.api.nvim_win_set_cursor(0, { row + 1, prefix_width })
			end
		end,
	})
end

return M
