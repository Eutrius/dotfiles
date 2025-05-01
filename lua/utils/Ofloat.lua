local M = {}

M.outer_win_id = nil
M.inner_win_id = nil
M.oil_buf_id = nil
M.prev_win_id = nil
M.ns_title = vim.api.nvim_create_namespace("OtTitle")

function M.close_windows()
	if M.inner_win_id and vim.api.nvim_win_is_valid(M.inner_win_id) then
		pcall(vim.api.nvim_win_close, M.inner_win_id, true)
		M.inner_win_id = nil
	end
	if M.outer_win_id and vim.api.nvim_win_is_valid(M.outer_win_id) then
		pcall(vim.api.nvim_win_close, M.outer_win_id, true)
		M.outer_win_id = nil
	end
end

function M.create_windows()
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
	local outer_width = math.floor(width * 0.4)
	local outer_height = math.floor(height * 0.7)
	local padding = 2
	local inner_width = outer_width - (padding * 2)
	local inner_height = outer_height - (padding * 2)
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

	M.update_title(vim.fn.getcwd())

	local inner_buf = vim.api.nvim_create_buf(false, true)
	M.inner_win_id = vim.api.nvim_open_win(inner_buf, true, {
		relative = "win",
		win = M.outer_win_id,
		width = inner_width,
		height = inner_height,
		col = padding,
		row = padding,
		style = "minimal",
		border = "none",
		noautocmd = true,
	})
	vim.api.nvim_win_set_option(M.inner_win_id, "winhl", "Normal:Normal")
	return inner_buf
end

function M.update_title(path)
	if not M.outer_win_id or not vim.api.nvim_win_is_valid(M.outer_win_id) then
		return
	end
	local title
	local cwd = vim.fn.getcwd()
	path = vim.fn.expand(path)
	path = path:gsub("//+", "/")

	if vim.startswith(path, cwd) then
		path = path:sub(#cwd + 2)
		title = vim.fn.fnamemodify(cwd, ":t") .. "/" .. path
	else
		path = path:sub(2)
		title = path
	end

	local outer_buf = vim.api.nvim_win_get_buf(M.outer_win_id)
	vim.api.nvim_buf_clear_namespace(outer_buf, M.ns_title or 0, 0, 1)
	vim.api.nvim_buf_set_extmark(outer_buf, M.ns_title, 0, 0, {
		virt_text = { { title, "TelescopeTitle" } },
	})
end

function M.open_file_in_main_editor(file_path)
	local target_win = M.prev_win_id
	M.close_windows()

	vim.defer_fn(function()
		if target_win and vim.api.nvim_win_is_valid(target_win) then
			vim.api.nvim_set_current_win(target_win)
		else
			vim.notify("Invalid or missing target window", vim.log.levels.WARN)
		end
		if file_path and file_path ~= "" then
			vim.cmd("drop " .. vim.fn.fnameescape(file_path))
		else
			vim.notify("Empty file path", vim.log.levels.ERROR)
		end
	end, 20)
end

function M.setup_keymaps()
	if not M.oil_buf_id then
		return
	end
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "oil",
		callback = function(args)
			local oil = require("oil")
			local actions = require("oil.actions")
			local home_dir = vim.fn.expand("~")

			for _, key in ipairs({ ";;", "q", "sf" }) do
				vim.keymap.set("n", key, function()
					M.close_windows()
				end, { buffer = args.buf, noremap = true })
			end

			vim.keymap.set("n", "sv", function()
				actions.select.callback({ vertical = true, close = true })
			end, { buffer = args.buf, noremap = true })

			vim.keymap.set("n", "h", function()
				local current_dir = oil.get_current_dir()
				if current_dir == home_dir .. "/" then
					return
				else
					actions.parent.callback()
					local dir = oil.get_current_dir()
					M.update_title(dir)
				end
			end, { buffer = args.buf, noremap = true })

			vim.keymap.set("n", "<CR>", function()
				local entry = oil.get_cursor_entry()
				local dir = oil.get_current_dir()
				local full_path = vim.fn.fnamemodify(dir .. "/" .. entry.name, ":p")
				if entry and entry.type == "file" and entry.name then
					M.open_file_in_main_editor(full_path)
				elseif entry and entry.type == "directory" then
					M.update_title(full_path)
					actions.select.callback()
				else
					vim.notify("Invalid or empty entry", vim.log.levels.WARN)
				end
			end, { buffer = args.buf, noremap = true })
		end,
	})
end

function M.setup_autocmds()
	local augroup_id = vim.api.nvim_create_augroup("OFloatingWindow", { clear = true })

	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = augroup_id,
		pattern = "TelescopePrompt",
		callback = function()
			M.close_windows()
		end,
	})
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
		group = augroup_id,
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].filetype == "oil" then
				M.close_windows()
			end
		end,
	})
end

function M.open_oil_in_float()
	M.prev_win_id = vim.api.nvim_get_current_win()
	M.close_windows()
	local inner_buf = M.create_windows()
	local has_oil, oil = pcall(require, "oil")
	if not has_oil then
		vim.api.nvim_buf_set_lines(inner_buf, 0, -1, false, {
			"Error: oil.nvim is not installed",
			"Please install oil.nvim to use this plugin",
		})
		return
	end

	local cwd = vim.fn.getcwd()
	if vim.api.nvim_win_is_valid(M.inner_win_id) then
		vim.api.nvim_set_current_win(M.inner_win_id)
		oil.open(cwd)
		M.oil_buf_id = vim.api.nvim_get_current_buf()
		M.setup_autocmds()
		M.setup_keymaps()
	end
end

vim.api.nvim_create_user_command("Ofloat", function()
	M.open_oil_in_float()
end, {})

return M
