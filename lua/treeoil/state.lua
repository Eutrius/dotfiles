local M = {}

M.buf = nil
M.win = nil
M.cwd = nil
M.ns = vim.api.nvim_create_namespace("TreeOil")

M.tree = {}
M.line_map = {}
M.original_lines = {}

M.show_hidden = false
M.buffer_changed = false

M.clipboard = {
	action = nil,
	path = nil,
}

return M
