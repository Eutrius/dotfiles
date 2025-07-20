return {
	"sakhnik/nvim-gdb",
	config = function()
		vim.api.nvim_win_set_var(0, "nvimgdb_termwin_command", "belowright vnew")
	end,
}
