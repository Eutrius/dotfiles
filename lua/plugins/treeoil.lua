return {
	{
		dir = "~/.config/nvim/lua/treeoil", -- or use vim.fn.stdpath("config") .. "/lua/treeoil"
		name = "treeoil",
		lazy = false,
		config = function()
			require("treeoil").setup()
		end,
	},
}
