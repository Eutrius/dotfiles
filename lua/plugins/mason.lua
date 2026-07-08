return {
	"williamboman/mason.nvim",
	event = "VeryLazy",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")

		mason.setup({
			ui = {
				border = "rounded",
				height = 0.8,
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			ensure_installed = {
				"clangd",
				"lua_ls",
				-- "ts_ls",
				-- "html",
				-- "cssls",
				-- "tailwindcss",
			},
			automatic_enable = false,
		})

		require("mason-tool-installer").setup({
			ensure_installed = { "stylua", "prettier", "eslint_d" },
		})
	end,
}
