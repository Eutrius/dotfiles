return {
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				use_default_keymaps = false,
				skip_confirm_for_simple_edits = true,
				delete_to_trash = true,
				cleanup_delay_ms = 100,
				default_file_explorer = false,
				keymaps = {
					["st"] = { "actions.toggle_trash", mode = "n" },
				},
				confirmation = {
					max_width = 0.9,
					min_width = { 30 },
				},
			})
		end,
	},
}
