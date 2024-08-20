local Z = {}

function Z.open_z_popup()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = 50
	local height = 1
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	local function set_prompt_highlight(bufnr)
		vim.api.nvim_command("highlight! link BufferPrompt CustomPrompt")

		vim.api.nvim_set_hl(0, "CustomPrompt", { fg = "#2AA2A0", bg = "NONE" })

		vim.api.nvim_win_set_option(bufnr, "winhighlight", "Normal:CustomPrompt")
	end

	vim.api.nvim_buf_set_option(buf, "buftype", "prompt")
	vim.fn.prompt_setprompt(buf, " z ")
	vim.api.nvim_win_set_cursor(win, { 1, 5 })
	vim.cmd("startinsert")

	set_prompt_highlight(win)

	vim.api.nvim_buf_set_keymap(
		buf,
		"i",
		"<leader>z",
		'<Esc>:lua require("Z").close_buff(' .. win .. "," .. buf .. ")<CR>",
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_keymap(
		buf,
		"i",
		"<CR>",
		'<Esc>:lua require("Z").handle_input(' .. win .. ")<CR>",
		{ noremap = true, silent = true }
	)
end

function Z.close_buff(win, buf)
	vim.api.nvim_win_close(win, true)
	vim.api.nvim_buf_delete(buf, { force = true })
end

function Z.handle_input(win)
	local buf = vim.api.nvim_get_current_buf()

	local input = string.sub(vim.api.nvim_get_current_line(), 3)

	Z.close_buff(win, buf)

	if input and input ~= "" then
		local cmd = "z -l " .. input .. " | awk 'NR==1{print $2}'"
		local path = vim.fn.system(cmd)

		path = vim.fn.trim(path)

		if path ~= "" then
			vim.cmd("cd " .. path)
		else
			print("No directory found for '" .. input .. "'")
		end
	end
end

vim.api.nvim_create_user_command("Z", function()
	Z.open_z_popup()
end, {})

return Z
