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
			if node.type == "directory" and node.is_open == "closed" then
				skip_prefix = node.path .. "/"
			else
				skip_prefix = nil
			end
		end
	end
	return filtered
end

local function render_nodes(filtered, lines, highlights)
	state.rendered_nodes = {}
	for i, node in ipairs(filtered) do
		local display = node.filename
		table.insert(lines, display)
		state.rendered_nodes[i] = node
		table.insert(highlights, {
			line = i - 1,
			col = 0,
			len = #node.filename + 2,
			hl = node.type == "directory" and "Directory" or "Normal",
		})
	end
end

function M.render()
	local lines = {}
	local highlights = {}

	local filtered = filter_nodes(state.nodes)
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
			virt_text_pos = "inline",
		})
	end

	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

function M.init_ui()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "treeoil://" .. state.cwd)

	local bo = vim.bo[state.buf]
	bo.filetype = "treeoil"
	bo.modifiable = false
	bo.swapfile = false

	vim.cmd("topleft " .. tostring(state.win_size) .. "vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)

	local wo = vim.wo[state.win]
	wo.number = false
	wo.signcolumn = "no"
	wo.relativenumber = false
	wo.numberwidth = 5
	wo.sidescrolloff = 20
	wo.cursorline = true
	wo.wrap = false
	wo.winfixwidth = true

	local cwd_name = vim.fn.fnamemodify(state.cwd, ":t")
	wo.winbar = "%#TelescopeTitle#" .. " " .. cwd_name
end

function M.open_ui()
	if next(state.nodes) == nil then
		state.cwd = vim.fn.getcwd()
		state.nodes = fs.scan_dir(state.cwd, state.show_hidden)
	end
	state.prev_win = vim.api.nvim_get_current_win()
	M.init_ui()
	M.render()
	local keymap = require("treeoil.keymap")
	keymap.setup_keymaps(state.buf)
	keymap.setup_buffer_autocmds(state.buf)

	if state.prev_cur_pos then
		vim.api.nvim_win_set_cursor(0, state.prev_cur_pos)
	else
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end
end

function M.toggle()
	state.ignore_winenter = true
	vim.schedule(function()
		state.ignore_winenter = false
	end)

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		state.prev_cur_pos = vim.api.nvim_win_get_cursor(state.win)
		vim.cmd("bdelete " .. state.buf)
		state.buf = nil
		state.win = nil
	else
		M.open_ui()
	end
end

return M
