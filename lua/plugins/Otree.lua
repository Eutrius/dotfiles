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
				win_size = 30,
				open_on_startup = false,
				use_default_keymaps = true,
				hijack_netrw = true,
				show_hidden = false,
				show_ignore = false,
				cursorline = false,
				focus_on_enter = false,
				open_on_left = true,
				git_signs = true,
				lsp_signs = true,
				oil = "float",

				ignore_patterns = {},

				keymaps = {
					["<CR>"] = "actions.select",
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

				tree = {
					space_after_icon = " ",
					space_after_connector = "",
					connector_space = "",
					connector_last = " ",
					connector_middle = " ",
					vertical_line = " ",
				},

				icons = {
					title = " ",
					default_file = "",
					default_directory = "",
					empty_dir = "",
					trash = " ",
					keymap = "⌨ ",
					oil = " ",
				},

				highlights = {
					directory = "Directory",
					file = "Normal",
					tree = "Comment",
					title = "Title",
					float_normal = "NormalFloat",
					float_border = "FloatBorder",
					link_path = "Comment",
					git_ignored = "NonText",
					git_untracked = "DiagnosticInfo",
					git_modified = "DiagnosticWarn",
					git_added = "DiagnosticHint",
					git_deleted = "DiagnosticError",
					git_conflict = "DiagnosticError",
					git_renamed = "DiagnosticHint",
					git_copied = "DiagnosticHint",
					lsp_warn = "DiagnosticWarn",
					lsp_info = "DiagnosticInfo",
					lsp_hint = "DiagnosticHint",
					lsp_error = "DiagnosticError",
				},

				float = {
					center = true,
					width_ratio = 0.4,
					height_ratio = 0.7,
					padding = 1,
					cursorline = true,
					border = "rounded",
				},
			})
		end,
	},
}
