local M = {}

local ui = require("treeoil.ui")

function M.toggle()
	ui.toggle()
end

function M.setup(opts)
	opts = opts or {}

	local state = require("treeoil.state")
	state.show_hidden = opts.show_hidden or false

	vim.api.nvim_create_user_command("TreeOil", M.toggle, {})

	if opts.default_mapping ~= false then
		vim.keymap.set("n", "ff", M.toggle)
	end

	return M
end

M.setup({
	show_hidden = false,
	default_mapping = true,
})

return M
