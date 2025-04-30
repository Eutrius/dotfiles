return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local lspwindows = require("lspconfig.ui.windows")
		local cpp_format = require("utils.cpp_format")

		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		lspwindows.default_options.border = "rounded"

		local servers = { "html", "ts_ls", "cssls", "tailwindcss", "lua_ls" }
		for _, server in ipairs(servers) do
			lspconfig[server].setup({
				capabilities = capabilities,
			})
		end

		lspconfig["clangd"].setup({
			capabilities = capabilities,
			cmd = {
				"clangd",
				"--fallback-style=Microsoft",
				"--offset-encoding=utf-16",
				"--header-insertion-decorators=0",
			},
			on_attach = cpp_format.setup_cpp_formatting,
		})
	end,
}
