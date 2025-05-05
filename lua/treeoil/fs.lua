local M = {}
local uv = vim.loop

local function is_hidden(name)
	return name:sub(1, 1) == "."
end

local devicons = require("nvim-web-devicons")

local id_counter = 0

local function base62_char(n)
	if n < 10 then
		return string.char(48 + n) -- '0' to '9'
	elseif n < 36 then
		return string.char(97 + n - 10) -- 'a' to 'z'
	else
		return string.char(65 + n - 36) -- 'A' to 'Z'
	end
end

local function to_base62(n)
	local base = 62
	local chars = {}
	for _ = 1, 4 do
		local rem = n % base
		table.insert(chars, 1, base62_char(rem))
		n = math.floor(n / base)
	end
	return table.concat(chars)
end

local function generate_id()
	local id = to_base62(id_counter)
	id_counter = (id_counter + 1) % (62 ^ 4)
	return id
end

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
		id = generate_id(),
		path = rel,
		full_path = full_path,
		filename = filename,
		type = type,
		is_dir = type == "directory",
		state = type == "directory" and "closed" or nil,
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

	local function get_parent_path(path)
		return path:match("^(.+)/[^/]+$")
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

function M.create_file(path)
	local file = io.open(path, "w")
	if file then
		file:close()
		return true
	end
	return false
end

function M.create_directory(path)
	return vim.fn.mkdir(path, "p") == 1
end

function M.delete(path)
	local stat = uv.fs_stat(path)
	if not stat then
		return false
	end

	if stat.type == "directory" then
		return vim.fn.delete(path, "rf") == 0
	else
		return vim.fn.delete(path) == 0
	end
end

function M.rename(old_path, new_path)
	return vim.fn.rename(old_path, new_path) == 0
end

function M.copy_file(src, dst)
	local content = M.read_file(src)
	if content then
		return M.write_file(dst, content)
	end
	return false
end

function M.read_file(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local content = file:read("*all")
	file:close()
	return content
end

function M.write_file(path, content)
	local file = io.open(path, "wb")
	if not file then
		return false
	end
	local success = file:write(content) ~= nil
	file:close()
	return success
end

return M
