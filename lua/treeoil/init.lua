local actions = require("treeoil.actions")
local state = require("treeoil.state")
local M = {}

function M.setup(opts)
	opts = opts or {}

	state.show_hidden = opts.show_hidden or false
	state.win_size = opts.win_size or 27

	vim.api.nvim_create_user_command("Treeoil", actions.toggle, {})
	return M
end

return M
