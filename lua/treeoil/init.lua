local M = {}

local ui = require("treeoil.ui")

function M.setup(opts)
	opts = opts or {}

	local state = require("treeoil.state")
	state.show_hidden = opts.show_hidden or false
	state.win_size = opts.win_size or 27

	vim.api.nvim_create_user_command("Treeoil", ui.toggle, {})

	if opts.default_mapping ~= false then
		vim.keymap.set("n", "ff", ui.toggle)
	end

	return M
end

return M
