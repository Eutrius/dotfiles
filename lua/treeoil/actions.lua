local state = require("treeoil.state")
local fs = require("treeoil.fs")

local M = {}

function M.save_changes()
	if not state.buffer_changed then
		return
	end

	local current_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)

	local changes = M.detect_changes(state.original_lines, current_lines)

	-- M.apply_changes(changes)
	M.refresh()

	state.buffer_changed = false
	vim.api.nvim_buf_set_option(state.buf, "modified", false)
end

function M.detect_changes(old_lines, new_lines)
	local changes = {
		created = {},
		deleted = {},
		renamed = {},
	}

	local old_map = {}
	local new_map = {}

	for i, _ in ipairs(old_lines) do
		local node = state.line_map[i - 1]
		if node then
			old_map[node.filename] = node
		end
	end

	for i, line in ipairs(new_lines) do
		-- Skip the ID and # at the beginning of line
		local clean_line = line:gsub("^%d+#", "")
		local indent = clean_line:match("^(%s*)")
		local filename = clean_line:sub(#indent + 3) -- +3 to skip the backslash and space

		if filename and filename ~= "" then
			local level = math.floor(#indent / 2)
			new_map[filename] = {
				filename = filename,
				level = level,
				line_num = i,
			}
		end
	end

	for name, node in pairs(old_map) do
		if not new_map[name] then
			table.insert(changes.deleted, node)
		end
	end

	for name, info in pairs(new_map) do
		if not old_map[name] then
			table.insert(changes.created, {
				filename = name,
				level = info.level,
			})
		end
	end

	return changes
end

function M.apply_changes(changes)
	for _, node in ipairs(changes.deleted) do
		local full_path = state.cwd .. "/" .. node.path
		if node.is_dir then
			vim.fn.delete(full_path, "rf")
		else
			vim.fn.delete(full_path)
		end
	end

	for _, info in ipairs(changes.created) do
		local parent_path = state.cwd

		local full_path = parent_path .. "/" .. info.filename
		if info.filename:match("/$") then
			vim.fn.mkdir(full_path, "p")
		else
			local file = io.open(full_path, "w")
			if file then
				file:close()
			end
		end
	end
end

function M.on_enter()
	local cursor = vim.api.nvim_win_get_cursor(state.win)
	local line = cursor[1] - 1
	local node = state.line_map[line]
	if not node then
		return
	end

	if node.type == "directory" then
		for _, item in ipairs(state.tree) do
			if item.full_path == node.full_path then
				item.state = item.state == "closed" and "open" or "closed"
			end
		end

		require("treeoil.ui").render()
	elseif node.type == "file" then
		vim.cmd("wincmd p")
		vim.cmd("edit " .. vim.fn.fnameescape(state.cwd .. "/" .. node.path))
	end
end

function M.close_buffer()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_set_option(state.buf, "modified", false)
		vim.cmd("bdelete " .. state.buf)
		state.buf = nil
		state.win = nil
	end
end

function M.refresh()
	state.tree = fs.scan_dir(state.cwd, state.show_hidden)

	require("treeoil.ui").render()
	state.buffer_changed = false
	state.original_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
end

function M.goto_parent()
	local parent_dir = vim.fn.fnamemodify(state.cwd, ":h")
	if parent_dir ~= state.cwd then
		state.cwd = parent_dir
		M.refresh()
	end
end

function M.toggle_hidden()
	state.show_hidden = not state.show_hidden
	M.refresh()
end

return M
