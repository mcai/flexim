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

	bool empty() {
		return this.entries.empty;
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

	int opApplyReverse(int delegate(ref uint, ref EntryT) dg) {
		int result;

		foreach_reverse(ref uint i, ref EntryT p; this.entries) {
			result = dg(i, p);
			if(result)
				break;
		}
		return result;
	}

	int opApplyReverse(int delegate(ref EntryT) dg) {
		int result;

		foreach_reverse(ref EntryT p; this.entries) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}

	void popFront() {
		this.entries.popFront();
	}
	
	void popBack() {
		this.entries.popBack();
	}

	EntryT front() {
		if(!this.empty) {
			return this.entries.front;
		}
		return null;
	}
	
	EntryT back() {
		if(!this.empty) {
			this.entries.back;
		}
		return null;
	}
	
	uint indexOf(EntryT value) {
		return this.entries.indexOf(value);
	}
	
	void removeAt(uint index) {
		this.entries = this.entries.remove(index);
	}
	
	void remove(EntryT value) {
		this.removeAt(this.indexOf(value));
	}
	
	EntryT opIndex(uint index) {
		assert(index - 1 >= 0 && index < this.size);
		return this.entries[index];
	}
	
	void opIndexAssign(EntryT value, uint index) {
		this.entries[index] = value;
	}
	
	EntryT before(EntryT entry) {
		uint index = this.indexOf(entry);
		return this[(index - 1) % this.size];
	}
	
	EntryT after(EntryT entry) {
		uint index = this.indexOf(entry);
		
		return this[(index + 1) % this.size];
	}
	
	void clear() {
		this.entries.clear();
	}

	void opOpAssign(string op, EntryT)(EntryT entry)
		if(op == "~") {
		this.entries ~= entry;
	}
	
	override string toString() {
		return format("List[size=%d]", this.size);
	}

	EntryT[] entries;
}

class Queue(EntryT): List!(EntryT) {
	this(string name, uint capacity) {
		this.name = name;
		this.capacity = capacity;
	}

	bool full() {
		return this.size >= this.capacity;
	}

	void opOpAssign(string op, EntryT)(EntryT entry)
		if(op == "~") {
		if(this.size >= this.capacity) {
			logging.fatalf(LogCategory.MISC, "%s", this);
		}
		this.entries ~= entry;
	}
	
	override void removeAt(uint index) {
		assert(index >= 0 && index < this.size);
		super.removeAt(index);
	}
	
	override string toString() {
		return format("%s[capacity=%d, size=%d]", this.name, this.capacity, this.size);
	}

	string name;
	uint capacity;
}

class DelayedQueue(EntryT): Queue!(EntryT), EventProcessor {
	this(string name, uint capacity) {
		super(name, capacity);
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this);
	} 
	
	void enqueue(EntryT entry, ulong delay = 0) {
		this.eventQueue.schedule({this ~= entry;}, delay);
	}
	
	override void processEvents() {
		this.eventQueue.processEvents();
	}
	
	DelegateEventQueue eventQueue;
}