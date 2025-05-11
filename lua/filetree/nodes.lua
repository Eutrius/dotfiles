local M = {}
local uv = vim.loop
local devicons = require("nvim-web-devicons")

local function generate_id()
	return tostring(uv.hrtime())
end

local function scan_directory(path, depth, nodes)
	local handle = uv.fs_scandir(path)
	if not handle then
		return
	end

	while true do
		local name, type = uv.fs_scandir_next(handle)
		if not name then
			break
		end

		local full_path = path .. "/" .. name
		local is_directory = (type == "directory")

		local icon, hl_group
		if is_directory then
			icon = ""
			hl_group = "Directory"
		else
			icon, hl_group = devicons.get_icon(name, nil, { default = true })
		end

		table.insert(nodes, {
			id = generate_id(),
			full_path = full_path,
			parent_path = path,
			filename = name,
			is_directory = is_directory,
			is_open = false,
			depth = depth or 0,
			icon = icon,
			hl_group = hl_group,
		})

		if is_directory then
			scan_directory(full_path, (depth or 0) + 1, nodes)
		end
	end
end

local function sort_nodes_tree(nodes)
	local node_by_path = {}
	for _, node in ipairs(nodes) do
		node_by_path[node.full_path] = node
	end

	local function get_parent_path(path)
		return path:match("^(.+)/[^/]+$")
	end

	local children_of = {}
	local root_nodes = {}

	for _, node in ipairs(nodes) do
		local parent_path = get_parent_path(node.full_path)

		if parent_path and node_by_path[parent_path] then
			children_of[parent_path] = children_of[parent_path] or {}
			table.insert(children_of[parent_path], node)
		else
			table.insert(root_nodes, node)
		end
	end

	local function compare_siblings(a, b)
		if a.is_directory ~= b.is_directory then
			return a.is_directory
		else
			return a.filename < b.filename
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
			if node.is_directory and children_of[node.full_path] then
				traverse(children_of[node.full_path])
			end
		end
	end

	traverse(root_nodes)
	return result
end

function M.get_nodes(path, depth)
	local nodes = {}
	scan_directory(path, depth, nodes)
	nodes = sort_nodes_tree(nodes)
	return nodes
end

return M
