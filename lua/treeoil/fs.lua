local ok, devicons = pcall(require, "nvim-web-devicons")
if not ok then
	vim.api.nvim_buf_set_lines(vim.fn.expand("%:p:h"), 0, -1, false, {
		"Error: devicons not installed",
	})
	return
end
local M = {}
local uv = vim.uv or vim.loop

local function is_hidden(name)
	return name:sub(1, 1) == "."
end

local function is_dir_empty(path)
	local req, err = uv.fs_scandir(path)
	if not req then
		return false
	end
	local entry = uv.fs_scandir_next(req)
	return entry == nil
end

local function get_parent_path(path)
	return path:match("^(.+)/[^/]+$")
end

local function get_icon(type, fullpath, filename)
	local icon, icon_hl
	if type == "directory" then
		if is_dir_empty(fullpath) then
			icon = ""
		else
			icon = ""
		end
		icon_hl = "Directory"
	else
		icon, icon_hl = devicons.get_icon(filename, nil, { default = true })
	end
	return icon, icon_hl
end

local function make_node(full_path, base, type)
	local rel = full_path:sub(#base + 2)
	local filename = vim.fn.fnamemodify(full_path, ":t")
	local level = select(2, rel:gsub("/", ""))
	local icon, icon_hl = get_icon(type, full_path, filename)

	return {
		filename = filename,
		path = rel,
		full_path = full_path,
		parent_path = get_parent_path(full_path),
		type = type,
		is_open = false,
		level = level,
		icon = icon,
		icon_hl = icon_hl,
	}
end

local function sort_nodes(nodes)
	local function compare_nodes(a, b)
		local isaDir = a.type == "directory"
		local isbDir = b.type == "directory"
		if isaDir ~= isbDir then
			return isaDir
		else
			return a.path < b.path
		end
	end
	local result = {}
	for _, node in ipairs(nodes) do
		table.insert(result, node)
	end
	table.sort(result, compare_nodes)
	return result
end

function M.scan_dir(dir, show_hidden)
	local base = dir or vim.fn.getcwd()
	local nodes = {}
	local handle = uv.fs_scandir(base)
	if not handle then
		return
	end

	while true do
		local name, t = uv.fs_scandir_next(handle)
		if not name then
			break
		end

		if show_hidden or not is_hidden(name) then
			local full = base .. "/" .. name
			local node = make_node(full, base, t)
			table.insert(nodes, node)
		end
	end
	return sort_nodes(nodes)
end

return M
