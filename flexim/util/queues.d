module flexim.util.queues;

import flexim.all;

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
		assert(this.size < this.capacity, format("[%d] %s", Simulator.singleInstance.currentCycle, this));
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