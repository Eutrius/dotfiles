return {
	"akinsho/bufferline.nvim",
	config = function()
		require("bufferline").setup({
			options = {
				mode = "tabs",
				show_buffer_close_icons = false,
				show_close_icon = false,
				always_show_bufferline = true,
				offsets = {
					{
						filetype = "oil",
						separator = true,
					},
				},
			},
		})
	end,
}
