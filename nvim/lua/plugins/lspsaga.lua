return {
	"nvimdev/lspsaga.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("lspsaga").setup({
			ui = {
				border = "rounded",
			},
			symbol_in_winbar = {
				enable = false,
			},
			lightbulb = {
				enable = false,
			},
		})
	end,
}
