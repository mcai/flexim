module flexim.cpu.fu;

import flexim.all;

class FU {
	this(FUCategory master, FUType fuType, uint opLat, uint issueLat) {
		this.master = master;
		this.fuType = fuType;
		this.opLat = opLat;
		this.issueLat = issueLat;
	}

	override string toString() {
		return format("%s [master: %s, fuType: %s, opLat: %d, issueLat: %d]", "FU", this.master.name, to!(string)(this.fuType), this.opLat, this.issueLat);
	}

	FUCategory master;

	FUType fuType;
	uint opLat;
	uint issueLat;
}

class FUCategory {
	this(string name, uint quantity, uint busy) {
		this.name = name;
		this.quantity = quantity;
		this.busy = busy;
	}

	override string toString() {
		return format("%s [name: %s, quantity: %d, busy: %d]", "FUCategory", this.name, this.quantity, this.busy);
	}

	string name;
	uint quantity;
	uint busy;

	FU[] x;
}