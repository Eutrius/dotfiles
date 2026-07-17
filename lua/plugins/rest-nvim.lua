return {
	"rest-nvim/rest.nvim",
	ft = "http",
	config = function()
		require("rest-nvim").setup({
			result = {
				show_curl_command = false,
				show_http_info = true,
				show_headers = true,
			},
			highlight = {
				enabled = true,
				timeout = 150,
			},
			jump_to_request = false,
			skip_ssl_verification = false,
			encode_url = true,
			logs = {
				level = "info",
			},
			cookies = {
				enable = true,
				file_name = ".rest_cookies.json",
			},
		})
	end,
}
