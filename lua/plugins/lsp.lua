return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local lspwindows = require("lspconfig.ui.windows")
		local F = require("utils.F")
		local cpp_format = require("utils.F.cpp")

		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = "", Warn = "", Hint = "󰌶", Info = "" }
		vim.diagnostic.config({
			virtual_text = { prefix = "●" },
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = signs.Error,
					[vim.diagnostic.severity.WARN] = signs.Warn,
					[vim.diagnostic.severity.INFO] = signs.Info,
					[vim.diagnostic.severity.HINT] = signs.Hint,
				},
			},
		})

		lspwindows.default_options.border = "rounded"

		vim.lsp.config("*", {
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					F.enable(bufnr)
				end
			end,
		})

		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--fallback-style=Microsoft",
				"--offset-encoding=utf-16",
				"--header-insertion-decorators=0",
			},
			on_attach = function(client, bufnr)
				local ok, err = pcall(cpp_format.setup_cpp_formatting, client, bufnr)
				if not ok then
					vim.notify("CPP format setup error: " .. tostring(err), vim.log.levels.ERROR)
				end
				if client.supports_method("textDocument/formatting") then
					F.enable(bufnr)
				end
			end,
		})

		vim.lsp.enable({
			"html",
			"ts_ls",
			"cssls",
			"tailwindcss",
			"lua_ls",
			"clangd",
			"pyright",
		})
	end,
}
