/*
 * flexim/util/misc.d
 * 
 * Copyright (c) 2010 Min Cai <itecgo@163.com>. 
 * 
 * This file is part of the Flexim multicore architectural simulator.
 * 
 * Flexim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Flexim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flexim.  If not, see <http ://www.gnu.org/licenses/>.
 */

module flexim.util.misc;

import flexim.all;

const string PUBLIC = "public";
const string PROTECTED = "protected";
const string PRIVATE = "private";

template Property(T, string _name, string setter_modifier = PUBLIC, string getter_modifier = PUBLIC, string field_modifier = PRIVATE) {
	mixin(setter_modifier ~ ": " ~ "void " ~ _name ~ "(" ~ T.stringof ~ " v) { m_" ~ _name ~ " = v; }");
	mixin(getter_modifier ~ ": " ~ T.stringof ~ " " ~ _name ~ "() { return m_" ~ _name ~ ";}");
	mixin(field_modifier ~ ": " ~ T.stringof ~ " m_" ~ _name ~ ";");
}

abstract class Stats(ValueT) {	
	this() {
		this.init();
	}

	protected abstract void init();

	protected abstract void init(string index);

	ref ValueT opIndex(string index) {
		assert(index in this.entries, index);
		return this.entries[index];
	}

	void opIndexAssign(ValueT value, string index) {
		assert(index in this.entries, index);
		this.entries[index] = value;
	}

	ValueT[string] entries;
}