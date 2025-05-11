return {
	{
		dir = "~/.config/nvim/lua/treeoil",
		name = "treeoil",
		lazy = false,
		config = function()
			require("treeoil").setup({
				show_hidden = false,
				default_mapping = true,
				win_size = 27,
			})
		end,
	},
}
