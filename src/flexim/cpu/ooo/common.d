/*
 * flexim/cpu/ooo/common.d
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flexim.	If not, see <http ://www.gnu.org/licenses/>.
 */

module flexim.cpu.ooo.common;

import flexim.all;

class FunctionalUnit {
	this(FunctionalUnitPool pool, FunctionalUnitType type, uint opLat, uint issueLat) {
		this.pool = pool;
		this.type = type;
		this.opLat = opLat;
		this.issueLat = issueLat;
	}

	override string toString() {
		return format("%s[type=%s, opLat=%d, issueLat=%d, busy=%d]", "FunctionalUnit",
			to!(string)(this.type), this.opLat, this.issueLat, this.busy);
	}
	
	void acquire(void delegate() onCompletedCallback) {	
		this.pool.eventQueue.schedule(
			{
				this.busy = false;
				
				if(onCompletedCallback !is null) {
					onCompletedCallback();
				}
			}, this.issueLat + this.opLat);
		this.busy = true;
	}

	FunctionalUnitPool pool;
	FunctionalUnitType type;
	uint opLat;
	uint issueLat;
	bool busy;
}

class FunctionalUnitPool {
	this() {		
		this.add(FunctionalUnitType.IntALU, 4, 1, 1);
		this.add(FunctionalUnitType.IntMULT, 1, 3, 1);
		this.add(FunctionalUnitType.IntDIV, 1, 20, 19);
		this.add(FunctionalUnitType.RdPort, 2, 1, 1);
		this.add(FunctionalUnitType.WrPort, 2, 1, 1);
		this.add(FunctionalUnitType.FloatADD, 4, 2, 1);
		this.add(FunctionalUnitType.FloatCMP, 4, 2, 1);
		this.add(FunctionalUnitType.FloatCVT, 4, 2, 1);
		this.add(FunctionalUnitType.FloatMULT, 1, 4, 1);
		this.add(FunctionalUnitType.FloatDIV, 1, 12, 12);
		this.add(FunctionalUnitType.FloatSQRT, 1, 24, 24);
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
	}
	
	void add(FunctionalUnitType type, uint quantity, uint opLat, uint issueLat) {
		this.entities[type] = new FunctionalUnit[quantity];
		for(uint i = 0; i < quantity; i++) {
			this.entities[type][i] = new FunctionalUnit(this, type, opLat, issueLat);
		}
	}
	
	FunctionalUnit findFree(FunctionalUnitType type) {
		auto res = filter!((FunctionalUnit fu){return !fu.busy;})(this.entities[type]);
		return !res.empty ? res.front: null;
	}
	
	void acquire(ReorderBufferEntry reorderBufferEntry, void delegate(ReorderBufferEntry reorderBufferEntry) onCompletedCallback2) {
		FunctionalUnitType type = reorderBufferEntry.dynamicInst.staticInst.fuType;
		FunctionalUnit fu = this.findFree(type);
		
		if(fu !is null) {
			fu.acquire({onCompletedCallback2(reorderBufferEntry);});
		}
		else {
			this.eventQueue.schedule(
				{
					this.acquire(reorderBufferEntry, onCompletedCallback2);
				}, 10);
		}
	}

	FunctionalUnit[][FunctionalUnitType] entities;
	DelegateEventQueue eventQueue;
}

enum PhysicalRegisterState: string {
	FREE = "FREE",
	ALLOC = "ALLOC",
	WB = "WB",
	ARCH = "ARCH"
}

class PhysicalRegister {
	this() {
		this.state = PhysicalRegisterState.FREE;
	}
	
	bool isReady() {
		return this.state == PhysicalRegisterState.WB || this.state == PhysicalRegisterState.ARCH;
	}
	
	override string toString() {
		return format("PhysicalRegister[state=%s]", this.state);
	}
	
	PhysicalRegisterState state;
}

class PhysicalRegisterFile {
	this(Core core, uint capacity = 128) {
		this.core = core;
		this.capacity = capacity;
		
		this.entries = new PhysicalRegister[this.capacity];
		for(uint i = 0; i < this.capacity; i++) {
			this.entries[i] = new PhysicalRegister();
		}
	}
	
	PhysicalRegister findFree() {
		auto res = filter!((PhysicalRegister physReg){return physReg.state == PhysicalRegisterState.FREE;})(this.entries);
		return !res.empty ? res.front : null;
	}
	
	PhysicalRegister alloc() {
		PhysicalRegister freeReg = this.findFree();
		assert(freeReg !is null); //TODO
		freeReg.state = PhysicalRegisterState.ALLOC;
		return freeReg;
	}
	
	PhysicalRegister opIndex(uint index) {
		assert(index >= 0 && index <= this.entries.length, format("%d", index));
		return this.entries[index];
	}
	
	void opIndexAssign(PhysicalRegister value, uint index) {
		assert(index >= 0 && index <= this.entries.length, format("%d", index));
		this.entries[index] = value;
	}
	
	override string toString() {
		return format("PhysicalRegisterFile[capacity=%d, core=%s, entries.length=%d]", this.capacity, this.core, this.entries.length);
	}

	Core core;
	uint capacity;
	PhysicalRegister[] entries;
}

class RegisterRenameTable {
	this() {
	}
	
	PhysicalRegister opIndex(RegisterDependency dep) {
		return this.entries[dep.type][dep.num];
	}
	
	PhysicalRegister opIndex(RegisterDependencyType type, uint num) {
		return this.entries[type][num];
	}
	
	void opIndexAssign(PhysicalRegister physReg, RegisterDependency dep) {
		this.entries[dep.type][dep.num] = physReg;
	}
	
	void opIndexAssign(PhysicalRegister physReg, RegisterDependencyType type, uint num) {
		this.entries[type][num] = physReg;
	}
	
	PhysicalRegister[uint][RegisterDependencyType] entries;
}

class DecodeBufferEntry {
	this(DynamicInst dynamicInst) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
	}
	
	override string toString() {
		return format("DecodeBufferEntry[id=%d, dynamicInst=%s]", this.id, this.dynamicInst);
	}
	
	ulong id;
	uint npc, nnpc, predNpc, predNnpc;
	DynamicInst dynamicInst;
	
	bool isSpeculative;
	bool isRecoverInst;
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class DecodeBuffer: Queue!(DecodeBufferEntry) {
	this(uint capacity = 4) {
		super("decodeBuffer", capacity);
	}
}

class ReorderBufferEntry {
	this(DynamicInst dynamicInst, RegisterDependency[] iDeps, RegisterDependency[] oDeps) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
		this.iDeps = iDeps;
		this.oDeps = oDeps;
	}
	
	bool allOperandsReady() {
		return filter!((RegisterDependency iDep){return !this.srcPhysRegs[iDep].isReady;})(this.iDeps).empty;
	}
	
	bool isInLoadStoreQueue() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry is null;
	}
	
	bool isEAComputation() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry !is null;
	}
	
	override string toString() {
		string operandsReadyToString() {
			string str = "\n";
		
			foreach(i, iDep; this.iDeps) {
				str ~= format("[%s] idep=%s, isReady=%s\n", i, iDep, this.srcPhysRegs[iDep].isReady);
			}
			
			return str;
		}
		
		return format("ReorderBufferEntry(id=%d, dynamicInst=%s, isEAComputation=%s, isDispatched=%s, isInReadyQueue=%s, isIssued=%s, isCompleted=%s) %s",
			this.id, this.dynamicInst, this.isEAComputation, this.isDispatched, this.isInReadyQueue, this.isIssued, this.isCompleted,
				operandsReadyToString);
	}
	
	ulong id;
	uint npc, nnpc, predNpc, predNnpc;
	DynamicInst dynamicInst;
	
	RegisterDependency[] iDeps, oDeps;
	PhysicalRegister[RegisterDependency] oldPhysRegs, physRegs, srcPhysRegs;
	
	bool isDispatched, isInReadyQueue, isIssued, isCompleted;
	
	ReorderBufferEntry loadStoreQueueEntry;
	uint ea;
	
	bool isSpeculative;
	bool isRecoverInst;
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class ReadyQueue: List!(ReorderBufferEntry) {
	this() {
		super("readyQueue");
	}
}

class WaitingQueue: List!(ReorderBufferEntry) {
	this() {
		super("waitingQueue");
	}
}

class ReorderBuffer: Queue!(ReorderBufferEntry) {
	this(uint capacity = 96) {
		super("reorderBuffer", capacity);
	}
}

class LoadStoreQueue: Queue!(ReorderBufferEntry) {
	this(uint capacity = 32) {
		super("loadStoreQueue", capacity);
	}
}
