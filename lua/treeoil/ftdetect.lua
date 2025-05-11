-- Set up filetype detection for treeoil buffers
local function setup_filetype_detection()
	vim.cmd([[
        augroup TreeOilFiletype
            autocmd!
            autocmd BufNewFile,BufRead treeoil://* setfiletype treeoil
        augroup END
    ]])
end

-- Register the syntax file path
local function register_syntax_path()
	-- Get the path to this file
	local source = debug.getinfo(1, "S").source:sub(2)
	local path = vim.fn.fnamemodify(source, ":p:h")

	-- Add the syntax directory to runtimepath
	vim.cmd("set runtimepath+=" .. path .. "/syntax")

	-- Create an autocmd to load the syntax file
	vim.cmd([[
        augroup TreeOilSyntax
            autocmd!
            autocmd FileType treeoil runtime syntax/treeoil.vim
        augroup END
    ]])
end

-- Initialize
setup_filetype_detection()
register_syntax_path()

return {}
