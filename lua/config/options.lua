local opt = vim.opt

opt.pumheight = 10
opt.scrolloff = 15

opt.signcolumn = "no"
opt.number = true
-- opt.relativenumber = true

opt.tabstop = 4
opt.expandtab = true
opt.shiftwidth = 4
opt.smarttab = true
opt.breakindent = true
opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

-- opt.cursorline = true
opt.laststatus = 0

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "cursor"

-- Disable swapfile
opt.swapfile = false

-- Auto reload buffers
opt.autoread = true

-- Custom format on save
vim.g.format_on_save = false
