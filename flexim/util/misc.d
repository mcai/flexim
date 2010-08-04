module flexim.util.misc;

import flexim.all;

uint mod(uint x, uint y) {
	return (x + y) % y;
}

const string PUBLIC = "public";
const string PROTECTED = "protected";
const string PRIVATE = "private";

template Property(T, string _name, string setter_modifier = PUBLIC, string getter_modifier = PUBLIC, string field_modifier = PRIVATE) {
	mixin(setter_modifier ~ ": " ~ "void " ~ _name ~ "(" ~ T.stringof ~ " v) { m_" ~ _name ~ " = v; }");
	mixin(getter_modifier ~ ": " ~ T.stringof ~ " " ~ _name ~ "() { return m_" ~ _name ~ ";}");
	mixin(field_modifier ~ ": " ~ T.stringof ~ " m_" ~ _name ~ ";");
}