local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- stylua: ignore
return {
	cpp = {
		s("cd", {
			t("#ifndef "), i(1, "ClassGuard"), t("_HPP"),
			t({ "", "#define " }), rep(1), t("_HPP"),
			t({ "", "" }),
			t({ "", "class " }), i(2, "ClassName"),
			t({ "", "{" }),
			t({ "", "  public:" }),
			t({ "", "    " }), rep(2), t("(void);"),
			t({ "", "    " }), rep(2), t("(const "), rep(2), t(" &other);"),
			t({ "", "    ~" }), rep(2), t("(void);"),
			t({ "", "", "    " }), rep(2), t(" &operator=(const "), rep(2), t(" &other);"), i(3, ""),
			t({ "", "};" }),
			t({ "", "" }),
			t({ "", "#endif" }),
		}),
		s("cl", {
			t("#include \""), i(1, "ClassName"), t(".hpp\""),
			t({ "", "", "" }),
			rep(1), t("::"), rep(1), t("(void)"),
			t({ "", "{" }),
			t({ "", "}" }),
			t({ "", "", "" }),
			rep(1), t("::"), rep(1), t("(const "), rep(1), t(" &other)"),
			t({ "", "{" }),
			t({ "", "}" }),
			t({ "", "", "" }),
			rep(1), t("::~"), rep(1), t("(void)"),
			t({ "", "{" }),
			t({ "", "}" }),
			t({ "", "", "" }),
			rep(1), t(" &"), rep(1), t("::operator=(const "), rep(1), t(" &other)"),
			t({ "", "{" }),
			t({ "", "    return (*this);" }),
			t({ "", "}" }),
		}),
	},
}
