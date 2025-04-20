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
<<<<<<< Updated upstream
=======
		local cpp_format = require("utils.cpp_format")
>>>>>>> Stashed changes

		local capabilities = cmp_nvim_lsp.default_capabilities()

		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		lspwindows.default_options.border = "rounded"

<<<<<<< Updated upstream
		lspconfig["html"].setup({
			capabilities = capabilities,
		})

		lspconfig["ts_ls"].setup({
			capabilities = capabilities,
		})

		lspconfig["cssls"].setup({
			capabilities = capabilities,
		})

		lspconfig["tailwindcss"].setup({
			capabilities = capabilities,
		})
=======
		local servers = { "html", "ts_ls", "cssls", "tailwindcss" }
		for _, server in ipairs(servers) do
			lspconfig[server].setup({
				capabilities = capabilities,
			})
		end
>>>>>>> Stashed changes

		lspconfig["clangd"].setup({
			capabilities = capabilities,
			cmd = {
				"clangd",
				"--fallback-style=Microsoft",
				"--offset-encoding=utf-16",
				"--header-insertion-decorators=0",
			},
<<<<<<< Updated upstream
			on_attach = function(client, bufnr)
				if client.server_capabilities.documentFormattingProvider then
					vim.api.nvim_clear_autocmds({ group = "LspFormatting", buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
						buffer = bufnr,
						callback = function()
							vim.lsp.buf.format({ bufnr = bufnr })
						end,
					})
				end
			end,
=======
			on_attach = cpp_format.setup_cpp_formatting,
>>>>>>> Stashed changes
		})
	end,
}
