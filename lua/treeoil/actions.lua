local state = require("treeoil.state")
local fs = require("treeoil.fs")

local M = {}

function M.on_enter()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.rendered_nodes[line]
	if not node then
		return
	end

	if node.type == "directory" then
		for _, item in ipairs(state.nodes) do
			if item.full_path == node.full_path then
				item.is_open = item.is_open == "closed" and "open" or "closed"
			end
		end

		require("treeoil.ui").render()
	elseif node.type == "file" then
		if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
			vim.api.nvim_set_current_win(state.prev_win)
			vim.cmd("drop " .. vim.fn.fnameescape(state.cwd .. "/" .. node.path))
		end
	end
end

function M.on_close_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.rendered_nodes[line]
	if not node then
		return
	end

	if node.type == "directory" and node.is_open == "open" then
		for _, item in ipairs(state.nodes) do
			if item.full_path == node.full_path then
				item.is_open = "closed"
				break
			end
		end

		require("treeoil.ui").render()
		vim.api.nvim_win_set_cursor(state.win, { line + 1, 0 })
		return
	end

	local parent = node.parent_path
	if parent then
		for _, item in ipairs(state.nodes) do
			if item.full_path == parent and item.type == "directory" then
				item.is_open = "closed"
				break
			end
		end

		require("treeoil.ui").render()

		for ln, n in pairs(state.rendered_nodes) do
			if n.full_path == parent then
				vim.api.nvim_win_set_cursor(state.win, { ln + 1, 0 })
				return
			end
		end

		vim.api.nvim_win_set_cursor(state.win, { math.max(line, 0) + 1, 0 })
	end
end

function M.close_buffer()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		state.prev_cur_pos = vim.api.nvim_win_get_cursor(state.win)
		vim.cmd("bdelete " .. state.buf)
		state.buf = nil
		state.win = nil
	end
end

function M.refresh()
	local open_dirs = {}
	if state.rendered_nodes then
		for _, node in ipairs(state.rendered_nodes) do
			if node.type == "directory" and node.is_open == "open" then
				open_dirs[node.full_path] = true
			end
		end
	end

	state.nodes = fs.scan_dir(state.cwd, state.show_hidden)

	for _, node in ipairs(state.nodes) do
		if node.type == "directory" and open_dirs[node.full_path] then
			node.is_open = "open"
		end
	end

	require("treeoil.ui").render()
end

function M.goto_parent()
	local parent_dir = vim.fn.fnamemodify(state.cwd, ":h")
	if parent_dir ~= state.cwd then
		vim.cmd("cd " .. parent_dir)
		M.close_buffer()
		state.nodes = {}
		state.prev_cur_pos = nil
		require("treeoil.ui").open_ui()
	end
end

function M.select_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.rendered_nodes[line]
	if node.type == "directory" then
		vim.cmd("cd " .. node.full_path)
		M.close_buffer()
		state.nodes = {}
		state.prev_cur_pos = nil
		require("treeoil.ui").open_ui()
	end
end

function M.edit_dir()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1]
	local node = state.rendered_nodes[line]
	require("treeoil.float").open_float(node.parent_path)
end

function M.toggle_hidden()
	state.show_hidden = not state.show_hidden
	M.refresh()
end

return M
