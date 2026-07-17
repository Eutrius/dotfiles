return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre" },
	dependencies = {
		"mason-org/mason.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{
			"antosha417/nvim-lsp-file-operations",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = true,
		},
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
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

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--log=error",
				"--fallback-style=Microsoft",
				"--offset-encoding=utf-16",
				"--header-insertion-decorators=0",
			},
			on_attach = function(client, bufnr)
				local ok, err = pcall(cpp_format.setup_cpp_formatting, client, bufnr)
				if not ok then
					vim.notify("CPP format setup error: " .. tostring(err), vim.log.levels.ERROR)
				end
			end,
		})

		vim.lsp.enable({
			-- "html",
			-- "ts_ls",
			-- "cssls",
			-- "tailwindcss",
			"lua_ls",
			"clangd",
			"pyright",
		})
	end,
}
