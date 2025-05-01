local M = {}

M.tree_win_id = nil
M.tree_buf_id = nil
M.prev_win_id = nil
M.tree_state = { last_dir = nil }
M.ignore_winenter = false

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
	vim.wo.winfixwidth = true
	local ok, oil = pcall(require, "oil")
	if not ok then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {
			"Error: oil.nvim not installed",
		})
		return
	end
	local dir = M.tree_state.last_dir or vim.fn.getcwd()
	oil.open(dir)
	M._update_title(dir)
	M.tree_state.last_dir = dir:gsub("//+", "/")
	M.tree_buf_id = vim.api.nvim_get_current_buf()
end

function M._update_title(path)
	if not M.tree_win_id or not vim.api.nvim_win_is_valid(M.tree_win_id) then
		return
	end
	local cwd = vim.fn.getcwd()
	path = vim.fn.expand(path):gsub("//+", "/")
	local title = vim.startswith(path, cwd) and (vim.fn.fnamemodify(cwd, ":t") .. "/" .. path:sub(#cwd + 2))
		or path:sub(2)

	local hl_group = "%#TelescopeTitle#"
	local win_width = vim.api.nvim_win_get_width(M.tree_win_id)
	local total_len = vim.fn.strdisplaywidth(title)
	local padding = math.max(math.floor((win_width - total_len) / 2), 0)
	local spaces = string.rep(" ", padding)

	vim.wo.winbar = hl_group .. spaces .. title
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

	local oil = require("oil")
	local actions = require("oil.actions")
	local home = vim.fn.expand("~")

	local telescope = require("telescope.builtin")
	local mappings = {
		[";f"] = telescope.find_files,
		[";r"] = telescope.live_grep,
		[";b"] = telescope.buffers,
		[";t"] = telescope.help_tags,
		[";e"] = telescope.diagnostics,
		[";;"] = telescope.resume,
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
		M._update_title(cwd)
		M.tree_state.last_dir = cwd
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "sf", function()
		local ofloat_ok, Ofloat = pcall(require, "utils.Ofloat")
		if ofloat_ok then
			Ofloat.float_toggle()
		end
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "h", function()
		local dir = oil.get_current_dir()
		if dir ~= home .. "/" then
			actions.parent.callback()
			local new_dir = oil.get_current_dir():gsub("//+", "/")
			M.tree_state.last_dir = new_dir
			M._update_title(new_dir)
		end
	end, { buffer = buf, noremap = true })

	for _, key in ipairs({ "sv", "ss" }) do
		vim.keymap.set("n", key, "<Nop>", { buffer = buf, noremap = true })
	end

	vim.keymap.set("n", "<CR>", function()
		local entry = oil.get_cursor_entry()
		if entry then
			local dir = oil.get_current_dir()
			local path = vim.fn.fnamemodify(dir .. "/" .. entry.name, ":p")
			if entry.type == "file" then
				if M.prev_win_id and vim.api.nvim_win_is_valid(M.prev_win_id) then
					vim.api.nvim_set_current_win(M.prev_win_id)
				end
				vim.cmd("drop " .. vim.fn.fnameescape(path))
			elseif entry.type == "directory" then
				actions.select.callback()
				M.tree_state.last_dir = path:gsub("//+", "/")
				vim.defer_fn(function()
					M._update_title(path)
				end, 10)
			end
		else
		end
	end, { buffer = buf, noremap = true })
end

vim.api.nvim_create_autocmd("WinEnter", {
	callback = function()
		if not M.ignore_winenter then
			local curr = vim.api.nvim_get_current_win()
			if curr ~= M.tree_win_id then
				M.prev_win_id = curr
			end
		end
	end,
})

return M
