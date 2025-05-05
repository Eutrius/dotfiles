local state = require("treeoil.state")
local fs = require("treeoil.fs")

local M = {}

local function filter_nodes(nodes)
	local filtered = {}
	local skip_prefix = nil
	for _, node in ipairs(nodes) do
		if skip_prefix and node.path:sub(1, #skip_prefix) == skip_prefix then
		else
			table.insert(filtered, node)
			if node.type == "directory" and node.state == "closed" then
				skip_prefix = node.path .. "/"
			else
				skip_prefix = nil
			end
		end
	end
	return filtered
end

local function render_nodes(filtered, lines, highlights)
	state.line_map = {}
	for _, node in ipairs(filtered) do
		local padding = string.rep(" ", (node.level * 3) + 3)
		local display = padding .. "\v" .. node.filename
		local line_index = #lines
		table.insert(lines, display)
		state.line_map[line_index] = node
		table.insert(highlights, {
			line = line_index,
			col = #padding,
			len = #node.filename + 2,
			hl = node.type == "directory" and "Directory" or "Normal",
		})
	end
end

function M.render()
	local lines = {}
	local highlights = {}

	local filtered = filter_nodes(state.tree)
	render_nodes(filtered, lines, highlights)

	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

	for _, h in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(state.buf, state.ns, h.hl, h.line, h.col, h.col + h.len)
	end

	for i, node in ipairs(filtered) do
		local line = i - 1
		local chunks = {}
		local npadding = node.level * 3

		for _ = 1, node.level do
			table.insert(chunks, { "│  ", "Comment" })
			npadding = npadding - 3
		end

		local is_last = true
		for j = i + 1, #filtered do
			local next_node = filtered[j]
			if next_node.level == node.level then
				is_last = false
				break
			elseif next_node.level < node.level then
				break
			end
		end
		local connector = is_last and "└─" or "├─"
		local padding = string.rep(" ", npadding)
		table.insert(chunks, { padding .. connector .. " ", "Comment" })

		if node.icon then
			table.insert(chunks, { node.icon .. " ", node.icon_hl or "Normal" })
		end

		vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, 0, {
			virt_text = chunks,
			virt_text_pos = "overlay",
		})
	end

	state.original_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	vim.api.nvim_buf_set_option(state.buf, "modified", false)
end

function M.init_ui()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "treeoil://" .. state.cwd)

	vim.api.nvim_buf_set_option(state.buf, "buftype", "acwrite")
	vim.api.nvim_buf_set_option(state.buf, "filetype", "treeoil")
	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)

	vim.cmd("topleft 35vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)

	vim.api.nvim_win_set_option(state.win, "number", false)
	vim.api.nvim_win_set_option(state.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(state.win, "relativenumber", false)
	vim.api.nvim_win_set_option(state.win, "numberwidth", 5)
	local cwd_name = vim.fn.fnamemodify(state.cwd, ":t")
	vim.api.nvim_win_set_option(state.win, "winbar", "%#TelescopeTitle#" .. " " .. cwd_name)
	vim.api.nvim_win_set_option(state.win, "wrap", false)

	local keymap = require("treeoil.keymap")
	keymap.setup_keymaps(state.buf)

	local actions = require("treeoil.actions")

	keymap.setup_enter_keymap(actions.on_enter)
	keymap.setup_close_keymap(actions.close_buffer)
	keymap.setup_refresh_keymap(actions.refresh)

	keymap.setup_buffer_autocmds(state.buf)
end

function M.open_ui()
	if next(state.tree) == nil then
		state.cwd = vim.fn.getcwd()
		state.tree = fs.scan_dir(state.cwd, state.show_hidden)
	else
	end
	M.init_ui()
	M.render()
end

function M.toggle()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		if vim.api.nvim_buf_get_option(state.buf, "modified") then
			local choice = vim.fn.confirm("Save changes?", "&Yes\n&No\n&Cancel", 1)
			if choice == 1 then
				local actions = require("treeoil.actions")
				actions.save_changes()
			elseif choice == 3 then
				return
			end
		end

		vim.api.nvim_buf_set_option(state.buf, "modified", false)
		vim.cmd("bdelete " .. state.buf)
		state.buf = nil
		state.win = nil
	else
		M.open_ui()
	end
end

return M
