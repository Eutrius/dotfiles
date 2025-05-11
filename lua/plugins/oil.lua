return {
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				use_default_keymaps = false,
				skip_confirm_for_simple_edits = true,
				default_file_explorer = false,
				keymaps = {
					["s."] = { "actions.toggle_hidden" },
					["sd"] = { "actions.cd" },
					["sr"] = { "actions.refresh" },
				},
			})
		end,
	},
}
