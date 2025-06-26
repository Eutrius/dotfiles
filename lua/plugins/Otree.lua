-- return {
-- 	"Eutrius/Otree.nvim",
-- 	lazy = false,
-- 	dependencies = {
-- 		"stevearc/oil.nvim",
-- 	},
-- 	config = function()
-- 		require("Otree").setup({
-- 			win_size = 27,
-- 			oil = "",
-- 		})
-- 	end,
-- }

return {
	{
		dir = "~/Otree.nvim",
		name = "Otree",
		lazy = false,
		config = function()
			require("Otree").setup({
				oil = "float",
			})
		end,
	},
}
