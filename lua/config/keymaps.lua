local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

vim.g.mapleader = " "

-- general keymaps
map("n", "x", '"_x', { desc = "Delete character without copying" })
map("n", "<c-a>", "ggvg", { desc = "Select all" })

-- Scroll horizontally
map("n", "<C-h>", "10zh", { desc = "Scroll left" })
map("n", "<C-l>", "10zl", { desc = "Scroll right" })

-- Move between windows
map("n", "<M-h>", "<c-w>h", { desc = "Move to left window" })
map("n", "<M-l>", "<c-w>l", { desc = "Move to right window" })
map("n", "<M-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<M-j>", "<C-w>j", { desc = "Move to lower window" })

-- Resize windows
map("n", "<M-H>", ":vertical resize -2<CR>", { desc = "Resize window left" })
map("n", "<M-L>", ":vertical resize +2<CR>", { desc = "Resize window right" })
map("n", "<M-K>", ":resize +2<CR>", { desc = "Resize window up" })
map("n", "<M-J>", ":resize -2<CR>", { desc = "Resize window down" })

-- LSP (using Lspsaga)
map("n", "<C-j>", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Jump to next diagnostic" })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Show hover documentation" })
map("n", "gd", "<cmd>Lspsaga finder<CR>", { desc = "Show LSP finder" })
map("n", "gr", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
map("n", "gP", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to definition" })

-- Split window
map("n", "ss", "<cmd>split<Return>", { desc = "Split window horizontally" })
map("n", "sv", "<cmd>vsplit<Return>", { desc = "Split window vertically" })

-- Telescope
map("n", "<leader>f", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>r", "<cmd>Telescope buffers<CR>", { desc = "Show buffers" })
map("n", "<leader>g", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>e", "<cmd>Telescope resume<CR>", { desc = "Resume Telescope" })

-- Tools
map("n", "<leader>t", "<cmd>Otree<CR>", { desc = "Open Oil tree" })
map("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy.nvim" })
map("n", "<leader>m", "<cmd>Mason<CR>", { desc = "Open Mason" })
map({ "n", "v" }, "<leader>c", "<cmd>CopilotChat<CR>", { desc = "Open Copilot Chat" })

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
