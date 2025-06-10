return {
	"Eutrius/Otree.nvim",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"stevearc/oil.nvim",
	},
	config = function()
		require("Otree").setup({
			win_size = 27,
			oil = "",
		})
	end,
}

-- return {
-- 	{
-- 		dir = "~/Otree.nvim",
-- 		name = "Otree",
-- 		lazy = false,
-- 		dependencies = {
-- 			"nvim-tree/nvim-web-devicons",
-- 			"stevearc/oil.nvim",
-- 		},
-- 		config = function()
-- 			require("Otree").setup()
-- 		end,
-- 	},
-- }
