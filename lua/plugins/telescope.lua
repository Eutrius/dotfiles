return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-file-browser.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")
		local actions = require("telescope.actions")

		local function telescope_buffer_dir()
			return vim.fn.expand("%:p:h")
		end

		local fb_actions = require("telescope").extensions.file_browser.actions
		telescope.setup({
			defaults = vim.tbl_deep_extend("force", {}, {
				wrap_results = true,
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
				mappings = {
					n = {
<<<<<<< Updated upstream
						["q"] = actions.close,
=======
						["<M-w>"] = actions.close,
						["<C-u>"] = function()
							vim.cmd("normal Vd")
						end,
						["<C-d>"] = actions.delete_buffer,
					},
					i = {
						["<M-w>"] = actions.close,
						["<C-u>"] = function()
							vim.cmd("normal Vd")
						end,
>>>>>>> Stashed changes
					},
				},
			}),
			pickers = {
				diagnostics = {
					theme = "ivy",
					initial_mode = "insert",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
			},
			extensions = {
				file_browser = {
					theme = "dropdown",
					hijack_netrw = true,
					respect_gitignore = false,
					hidden = true,
					grouped = true,
					previewer = false,
<<<<<<< Updated upstream
					initial_mode = "insert",
=======
					initial_mode = "normal",
>>>>>>> Stashed changes
					layout_config = { height = 30 },
					mappings = {
						["i"] = {
							["<C-w>"] = function()
								vim.cmd("normal vbd")
							end,
						},
						["n"] = {
							["N"] = fb_actions.create,
							["h"] = fb_actions.goto_parent_dir,
							["/"] = function()
								vim.cmd("startinsert")
							end,
						},
					},
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("file_browser")
		vim.keymap.set("n", ";f", function()
			builtin.find_files({
				no_ignore = false,
				hidden = true,
			})
		end)
		vim.keymap.set("n", ";r", function()
			builtin.live_grep()
		end)
<<<<<<< Updated upstream
		vim.keymap.set("n", "sb", function()
=======
		vim.keymap.set("n", ";b", function()
>>>>>>> Stashed changes
			builtin.buffers()
		end)
		vim.keymap.set("n", ";t", function()
			builtin.help_tags()
		end)
		vim.keymap.set("n", ";;", function()
			builtin.resume()
		end)
		vim.keymap.set("n", ";e", function()
			builtin.diagnostics()
		end)
<<<<<<< Updated upstream
		vim.keymap.set("n", "sf", function()
=======
		vim.keymap.set("n", ";l", function()
>>>>>>> Stashed changes
			telescope.extensions.file_browser.file_browser({
				path = "%:p:h",
				cwd = telescope_buffer_dir(),
			})
		end)
	end,
}
