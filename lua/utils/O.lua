local M = {}

local Ofloat = require("utils.Ofloat")
local Otree = require("utils.Otree")

vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		local buf = args.buf
		if vim.bo[buf].filetype ~= "oil" then
			return
		end
		if vim.g.oil_mode == "float" then
			Ofloat.apply_keymaps(buf)
		elseif vim.g.oil_mode == "tree" then
			Otree.apply_keymaps(buf)
		end
	end,
})

vim.api.nvim_create_user_command("Ofloat", function()
	Ofloat.float_toggle()
end, {})

vim.api.nvim_create_user_command("Otree", function()
	Otree.tree_toggle()
end, {})

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		if vim.fn.argc() == 1 then
			local target = vim.fn.argv(0)
			local stat = vim.loop.fs_stat(target)
			if stat and stat.type == "directory" then
				vim.cmd("cd " .. target)
				vim.schedule(function()
					vim.cmd("Ofloat")
				end)
				vim.cmd("bd!")
			end
		end
	end,
})

return M
