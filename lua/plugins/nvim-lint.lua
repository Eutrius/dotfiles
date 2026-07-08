return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}

		-- Preserve the none-ls "[eslint] <msg> (<code>)" prefix.
		local eslint = lint.linters.eslint_d
		local base_parser = eslint.parser
		eslint.parser = function(output, bufnr, cwd)
			local diagnostics = base_parser(output, bufnr, cwd)
			for _, d in ipairs(diagnostics) do
				d.message = string.format("[eslint] %s (%s)", d.message, d.code or "")
			end
			return diagnostics
		end

		local group = vim.api.nvim_create_augroup("NvimLint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = group,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
