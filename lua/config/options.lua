local opt = vim.opt

opt.pumheight = 10
opt.scrolloff = 15

-- opt.relativenumber = true
-- opt.signcolumn = "yes"
opt.number = true
opt.numberwidth = 1

opt.tabstop = 4
opt.shiftwidth = 4
opt.smarttab = true
opt.breakindent = true
opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

-- opt.cursorline = false
opt.laststatus = 3

opt.termguicolors = true
opt.background = "dark"

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

-- Auto Save
-- local timer = vim.loop.new_timer()
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
-- 	pattern = "*",
-- 	callback = function()
-- 		timer:stop()
-- 		timer:start(
-- 			10000,
-- 			0,
-- 			vim.schedule_wrap(function()
-- 				if vim.bo.modified and vim.bo.filetype ~= "" and vim.bo.buftype == "" then
-- 					vim.cmd("silent! write")
-- 				end
-- 			end)
-- 		)
-- 	end,
-- })
