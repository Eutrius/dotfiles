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
		dir = "~/Personal/Otree.nvim",
		name = "Otree",
		lazy = false,
		config = function()
			require("Otree").setup({
				open_on_startup = false,
				use_default_keymaps = true,
				hijack_netrw = true,
				show_hidden = false,
				show_ignore = false,
				focus_on_enter = false,
				open_on_left = true,
				git_signs = true,
				lsp_signs = true,

				ignore_patterns = {},

				keymaps = {
					["<CR>"] = "actions.select_then_close",
					["l"] = "actions.select",
					["h"] = "actions.close_dir",
					["<Esc>"] = "actions.close_win",
					["<C-h>"] = "actions.goto_parent",
					["<C-l>"] = "actions.goto_dir",
					["<M-h>"] = "actions.goto_home_dir",
					["`"] = "actions.change_home_dir",
					["L"] = "actions.open_dirs",
					["H"] = "actions.close_dirs",
					["o"] = "actions.oil_dir",
					["O"] = "actions.oil_into_dir",
					["t"] = "actions.open_tab",
					["sv"] = "actions.open_vsplit",
					["ss"] = "actions.open_split",
					["."] = "actions.toggle_hidden",
					["i"] = "actions.toggle_ignore",
					["r"] = "actions.refresh",
					["f"] = "actions.focus_file",
					["?"] = "actions.open_help",
				},

				oil_float = {
					center = true,
					width_ratio = 0.4,
					height_ratio = 0.7,
					padding = 1,
					cursorline = true,
					border = "rounded",
				},

				filetree = {
					mode = "right_split",
					cursorline = false,
					win_size = 30,
					float = {
						center = true,
						width_ratio = 0.4,
						height_ratio = 0.7,
						padding = 1,
						cursorline = true,
						border = "rounded",
					},
				},
			})
		end,
	},
}
