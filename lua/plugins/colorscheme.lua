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
				local border = { fg = colors.cyan700, bg = colors.none }
				local title = { fg = colors.cyan, bg = colors.none }
				local cursor_line = { fg = colors.base4, bg = colors.base02 }

				highlights.FzfLuaBorder = border
				highlights.FzfLuaTitle = title
				highlights.FzfLuaFzfCursorLine = cursor_line
				highlights.FzfLuaFzfMatch = { fg = colors.blue }
				highlights.FzfLuaFzfPrompt = { fg = colors.blue }
				highlights.FzfLuaFzfPointer = { fg = colors.blue }
				highlights.CmpFloatBorder = border
				highlights.LazyGitBorder = border
				highlights.CmpNormal = { fg = colors.cyan }
				highlights.CmpSelection = { fg = colors.base4, bg = colors.base02, italic = true }
				highlights.CmpItemAbbrMatch = { fg = colors.blue, bg = colors.none }
				highlights.FloatBorder = border
				highlights.Title = title
				highlights.FloatTitle = title
				highlights.DiffChange = { fg = colors.cyan, bg = colors.none }
				highlights.MsgArea = { fg = colors.base4 }
				highlights.WinBar = { bg = colors.none }
				highlights.WinBarNC = { bg = colors.none }
				highlights.StatusLine = { bg = colors.none }
			end,
		})
		vim.cmd.colorscheme("solarized-osaka")
	end,
}
