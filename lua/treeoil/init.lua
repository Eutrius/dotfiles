local M = {}

local ui = require("treeoil.ui")

-- Configure the syntax file path
local function setup_syntax()
	-- Get the runtime path of the plugin
	local rtp = vim.split(vim.fn.escape(vim.fn.finddir("treeoil", vim.o.runtimepath), " \\,"), "\n")

	if #rtp > 0 then
		-- Register the syntax file
		vim.cmd([[
            augroup TreeOilSyntax
                autocmd!
                autocmd FileType treeoil runtime lua/treeoil/syntax/treeoil.vim
            augroup END
        ]])
	end
end

function M.toggle()
	ui.toggle()
end

function M.setup(opts)
	opts = opts or {}

	local state = require("treeoil.state")
	state.show_hidden = opts.show_hidden or false

	-- Setup syntax highlighting
	setup_syntax()

	vim.api.nvim_create_user_command("TreeOil", M.toggle, {})

	if opts.default_mapping ~= false then
		vim.keymap.set("n", "ff", M.toggle)
	end

	return M
end

-- Default configuration
M.setup({
	show_hidden = false,
	default_mapping = true,
})

return M
