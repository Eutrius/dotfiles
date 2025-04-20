local M = {}

M.insert_void_treesitter = function(bufnr)
	local ts_utils = require("nvim-treesitter.ts_utils")
	local ts_query = require("vim.treesitter.query")
	local parsers = require("nvim-treesitter.parsers")

	if not parsers.has_parser("cpp") then
		vim.notify("Treesitter C++ parser not installed or available.", vim.log.levels.WARN)
		return false
	end

	local cpp_parser = parsers.get_parser(bufnr, "cpp")
	if not cpp_parser then
		vim.notify("Could not get Treesitter C++ parser for buffer: " .. bufnr, vim.log.levels.WARN)
		return false
	end

	cpp_parser:parse(true)
	local tree = cpp_parser:trees()[1]
	if not tree then
		vim.notify("Could not get C++ syntax tree for buffer: " .. bufnr, vim.log.levels.WARN)
		return false
	end

	local root = tree:root()
	local simple_query_str = [[
     (parameter_list) @params
     (#eq? @params "()") ;; Check if the text content of the node is exactly "()"
   ]]

	local query = ts_query.parse("cpp", simple_query_str)
	if not query then
		vim.notify("Failed to parse Treesitter C++ 'insert_void' query.", vim.log.levels.ERROR)
		return false
	end

	local replacements = {}
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

	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
	for _, rep in ipairs(replacements) do
		vim.api.nvim_buf_set_text(bufnr, rep.start_row, rep.start_col, rep.end_row, rep.end_col, { rep.new_text })
	end

	return true
end

M.parenthesize_return = function(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local changed = false
	local pattern = "return%s+([^;]+)%s*;"

	for i = #lines, 1, -1 do
		local line = lines[i]
		local match_found = false
		local new_line = line:gsub(pattern, function(value)
			match_found = true
			local trimmed_value = value:gsub("^%s*(.-)%s*$", "%1")
			if trimmed_value:match("^%(.*%)$") then
				return "return " .. value .. ";"
			else
				changed = true
				return "return (" .. trimmed_value .. ");"
			end
		end)

		if match_found and new_line ~= line then
			vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line })
		end
	end

	return changed
end

M.setup_cpp_formatting = function(client, bufnr)
	if not client.server_capabilities.documentFormattingProvider then
		return
	end

	local group = vim.api.nvim_create_augroup("LspCustomCppFormatTS", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		buffer = bufnr,
		callback = function()
			local filename = vim.api.nvim_buf_get_name(bufnr)
			if not filename:match("%.cpp$") and not filename:match("%.hpp") then
				return
			end

			vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000 })
			local cursor_before = vim.api.nvim_win_get_cursor(0)

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

			if made_changes_treesitter or made_changes_regex then
				local final_line_count = vim.api.nvim_buf_line_count(bufnr)
				local target_line = math.min(cursor_before[1], final_line_count)
				pcall(vim.api.nvim_win_set_cursor, 0, { target_line, cursor_before[2] })
				vim.notify("Applied custom C++ formatting.", vim.log.levels.INFO, { title = "Formatting" })
			end
		end,
	})
end

return M
