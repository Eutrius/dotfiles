local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- stylua: ignore
return {
	cpp = {
		s("cd", {
			t("#pragma once "),
			t({ "", "" }),
			t({ "", "class " }), i(1, "ClassName"),
			t({ "", "{" }),
			t({ "", "  public:" }),
			t({ "", "    " }), rep(1), t("(void);"),
			t({ "", "    " }), rep(1), t("(const "), rep(1), t(" &other);"),
			t({ "", "    ~" }), rep(1), t("(void);"),
			t({ "", "", "    " }), rep(1), t(" &operator=(const "), rep(1), t(" &other);"), i(2, ""),
			t({ "", "};" }),
			t({ "", "" }),
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
