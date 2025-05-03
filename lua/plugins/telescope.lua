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
					},
					i = {
						[";;"] = actions.close,
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
				buffers = {
					theme = "dropdown",
					previewer = false,
					sort_mru = true,
					show_all_buffers = true,
					ignore_current_buffer = true,
					mappings = {
						n = {
							["dd"] = actions.delete_buffer,
						},
					},
				},
			},
		})
		telescope.load_extension("fzf")
	end,
}
