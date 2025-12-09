return {
	"nvimtools/none-ls.nvim",
	event = "LspAttach",
	dependencies = {
        "nvimtools/none-ls-extras.nvim",
        'nvim-lua/plenary.nvim'
	},
	config = function()
		local null_ls = require("null-ls")
		local F = require("utils.F")
        local c_fmt = require("utils.F.c")

		null_ls.setup({
			sources = {
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
				require("none-ls.diagnostics.eslint_d").with({
					diagnostics_format = "[eslint] #{m}\n(#{c})",
				}),
                c_fmt.source,
			},
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					F.enable(bufnr)
				end
			end,
		})
	end,
}
