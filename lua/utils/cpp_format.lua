---@diagnostic disable: redefined-local, unused-local
local M = {}

local function ensure_buffer_valid(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		vim.notify("Buffer " .. bufnr .. " is not valid", vim.log.levels.WARN)
		return false
	end

	if not vim.api.nvim_buf_get_option(bufnr, "modifiable") then
		pcall(vim.api.nvim_buf_set_option, bufnr, "modifiable", true)

		if not vim.api.nvim_buf_get_option(bufnr, "modifiable") then
			vim.notify("Buffer " .. bufnr .. " is not modifiable", vim.log.levels.WARN)
			return false
		end
	end

	return true
end

M.insert_void_treesitter = function(bufnr)
	if not ensure_buffer_valid(bufnr) then
		return false
	end

	local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if not ok then
		vim.notify("nvim-treesitter.ts_utils not available", vim.log.levels.WARN)
		return false
	end

	local ok, parsers = pcall(require, "nvim-treesitter.parsers")
	if not ok then
		vim.notify("nvim-treesitter.parsers not available", vim.log.levels.WARN)
		return false
	end

	if not parsers.has_parser("cpp") then
		vim.notify("Treesitter C++ parser not installed or available.", vim.log.levels.WARN)
		return false
	end

	local cpp_parser
	ok, cpp_parser = pcall(parsers.get_parser, bufnr, "cpp")
	if not ok or not cpp_parser then
		vim.notify("Could not get Treesitter C++ parser for buffer: " .. bufnr, vim.log.levels.WARN)
		return false
	end

	ok, _ = pcall(function()
		cpp_parser:parse(true)
	end)
	if not ok then
		vim.notify("Failed to parse buffer with Treesitter", vim.log.levels.WARN)
		return false
	end

	local trees = cpp_parser:trees()
	if not trees or #trees == 0 then
		vim.notify("No syntax trees available for buffer: " .. bufnr, vim.log.levels.WARN)
		return false
	end

	local tree = trees[1]
	if not tree then
		vim.notify("Could not get C++ syntax tree for buffer: " .. bufnr, vim.log.levels.WARN)
		return false
	end

	local root = tree:root()
	if not root then
		vim.notify("Could not get root node for C++ syntax tree", vim.log.levels.WARN)
		return false
	end

	local ts_query
	ok, ts_query = pcall(require, "vim.treesitter.query")
	if not ok then
		vim.notify("vim.treesitter.query not available", vim.log.levels.WARN)
		return false
	end

	local simple_query_str = [[
        (parameter_list) @params
        (#eq? @params "()") ;; Check if the text content of the node is exactly "()"
    ]]

	local query
	ok, query = pcall(ts_query.parse, "cpp", simple_query_str)
	if not ok or not query then
		vim.notify("Failed to parse Treesitter C++ 'insert_void' query.", vim.log.levels.ERROR)
		return false
	end

	local replacements = {}

	ok, _ = pcall(function()
		for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
			local capture_name = query.captures[id]
			if capture_name == "params" then
				local node_text = vim.treesitter.get_node_text(node, bufnr)
				if node_text == "()" then
					local range = { node:range() }
					table.insert(replacements, {
						start_row = range[1],
						start_col = range[2],
						end_row = range[3],
						end_col = range[4],
						new_text = "(void)",
					})
				end
			end
		end
	end)

	if not ok then
		vim.notify("Error while querying syntax tree", vim.log.levels.WARN)
		return false
	end

	if #replacements == 0 then
		return false
	end

	table.sort(replacements, function(a, b)
		if a.start_row ~= b.start_row then
			return a.start_row > b.start_row
		else
			return a.start_col > b.start_col
		end
	end)

	local changed = false
	for _, rep in ipairs(replacements) do
		ok = pcall(
			vim.api.nvim_buf_set_text,
			bufnr,
			rep.start_row,
			rep.start_col,
			rep.end_row,
			rep.end_col,
			{ rep.new_text }
		)
		if ok then
			changed = true
		end
	end

	return changed
end

M.parenthesize_return = function(bufnr)
	if not ensure_buffer_valid(bufnr) then
		return false
	end

	local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
	if not ok or not lines then
		vim.notify("Failed to get buffer lines", vim.log.levels.WARN)
		return false
	end

	local changed = false
	local pattern = "return%s+([^;(][^;]-)%s*;"

	for i = #lines, 1, -1 do
		local line = lines[i]
		local match_found = false

		local new_line = line:gsub(pattern, function(value)
			match_found = true
			local trimmed_value = value:gsub("^%s*(.-)%s*$", "%1")

			if not trimmed_value:match("^%(.*%)$") then
				changed = true
				return "return (" .. trimmed_value .. ");"
			else
				return "return " .. value .. ";"
			end
		end)

		if match_found and new_line ~= line then
			ok = pcall(vim.api.nvim_buf_set_lines, bufnr, i - 1, i, false, { new_line })
			if not ok then
				vim.notify("Failed to update line " .. i, vim.log.levels.WARN)
			end
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
			if not vim.api.nvim_buf_is_valid(bufnr) then
				pcall(vim.api.nvim_del_augroup_by_name, group_name)
				return
			end

			local filename = vim.api.nvim_buf_get_name(bufnr)
			if not filename:match("%.cpp$") and not filename:match("%.hpp$") then
				return
			end

			local win = vim.fn.bufwinid(bufnr)
			local cursor_before = win ~= -1 and vim.api.nvim_win_get_cursor(win) or nil

			local format_ok, format_err = pcall(vim.lsp.buf.format, {
				bufnr = bufnr,
				timeout_ms = 3000,
			})

			if not format_ok then
				vim.notify("LSP formatting error: " .. tostring(format_err), vim.log.levels.WARN)
			end

			if not ensure_buffer_valid(bufnr) then
				return
			end

			local made_changes_treesitter = false
			local made_changes_regex = false

			local ts_ok, ts_changed = pcall(M.insert_void_treesitter, bufnr)
			if ts_ok and ts_changed then
				made_changes_treesitter = true
			elseif not ts_ok then
				vim.notify(
					"Error during Treesitter 'insert_void' formatting: " .. tostring(ts_changed),
					vim.log.levels.ERROR
				)
			end

			local regex_ok, regex_changed = pcall(M.parenthesize_return, bufnr)
			if regex_ok and regex_changed then
				made_changes_regex = true
			elseif not regex_ok then
				vim.notify(
					"Error during Regex 'parenthesize_return' formatting: " .. tostring(regex_changed),
					vim.log.levels.ERROR
				)
			end

			if cursor_before and win ~= -1 and vim.api.nvim_win_is_valid(win) then
				local final_line_count = vim.api.nvim_buf_line_count(bufnr)
				local target_line = math.min(cursor_before[1], final_line_count)
				pcall(vim.api.nvim_win_set_cursor, win, { target_line, cursor_before[2] })
			end

			if made_changes_treesitter or made_changes_regex then
				vim.notify("Applied custom C++ formatting.", vim.log.levels.INFO, { title = "Formatting" })
			end
		end,
	})
end

return M
