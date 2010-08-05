/*
 * flexim/cpu/fu.d
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