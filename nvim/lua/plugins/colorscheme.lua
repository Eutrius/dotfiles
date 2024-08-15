return {
	"craftzdog/solarized-osaka.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("solarized-osaka").setup({
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
			on_highlights = function(highlights, colors)
				highlights.TelescopeNormal = { fg = colors.fg, bg = "NONE" }
				highlights.TelescopeSelection = { fg = colors.base4, bg = colors.base02 }
				highlights.TelescopeSelectionDirectory = { fg = colors.base4, bg = colors.base02 }
				highlights.TelescopeMatching = { fg = colors.blue, bold = true }
				highlights.TelescopePromptPrefix = { fg = colors.blue }
				highlights.TelescopeSelectionCaret = { fg = colors.blue, bg = colors.base02 }
				highlights.TelescopeBorder = { fg = colors.cyan700, bg = "NONE" }
				highlights.TelescopeTitle = { fg = colors.cyan, bg = "NONE" }
				highlights.DiffChange = { fg = colors.cyan, bg = "NONE" }
			end,
		})
		vim.cmd([[colorscheme solarized-osaka]])
	end,
}
