local M = {}

M.tree_win_id = nil
M.tree_buf_id = nil
M.prev_win_id = nil
M.tree_state = {
	last_dir = nil,
}
M.ignore_winenter = false

function M.close_tree()
	M.ignore_winenter = true
	vim.schedule(function()
		M.ignore_winenter = false
	end)

	if M.tree_win_id and vim.api.nvim_win_is_valid(M.tree_win_id) then
		pcall(vim.api.nvim_win_close, M.tree_win_id, true)
	end
	M.tree_win_id = nil
	M.tree_buf_id = nil
end

function M.open_tree()
	M.ignore_winenter = true
	vim.schedule(function()
		M.ignore_winenter = false
	end)
	M.prev_win_id = vim.api.nvim_get_current_win()
	vim.cmd("topleft 28vsplit")
	M.tree_win_id = vim.api.nvim_get_current_win()

	vim.api.nvim_win_set_option(M.tree_win_id, "number", false)
	vim.api.nvim_win_set_option(M.tree_win_id, "relativenumber", false)
	vim.api.nvim_win_set_option(M.tree_win_id, "signcolumn", "no")
	vim.api.nvim_win_set_option(M.tree_win_id, "winfixwidth", true)
	local has_oil, oil = pcall(require, "oil")
	if not has_oil then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {
			"Error: oil.nvim is not installed",
			"Please install oil.nvim to use this plugin",
		})
		return
	end

	local dir_to_open = M.tree_state.last_dir or vim.fn.getcwd()
	M.tree_state.last_dir = dir_to_open:gsub("//+", "/")
	oil.open(dir_to_open)
	print(M.tree_state.last_dir)
	M.tree_buf_id = vim.api.nvim_get_current_buf()

	M.setup_keymaps()
end

function M.toggle_tree()
	if M.tree_win_id and vim.api.nvim_win_is_valid(M.tree_win_id) then
		M.close_tree()
	else
		M.open_tree()
	end
end

function M.setup_keymaps()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "oil",
		callback = function(args)
			local oil = require("oil")
			local actions = require("oil.actions")
			local home_dir = vim.fn.expand("~")

			vim.keymap.set("n", "h", function()
				local current_dir = oil.get_current_dir()
				if current_dir == home_dir .. "/" then
					return
				else
					actions.parent.callback()
					local dir = oil.get_current_dir()
					M.tree_state.last_dir = dir:gsub("//+", "/")
					print(M.tree_state.last_dir)
				end
			end, { buffer = args.buf, noremap = true })

			vim.keymap.set("n", "<CR>", function()
				local entry = oil.get_cursor_entry()
				local dir = oil.get_current_dir()
				local full_path = vim.fn.fnamemodify(dir .. "/" .. entry.name, ":p")
				if entry and entry.type == "file" and entry.name then
					if M.prev_win_id and vim.api.nvim_win_is_valid(M.prev_win_id) then
						vim.api.nvim_set_current_win(M.prev_win_id)
					end
					vim.cmd("drop " .. vim.fn.fnameescape(full_path))
				elseif entry and entry.type == "directory" then
					actions.select.callback()
					M.tree_state.last_dir = full_path:gsub("//+", "/")
					print(M.tree_state.last_dir)
				end
			end, { buffer = args.buf, noremap = true })
		end,
	})
end

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if M.ignore_winenter then
			return
		end
		local curr_win = vim.api.nvim_get_current_win()
		if curr_win ~= M.tree_win_id then
			M.prev_win_id = curr_win
		end
	end,
})

vim.api.nvim_create_user_command("Otree", function()
	M.toggle_tree()
end, {})

return M
