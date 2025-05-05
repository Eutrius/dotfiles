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
		local padding = string.rep(" ", (node.level * 3))
		local display = node.id .. padding .. "\\" .. node.filename
		local line_index = #lines
		table.insert(lines, display)
		state.line_map[line_index] = node
		table.insert(highlights, {
			line = line_index,
			col = #padding,
			len = #node.filename + 5,
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
		local pad = 0
		local npadding = node.level * 3

		for _ = 1, node.level do
			if _ == 1 then
				vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad, {
					virt_text = { { "│", "Comment" } },
					virt_text_pos = "overlay",
					virt_text_hide = true,
				})
				vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad + 1, {
					virt_text = { { " ", "Comment" } },
					virt_text_pos = "overlay",
					virt_text_hide = true,
				})
				vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad + 2, {
					virt_text = { { " ", "Comment" } },
					virt_text_pos = "overlay",
					virt_text_hide = true,
				})
			else
				vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad, {
					virt_text = { { "│  ", "Comment" } },
					virt_text_pos = "overlay",
					virt_text_hide = true,
				})
			end
			pad = pad + 3
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
		local connector = is_last and "└" or "├"
		if npadding == 0 then
			vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad, {
				virt_text = { { connector, "Comment" } },
				virt_text_pos = "overlay",
				virt_text_hide = true,
			})
			vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad + 1, {
				virt_text = { { "─", "Comment" } },
				virt_text_pos = "overlay",
				virt_text_hide = true,
			})
			vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad + 2, {
				virt_text = { { " ", "Comment" } },
				virt_text_pos = "overlay",
				virt_text_hide = true,
			})
		else
			local connector_text = string.rep(" ", npadding) .. connector .. " "
			vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad, {
				virt_text = { { connector_text, "Comment" } },
				virt_text_pos = "overlay",
				virt_text_hide = true,
			})
		end

		if node.icon then
			local icon_chunk = { { node.icon .. " ", node.icon_hl or "Normal" } }

			vim.api.nvim_buf_set_extmark(state.buf, state.ns, line, pad + 3, {
				virt_text = icon_chunk,
				virt_text_pos = "overlay",
				virt_text_hide = true,
			})
		end
	end

	state.original_lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	vim.api.nvim_buf_set_option(state.buf, "modified", false)
	vim.schedule(function()
		local old_undolevels = vim.api.nvim_buf_get_option(state.buf, "undolevels")
		vim.api.nvim_buf_set_option(state.buf, "undolevels", -1)
		vim.api.nvim_buf_call(state.buf, function()
			vim.cmd("silent normal! i<Esc>")
			vim.cmd("silent %s/<Esc>/")
		end)
		vim.api.nvim_buf_set_option(state.buf, "undolevels", old_undolevels)
	end)
end

function M.init_ui()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.buf, "treeoil://" .. state.cwd)

	local bo = vim.bo[state.buf]
	bo.buftype = "acwrite"
	bo.filetype = "treeoil"
	bo.modifiable = true
	bo.swapfile = false

	vim.cmd("topleft 25vsplit")
	state.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(state.win, state.buf)

	local wo = vim.wo[state.win]
	wo.number = false
	wo.signcolumn = "no"
	wo.relativenumber = false
	wo.numberwidth = 5
	wo.sidescrolloff = 5
	wo.wrap = false

	local cwd_name = vim.fn.fnamemodify(state.cwd, ":t")
	wo.winbar = "%#TelescopeTitle#" .. " " .. cwd_name
end

function M.open_ui()
	if next(state.tree) == nil then
		state.cwd = vim.fn.getcwd()
		state.tree = fs.scan_dir(state.cwd, state.show_hidden)
	else
	end
	M.init_ui()
	M.render()
	local keymap = require("treeoil.keymap")
	keymap.setup_keymaps(state.buf)

	local actions = require("treeoil.actions")
	keymap.setup_enter_keymap(actions.on_enter)
	keymap.setup_close_keymap(actions.close_buffer)
	keymap.setup_refresh_keymap(actions.refresh)
	keymap.setup_buffer_autocmds(state.buf)
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
