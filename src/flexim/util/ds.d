/*
 * flexim/util/ds.d
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

module flexim.util.ds;

import flexim.all;

class List(EntryT) {
	this() {
	}
	
	void add(EntryT entry) {
		this.pendingEntries ~= entry;
	}
	
	void remove(EntryT entry) {
		uint indexToRemove = this.pendingEntries.indexOf(entry);
		this.pendingEntries = this.pendingEntries.remove(indexToRemove);
	}

	EntryT[] pendingEntries;
}

class Queue(EntryT) {
	this(string name, uint capacity) {
		this.name = name;
		this.capacity = capacity;
	}

	bool empty() {
		return this.entries.empty;
	}

	bool full() {
		return this.size >= this.capacity;
	}

	uint size() {
		return this.entries.length;
	}

	int opApply(int delegate(ref uint, ref EntryT) dg) {
		int result;

		foreach(ref uint i, ref EntryT p; this.entries) {
			result = dg(i, p);
			if(result)
				break;
		}
		return result;
	}

	int opApply(int delegate(ref EntryT) dg) {
		int result;

		foreach(ref EntryT p; this.entries) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}

	void popFront() {
		this.entries.popFront;
	}

	EntryT front() {
		return this.entries.front;
	}

	void opOpAssign(string op, EntryT)(EntryT entry)
		if(op == "~")
	{
		if(this.size >= this.capacity) {
			logging.fatalf(LogCategory.MISC, "%s", this);
		}
		this.entries ~= entry;
	}

	override string toString() {
		string str;

		str ~= format("%s [size: %d, capacity: %d]\n", this.name, this.size, this.capacity);

		foreach(i, entry; this) {
			str ~= format("  %2d: %s\n", i, to!(string)(entry));
		}

		return str;
	}

	string name;

	uint capacity;

	EntryT[] entries;
}