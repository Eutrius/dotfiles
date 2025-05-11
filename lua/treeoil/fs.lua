local M = {}
local uv = vim.loop

local function is_hidden(name)
	return name:sub(1, 1) == "."
end

local function get_parent_path(path)
	return path:match("^(.+)/[^/]+$")
end

local devicons = require("nvim-web-devicons")

local function make_node(full_path, base, type)
	local rel = full_path:sub(#base + 2)
	local filename = vim.fn.fnamemodify(full_path, ":t")
	local level = select(2, rel:gsub("/", ""))

	local icon, icon_hl
	if type == "directory" then
		icon = ""
		icon_hl = "Directory"
	else
		icon, icon_hl = devicons.get_icon(filename, nil, { default = true })
	end

	return {
		path = rel,
		full_path = full_path,
		parent_path = get_parent_path(full_path),
		filename = filename,
		type = type,
		is_dir = type == "directory",
		is_open = type == "directory" and "closed" or nil,
		level = level or 0,
		icon = icon,
		icon_hl = icon_hl,
	}
end

local function sort_nodes_tree(nodes)
	local node_by_path = {}
	for _, node in ipairs(nodes) do
		node_by_path[node.path] = node
	end

	local children_of = {}
	local root_nodes = {}

	for _, node in ipairs(nodes) do
		local parent_path = get_parent_path(node.path)

		if parent_path and node_by_path[parent_path] then
			children_of[parent_path] = children_of[parent_path] or {}
			table.insert(children_of[parent_path], node)
		else
			table.insert(root_nodes, node)
		end
	end

	local function compare_siblings(a, b)
		if a.is_dir ~= b.is_dir then
			return a.is_dir
		else
			return a.path < b.path
		end
	end

	for _, children in pairs(children_of) do
		table.sort(children, compare_siblings)
	end

	table.sort(root_nodes, compare_siblings)

	local result = {}
	local function traverse(node_list)
		for _, node in ipairs(node_list) do
			table.insert(result, node)
			if node.is_dir and children_of[node.path] then
				traverse(children_of[node.path])
			end
		end
	end

	traverse(root_nodes)
	return result
end

function M.scan_dir(base, show_hidden)
	local function walk(dir, result)
		local handle = uv.fs_scandir(dir)
		if not handle then
			return
		end

		while true do
			local name, t = uv.fs_scandir_next(handle)
			if not name then
				break
			end

			if show_hidden or not is_hidden(name) then
				local full = dir .. "/" .. name
				local node = make_node(full, base, t)
				table.insert(result, node)
				if t == "directory" then
					walk(full, result)
				end
			end
		end
	end

	local base_dir = base or vim.fn.getcwd()
	local nodes = {}
	walk(base_dir, nodes)
	return sort_nodes_tree(nodes)
end

return M
