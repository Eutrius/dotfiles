return {
	"akinsho/bufferline.nvim",
	event = "BufEnter",
	version = "*",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "tabs",
				show_buffer_close_icons = false,
				show_close_icon = false,
				always_show_bufferline = true,
			},
		})
	end,
}
