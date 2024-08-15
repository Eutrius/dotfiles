local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set('n', 'x', '"_x')
keymap.set('i', '<M-f>', '<esc>')

--UpdatePlugins
keymap.set('n', '<Leader>u', ':lua UpdatePlugins()<CR>', opts)

--Copy
keymap.set('v', 'Y', ':y+<CR>')


-- Delete a word backwards
keymap.set('n', 'dw', 'vb"_d')

-- Select all
keymap.set('n', '<C-a>', 'gg<S-v>G')

-- Quote
keymap.set('v', '\'', 'c"<c-r>""<Esc>')
keymap.set('v', '"', 'd<left>"_x"_x<left>p')

-- Tab
keymap.set('n', 'te', ':tabedit<cr>', opts)
keymap.set('n', 'tx', ':tabclose<cr>', opts)
keymap.set('n', '<m-right>', ':tabmove +1<cr>')
keymap.set('n', '<m-left>', ':tabmove -1<cr>')

--  Split  window
keymap.set('n', 'ss', ':split<Return><C-w>w', opts)
keymap.set('n', 'sv', ':vsplit<Return><C-w>w', opts)

-- Move window
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('', 'sh', '<C-w>h')
keymap.set('', 'sk', '<C-w>k')
keymap.set('', 'sj', '<C-w>j')
keymap.set('', 'sl', '<C-w>l')

-- Resize window
keymap.set('n', '<C-w><left>', '<C-w><')
keymap.set('n', '<C-w><right>', '<C-w>>')
keymap.set('n', '<C-w><up>', '<C-w>+')
keymap.set('n', '<C-w><down>', '<C-w>-')

-- Move Lines
keymap.set('v', '<M-j>', ':m \'>+1<CR>gv', opts)
keymap.set('v', '<M-k>', ':m \'<-2<CR>gv', opts)
keymap.set('v', '<M-l>', '>gv', opts)
keymap.set('v', '<M-h>', '<gv', opts)
keymap.set('n', '<M-j>', ':m+1<CR>', opts)
keymap.set('n', '<M-k>', ':m-2<CR>', opts)
keymap.set('n', '<M-h>', '<<', opts)
keymap.set('n', '<M-l>', '>>', opts)

-- Lspsaga
vim.keymap.set('n', '<C-j>', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts)
vim.keymap.set('n', 'gl', '<Cmd>Lspsaga show_cursor_diagnostics<CR>', opts)
vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', opts)
vim.keymap.set('n', 'gd', '<Cmd>Lspsaga finder<CR>', opts)
vim.keymap.set('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', opts)
vim.keymap.set('n', 'gP', '<Cmd>Lspsaga goto_definition<CR>', opts)
vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', opts)
vim.keymap.set("n", "<leader>ca", '<Cmd>Lspsaga code_action<CR>', opts)

--Rest.nvim
keymap.set('n', 'rnp', "<Cmd>Rest run<CR>", opts)
keymap.set('n', 'rnl', "<Cmd>Rest run last<CR>", opts)
keymap.set('n', 'rne', "<Cmd>Telescope rest select_env<CR>", opts)
