local M = {}
local renderer = require("filetree.renderer")

function M.handle_enter(buf, current_nodes, line_number, previous_window)
	local rendered_nodes = renderer.get_last_rendered_nodes()
	local node = rendered_nodes[line_number + 1]
	if not node then
		return
	end

	if node.is_directory then
		for _, current_node in ipairs(current_nodes) do
			if current_node.full_path == node.full_path then
				current_node.is_open = not current_node.is_open
				break
			end
		end
		renderer.render(buf, current_nodes)
	else
		if previous_window and vim.api.nvim_win_is_valid(previous_window) then
			vim.api.nvim_set_current_win(previous_window)
			vim.cmd("edit " .. node.full_path)
		else
			print("Error: Previous window is invalid.")
		end
	end
end

function M.handle_close_directory(buf, _, line_number)
	local rendered_nodes = renderer.get_last_rendered_nodes()
	local node = rendered_nodes[line_number + 1]
	if not node then
		return
	end

	if node.is_directory and node.is_open then
		node.is_open = false
		renderer.render(buf, rendered_nodes)
		M.set_cursor_safe(line_number + 1, 0)
		return
	end

	local parent_path = node.parent_path
	if parent_path then
		local parent_line = nil
		for i, rendered_node in ipairs(rendered_nodes) do
			if rendered_node.full_path == parent_path and rendered_node.is_directory then
				rendered_node.is_open = false
				parent_line = i - 1
				break
			end
		end
		renderer.render(buf, rendered_nodes)

		if parent_line then
			M.set_cursor_safe(parent_line + 1, 0)
		else
			M.set_cursor_safe(math.max(line_number, 1), 0)
		end
	end
end

function M.set_cursor_safe(row, col)
	local buf_lines = vim.api.nvim_buf_line_count(0)
	row = math.max(1, math.min(row, buf_lines))
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
	col = math.max(0, math.min(col, #line))
	vim.api.nvim_win_set_cursor(0, { row, col })
end

return M
