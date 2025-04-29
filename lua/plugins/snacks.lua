return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		dashboard = {
			enabled = true,
			sections = {
				{ section = "header", padding = 2 },
				{ icon = " ", section = "keys", gap = 1, padding = 2 },
				{ title = "Projects", icon = " ", padding = 1 },
				{ section = "projects", indent = 2, gap = 1, padding = 7 },
				{ section = "startup", padding = 0 },
			},
		},
	},
}
