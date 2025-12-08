return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local fzf = require("fzf-lua")
		local actions = require("fzf-lua.actions")

		fzf.setup({
			winopts = {
				border = "rounded",
				title_pos = "center",
				title_flags = false,
				cursorline = true,
				row = 0.5,
				col = 0.5,
				preview = {
					border = "rounded",
					scrollbar = false,
				},
			},
			keymap = {
				builtin = {
					["<C-d>"] = "preview-half-page-down",
					["<C-u>"] = "preview-half-page-up",
				},
				fzf = {
					["ctrl-q"] = "select-all+accept",
				},
			},
			fzf_colors = {
				["fg"] = { "fg", "Normal" },
				["bg"] = { "bg", "Normal" },
				["hl"] = { "fg", "FzfLuaFzfMatch" },
				["fg+"] = { "fg", "FzfLuaFzfCursorLine" },
				["bg+"] = { "bg", "FzfLuaFzfCursorLine" },
				["hl+"] = { "fg", "FzfLuaFzfMatch" },
				["info"] = { "fg", "DiagnosticInfo" },
				["prompt"] = { "fg", "FzfLuaFzfPrompt" },
				["pointer"] = { "fg", "FzfLuaFzfPointer" },
				["marker"] = { "fg", "FzfLuaFzfMarker" },
				["spinner"] = { "fg", "DiagnosticInfo" },
				["header"] = { "fg", "FloatTitle" },
				["border"] = { "fg", "FzfLuaFzfBorder" },
				["gutter"] = { "bg", "Normal" },
			},
			files = {
				cwd = vim.loop.cwd(),
				cwd_prompt = false,
				previewer = "builtin",
				color_icons = true,
				hidden = true,
				headers = false,
				actions = {
					["enter"] = actions.file_edit_or_qf,
				},
			},
			buffers = {
				previewer = false,
				sort_mru = true,
				sort_lastused = true,
				ignore_current_buffer = false,
				headers = false,
				filename_only = false,

				actions = {
					["enter"] = actions.file_edit_or_qf,
					["ctrl-d"] = { fn = actions.buf_del, reload = true },
				},
				winopts = {
					height = 0.4,
					width = 0.4,
				},
			},
			grep = {
				headers = false,
				grep_opts = "--binary-files=without-match --line-number --recursive --color=never --perl-regexp -e",
				rg_opts = "--column --line-number --no-heading --color=never --smart-case --max-columns=4096 -e",
				previewer = {
					cmd = "bat --color=never --style=plain --paging=never",
				},
				actions = {
					["enter"] = actions.file_edit_or_qf,
				},
			},
		})
	end,
}
