local M = {}

local has_dev_icons, devicons = pcall(require, "nvim-web-devicons")

local default_icon = ""

local function is_normal_file_window(win)
	win = win or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	if not vim.api.nvim_buf_is_valid(buf) then
		return false
	end
	local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
	if buftype ~= "" then
		return false
	end
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return false
	end
	local config = vim.api.nvim_win_get_config(win)
	if config.relative ~= "" then
		return false
	end
	return true
end

local function get_icon(filename, extension)
	local icon, icon_highlight

	if has_dev_icons then
		icon, icon_highlight = devicons.get_icon(filename, extension, { default = true })
		if icon then
			return icon, icon_highlight or "Normal"
		end
	end

	return default_icon, "Normal"
end

local function get_winbar()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		return ""
	end

	local extension = vim.fn.expand("%:e")
	local icon, icon_highlight = get_icon(filename, extension)

	return string.format("%%#%s#%s %%#WinbarBold#%s", icon_highlight, icon, filename)
end

vim.cmd("highlight WinbarBold gui=bold")

function M.setup()
	vim.api.nvim_create_augroup("WinbarWithIcons", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufFilePost" }, {
		group = "WinbarWithIcons",
		callback = function()
			local win = vim.api.nvim_get_current_win()
			if vim.w[win].autogroup_id then
				return
			end
			if not is_normal_file_window(win) then
				return
			end
			vim.wo[win].winbar = get_winbar()
		end,
	})
end

M.setup()
return M
