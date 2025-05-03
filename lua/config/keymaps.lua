local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- General keymaps
map("n", "<leader>r", "<cmd>bufdo update | e!<CR>", { desc = "Reload all buffers" })
map("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "dw", 'vb"_d', { desc = "Delete word backwards" })
map("n", "x", '"_x', { desc = "Delete character without copying" })
map("n", "<C-a>", "ggVG", { desc = "Select all" })
map("n", ";w", "<cmd>w<CR>", { desc = "Save file" })
map("n", ";W", "<cmd>wa<CR>", { desc = "Save all file" })

-- LSP (using Lspsaga)
map("n", "<C-j>", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next diagnostic" })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover documentation" })
map("n", "gd", "<cmd>Lspsaga finder<CR>", { desc = "LSP finder" })
map("n", "gr", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
map("n", "gP", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to definition" })
map({ "n", "t" }, "<leader>t", "<cmd>Lspsaga term_toggle<CR>", { desc = "Toggle terminal" })

-- Telescope
map("n", ";f", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", ";r", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", ";b", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
map("n", ";t", "<cmd>Telescope help_tags<CR>", { desc = "Help tags" })
map("n", ";;", "<cmd>Telescope resume<CR>", { desc = "Resume last Telescope" })
map("n", ";e", "<cmd>Telescope diagnostics<CR>", { desc = "Diagnostics" })

-- Split window
map("n", "ss", "<cmd>split<Return>", { desc = "Horizontal split" })
map("n", "sv", "<cmd>vsplit<Return>", { desc = "Vertical split" })

-- Move between windows
map("n", "<Space>", "<C-w>w", { desc = "Move to next window" })
map("n", "sh", "<C-w>h", { desc = "Move to left window" })
map("n", "sk", "<C-w>k", { desc = "Move to upper window" })
map("n", "sj", "<C-w>j", { desc = "Move to lower window" })
map("n", "sl", "<C-w>l", { desc = "Move to right window" })

-- Move lines
map("v", "<M-j>", "<cmd>m '>+1<CR>gv", { desc = "Move line(s) down" })
map("v", "<M-k>", "<cmd>m '<-2<CR>gv", { desc = "Move line(s) up" })
map("v", "<M-l>", ">gv", { desc = "Indent right" })
map("v", "<M-h>", "<gv", { desc = "Indent left" })
map("n", "<M-j>", "<cmd>m+1<CR>", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>m-2<CR>", { desc = "Move line up" })
map("n", "<M-h>", "<<", { desc = "Indent left" })
map("n", "<M-l>", ">>", { desc = "Indent right" })

map("n", "<M-e>", "<cmd>bnext<CR>", { desc = "Next Buffer" })
map("n", "<M-q>", "<cmd>bprev<CR>", { desc = "Previous Buffer" })
-- Tools
map("n", ";g", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })
map("n", ";z", "<cmd>Z<CR>", { desc = "Open zshz" })
map("n", "sf", "<cmd>Ofloat<CR>", { desc = "Open oil float" })
map("n", "st", "<cmd>Otree<CR>", { desc = "Open oil tree" })
map("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy.nvim" })
map("n", "<leader>m", "<cmd>Mason<CR>", { desc = "Open Mason" })
map(
	"n",
	"<leader>n",
	[[:if &number || &relativenumber | set nonumber norelativenumber | else | set number relativenumber | endif<CR>]],
	{ desc = "Toggle line numbers" }
)

-- -- Rest-nvim (commented out)
-- map("n", "<leader>rr", "<Plug>RestNvim", { desc = "Run HTTP request under cursor" })
-- map("n", "<leader>rp", "<Plug>RestNvimPreview", { desc = "Preview HTTP request cURL" })
-- map("n", "<leader>rl", "<Plug>RestNvimLast", { desc = "Re-run last HTTP request" })
