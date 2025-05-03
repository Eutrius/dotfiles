return {
	{
		"stevearc/oil.nvim",
		config = function()
			require("oil").setup({
				columns = { "icon" },
				use_default_keymaps = false,
				keymaps = {
					["<CR>"] = { "actions.select" },
					["h"] = { "actions.parent" },
					["H"] = { "actions.open_cwd" },
					["s."] = { "actions.toggle_hidden" },
					["fq"] = { "npgvbaf.pq" },
					["fe"] = { "npgvbaf.erserfu" },
				},
			})
		end,
	},
}
