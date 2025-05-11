return {
	{
		dir = "~/.config/nvim/lua/filetree", -- or use vim.fn.stdpath("config") .. "/lua/treeoil"
		name = "filetree",
		lazy = false,
		config = function()
			require("filetree").setup()
		end,
	},
}
