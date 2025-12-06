local M = {}

local function ensure_buffer_valid(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	if not vim.api.nvim_buf_get_option(bufnr, "modifiable") then
		pcall(vim.api.nvim_buf_set_option, bufnr, "modifiable", true)
		if not vim.api.nvim_buf_get_option(bufnr, "modifiable") then
			return false
		end
	end
	return true
end

M.insert_void_treesitter = function(bufnr)
	if not ensure_buffer_valid(bufnr) then
		return false
	end

	local ok, _ = pcall(require, "nvim-treesitter.ts_utils")
	if not ok then return false end

	local _, parsers = pcall(require, "nvim-treesitter.parsers")
	if not ok then return false end

	if not parsers.has_parser("cpp") then return false end

	local _, cpp_parser = pcall(parsers.get_parser, bufnr, "cpp")
	if not ok or not cpp_parser then return false end

	pcall(function() cpp_parser:parse(true) end)

	local trees = cpp_parser:trees()
	if not trees or #trees == 0 then return false end

	local tree = trees[1]
	if not tree then return false end

	local root = tree:root()
	if not root then return false end

	local _, ts_query = pcall(require, "vim.treesitter.query")
	if not ok then return false end

	local simple_query_str = [[
        (parameter_list) @params
        (#eq? @params "()")
    ]]

	local _, query = pcall(ts_query.parse, "cpp", simple_query_str)
	if not ok or not query then return false end

	local replacements = {}

	pcall(function()
		for id, node in query:iter_captures(root, bufnr, 0, -1) do
			local name = query.captures[id]
			if name == "params" then
				local text = vim.treesitter.get_node_text(node, bufnr)
				if text == "()" then
					local r = { node:range() }
					table.insert(replacements, {
						start_row = r[1],
						start_col = r[2],
						end_row = r[3],
						end_col = r[4],
						new_text = "(void)",
					})
				end
			end
		end
	end)

	if #replacements == 0 then return false end

	table.sort(replacements, function(a, b)
		if a.start_row ~= b.start_row then
			return a.start_row > b.start_row
		else
			return a.start_col > b.start_col
		end
	end)

	local changed = false

	for _, rep in ipairs(replacements) do
		local _ = pcall(
			vim.api.nvim_buf_set_text,
			bufnr,
			rep.start_row,
			rep.start_col,
			rep.end_row,
			rep.end_col,
			{ rep.new_text }
		)
		if ok then changed = true end
	end

	return changed
end

M.parenthesize_return = function(bufnr)
	if not ensure_buffer_valid(bufnr) then
		return false
	end

	local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
	if not ok or not lines then return false end

	local changed = false
	local pattern = "return%s+([^;(][^;]-)%s*;"

	for i = #lines, 1, -1 do
		local line = lines[i]
		local found = false

		local new = line:gsub(pattern, function(value)
			found = true
			local trimmed = value:gsub("^%s*(.-)%s*$", "%1")
			if not trimmed:match("^%(.*%)$") then
				changed = true
				return "return (" .. trimmed .. ");"
			else
				return "return " .. value .. ";"
			end
		end)

		if found and new ~= line then
			pcall(vim.api.nvim_buf_set_lines, bufnr, i - 1, i, false, { new })
		end
	end

	return changed
end

M.setup_cpp_formatting = function(client, bufnr)
	if not client or not client.server_capabilities or not client.server_capabilities.documentFormattingProvider then
		return
	end

	local group_name = "LspCustomCppFormatTS_" .. bufnr
	local group = vim.api.nvim_create_augroup(group_name, { clear = true })

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		buffer = bufnr,
		callback = function(args)
			if args.data and args.data.client_id == client.id then
				pcall(vim.api.nvim_del_augroup_by_name, group_name)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		buffer = bufnr,
		callback = function()
			if not ensure_buffer_valid(bufnr) then return end

			local name = vim.api.nvim_buf_get_name(bufnr)
			if not name:match("%.cpp$") and not name:match("%.hpp$") then return end

			local win = vim.fn.bufwinid(bufnr)
			local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or nil

			pcall(vim.lsp.buf.format, {
				bufnr = bufnr,
				timeout_ms = 3000,
			})

			if not ensure_buffer_valid(bufnr) then return end

			local ts_ok, ts_changed = pcall(M.insert_void_treesitter, bufnr)
			local regex_ok, regex_changed = pcall(M.parenthesize_return, bufnr)

			if cursor and win ~= -1 and vim.api.nvim_win_is_valid(win) then
				local total = vim.api.nvim_buf_line_count(bufnr)
				local line = math.min(cursor[1], total)
				pcall(vim.api.nvim_win_set_cursor, win, { line, cursor[2] })
			end

			if (ts_ok and ts_changed) or (regex_ok and regex_changed) then
				vim.notify("Applied custom C++ formatting.", vim.log.levels.INFO)
			end
		end,
	})
end

M.run = function(bufnr)
	vim.lsp.buf.format({ bufnr = bufnr })
end

return M
