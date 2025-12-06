local M = {}
local null_ls = require("null-ls")

M.source = {
  method = null_ls.methods.FORMATTING,
  filetypes = { "c", "h" },
  generator = null_ls.formatter({
    command = "sh",
    args = { "-c", "c_formatter_42" },
    to_stdin = true,
    from_stderr = false,
    filter = function()
      local filename = vim.api.nvim_buf_get_name(0)
      return filename:match("%.c$") or filename:match("%.h$")
    end,
  }),
}

function M.run(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    filter = function(client)
      return client.name == "null-ls"
    end,
  })
end

return M
