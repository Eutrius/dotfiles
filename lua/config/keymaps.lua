local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

vim.g.mapleader = " "

-- general keymaps
map("n", "x", '"_x', { desc = "delete character without copying" })
map("n", "<c-a>", "ggvg", { desc = "select all" })

-- scoll horizontally
map("n", "<C-h>", "10zh", { desc = "scroll left" })
map("n", "<C-l>", "10zl", { desc = "scroll right" })

-- move between windows
map("n", "<M-h>", "<c-w>h", { desc = "move window to left" })
map("n", "<M-l>", "<c-w>l", { desc = "move window to right" })
map("n", "<M-k>", "<C-w>k", { desc = "Move window to top" })
map("n", "<M-j>", "<C-w>j", { desc = "Move window to bottom" })

-- Resize windows
map("n", "<M-H>", ":vertical resize -2<CR>", { desc = "Resize window left" })
map("n", "<M-L>", ":vertical resize +2<CR>", { desc = "Resize window right" })
map("n", "<M-K>", ":resize +2<CR>", { desc = "Resize window up" })
map("n", "<M-J>", ":resize -2<CR>", { desc = "Resize window down" })

-- LSP (using Lspsaga)
map("n", "<C-j>", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next diagnostic" })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover documentation" })
map("n", "gd", "<cmd>Lspsaga finder<CR>", { desc = "LSP finder" })
map("n", "gr", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
map("n", "gP", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to definition" })

-- Split window
map("n", "ss", "<cmd>split<Return>", { desc = "Horizontal split" })
map("n", "sv", "<cmd>vsplit<Return>", { desc = "Vertical split" })

-- Telescope
map("n", "<leader>f", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>r", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
map("n", "<leader>g", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>e", "<cmd>Telescope resume<CR>", { desc = "Telescope Resume" })

-- Tools
map("n", "<leader>t", "<cmd>Otree<CR>", { desc = "Open oil tree" })
map("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy.nvim" })
map("n", "<leader>m", "<cmd>Mason<CR>", { desc = "Open Mason" })
map({ "n", "v" }, "<leader>c", "<cmd>CopilotChat<CR>", { desc = "Open Copilot" })

-- Custom
map("n", "<leader>w", function()
	if vim.wo.wrap then
		vim.wo.wrap = false
		vim.wo.linebreak = false
		vim.wo.showbreak = ""
	else
		vim.wo.wrap = true
		vim.wo.linebreak = true
		vim.wo.showbreak = "> "
	end
end, { desc = "Toggle wrap" })
