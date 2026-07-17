local M = {}

local function load_formatter(ft)
	if ft == "cpp" or ft == "hpp" then
		return require("utils.F.cpp").run
	end
	return nil
end

function M.format(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	local custom = load_formatter(ft)
	if custom then
		return custom(bufnr)
	end
	require("conform").format({
		bufnr = bufnr,
		lsp_format = "fallback",
		timeout_ms = 3000,
	})
end

vim.api.nvim_create_user_command("F", function(opts)
	local arg = opts.args
	if arg == "toggle" then
		if vim.g.format_on_save == nil then
			vim.g.format_on_save = true
		end
		vim.g.format_on_save = not vim.g.format_on_save
		vim.notify("format_on_save: " .. tostring(vim.g.format_on_save))
	elseif arg == "enable" then
		vim.g.format_on_save = true
		vim.notify("format_on_save: true")
	elseif arg == "disable" then
		vim.g.format_on_save = false
		vim.notify("format_on_save: false")
	else
		M.format()
	end
end, {
	nargs = "?",
	complete = function()
		return { "toggle", "enable", "disable" }
	end,
})

return M
