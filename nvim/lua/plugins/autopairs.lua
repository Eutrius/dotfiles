return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = true,
	opts = {
		disable_filetype = { "TelescopePrompt", "spectre_panel", "vim" },
	},
}
