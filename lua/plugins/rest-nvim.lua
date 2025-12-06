return {
	{
		"vhyrro/luarocks.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = true,
		opts = {
			rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
		},
	},
	{
		"rest-nvim/rest.nvim",
		ft = "http",
		dependencies = { "luarocks.nvim" },
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

                -- IMPORTANT
                skip_ssl_verification = false,
                encode_url = true,
                logs = {
                    level = "info",
                },

                -- THIS ENABLES COOKIE STORAGE
                cookies = {
                    enable = true,
                    file_name = ".rest_cookies.json",
                },
            })
		end,
	},
}
