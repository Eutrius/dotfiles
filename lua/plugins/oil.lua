return {
	"stevearc/oil.nvim",
	opts = {
		skip_confirm_for_simple_edits = true,
		delete_to_trash = true,
		cleanup_delay_ms = false,
		default_file_explorer = false,
		columns = {
			"icon",
		},
		keymaps = {
			["t"] = { "actions.toggle_trash", mode = "n" },
			["."] = { "actions.toggle_hidden", mode = "n" },
		},
		confirmation = {
			max_width = 0.9,
			min_width = { 50 },
		},
	},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	lazy = false,
}
