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
	config = function()
		local chat = require("CopilotChat")

		chat.setup({
			model = "gpt-4.1",
			resource_processing = true,
			auto_follow_cursor = true,
			insert_at_end = true,
			show_help = false,
			show_folds = false,

			headers = {
				user = "  Me",
				assistant = "  Copilot",
				tool = "   Tool",
			},
		})

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
			pattern = "copilot-chat",
			callback = function()
				vim.opt_local.cursorline = false
				vim.opt_local.number = false
			end,
		})

		local hl_groups = {
			"CopilotChatSeparator",
			"CopilotChatStatus",
			"CopilotChatHelp",
			"CopilotChatSelection",
			"CopilotChatKeyword",
			"CopilotChatAnnotation",
		}

		for _, group in ipairs(hl_groups) do
			vim.api.nvim_set_hl(0, group, { fg = "NONE", bg = "NONE", bold = false, italic = false })
		end
	end,
}
