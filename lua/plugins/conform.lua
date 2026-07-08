return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	config = function()
		require("conform").setup({
			formatters = {
				c_formatter_42 = {
					command = "c_formatter_42",
					stdin = true,
				},
			},
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				c = { "c_formatter_42" },
				h = { "c_formatter_42" }, -- inert on default nvim (.h => cpp); harmless
			},
			format_on_save = function(bufnr)
				if vim.g.format_on_save == false then
					return -- respects :F enable/disable/toggle (default off, from options.lua)
				end
				local ft = vim.bo[bufnr].filetype
				if ft == "cpp" or ft == "hpp" then
					return -- handled by clangd + treesitter path in utils/F/cpp.lua
				end
				return { timeout_ms = 3000, lsp_format = "fallback" }
			end,
		})
	end,
}
