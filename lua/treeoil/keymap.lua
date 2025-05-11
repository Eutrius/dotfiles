local M = {}
local state = require("treeoil.state")
local actions = require("treeoil.actions")

function M.setup_keymaps(buf)
	M.buf = buf

	-- vim.keymap.set("n", "o", function()
	-- 	local cursor = vim.api.nvim_win_get_cursor(0)
	-- 	local current_line = cursor[1]
	-- 	local prev_line = current_line - 1
	-- 	local line = vim.api.nvim_buf_get_lines(0, prev_line, prev_line + 1, false)[1]
	-- 	local prefix_width = select(2, line:find("\\+")) + 1 or 0
	-- 	vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { string.rep(" ", prefix_width) })
	-- 	vim.api.nvim_win_set_cursor(0, { current_line + 1, prefix_width })
	-- 	vim.cmd("silent startinsert")
	-- end, { buffer = buf })
	--
	-- vim.keymap.set("n", "O", function()
	-- 	local cursor = vim.api.nvim_win_get_cursor(0)
	-- 	local current_line = cursor[1] - 1
	-- 	local prev_line = current_line + 1
	-- 	local line = vim.api.nvim_buf_get_lines(0, prev_line, prev_line + 1, false)[1]
	-- 	local prefix_width = select(2, line:find("\\+")) + 1 or 0
	-- 	vim.api.nvim_buf_set_lines(0, current_line, current_line, false, { string.rep(" ", prefix_width) })
	-- 	vim.api.nvim_win_set_cursor(0, { current_line + 1, prefix_width })
	-- 	vim.cmd("silent startinsert")
	-- end, { buffer = buf })
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
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = state.buf,
		callback = function()
			local pos = vim.fn.getcurpos()
			local row = pos[2] - 1
			local col = pos[3] - 1
			local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
			local prefix_width = select(2, line:find(" +")) or 0
			if col < prefix_width then
				vim.api.nvim_win_set_cursor(0, { row + 1, prefix_width })
			end
		end,
	})
	--
	-- vim.api.nvim_create_autocmd({ "InsertEnter" }, {
	-- 	buffer = state.buf,
	-- 	callback = function()
	-- 		local start_cursor = vim.api.nvim_win_get_cursor(0)
	-- 		vim.keymap.set("i", "<C-h>", function()
	-- 			local cursor = vim.api.nvim_win_get_cursor(0)
	-- 			local col = cursor[2]
	-- 			if start_cursor[2] == col then
	-- 				return
	-- 			else
	-- 				return "<C-h>"
	-- 			end
	-- 		end, { buffer = buf, expr = true })
	-- 		vim.keymap.set("i", "<BS>", function()
	-- 			local cursor = vim.api.nvim_win_get_cursor(0)
	-- 			local col = cursor[2]
	-- 			if start_cursor[2] == col then
	-- 				return
	-- 			else
	-- 				return "<C-h>"
	-- 			end
	-- 		end, { buffer = buf, expr = true })
	-- 	end,
	-- })
end

return M
