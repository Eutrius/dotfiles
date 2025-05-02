local M = {}

M.outer_win_id = nil
M.inner_win_id = nil
M.oil_buf_id = nil
M.prev_win_id = nil
M.ns_title = vim.api.nvim_create_namespace("OfloatTitle")

function M.is_open()
	return M.outer_win_id and vim.api.nvim_win_is_valid(M.outer_win_id)
end

function M._close()
	if M.inner_win_id and vim.api.nvim_win_is_valid(M.inner_win_id) then
		pcall(vim.api.nvim_win_close, M.inner_win_id, true)
	end
	if M.outer_win_id and vim.api.nvim_win_is_valid(M.outer_win_id) then
		pcall(vim.api.nvim_win_close, M.outer_win_id, true)
	end
	M.outer_win_id = nil
	M.inner_win_id = nil
end

function M._create_windows()
	local width = vim.o.columns
	local height = vim.o.lines
	local outer_width = math.floor(width * 0.4)
	local outer_height = math.floor(height * 0.7)
	local padding = 2
	local col = math.floor((width - outer_width) / 2)
	local row = math.floor((height - outer_height) / 2)

	local outer_buf = vim.api.nvim_create_buf(false, true)
	M.outer_win_id = vim.api.nvim_open_win(outer_buf, false, {
		relative = "editor",
		width = outer_width,
		height = outer_height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		noautocmd = true,
		focusable = false,
	})
	vim.api.nvim_win_set_option(M.outer_win_id, "winhl", "Normal:TelescopeNormal,FloatBorder:TelescopeBorder")

	local inner_buf = vim.api.nvim_create_buf(false, true)
	M.inner_win_id = vim.api.nvim_open_win(inner_buf, true, {
		relative = "win",
		win = M.outer_win_id,
		width = outer_width - padding * 2,
		height = outer_height - padding * 2,
		col = padding,
		row = padding,
		style = "minimal",
		border = "none",
		noautocmd = true,
	})
	vim.api.nvim_win_set_option(M.inner_win_id, "winhl", "Normal:Normal")
	return inner_buf
end

function M._update_title(path)
	if not M.outer_win_id or not vim.api.nvim_win_is_valid(M.outer_win_id) then
		return
	end
	local cwd = vim.fn.getcwd()
	path = vim.fn.expand(path):gsub("//+", "/")
	local title = vim.startswith(path, cwd) and (vim.fn.fnamemodify(cwd, ":t") .. "/" .. path:sub(#cwd + 2))
		or path:sub(2)
	local buf = vim.api.nvim_win_get_buf(M.outer_win_id)
	vim.api.nvim_buf_clear_namespace(buf, M.ns_title, 0, 1)
	vim.api.nvim_buf_set_extmark(buf, M.ns_title, 0, 0, {
		virt_text = { { title, "TelescopeTitle" } },
	})
	vim.defer_fn(function()
		vim.wo.winbar = ""
	end, 10)
end

function M._open_file(path)
	local target_win = M.prev_win_id
	M._close()
	vim.defer_fn(function()
		if target_win and vim.api.nvim_win_is_valid(target_win) then
			vim.api.nvim_set_current_win(target_win)
		end
		if path and path ~= "" then
			vim.cmd("drop " .. vim.fn.fnameescape(path))
		end
	end, 20)
end

function M.apply_keymaps(buf)
	if vim.b.oil_attached_by == "ofloat" then
		return
	end
	vim.b.oil_attached_by = "ofloat"

	local oil = require("oil")
	local actions = require("oil.actions")
	local home = vim.fn.expand("~")

	for _, key in ipairs({ ";;", "q", "sf", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			M._close()
		end, { buffer = buf, noremap = true })
	end

	vim.keymap.set("n", "sv", function()
		actions.select.callback({ vertical = true })
		M._close()
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "ss", function()
		actions.select.callback({ horizontal = true })
		M._close()
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "H", function()
		actions.open_cwd.callback()
		M._update_title(vim.fn.getcwd())
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "h", function()
		local dir = oil.get_current_dir()
		if dir ~= home .. "/" then
			actions.parent.callback()
			M._update_title(oil.get_current_dir())
		end
	end, { buffer = buf, noremap = true })

	vim.keymap.set("n", "<CR>", function()
		local entry = oil.get_cursor_entry()
		if entry then
			local dir = oil.get_current_dir()
			local path = vim.fn.fnamemodify(dir .. "/" .. entry.name, ":p")
			if entry.type == "file" then
				M._open_file(path)
			elseif entry.type == "directory" then
				actions.select.callback()
				M._update_title(path)
			end
		else
			vim.notify("Invalid or empty entry", vim.log.levels.WARN)
		end
	end, { buffer = buf, noremap = true })
end

function M.setup_autocmds()
	local augroup_id = vim.api.nvim_create_augroup("OFloatingWindow", { clear = true })

	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = augroup_id,
		pattern = "TelescopePrompt",
		callback = function()
			M._close()
		end,
	})

	vim.api.nvim_create_autocmd({ "WinClosed" }, {
		group = augroup_id,
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].filetype == "oil" then
				M._close()
			end
		end,
	})
end

function M.float_toggle()
	vim.g.oil_mode = "float"
	M.prev_win_id = vim.api.nvim_get_current_win()
	M._close()
	local otree_ok, Otree = pcall(require, "utils.Otree")
	if otree_ok and Otree.is_open and Otree.is_open() then
		Otree._close()
	end
	local inner_buf = M._create_windows()
	local ok, oil = pcall(require, "oil")
	if not ok then
		vim.api.nvim_buf_set_lines(inner_buf, 0, -1, false, {
			"Error: oil.nvim not installed",
		})
		return
	end
	if vim.api.nvim_win_is_valid(M.inner_win_id) then
		vim.api.nvim_set_current_win(M.inner_win_id)
		oil.open(vim.fn.getcwd())
		M.oil_buf_id = vim.api.nvim_get_current_buf()
		M._update_title(vim.fn.getcwd())
		M.setup_autocmds()
	end
end

return M
