local M = {}
local null_ls = require("null-ls")

M.setup_c_formatter_42 = function()
	local c_formatter_42 = {
		method = null_ls.methods.FORMATTING,
		filetypes = { "c", "cpp" },
		generator = null_ls.formatter({
			command = "sh",
			args = function()
				return {
					"-c",
					string.format("c_formatter_42"),
				}
			end,
			to_stdin = true,
			from_stderr = false,
			filter = function()
				local filename = vim.api.nvim_buf_get_name(0)
				return (filename:match("%.c$") or filename:match("%.h$"))
			end,
		}),
	}

	null_ls.register(c_formatter_42)
end

return M
