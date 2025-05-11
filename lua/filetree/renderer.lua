local M = {}

local last_rendered_nodes = {}

M.show_hidden = false

local function is_hidden(filename)
	return filename:sub(1, 1) == "."
end

local function filter_rendered_nodes(nodes)
	local rendered_nodes = {}
	local open_dirs = {}
	for _, node in ipairs(nodes) do
		if not M.show_hidden and is_hidden(node.filename) then
		else
			if node.depth == 0 or open_dirs[node.parent_path] then
				table.insert(rendered_nodes, node)
				if node.is_directory and node.is_open then
					open_dirs[node.full_path] = true
				end
			end
		end
	end
	return rendered_nodes
end

function M.toggle_hidden()
	M.show_hidden = not M.show_hidden
end

function M.render(buf, nodes)
	last_rendered_nodes = filter_rendered_nodes(nodes)
	local lines = {}
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
	for _, node in ipairs(last_rendered_nodes) do
		local indent = string.rep("│ ", node.depth)
		local padding = "  "
		local line = string.format("%s%s%s%s", indent, node.icon, padding, node.filename)
		table.insert(lines, line)
	end
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for line_index, node in ipairs(last_rendered_nodes) do
		local indent = string.rep("│ ", node.depth)
		local highlight_start = #indent + #node.icon + 2 -- Account for indent + icon + padding
		local highlight_length = #node.filename
		vim.api.nvim_buf_add_highlight(
			buf,
			-1,
			node.type == "directory" and "Directory" or "Normal",
			line_index - 1,
			highlight_start,
			highlight_start + highlight_length
		)
	end
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.get_last_rendered_nodes()
	return last_rendered_nodes
end

function M.get_prefix_width(_, depth)
	local indent_width = #string.rep("│ ", depth)
	local icon_width = 2
	local padding_width = 2
	return indent_width + icon_width + padding_width
end

return M
