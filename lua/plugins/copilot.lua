return {
	"CopilotC-Nvim/CopilotChat.nvim",
	dependencies = {
		{
			"github/copilot.vim",
			init = function()
				vim.g.copilot_enabled = false
			end,
		},
		{ "nvim-lua/plenary.nvim", branch = "master" },
	},
	build = "make tiktoken",
	opts = {
		window = {
			cursorline = false,
			number = false,
		},
		highlight = {
			backgrounds = "diff",
		},
	},
}
