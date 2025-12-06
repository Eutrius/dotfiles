local M = {}

M.autoformat = true
M.augroup = vim.api.nvim_create_augroup("UnifiedLspFormatting", {})

local function is_format_on_save_enabled()
	if vim.g.format_on_save == nil then
		return true
	end
	return vim.g.format_on_save
end

local function load_formatter(ft)
	if ft == "c" or ft == "h" then
		return require("utils.F.c").run
	elseif ft == "cpp" or ft == "hpp" then
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
	vim.lsp.buf.format({
		bufnr = bufnr,
		filter = function(client)
			if client.name == "null-ls" then return true end
			return client.supports_method("textDocument/formatting")
		end,
	})
end

function M.enable(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	M.autoformat = true
	vim.api.nvim_clear_autocmds({ group = M.augroup, buffer = bufnr })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = M.augroup,
		buffer = bufnr,
		callback = function()
			if not M.autoformat then return end
			if not is_format_on_save_enabled() then return end
			M.format(bufnr)
		end,
	})
end

function M.disable(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	M.autoformat = false
	vim.api.nvim_clear_autocmds({ group = M.augroup, buffer = bufnr })
end

function M.toggle(bufnr)
	if M.autoformat then M.disable(bufnr) else M.enable(bufnr) end
end

vim.api.nvim_create_user_command("F", function(opts)
	local arg = opts.args
	if arg == "toggle" then
		if vim.g.format_on_save == nil then vim.g.format_on_save = true end
		vim.g.format_on_save = not vim.g.format_on_save
		vim.notify("format_on_save: " .. tostring(vim.g.format_on_save))
	elseif arg == "on" then
		vim.g.format_on_save = true
		vim.notify("format_on_save: true")
	elseif arg == "off" then
		vim.g.format_on_save = false
		vim.notify("format_on_save: false")
	else
		M.format()
	end
end, {
	nargs = "?",
	complete = function()
		return { "toggle", "on", "off" }
	end,
})

return M
