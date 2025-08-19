local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- General keymaps
map("n", "x", '"_x', { desc = "Delete character without copying" })
map("n", "<C-a>", "ggVG", { desc = "Select all" })

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
map("v", "<M-j>", ":m '>+1<CR>gv", { desc = "Move line(s) down" })
map("v", "<M-k>", ":m '<-2<CR>gv", { desc = "Move line(s) up" })
map("v", "<M-l>", ">gv", { desc = "Indent right" })
map("v", "<M-h>", "<gv", { desc = "Indent left" })
map("n", "<M-j>", "<cmd>m+1<CR>", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>m-2<CR>", { desc = "Move line up" })
map("n", "<M-h>", "<<", { desc = "Indent left" })
map("n", "<M-l>", ">>", { desc = "Indent right" })

-- LSP (using Lspsaga)
map("n", "<C-j>", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next diagnostic" })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover documentation" })
map("n", "gd", "<cmd>Lspsaga finder<CR>", { desc = "LSP finder" })
map("n", "gr", "<cmd>Lspsaga rename<CR>", { desc = "Rename symbol" })
map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek definition" })
map("n", "gP", "<cmd>Lspsaga goto_definition<CR>", { desc = "Go to definition" })

-- Telescope
map("n", "<leader>f", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>b", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
map("n", "<leader>g", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>r", "<cmd>Telescope resume<CR>", { desc = "Telescope Resume" })

-- Tools
map("n", "<leader>z", "<cmd>bufdo update | e!<CR>", { desc = "Reload all buffers" })
map("n", "<leader>x", "<cmd>enew | setlocal nobuflisted | %bw<CR>", { desc = "Wipeout All buffers" })
map("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy.nvim" })
map("n", "<leader>m", "<cmd>Mason<CR>", { desc = "Open Mason" })
map("n", "<leader>c", "<cmd>CopilotChat<CR>", { desc = "Open Copilot" })

map("n", "<leader>t", "<cmd>Otree<CR>", { desc = "Open oil tree" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>q", function()
	local buffers = vim.fn.getbufinfo({ buflisted = 1 })
	if #buffers > 1 then
		vim.cmd("silent! bp | silent! bd #")
	else
		vim.cmd("silent! enew | setlocal nobuflisted | silent! bd #")
	end
end, { desc = "Smart buffer close" })

-- -- Rest-nvim
-- map("n", "<leader>rr", "<Plug>RestNvim", { desc = "Run HTTP request under cursor" })
-- map("n", "<leader>rp", "<Plug>RestNvimPreview", { desc = "Preview HTTP request cURL" })
-- map("n", "<leader>rl", "<Plug>RestNvimLast", { desc = "Re-run last HTTP request" })
