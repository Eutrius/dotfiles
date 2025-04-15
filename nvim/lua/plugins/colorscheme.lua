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
				highlights.TelescopeSelection = { fg = colors.base4, bg = colors.base02 }
				highlights.TelescopeMatching = { fg = colors.blue, bold = true }
				highlights.TelescopePromptPrefix = { fg = colors.blue }
				highlights.TelescopeSelectionCaret = { fg = colors.blue, bg = colors.base02 }
				highlights.TelescopeBorder = { fg = colors.cyan700, bg = colors.none }
				highlights.TelescopeTitle = { fg = colors.cyan, bg = colors.none }
				highlights.SagaBorder = { fg = colors.cyan700 }
				highlights.SagaTitle = { fg = colors.cyan }
				highlights.CmpNormal = { fg = colors.cyan }
				highlights.CmpSelection = { fg = colors.base4, bg = colors.base02, italic = true }
				highlights.CmpItemAbbrMatch = { fg = colors.blue, bg = colors.none }
				highlights.CmpFloatBorder = { fg = colors.cyan700, bg = colors.none }
				highlights.FloatBorder = { fg = colors.cyan700, bg = colors.none }
				highlights.LazyGitBorder = { fg = colors.cyan700, bg = colors.none }
				highlights.DiffChange = { fg = colors.cyan, bg = colors.none }
				highlights.MsgArea = { fg = colors.base4 }
			end,
		})
		vim.cmd([[colorscheme solarized-osaka]])
	end,
}
