return {
	{
		"stevearc/oil.nvim",
		config = function()
			local function is_git_repo(path)
				local cmd = { "git", "-C", path, "rev-parse", "--is-inside-work-tree" }
				local result = vim.fn.systemlist(cmd)
				return result[1] == "true"
			end

			local function is_git_ignored(name)
				local oil = require("oil")
				local dir = oil.get_current_dir()

				if not is_git_repo(dir) then
					return false
				end
				local path = dir .. "/" .. name
				local cmd = { "git", "-C", dir, "check-ignore", path }
				local result = vim.fn.systemlist(cmd)

				return #result > 0
			end
			require("oil").setup({
				view_options = {
					is_hidden_file = function(name)
						if name:match("^%.") then
							return true
						end
						return is_git_ignored(name)
					end,
				},
				columns = { "icon" },
				use_default_keymaps = false,
				keymaps = {
					["s."] = { "actions.toggle_hidden" },
					["z"] = { "actions.cd" },
				},
			})
		end,
	},
}
