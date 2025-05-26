return {
	{
		dir = "~/Otree.nvim",
		name = "Otree",
		lazy = false,
		config = function()
			require("Otree").setup({
				show_hidden = false,
				show_ignore = false,
				default_mapping = true,
				win_size = 27,
			})
		end,
	},
}
--
-- return {
-- 	"Eutrius/Otree.nvim",
-- 	lazy = false,
-- 	dependencies = {
-- 		"nvim-tree/nvim-web-devicons",
-- 		"stevearc/oil.nvim",
-- 	},
-- 	config = function()
-- 		require("Otree").setup()
-- 	end,
-- }
