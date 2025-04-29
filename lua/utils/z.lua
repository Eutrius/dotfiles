local plenary_ok, plenary = pcall(require, "plenary")
if not plenary_ok then
	vim.notify("Error: plenary.nvim is required for telescope_z module.", vim.log.levels.ERROR)
	return {}
end

local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
	vim.notify("Error: telescope.nvim is required for telescope_z module.", vim.log.levels.ERROR)
	return {}
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local Z = {}

vim.g.telescope_z_command = 'zsh -c "source ~/.config/zsh/plugins/zsh-z/zsh-z.plugin.zsh && zshz -r"'

local function get_z_results()
	local cmd = vim.g.telescope_z_command
	if not cmd or cmd == "" then
		return nil, "z command not configured. Set vim.g.telescope_z_command in your config."
	end

	local output = vim.fn.systemlist(cmd)
	local exit_code = vim.v.shell_error

	if exit_code ~= 0 then
		return nil, "'" .. cmd .. "' failed with exit code: " .. exit_code
	end

	if not output or #output == 0 then
		return {}, nil
	end

	local results = {}
	for _, line in ipairs(output) do
		local rank, path = line:match("^%s*(%S+)%s+(.+)$")
		if rank and path then
			table.insert(results, {
				rank = tonumber(rank) or 0,
				path = vim.trim(path),
			})
		else
			vim.notify("Warning: Could not parse z output line: '" .. line .. "'", vim.log.levels.WARN)
		end
	end

	for i = 1, math.floor(#results / 2) do
		results[i], results[#results - i + 1] = results[#results - i + 1], results[i]
	end

	return results, nil
end

function Z.find_directories()
	local z_results, err = get_z_results()
	if err then
		vim.notify("Error getting Z directories: " .. err, vim.log.levels.ERROR)
		return
	end

	if not z_results or #z_results == 0 then
		vim.notify("No directories found in 'z' history.", vim.log.levels.INFO)
		return
	end

	pickers
		.new({}, {
			prompt_title = "Z",
			layout_config = { width = 0.5, height = 0.5 },
			finder = finders.new_table({
				results = z_results,
				entry_maker = function(entry)
					return {
						value = entry.path,
						display = entry.path,
						ordinal = entry.path,
						rank = entry.rank,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)

					if selection and selection.value then
						local success, err = pcall(vim.api.nvim_set_current_dir, selection.value)
						if success then
							vim.notify("Changed directory to: " .. selection.value, vim.log.levels.INFO)
							vim.cmd("doautocmd DirChanged")
						else
							vim.notify("Error changing directory: " .. tostring(err), vim.log.levels.ERROR)
						end
					end
				end)
				return true
			end,
		})
		:find()
end

vim.api.nvim_create_user_command("Z", function()
  Z.find_directories()
end, { desc = "Find Z directories [Telescope]" })

return Z

