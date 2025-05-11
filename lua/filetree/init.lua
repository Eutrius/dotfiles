local M = {}
local nodes = require("filetree.nodes")
local renderer = require("filetree.renderer")
local actions = require("filetree.actions")
local devicons = require("nvim-web-devicons")

_G.current_nodes = {}
_G.previous_window = nil
_G.filetree_cursor_position = nil

function M.create_window()
	vim.cmd("topleft 25vsplit")
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "filetree")
	vim.api.nvim_win_set_option(win, "number", false)
	vim.api.nvim_win_set_option(win, "relativenumber", false)
	vim.api.nvim_win_set_option(win, "signcolumn", "no")

	local cwd = vim.loop.cwd()
	local cwd_name = vim.fn.fnamemodify(cwd, ":t")
	local winbar_text = string.format("  %s%s/", " ", cwd_name)
	vim.api.nvim_win_set_option(win, "winbar", "%#TelescopeTitle#" .. winbar_text)

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = buf,
		callback = function()
			local pos = vim.fn.getcurpos()
			local row = pos[2] - 1
			local col = pos[3] - 1
			local rendered_nodes = renderer.get_last_rendered_nodes()
			local node = rendered_nodes[row + 1]

			if not node then
				return
			end

			local prefix_width = renderer.get_prefix_width("", node.depth)

			if col < prefix_width then
				vim.api.nvim_win_set_cursor(0, { row + 1, prefix_width })
			end
		end,
	})

	return buf, win
end

function M.close_filetree()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
		if filetype == "filetree" then
			_G.filetree_cursor_position = vim.api.nvim_win_get_cursor(win)
			vim.api.nvim_win_close(win, true)
			return
		end
	end
end

function M.open_filetree()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
		if filetype == "filetree" then
			M.close_filetree()
			return
		end
	end

	_G.previous_window = vim.api.nvim_get_current_win()
	local buf, _ = M.create_window()
	local cwd = vim.loop.cwd()

	if not _G.current_nodes or vim.loop.cwd() ~= _G.current_nodes_cwd then
		_G.current_nodes = require("filetree.nodes").get_nodes(cwd)
		_G.current_nodes_cwd = cwd
	end

	require("filetree.renderer").render(buf, _G.current_nodes)

	if _G.filetree_cursor_position then
		vim.api.nvim_win_set_cursor(0, _G.filetree_cursor_position)
	else
		vim.api.nvim_win_set_cursor(0, { 1, 0 })
	end

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<CR>",
		":lua require('filetree.actions').handle_enter("
			.. buf
			.. ", _G.current_nodes, vim.fn.line('.') - 1, _G.previous_window)<CR>",
		{ noremap = true, silent = true }
	)

	-- Add key mapping for <M-h> to close directories
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<M-h>",
		":lua require('filetree.actions').handle_close_directory("
			.. buf
			.. ", _G.current_nodes, vim.fn.line('.') - 1)<CR>",
		{ noremap = true, silent = true }
	)
end

function M.setup()
	vim.api.nvim_create_user_command("FileTree", function()
		M.open_filetree()
	end, {})
	vim.api.nvim_set_keymap("n", "<leader>f", ":FileTree<CR>", { noremap = true, silent = true })
end

return M
