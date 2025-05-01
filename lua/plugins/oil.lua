return {
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				columns = { "icon" },
				use_default_keymaps = false,
				keymaps = {
					["s."] = { "actions.toggle_hidden" },
					["sd"] = { "actions.cd" },
				},
			})
		end,
	},
}
