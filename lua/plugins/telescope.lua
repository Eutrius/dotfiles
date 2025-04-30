return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")
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
				buffers = {
					sort_lastused = true,
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
		vim.keymap.set("n", ";f", function()
			builtin.find_files({
				no_ignore = false,
				hidden = true,
			})
		end)
		vim.keymap.set("n", ";r", function()
			builtin.live_grep()
		end)
		vim.keymap.set("n", ";b", function()
			builtin.buffers()
		end)
		vim.keymap.set("n", ";t", function()
			builtin.help_tags()
		end)
		vim.keymap.set("n", ";;", function()
			builtin.resume({
				default_text = "",
			})
		end)
		vim.keymap.set("n", ";e", function()
			builtin.diagnostics()
		end)
	end,
}
