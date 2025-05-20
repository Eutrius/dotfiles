return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
		"onsails/lspkind.nvim",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local lspkind = require("lspkind")

		require("luasnip.loaders.from_vscode").lazy_load()

		local custom_snippets = require("utils.S")
		for ft, snippets in pairs(custom_snippets) do
			luasnip.add_snippets(ft, snippets)
		end

		local map = vim.keymap.set

		map({ "i", "s" }, "<Tab>", function()
			if luasnip.jumpable(1) then
				luasnip.jump(1)
			end
		end, { desc = "LuaSnip: jump forward", silent = true })

		map({ "i", "s" }, "<S-Tab>", function()
			if luasnip.jumpable(-1) then
				luasnip.jump(-1)
			end
		end, { desc = "LuaSnip: jump backward", silent = true })

		cmp.setup({
			window = {
				completion = {
					border = "rounded",
					winhighlight = "Normal:CmpNormal,FloatBorder:CmpFloatBorder,CursorLine:CmpSelection,Search:None",
					scrollbar = false,
				},
				documentation = {
					border = "rounded",
					winhighlight = "FloatBorder:CmpFloatBorder",
				},
			},
			completion = {
				completeopt = "menu,menuone,preview,noselect",
			},
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = false }),
			}),
			sources = cmp.config.sources({
				{ name = "buffer" },
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			}),
			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol",
					maxwidth = 50,
					ellipsis_char = "...",

					before = function(_, vim_item)
						vim_item.menu = ({ nvim_lsp = "" })["clangd"]
						return vim_item
					end,
				}),
			},
		})
	end,
}
