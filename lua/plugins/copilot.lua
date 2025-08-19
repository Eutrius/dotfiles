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
			model = "claude-3.5-sonnet",
			resource_processing = true,
			auto_follow_cursor = true,
			auto_insert_mode = true,
			insert_at_end = true,
			show_help = false,
			show_folds = false,
			separator = " ",
			window = {
				layout = "float",
				width = 100,
				height = 40,
				border = "rounded",
				title = " Copilot ",
				zindex = 100,
			},

			headers = {
				user = "  ",
				assistant = "  ",
				tool = "  ",
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
