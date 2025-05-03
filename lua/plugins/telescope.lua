return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")

		telescope.setup({
			defaults = vim.tbl_deep_extend("force", {}, {
				wrap_results = true,
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
				mappings = {
					n = {
						[";;"] = actions.close,
						["<M-w>"] = actions.close,
						["<C-u>"] = function()
							vim.cmd("normal Vd")
						end,
					},
					i = {
						[";;"] = actions.close,
						["<M-w>"] = actions.close,
						["<C-u>"] = function()
							vim.cmd("normal Vd")
						end,
						["<C-w>"] = function()
							vim.cmd("normal vbd")
						end,
					},
				},
			}),
			pickers = {
				find_files = {
					no_ignore = false,
					hidden = true,
				},
				resume = {
					default_text = "",
				},
				buffers = {
					sort_mru = true,
					ignore_current_buffer = true,
					show_all_buffers = true,
					mappings = {
						n = {
							["<C-d>"] = actions.delete_buffer,
						},
						i = {
							["<C-d>"] = actions.delete_buffer,
						},
					},
				},
				diagnostics = {
					theme = "ivy",
					initial_mode = "insert",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
			},
		})
		telescope.load_extension("fzf")
	end,
}
