local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- General keymaps
map("i", "<M-f>", "<Esc><Esc>")
map("n", "<leader>w", ":w<CR>")
map("n", "<leader>q", ":q<CR>")
map("n", "dw", 'vb"_d')

-- LSP (using Lspsaga)
map("n", "<C-j>", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next diagnostic" })
map("n", "gl", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { desc = "Show cursor diagnostics" })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover documentation" })
map("n", "gd", "<cmd>Lspsaga finder<CR>", { desc = "LSP finder" })
map({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Code action" })
map("n", "gr", "<cmd>Lspsaga rename<CR>", { desc = "Rename" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
map("n", "gP", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to definition" })

-- Tab
map("n", "te", ":tabedit<cr>")
map("n", "tx", ":tabclose<cr>")
map("n", "<M-right>", ":tabmove +1<cr>")
map("n", "<M-left>", ":tabmove -1<cr>")

-- Bufferline
map("n", "<M-e>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<M-q>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })

--  Split  window
map("n", "ss", ":split<Return><C-w>w")
map("n", "sv", ":vsplit<Return><C-w>w")

-- Move window
map("n", "<Space>", "<C-w>w")
map("", "sh", "<C-w>h")
map("", "sk", "<C-w>k")
map("", "sj", "<C-w>j")
map("", "sl", "<C-w>l")

-- Resize window
map("n", "<C-w><left>", "<C-w><")
map("n", "<C-w><right>", "<C-w>>")
map("n", "<C-w><up>", "<C-w>+")
map("n", "<C-w><down>", "<C-w>-")

-- Move Lines
map("v", "<M-j>", ":m '>+1<CR>gv")
map("v", "<M-k>", ":m '<-2<CR>gv")
map("v", "<M-l>", ">gv")
map("v", "<M-h>", "<gv")
map("n", "<M-j>", ":m+1<CR>")
map("n", "<M-k>", ":m-2<CR>")
map("n", "<M-h>", "<<")
map("n", "<M-l>", ">>")

-- Lazygit
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })

-- Rest-nvim
map("n", "<leader>rr", "<Plug>RestNvim", { desc = "Run request under cursor" })
map("n", "<leader>rp", "<Plug>RestNvimPreview", { desc = "Preview request cURL command" })
map("n", "<leader>rl", "<Plug>RestNvimLast", { desc = "Re-run last request" })
