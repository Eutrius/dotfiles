local rules = {
	{ filetypes = { "c", "cpp", "lua" }, width = 4, expandtab = false },
	{ filetypes = { "python", "asm", "nasm" }, width = 4, expandtab = true },
	{ filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }, width = 2, expandtab = true },
}

local group = vim.api.nvim_create_augroup("IndentByFiletype", { clear = true })

for _, rule in ipairs(rules) do
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = rule.filetypes,
		callback = function()
			vim.opt_local.tabstop = rule.width
			vim.opt_local.expandtab = rule.expandtab
			vim.opt_local.shiftwidth = rule.width
		end,
	})
end
