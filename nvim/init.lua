require('base')
require('highlights')
require('maps')
require('plugins')

vim.api.nvim_create_user_command("Q", ":q!", {})
vim.opt.signcolumn = "yes"
vim.g.python3_host_prog = vim.fn.exepath("python3")
vim.g.python_host_prog = vim.fn.exepath("python3")

function UpdatePlugins()
  vim.cmd("MasonUpdate")
  vim.cmd("PackerSync")
  vim.cmd("TSUpdate")
end
