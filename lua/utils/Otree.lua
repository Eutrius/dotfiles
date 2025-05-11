local M = {}

M.tree_win_id = nil
M.tree_buf_id = nil
M.prev_win_id = nil
M.tree_state = { last_dir = nil }
M.ignore_winenter = false

local ok, oil = pcall(require, "oil")
if not ok then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: oil.nvim not installed",
	})
	return
end

local ok_tel, telescope = pcall(require, "telescope.builtin")
if not ok_tel then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: telescope not installed",
	})
	return
end
local ok_ac, actions = pcall(require, "oil.actions")
if not ok_ac then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: oil.actions failed",
	})
	return
end

function M.is_open()
	return M.tree_win_id and vim.api.nvim_win_is_valid(M.tree_win_id)
end

function M._close()
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

function M._open()
	M.ignore_winenter = true
	vim.schedule(function()
		M.ignore_winenter = false
	end)
	vim.g.oil_mode = "tree"
	M.prev_win_id = vim.api.nvim_get_current_win()
	vim.cmd("topleft 28vsplit")
	M.tree_win_id = vim.api.nvim_get_current_win()
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
	vim.wo.cursorline = true
	vim.wo.winfixwidth = true
	local dir = M.tree_state.last_dir or vim.fn.getcwd()
	oil.open(dir)
	M._update_title(dir)
	M.tree_state.last_dir = dir
	M.tree_buf_id = vim.api.nvim_get_current_buf()
	M.setup_autocmds()
end

function M._update_title(path)
	if not M.tree_win_id or not vim.api.nvim_win_is_valid(M.tree_win_id) then
		return
	end
	if not path then
		path = vim.fn.expand("%:t")
	end
	local cwd = vim.fn.getcwd()
	path = vim.fn.expand(path):gsub("//+", "/")
	local title = vim.startswith(path, cwd) and (vim.fn.fnamemodify(cwd, ":t") .. "/" .. path:sub(#cwd + 2))
		or path:sub(2)

	local win_width = vim.api.nvim_win_get_width(M.tree_win_id)
	local total_len = vim.fn.strdisplaywidth(title)
	local padding = math.max(math.floor((win_width - total_len) / 2), 0)
	local spaces = string.rep(" ", padding)

	vim.wo.winbar = "%#TelescopeTitle#" .. spaces .. title
end

function M.tree_toggle()
	local ofloat_ok, Ofloat = pcall(require, "utils.Ofloat")
	if ofloat_ok and Ofloat.is_open and Ofloat.is_open() then
		Ofloat._close()
	end
	if M.tree_win_id and vim.api.nvim_win_is_valid(M.tree_win_id) then
		M._close()
	else
		M._open()
	end
end

function M.apply_keymaps(buf)
	if vim.b.oil_attached_by == "otree" then
		return
	end
	vim.b.oil_attached_by = "otree"

	local mappings = {
		[";f"] = telescope.find_files,
		[";r"] = telescope.live_grep,
		[";b"] = telescope.buffers,
		[";;"] = telescope.resume,
		["sf"] = function()
			vim.cmd("Ofloat")
		end,
	}
	for key, func in pairs(mappings) do
		vim.keymap.set("n", key, function()
			if M.prev_win_id and vim.api.nvim_win_is_valid(M.prev_win_id) then
				vim.api.nvim_set_current_win(M.prev_win_id)
				func()
			end
		end, { buffer = buf, noremap = true })
	end

	vim.keymap.set("n", "H", function()
		actions.open_cwd.callback()
		local cwd = vim.fn.getcwd()
		M.tree_state.last_dir = cwd
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "h", function()
		local dir = oil.get_current_dir()
		if dir ~= vim.fn.expand("~") .. "/" then
			actions.parent.callback()
			local new_dir = oil.get_current_dir()
			M.tree_state.last_dir = new_dir
		end
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "<M-h>", function()
		local alt_buf = vim.fn.bufnr("#")
		if not vim.api.nvim_buf_is_valid(alt_buf) or not vim.api.nvim_buf_is_loaded(alt_buf) then
			vim.notify("Alternate buffer is not valid or not loaded", vim.log.levels.WARN)
			return
		end

		local file_path = vim.api.nvim_buf_get_name(alt_buf)
		local file_dir = vim.fn.fnamemodify(file_path, ":h")

		if file_dir and vim.fn.isdirectory(file_dir) == 1 then
			require("oil").open(file_dir)
			M.tree_state.last_dir = file_dir
		else
			vim.notify("Could not resolve file directory", vim.log.levels.WARN)
		end
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "<CR>", function()
		local entry = oil.get_cursor_entry()
		if entry then
			local dir = oil.get_current_dir()
			local path = vim.fn.fnamemodify(dir .. "/" .. entry.name, ":p")
			if entry.type == "file" then
				if M.prev_win_id and vim.api.nvim_win_is_valid(M.prev_win_id) then
					vim.api.nvim_set_current_win(M.prev_win_id)
				end
				if vim.api.nvim_get_current_win() == M.tree_win_id then
					return
				end
				local full_path = dir .. entry.name
				local relative_path = vim.fn.fnamemodify(full_path, ":.")
				vim.cmd("drop " .. vim.fn.fnameescape(relative_path))
			elseif entry.type == "directory" then
				actions.select.callback()
				M.tree_state.last_dir = path
			end
		else
		end
	end, { buffer = buf, noremap = true })
end

function M.setup_autocmds()
	local augroup_id = vim.api.nvim_create_augroup("OtreeWindow", { clear = true })

	vim.api.nvim_create_autocmd("WinEnter", {
		group = augroup_id,
		callback = function()
			if M.tree_win_id and vim.api.nvim_win_is_valid(M.tree_win_id) then
				local wins = vim.api.nvim_tabpage_list_wins(0)
				if #wins == 1 and wins[1] == M.tree_win_id then
					M.tree_toggle()
					local ok_q, err = pcall(vim.cmd, "silent quit")
					if not ok_q then
						vim.notify(err:match("(E%d+:.+)"), vim.log.levels.WARN)
					end
				end
			end

			if not M.ignore_winenter then
				local curr = vim.api.nvim_get_current_win()
				if curr ~= M.tree_win_id then
					M.prev_win_id = curr
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
		group = augroup_id,
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].filetype == "oil" then
				M._update_title(oil.get_current_dir())
			end
		end,
	})
	vim.api.nvim_create_autocmd("WinNew", {
		group = augroup_id,
		callback = function()
			M.ignore_winenter = true
		end,
	})
end

return M
