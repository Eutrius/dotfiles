local state = require("treeoil.state")
local actions = require("treeoil.actions")

local ok_tel, telescope = pcall(require, "telescope.builtin")
if not ok_tel then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: telescope not installed",
	})
	return
end

local M = {}
M.ignore_winenter = false

function M.setup_keymaps(buf)
	for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "c", "C", "s", "S", "r", "R" }) do
		vim.keymap.set("n", key, "<Nop>", { buffer = buf })
	end
	local mappings = {
		[";f"] = telescope.find_files,
		[";r"] = telescope.live_grep,
		[";;"] = telescope.resume,
	}
	for key, func in pairs(mappings) do
		vim.keymap.set("n", key, function()
			if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
				vim.api.nvim_set_current_win(state.prev_win)
				func()
			end
		end, { buffer = buf, noremap = true })
	end
	vim.keymap.set("n", "<CR>", actions.on_enter, { buffer = buf, nowait = true })
	vim.keymap.set("n", "q", actions.close_buffer, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<M-r>", actions.refresh, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<M-l>", actions.on_enter, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<M-h>", actions.on_close_dir, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<C-h>", actions.goto_parent, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<C-l>", actions.select_dir, { buffer = buf, nowait = true })
	vim.keymap.set("n", "o", actions.edit_dir, { buffer = buf, nowait = true })
end

function M.setup_buffer_autocmds(buf)
	local augroup = vim.api.nvim_create_augroup("TreeOilGroup", { clear = true })

	vim.api.nvim_create_autocmd("WinEnter", {
		group = augroup,
		buffer = buf,
		callback = function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				local wins = vim.api.nvim_tabpage_list_wins(0)
				if #wins == 1 and wins[1] == state.win then
					local ok_q, err = pcall(vim.cmd, "silent quit")
					if not ok_q then
						vim.notify(err:match("(E%d+:.+)"), vim.log.levels.WARN)
					end
				end
			end

			if not state.ignore_winenter then
				local curr = vim.api.nvim_get_current_win()
				if curr ~= state.win then
					state.prev_win = curr
				end
			end
		end,
	})
end

return M
