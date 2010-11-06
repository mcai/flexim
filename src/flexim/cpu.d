/*
 * flexim/cpu.d
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

module flexim.cpu;

import flexim.all;

import core.stdc.errno;

import std.c.stdlib;

import std.path;

class BpredBtbEntry {
	this() {

	}

	uint addr;
	StaticInst staticInst;
	uint target;
	BpredBtbEntry prev, next;
}

const uint MD_BR_SHIFT = 3;

class BimodBpredDir {
	this(uint size) {
		this.size = size;
		this.table = new ubyte[this.size];

		ubyte flipflop = 1;
		for(uint cnt = 0; cnt < this.size; cnt++) {
			this.table[cnt] = flipflop;
			flipflop = cast(ubyte) (3 - flipflop);
		}
	}

	uint hash(uint baddr) {
		return (baddr >> 19) ^ (baddr >> MD_BR_SHIFT) & (this.size - 1);
	}

	ubyte* lookup(uint baddr) {
		return &this.table[this.hash(baddr)];
	}

	uint size;
	ubyte[] table;
}

class TwoLevelBpredDir {
	this(uint l1Size, uint l2Size, uint shiftWidth, bool xor) {
		this.l1Size = l1Size;
		this.l2Size = l2Size;
		this.shiftWidth = shiftWidth;
		this.xor = xor;

		this.shiftRegs = new uint[this.l1Size];
		this.l2Table = new ubyte[this.l2Size];

		ubyte flipflop = 1;
		for(uint cnt = 0; cnt < this.l2Size; cnt++) {
			this.l2Table[cnt] = flipflop;
			flipflop = cast(ubyte) (3 - flipflop);
		}
	}

	ubyte* lookup(uint baddr) {
		uint l1Index = (baddr >> MD_BR_SHIFT) & (this.l1Size - 1);
		uint l2Index = this.shiftRegs[l1Index];

		if(this.xor) {
			l2Index = (((l2Index ^ (baddr >> MD_BR_SHIFT)) & ((1 << this.shiftWidth) - 1)) | ((baddr >> MD_BR_SHIFT) << this.shiftWidth));
		}
		else {
			l2Index |= (baddr >> MD_BR_SHIFT) << this.shiftWidth;
		}
		
		l2Index &= (this.l2Size - 1);
		
		return &this.l2Table[l2Index];
	}

	uint l1Size;
	uint l2Size;
	uint shiftWidth;
	bool xor;
	uint[] shiftRegs;
	ubyte[] l2Table;
}

class BTB {
	this(uint sets, uint assoc) {
		this.sets = sets;
		this.assoc = assoc;

		this.entries = new BpredBtbEntry[this.sets * this.assoc];
		for(uint i = 0; i < this.sets * this.assoc; i++) {
			this[i] = new BpredBtbEntry();
		}

		if(this.assoc > 1) {
			for(uint i = 0; i < this.sets * this.assoc; i++) {
				if(i % this.assoc != (this.assoc - 1)) {
					this[i].next = this[i + 1];
				} else {
					this[i].next = null;
				}

				if(i % this.assoc != (this.assoc - 1)) {
					this[i + 1].prev = this[i];
				}
			}
		}
	}

	BpredBtbEntry opIndex(uint index) {
		return this.entries[index];
	}

	void opIndexAssign(BpredBtbEntry value, uint index) {
		this.entries[index] = value;
	}

	uint sets;
	uint assoc;
	BpredBtbEntry[] entries;
}

class RAS {
	this(uint size) {
		this.size = size;
		this.entries = new BpredBtbEntry[this.size];
		for(uint i = 0; i < this.size; i++) {
			this[i] = new BpredBtbEntry();
		}

		this.tos = this.size - 1;
	}

	BpredBtbEntry opIndex(uint index) {
		return this.entries[index];
	}

	void opIndexAssign(BpredBtbEntry value, uint index) {
		this.entries[index] = value;
	}

	uint size;
	uint tos;
	BpredBtbEntry[] entries;
}

class BpredUpdate {
	this() {

	}

	ubyte* pdir1;
	ubyte* pdir2;
	ubyte* pmeta;

	bool ras;
	bool bimod;
	bool twoLevel;
	bool meta;
}

interface Bpred {
	uint lookup(uint baddr, uint btarget, DynamicInst dynamicInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx);

	void recover(uint baddr, uint stackRecoverIdx);
	
	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, DynamicInst dynamicInst, ref BpredUpdate dirUpdate);	
}

class CombinedBpred : Bpred {
	this() {
		this(65536, 1, 65536, 65536, 16, 1, 1024, 4, 1024);
	}
	
	this(uint bimodSize, uint l1Size, uint l2Size, uint metaSize, uint shiftWidth, bool xor, uint btbSets, uint btbAssoc, uint rasSize) {
		this.twoLevel = new TwoLevelBpredDir(l1Size, l2Size, shiftWidth, xor);
		this.bimod = new BimodBpredDir(bimodSize);
		this.meta = new BimodBpredDir(metaSize);

		this.btb = new BTB(btbSets, btbAssoc);
		this.retStack = new RAS(rasSize);
	}

	// btarget is for static predictors such taken or not taken, so here it is not used at all
	uint lookup(uint baddr, uint btarget, DynamicInst dynamicInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx) {
		StaticInst staticInst = dynamicInst.staticInst;
				
		if(!staticInst.isControl) {
			return 0;
		}

		dirUpdate = new BpredUpdate();
		dirUpdate.ras = false;
		dirUpdate.pdir1 = null;
		dirUpdate.pdir2 = null;
		dirUpdate.pmeta = null;
		
		if(staticInst.isControl && !staticInst.isUnconditional) {
			ubyte* bimodCtr = this.bimod.lookup(baddr);
			ubyte* twoLevelCtr = this.twoLevel.lookup(baddr);
			ubyte* metaCtr = this.meta.lookup(baddr);
			
			dirUpdate.pmeta = metaCtr;
			dirUpdate.meta = (*metaCtr >= 2);
			dirUpdate.bimod = (*bimodCtr >= 2);
			dirUpdate.twoLevel = (*twoLevelCtr >= 2);
			
			if(*metaCtr >=2) {
				dirUpdate.pdir1 = twoLevelCtr;
				dirUpdate.pdir2 = bimodCtr;
			}
			else {
				dirUpdate.pdir1 = bimodCtr;
				dirUpdate.pdir2 = twoLevelCtr;
			}
		}
		
		if(this.retStack.size > 0) {
			stackRecoverIdx = this.retStack.tos;
		}
		else {
			stackRecoverIdx = 0;
		}
		
		if(staticInst.isReturn && this.retStack.size > 0) {
			uint target = this.retStack[this.retStack.tos].target;
			this.retStack.tos = (this.retStack.tos + this.retStack.size - 1) % this.retStack.size;
			dirUpdate.ras = true;
		}
		
		if(staticInst.isCall && this.retStack.size > 0) {
			this.retStack.tos = (this.retStack.tos + 1) % this.retStack.size;
			this.retStack[this.retStack.tos].target = baddr + uint.sizeof;
		}
		
		uint index = (baddr >> MD_BR_SHIFT) & (this.btb.sets - 1);
		
		BpredBtbEntry btbEntry;
		
		if(this.btb.assoc > 1) {
			index *= this.btb.assoc;
			
			for(uint i = index; i < (index + this.btb.assoc); i++) {
				if(this.btb[i].addr == baddr) {
					btbEntry = this.btb[i];
					break;
				}
			}
		}
		else {
			btbEntry = this.btb[index];
			if(btbEntry.addr != baddr) {
				btbEntry = null;
			}
		}
		
		if(staticInst.isControl && staticInst.isUnconditional) {
			return btbEntry !is null ? btbEntry.target : 1;
		}
		
		if(btbEntry is null) {
			return *(dirUpdate.pdir1) >= 2 ? 1 : 0;
		}
		else {
			return *(dirUpdate.pdir1) >= 2 ? btbEntry.target :0;
		}
	}

	void recover(uint baddr, uint stackRecoverIdx) {
		this.retStack.tos = stackRecoverIdx;
	}

	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, DynamicInst dynamicInst, ref BpredUpdate dirUpdate) {
		StaticInst staticInst = dynamicInst.staticInst;
		
		BpredBtbEntry btbEntry = null;
		
		if(!staticInst.isControl) {
			return;
		}
		
		if(staticInst.isControl && !staticInst.isUnconditional) {
			uint l1Index = (baddr >> MD_BR_SHIFT) & (this.twoLevel.l1Size - 1);
			uint shiftReg = (this.twoLevel.shiftRegs[l1Index] << 1) | taken;
			this.twoLevel.shiftRegs[l1Index] = shiftReg & ((1 << this.twoLevel.shiftWidth) - 1);
		}
		
		if(taken) {
			uint index = (baddr >> MD_BR_SHIFT) & (this.btb.sets - 1);
			
			if(this.btb.assoc > 1) {
				index *= this.btb.assoc;
				
				BpredBtbEntry lruHead = null, lruItem = null;
				
				for(uint i = index; i < (index + this.btb.assoc); i++) {
					if(this.btb[i].addr == baddr) {
						assert(btbEntry is null);
						btbEntry = this.btb[i];
					}
					
					assert(this.btb[i].prev != this.btb[i].next);
					
					if(this.btb[i].prev is null) {
						assert(lruHead is null);
						lruHead = this.btb[i];
					}
					
					if(this.btb[i].next is null) {
						assert(lruItem is null);
						lruItem = this.btb[i];
					}
				}
				
				assert(lruHead !is null && lruItem !is null);
				
				if(btbEntry is null) {
					btbEntry = lruItem;
				}
				
				if(btbEntry != lruHead) {
					if(btbEntry.prev !is null) {
						btbEntry.prev.next = btbEntry.next;
					}
					
					if(btbEntry.next !is null) {
						btbEntry.next.prev = btbEntry.prev;
					}
					
					btbEntry.next = lruHead;
					btbEntry.prev = null;
					lruHead.prev = btbEntry;
					assert(btbEntry.prev !is null || btbEntry.next !is null);
					assert(btbEntry.prev != btbEntry.next);
				}
			}
			else {
				btbEntry = this.btb[index];
			}
		}
		
		if(dirUpdate.pdir1 !is null) {
			if(taken) {
				if(*dirUpdate.pdir1 < 3) {
					++*dirUpdate.pdir1;
				}
			}
			else {
				if(*dirUpdate.pdir1 > 0) {
					++*dirUpdate.pdir1;
				}
			}
		}
		
		if(dirUpdate.pdir2 !is null) {
			if(taken) {
				if(*dirUpdate.pdir2 < 3) {
					++*dirUpdate.pdir2;
				}
			}
			else {
				if(*dirUpdate.pdir2 > 0) {
					--*dirUpdate.pdir2;
				}
			}
		}
		
		if(dirUpdate.pmeta !is null) {
			if(dirUpdate.bimod != dirUpdate.twoLevel) {
				if(dirUpdate.twoLevel == taken) {
					if(*dirUpdate.pmeta < 3) {
						++*dirUpdate.pmeta;
					}
				}
				else {
					if(*dirUpdate.pmeta > 0) {
						--*dirUpdate.pmeta;
					}
				}
			}
		}
		
		if(btbEntry !is null) {
			assert(taken);
			
			if(btbEntry.addr == baddr) {
				if(!correct) {
					btbEntry.target = btarget;
				}
			}
			else {
				btbEntry.addr = baddr;
				btbEntry.staticInst = staticInst;
				btbEntry.target = btarget;
			}
		}
	}

	TwoLevelBpredDir twoLevel;
	BimodBpredDir bimod;
	BimodBpredDir meta;

	BTB btb;
	RAS retStack;
}

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
	
	void acquire(ReorderBufferEntry reorderBufferEntry, void delegate() onCompletedCallback) {
		this.pool.listenerSupportAcquire.dispatch(this.pool, new FunctionalUnitPool.ListenerContext(reorderBufferEntry, this));
		this.pool.eventQueue.schedule(
			{
				this.busy = false;
				
				if(onCompletedCallback !is null) {
					onCompletedCallback();
				}
				
				this.pool.listenerSupportRelease.dispatch(this.pool, new FunctionalUnitPool.ListenerContext(reorderBufferEntry, this));
				
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
	static class ListenerContext {
		this(ReorderBufferEntry reorderBufferEntry, FunctionalUnit fu) {
			this.reorderBufferEntry = reorderBufferEntry;
			this.fu = fu;
		}
		
		ReorderBufferEntry reorderBufferEntry;
		FunctionalUnit fu;
	}
	
	alias ListenerSupport!(FunctionalUnitPool, ListenerContext) ListenerSupportT;
	alias ListenerSupportT.ListenerT ListenerT;
	
	this(Core core) {
		this.core = core;
		
		this.name = format("c%d.fuPool", this.core.num);
				
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
		
		this.listenerSupportAcquire = new ListenerSupportT();
		this.listenerSupportRelease = new ListenerSupportT();
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
			fu.acquire(reorderBufferEntry, 
				{
					onCompletedCallback2(reorderBufferEntry);
				});
		}
		else {
			this.eventQueue.schedule(
				{
					this.acquire(reorderBufferEntry, onCompletedCallback2);
				}, 10);
		}
	}
	
	void addAcquireListener(ListenerT listener) {
		this.listenerSupportAcquire.addListener(listener);
	}
	
	void addReleaseListener(ListenerT listener) {
		this.listenerSupportRelease.addListener(listener);
	}
	
	Core core;
	string name;

	FunctionalUnit[][FunctionalUnitType] entities;
	DelegateEventQueue eventQueue;
	
	ListenerSupportT listenerSupportAcquire;
	ListenerSupportT listenerSupportRelease;
}

enum PhysicalRegisterState: string {
	FREE = "FREE",
	ALLOC = "ALLOC",
	WB = "WB",
	ARCH = "ARCH"
}

class PhysicalRegister {
	this(PhysicalRegisterFile file) {
		this.file = file;
		this.state = PhysicalRegisterState.FREE;
	}
	
	void alloc(ReorderBufferEntry reorderBufferEntry) {
		this.file.listenerSupportWriteback.dispatch(this.file, new PhysicalRegisterFile.ListenerContext(reorderBufferEntry, this));
		this.state = PhysicalRegisterState.ALLOC;
		this.reorderBufferEntry = reorderBufferEntry;
	}
	
	void writeback() {
		this.file.listenerSupportWriteback.dispatch(this.file, new PhysicalRegisterFile.ListenerContext(this.reorderBufferEntry, this));
		this.state = PhysicalRegisterState.WB;
	}
	
	void commit() {
		this.file.listenerSupportCommit.dispatch(this.file, new PhysicalRegisterFile.ListenerContext(this.reorderBufferEntry, this));
		this.state = PhysicalRegisterState.ARCH;
	}
	
	void dealloc() {
		this.file.listenerSupportDealloc.dispatch(this.file, new PhysicalRegisterFile.ListenerContext(this.reorderBufferEntry, this));
		this.state = PhysicalRegisterState.FREE;
		this.reorderBufferEntry = null;
	}
	
	bool isReady() {
		return this.state == PhysicalRegisterState.WB || this.state == PhysicalRegisterState.ARCH;
	}
	
	override string toString() {
		return format("PhysicalRegister[state=%s, reorderBufferEntry=%s]", this.state, this.reorderBufferEntry);
	}
	
	PhysicalRegisterFile file;
	PhysicalRegisterState state;
	ReorderBufferEntry reorderBufferEntry;
}

class NoFreePhysicalRegisterException: Exception {
	this() {
		super("NoFreePhysicalRegisterException");
	}
}

class PhysicalRegisterFile {
	static class ListenerContext {
		this(ReorderBufferEntry reorderBufferEntry, PhysicalRegister physicalRegister) {
			this.reorderBufferEntry = reorderBufferEntry;
			this.physicalRegister = physicalRegister;
		}
		
		ReorderBufferEntry reorderBufferEntry;
		PhysicalRegister physicalRegister;
	}
	
	alias ListenerSupport!(PhysicalRegisterFile, ListenerContext) ListenerSupportT;
	alias ListenerSupportT.ListenerT ListenerT;
	
	this(Core core, string namePostfix, uint capacity) {
		this.core = core;
		this.name = format("c%d.%s", core.num, namePostfix);
		this.capacity = capacity;
		
		this.entries = new PhysicalRegister[this.capacity];
		for(uint i = 0; i < this.capacity; i++) {
			this.entries[i] = new PhysicalRegister(this);
		}
		
		this.listenerSupportAlloc = new ListenerSupportT();
		this.listenerSupportWriteback = new ListenerSupportT();
		this.listenerSupportCommit = new ListenerSupportT();
		this.listenerSupportDealloc = new ListenerSupportT();
	}
	
	PhysicalRegister findFree() {
		auto res = filter!((PhysicalRegister physReg){return physReg.state == PhysicalRegisterState.FREE;})(this.entries);
		return !res.empty ? res.front : null;
	}
	
	PhysicalRegister alloc(ReorderBufferEntry reorderBufferEntry) {
		PhysicalRegister freeReg = this.findFree();
		
		if(freeReg is null) {
			throw new NoFreePhysicalRegisterException();
		}
		
		freeReg.alloc(reorderBufferEntry);
		return freeReg;
	}
	
	void addAllocListener(ListenerT listener) {
		this.listenerSupportAlloc.addListener(listener);
	}
	
	void addWritebackListener(ListenerT listener) {
		this.listenerSupportWriteback.addListener(listener);
	}
	
	void addCommitListener(ListenerT listener) {
		this.listenerSupportCommit.addListener(listener);
	}
	
	void addDeallocListener(ListenerT listener) {
		this.listenerSupportDealloc.addListener(listener);
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
	string name;
	uint capacity;
	PhysicalRegister[] entries;
	
	ListenerSupportT listenerSupportAlloc, listenerSupportWriteback, listenerSupportCommit, listenerSupportDealloc;
}

class RegisterRenameTable {
	static class ListenerContext {
		this(RegisterDependencyType type, uint num, PhysicalRegister physReg) {
			this.type = type;
			this.num = num;
			this.physReg = physReg;
		}
		
		RegisterDependencyType type;
		uint num;
		PhysicalRegister physReg;
	}
	
	alias ListenerSupport!(RegisterRenameTable, ListenerContext) ListenerSupportT;
	alias ListenerSupportT.ListenerT ListenerT;
	
	this(Thread thread) {
		this.thread = thread;
		this.name = format("c%dt%d.renameTable", this.thread.core.num, this.thread.num);
		
		this.listenerSupportValueChanged = new ListenerSupportT();
	}
	
	PhysicalRegister opIndex(RegisterDependency dep) {
		return this[dep.type, dep.num];
	}
	
	void opIndexAssign(PhysicalRegister physReg, RegisterDependency dep) {
		this[dep.type, dep.num] = physReg;
	}
	
	PhysicalRegister opIndex(RegisterDependencyType type, uint num) {
		return this.entries[type][num];
	}
	
	void opIndexAssign(PhysicalRegister physReg, RegisterDependencyType type, uint num) {
		this.listenerSupportValueChanged.dispatch(this, new ListenerContext(type, num, physReg));
		this.entries[type][num] = physReg;
	}
	
	void addValueChangedListener(ListenerT listener) {
		this.listenerSupportValueChanged.addListener(listener);
	}
	
	Thread thread;
	string name;
	PhysicalRegister[uint][RegisterDependencyType] entries;
	
	ListenerSupportT listenerSupportValueChanged;
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
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class DecodeBuffer: Queue!(DecodeBufferEntry, DecodeBuffer) {
	this(Thread thread, uint capacity) {
		super(format("c%dt%d.decodeBuffer", thread.core.num, thread.num), capacity);
	}
}

class ReorderBufferEntry {
	this(DynamicInst dynamicInst, RegisterDependency[] iDeps, RegisterDependency[] oDeps) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
		this.iDeps = iDeps;
		this.oDeps = oDeps;
		
		this.isValid = true;
	}
	
	void signalExecutionCompleted() {
		this.dynamicInst.thread.core.oooEventQueue ~= this;
	}
	
	bool allOperandsReady() {
		return filter!((RegisterDependency iDep){return !this.srcPhysRegs[iDep].isReady;})(this.iDeps).empty;
	}
	
	bool storeAddressReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.dynamicInst.staticInst));		
		assert(memOp !is null);	
		
		return this.srcPhysRegs[memOp.memIDeps[0]].isReady;
	}
	
	bool storeOperandsReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.dynamicInst.staticInst));		
		assert(memOp !is null);	
		
		return filter!((RegisterDependency iDep){return !this.srcPhysRegs[iDep].isReady;})(memOp.memIDeps[1..$]).empty;
	}
	
	bool isInLoadStoreQueue() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry is null;
	}
	
	bool isEAComputation() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry !is null;
	}
	
	void invalidate() {
		this.isValid = false;
	}
	
	override string toString() {
		string operandsReadyToString() {
			string str = "\n";
		
			foreach(i, iDep; this.iDeps) {
				str ~= format("[%s] idep=%s, isReady=%s\n", i, iDep, this.srcPhysRegs[iDep].isReady);
			}
			
			return str;
		}
		
		return format("ReorderBufferEntry(id=%d, dynamicInst=%s, isEAComputation=%s, isDispatched=%s, isInReadyQueue=%s, isIssued=%s, isCompleted=%s, isValid=%s) %s",
			this.id, this.dynamicInst, this.isEAComputation, this.isDispatched, this.isInReadyQueue, this.isIssued, this.isCompleted, this.isValid,
				operandsReadyToString);
	}
	
	uint npc, nnpc, predNpc, predNnpc;
	DynamicInst dynamicInst;
	
	RegisterDependency[] iDeps, oDeps;
	PhysicalRegister[RegisterDependency] oldPhysRegs, physRegs, srcPhysRegs;
	
	bool isDispatched, isInReadyQueue, isIssued, isCompleted, isValid;
	
	ReorderBufferEntry loadStoreQueueEntry;
	uint ea;
	
	bool isSpeculative;
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	ulong id;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class ReadyQueue: List!(ReorderBufferEntry, ReadyQueue) {
	this(Core core) {
		super(format("c%d.readyQueue", core.num));
	}
}

class WaitingQueue: List!(ReorderBufferEntry, WaitingQueue) {
	this(Core core) {
		super(format("c%d.waitingQueue", core.num));
	}
}

class OoOEventQueue: List!(ReorderBufferEntry, OoOEventQueue) {
	this(Core core) {
		super(format("c%d.oooEventQueue", core.num));
	}
}

class ReorderBuffer: Queue!(ReorderBufferEntry, ReorderBuffer) {
	this(Thread thread, uint capacity) {
		super(format("c%dt%d.reorderBuffer", thread.core.num, thread.num), capacity);
	}
}

class LoadStoreQueue: Queue!(ReorderBufferEntry, LoadStoreQueue) {
	this(Thread thread, uint capacity) {
		super(format("c%dt%d.loadStoreQueue", thread.core.num, thread.num), capacity);
	}
}

/* 
 * functional execution logic
 *
 * this.pc = this.npc;
 * this.npc = this.nnpc;
 * this.nnpc += uint.sizeof;
 * 	
 * StaticInst staticInst = this.isa.decode(this.pc, this.mem);
 * DynamicInst uop = new DynamicInst(this, this.pc, staticInst);
 * uop.execute();
 */

/*
 * core:
 * 	functionalUnitPool
 * 	dispatchBuffer
 * 	intRegs, floatRegs, miscRegs
 * 	(eventQueue, readyQueue, waitingQueue)
 * 
 * thread:
 * 	decodeBuffer
 * 	reorderBuffer
 * 	(loadStoreQueue)
 * 
 * instruction lifecycle: decodeBuffer -> dispatchBuffer -> reorderBuffer
 */

class Processor {
	public:
		this(CPUSimulator simulator) {
			this(simulator, "");
		}

		this(CPUSimulator simulator, string name) {
			this.simulator = simulator;
			this.name = name;
			
			this.activeThreadCount = 0;
		}
		
		bool canRun() {
			return this.activeThreadCount > 0;
		}

		void run() {
			foreach(core; this.cores) {
				core.run();
			}
		}

		CPUSimulator simulator;
		string name;
		Core[] cores;
		
		int activeThreadCount;
}

class Core {
	this(Processor processor, ProcessorConfig config, uint num) {
		this.processor = processor;
		this.num = num;
	
		this.decodeWidth = config.decodeWidth;
		this.issueWidth = config.issueWidth;
		
		this.intRegFile = new PhysicalRegisterFile(this, "intRegFile", config.physicalRegisterFileCapacity);
		this.fpRegFile = new PhysicalRegisterFile(this, "fpRegFile", config.physicalRegisterFileCapacity);
		this.miscRegFile = new PhysicalRegisterFile(this, "miscRegFile", config.physicalRegisterFileCapacity);
		
		this.fuPool = new FunctionalUnitPool(this);
		
		this.isa = new MipsISA();
		
		this.readyQueue = new ReadyQueue(this);
		this.waitingQueue = new WaitingQueue(this);
		this.oooEventQueue = new OoOEventQueue(this);
		
		this.mem = new Memory();
	}
	
	void fetch() {
		foreach(thread; this.threads) {
			thread.fetch();
		}
	}
	
	uint findNextThreadIdToDecode(ref bool allStalled, ref bool[uint] decodeStalled) {
		foreach(i, thread; this.threads) {
			if(!decodeStalled[i] && !thread.decodeBuffer.empty && !thread.reorderBuffer.full && !thread.loadStoreQueue.full) {
				allStalled = false;
				return i;
			}
		}
		
		allStalled = true;
		return -1;
	}
	
	void registerRename() {
		bool[uint] decodeStalled;
		
		static uint decodeThreadId = 0;
		
		foreach(i, thread; this.threads) {
			decodeStalled[i] = false;
		}
		
		decodeThreadId = (decodeThreadId + 1) % this.threads.length;
		
		uint numRenamed = 0;
		
		/* instruction decode B/W left? */
		while(numRenamed < this.decodeWidth) {
			bool allStalled = true;
			
			decodeThreadId = this.findNextThreadIdToDecode(allStalled, decodeStalled);
			
			if(allStalled) {
				break;
			}
			
			DecodeBufferEntry decodeBufferEntry = this.threads[decodeThreadId].decodeBuffer.front;
	
			/* maintain $r0 semantics */
			this.threads[decodeThreadId].regs.intRegs.set(ZeroReg, 0);
			
			DynamicInst dynamicInst = decodeBufferEntry.dynamicInst;
	
			/* is this a NOP */
			if(!dynamicInst.staticInst.isNop) {
				ReorderBufferEntry reorderBufferEntry = new ReorderBufferEntry(dynamicInst, dynamicInst.staticInst.iDeps, dynamicInst.staticInst.oDeps);
				reorderBufferEntry.npc = decodeBufferEntry.npc;
				reorderBufferEntry.nnpc = decodeBufferEntry.nnpc;
				reorderBufferEntry.predNpc = decodeBufferEntry.predNpc;
				reorderBufferEntry.predNnpc = decodeBufferEntry.predNnpc;
				reorderBufferEntry.stackRecoverIndex = decodeBufferEntry.stackRecoverIndex;
				reorderBufferEntry.dirUpdate = decodeBufferEntry.dirUpdate;
				reorderBufferEntry.isSpeculative = decodeBufferEntry.isSpeculative;
				
				foreach(iDep; reorderBufferEntry.iDeps) {
					reorderBufferEntry.srcPhysRegs[iDep] = this.threads[decodeThreadId].renameTable[iDep];
				}
				
				try {
					foreach(oDep; reorderBufferEntry.oDeps) {
						reorderBufferEntry.oldPhysRegs[oDep] = this.threads[decodeThreadId].renameTable[oDep];
						this.threads[decodeThreadId].renameTable[oDep] = reorderBufferEntry.physRegs[oDep] = this.getPhysicalRegisterFile(oDep.type).alloc(reorderBufferEntry);
					}
				}
				catch(NoFreePhysicalRegisterException ex) {
					decodeStalled[decodeThreadId] = true;
					continue;
				}
	
				/* split ld/st's into two operations: eff addr comp + mem access */
				if(dynamicInst.staticInst.isMem) {					
					ReorderBufferEntry loadStoreQueueEntry = new ReorderBufferEntry(dynamicInst, 
						(cast(MemoryOp) dynamicInst.staticInst).memIDeps, (cast(MemoryOp) dynamicInst.staticInst).memODeps);
					
					loadStoreQueueEntry.npc = decodeBufferEntry.npc;
					loadStoreQueueEntry.nnpc = decodeBufferEntry.nnpc;
					loadStoreQueueEntry.predNpc = decodeBufferEntry.predNpc;
					loadStoreQueueEntry.predNnpc = decodeBufferEntry.predNnpc;
					loadStoreQueueEntry.stackRecoverIndex = 0;
					loadStoreQueueEntry.dirUpdate = null;
					loadStoreQueueEntry.isSpeculative = false;
					
					loadStoreQueueEntry.ea = (cast(MemoryOp) dynamicInst.staticInst).ea(this.threads[decodeThreadId]);
					
					reorderBufferEntry.loadStoreQueueEntry = loadStoreQueueEntry; 
					
					foreach(iDep; loadStoreQueueEntry.iDeps) {
						loadStoreQueueEntry.srcPhysRegs[iDep] = this.threads[decodeThreadId].renameTable[iDep];
					}
					
					try {
						foreach(oDep; loadStoreQueueEntry.oDeps) {
							loadStoreQueueEntry.oldPhysRegs[oDep] = this.threads[decodeThreadId].renameTable[oDep];
							this.threads[decodeThreadId].renameTable[oDep] = loadStoreQueueEntry.physRegs[oDep] = this.getPhysicalRegisterFile(oDep.type).alloc(loadStoreQueueEntry);
						}
					}
					catch(NoFreePhysicalRegisterException ex) {
						decodeStalled[decodeThreadId] = true;
						continue;
					}
					
					this.threads[decodeThreadId].loadStoreQueue ~= loadStoreQueueEntry;
				}
				
				this.threads[decodeThreadId].reorderBuffer ~= reorderBufferEntry;
			}
			
			this.threads[decodeThreadId].decodeBuffer.takeFront();
			
			numRenamed++;
		}
	}
	
	void dispatch() {
		static uint dispatchThreadId = 0; 
		
		uint numDispatched = 0;
		bool[uint] dispatchStalled;
		uint[uint] numDispatchedPerThread;
		
		foreach(i, thread; this.threads) {
			dispatchStalled[i] = false;
			numDispatchedPerThread[i] = 0;
		}
		
		dispatchThreadId = (dispatchThreadId + 1) % this.threads.length;

		/* instruction decode B/W left? */
		while(numDispatched < this.decodeWidth) {
			bool allStalled = true;
			
			foreach(i, thread; this.threads) {
				if(!dispatchStalled[i]) {
					allStalled = false;
				}
			}
			
			if(allStalled) {
				break;
			}
			
			ReorderBufferEntry reorderBufferEntry = this.threads[dispatchThreadId].getNextReorderBufferEntryToDispatch(
				dispatchStalled[dispatchThreadId]);
			
			if(dispatchStalled[dispatchThreadId]) {
				dispatchThreadId = (dispatchThreadId + 1) % this.threads.length;
				continue;
			}
			
			numDispatchedPerThread[dispatchThreadId]++;
	
			/* insert into the ready or waiting queue */
			if(reorderBufferEntry.allOperandsReady) {
				this.readyQueue ~= reorderBufferEntry;
				reorderBufferEntry.isInReadyQueue = true;
			}
			else {
				this.waitingQueue ~= reorderBufferEntry;
			}
			
			/* update the rob entry */
			reorderBufferEntry.isDispatched = true;
			
			if(reorderBufferEntry.loadStoreQueueEntry !is null) {
				ReorderBufferEntry loadStoreQueueEntry = reorderBufferEntry.loadStoreQueueEntry;
				
				/* issue stores only, loads are issued by lsq_refresh() */
				if(loadStoreQueueEntry.dynamicInst.staticInst.isStore) { 
					if(loadStoreQueueEntry.allOperandsReady) {
						this.readyQueue ~= loadStoreQueueEntry;
						loadStoreQueueEntry.isInReadyQueue = true;
					}
					else {
						this.waitingQueue ~= loadStoreQueueEntry;
					}
				}
				loadStoreQueueEntry.isDispatched = true;
			}
			
			numDispatched++;
		}
	}
	
	void wakeup() {
		ReorderBufferEntry[] toWaitingQueue;
		
		while(!this.waitingQueue.empty) {
			ReorderBufferEntry waitingQueueEntry = this.waitingQueue.front;
			
			if(!waitingQueueEntry.isValid) {
				this.waitingQueue.takeFront();
				continue;
			}
			
			if(waitingQueueEntry.allOperandsReady) {
				this.readyQueue ~= waitingQueueEntry;
				waitingQueueEntry.isInReadyQueue = true;
			}
			else {
				toWaitingQueue ~= waitingQueueEntry;
			}
			
			this.waitingQueue.takeFront();
		}
		
		foreach(waitingQueueEntry; toWaitingQueue) {
			this.waitingQueue ~= waitingQueueEntry;
		}
	}
	
	void selection() {
		uint numIssued = 0;
		
		while(numIssued < this.issueWidth && !this.readyQueue.empty) {
			ReorderBufferEntry readyQueueEntry = this.readyQueue.front;
			
			if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isStore) {
				readyQueueEntry.isIssued = true;
				readyQueueEntry.isCompleted = true;
			}
			else if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isLoad) {
				this.fuPool.acquire(readyQueueEntry,
					(ReorderBufferEntry readyQueueEntry)
					{
						bool hitInLoadStoreQueue = false;
						
						foreach_reverse(loadStoreQueueEntry; readyQueueEntry.dynamicInst.thread.loadStoreQueue) {
							if(loadStoreQueueEntry.dynamicInst.staticInst.isStore && loadStoreQueueEntry.ea == readyQueueEntry.ea) {
								hitInLoadStoreQueue = true;
							}
						}
						
						if(hitInLoadStoreQueue) {
							readyQueueEntry.signalExecutionCompleted();
						}
						else {
							this.seqD.load(this.mmu.translate(readyQueueEntry.ea), false, readyQueueEntry,
								(ReorderBufferEntry readyQueueEntry)
								{
									readyQueueEntry.signalExecutionCompleted();
								});
						}
					});
				
				readyQueueEntry.isIssued = true;
			}
			else {
				if(readyQueueEntry.dynamicInst.staticInst.fuType != FunctionalUnitType.NONE) {
					this.fuPool.acquire(readyQueueEntry,
						(ReorderBufferEntry readyQueueEntry)
						{
							readyQueueEntry.signalExecutionCompleted();
						});
					readyQueueEntry.isIssued = true;
				}
				else {
					readyQueueEntry.isIssued = true;
					readyQueueEntry.isCompleted = true;
				}
			}
			
			this.readyQueue.takeFront();
			readyQueueEntry.isInReadyQueue = false;
			
			numIssued++;
		}
	}
	
	void writeback() {
		while(!this.oooEventQueue.empty) {
			ReorderBufferEntry reorderBufferEntry = this.oooEventQueue.front;
			
			if(!reorderBufferEntry.isValid) {
				this.oooEventQueue.takeFront();
				continue;
			}
			
			reorderBufferEntry.isCompleted = true;

			foreach(oDep; reorderBufferEntry.oDeps) {
				reorderBufferEntry.physRegs[oDep].writeback();
			}
	
			/* if this is the first instruction in spec mode, empty reorder buffer */
			if(reorderBufferEntry.isSpeculative) {				
				reorderBufferEntry.dynamicInst.thread.bpred.recover(reorderBufferEntry.dynamicInst.physPc, reorderBufferEntry.stackRecoverIndex);

				/* regenerate fetch stage status */
				reorderBufferEntry.dynamicInst.thread.regs.isSpeculative = reorderBufferEntry.dynamicInst.thread.isSpeculative = false;
				reorderBufferEntry.dynamicInst.thread.fetchNpc = reorderBufferEntry.dynamicInst.thread.regs.npc;
				reorderBufferEntry.dynamicInst.thread.fetchNnpc = reorderBufferEntry.dynamicInst.thread.regs.nnpc;
				
				/* squash pipeline and stop commit */
				reorderBufferEntry.dynamicInst.thread.recoverReorderBuffer(reorderBufferEntry);
				break;
			}
			
			this.oooEventQueue.takeFront();
		}
	}
	
	void refreshLoadStoreQueue() {
		foreach(thread; this.threads) {
			thread.refreshLoadStoreQueue();
		}
	}
	
	void commit() {
		foreach(thread; this.threads) {
			thread.commit();
		}
	}
	
	void run() {
		this.commit();
		this.writeback();
		this.refreshLoadStoreQueue();
		this.wakeup();
		this.selection();
		this.dispatch();
		this.registerRename();
		this.fetch();
	}
	
	PhysicalRegisterFile getPhysicalRegisterFile(RegisterDependencyType type) {
		if(type == RegisterDependencyType.INT) {
			return this.intRegFile;
		}
		else if(type == RegisterDependencyType.FP) {
			return this.fpRegFile;
		}
		else {
			return this.miscRegFile;
		}
	}
	
	uint numThreadsPerCore() {
		return this.threads.length;
	}

	Sequencer seqI() {
		return this.processor.simulator.memorySystem.seqIs[this.num];
	}
	
	CoherentCacheNode l1I() {
		return this.processor.simulator.memorySystem.l1Is[this.num];
	}

	Sequencer seqD() {
		return this.processor.simulator.memorySystem.seqDs[this.num];
	}
	
	CoherentCacheNode l1D() {
		return this.processor.simulator.memorySystem.l1Ds[this.num];
	}
	
	MMU mmu() {
		return this.processor.simulator.memorySystem.mmu;
	}

	uint num;
	Processor processor;
	Thread[] threads;
	
	Memory mem;
	
	uint decodeWidth;
	uint issueWidth;

	FunctionalUnitPool fuPool;
	
	PhysicalRegisterFile intRegFile;
	PhysicalRegisterFile fpRegFile;
	PhysicalRegisterFile miscRegFile;
	
	ISA isa;
	
	ReadyQueue readyQueue;
	WaitingQueue waitingQueue;
	OoOEventQueue oooEventQueue;
}

enum ThreadState: string {
	Inactive = "Inactive",
	Active = "Active",
	Halted = "Halted"
}

class AlwaysTakenBpred: Bpred {
	uint lookup(uint baddr, uint btarget, DynamicInst dynamicInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx) {
		return dynamicInst.staticInst.targetPc(dynamicInst.thread);
	}

	void recover(uint baddr, uint stackRecoverIdx) {
	}
	
	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, DynamicInst dynamicInst, ref BpredUpdate dirUpdate) {
	}
}

class Thread {
	this(Core core, ProcessorConfig config, ContextStat stat, uint num, Process process) {
		this.core = core;
		
		this.num = num;
		
		this.process = process;
		
		this.syscallEmul = new SyscallEmul();

		//this.bpred = new CombinedBpred();
		this.bpred = new AlwaysTakenBpred();
		
		this.renameTable = new RegisterRenameTable(this);

		this.clearArchRegs();

		this.process.load(this);
		
		this.stat = stat;
		
		this.state = ThreadState.Active;
		
		for(uint i = 0; i < NumIntRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumIntRegs + i];
			physReg.commit();
			this.renameTable[RegisterDependencyType.INT, i] = physReg;
		}
		
		for(uint i = 0; i < NumFloatRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumFloatRegs + i];
			physReg.commit();
			this.renameTable[RegisterDependencyType.FP, i] = physReg;
		}
		
		for(uint i = 0; i < NumMiscRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumMiscRegs + i];
			physReg.commit();
			this.renameTable[RegisterDependencyType.MISC, i] = physReg;
		}
		
		this.commitWidth = config.commitWidth;
		
		this.decodeBuffer = new DecodeBuffer(this, config.decodeBufferCapacity);
		this.reorderBuffer = new ReorderBuffer(this, config.reorderBufferCapacity);
		this.loadStoreQueue = new LoadStoreQueue(this, config.loadStoreQueueCapacity);
		
		this.fetchNpc = this.regs.npc;
		this.fetchNnpc = this.regs.nnpc;
	}
	
	DynamicInst decodeAndExecute() {
		this.regs.pc = this.regs.npc;
		this.regs.npc = this.regs.nnpc;
		this.regs.nnpc += uint.sizeof;

		/* fetch instruction from memory */
		StaticInst staticInst = this.core.isa.decode(this.regs.pc, this.mem);
		DynamicInst dynamicInst = new DynamicInst(this, this.regs.pc, staticInst);

		/* functional simulation */
		dynamicInst.execute();
		
		return dynamicInst;
	}
	
	void fetch() {
		uint blockToFetch = aligned(this.fetchNpc, this.core.seqI.blockSize);
		if(blockToFetch != this.lastFetchedBlock) {
			this.lastFetchedBlock = blockToFetch;
			
			this.core.seqI.load(this.core.mmu.translate(this.fetchNpc), false, 
				{
					this.fetchStalled = false;
				});
			
			this.fetchStalled = true;
		}
		
		bool done = false;
	
		/* fetch instructions */
		while(!done && !this.decodeBuffer.full && !this.fetchStalled) {
			bool setNpc() {
				if(this.regs.npc == this.fetchNpc) {
					return false;
				}
				
				if(this.isSpeculative) {
					this.regs.npc = this.fetchNpc;
					return false;
				}
				
				return true;
			}
			
			if(setNpc()) {
				this.regs.isSpeculative = this.isSpeculative = true;
			}
			
			this.fetchPc = this.fetchNpc;
			this.fetchNpc = this.fetchNnpc;
			
			DynamicInst dynamicInst = this.decodeAndExecute();
			
			if(this.fetchNpc != this.fetchPc + uint.sizeof) {
				done = true;
			}
	
			if((this.fetchPc + uint.sizeof) % this.core.seqI.blockSize == 0) {
				done = true;
			}
			
			uint stackRecoverIndex;
			BpredUpdate dirUpdate = new BpredUpdate();
	
			/* calculate fetch nnpc */
			uint dest = this.bpred.lookup(
				this.core.mmu.translate(this.fetchPc),
				0,
				dynamicInst,
				dirUpdate,
				stackRecoverIndex);
			this.fetchNnpc = dest <= 1 ? this.fetchNpc + uint.sizeof : dest;
	
			this.fetchNnpc = this.regs.nnpc; //TODO: remove it
	
			/* insert instruction in decode buffer */
			DecodeBufferEntry decodeBufferEntry = new DecodeBufferEntry(dynamicInst);
			decodeBufferEntry.npc = this.regs.npc;
			decodeBufferEntry.nnpc = this.regs.nnpc;
			decodeBufferEntry.predNpc = this.fetchNpc;
			decodeBufferEntry.predNnpc = this.fetchNnpc;
			decodeBufferEntry.stackRecoverIndex = stackRecoverIndex;
			decodeBufferEntry.dirUpdate = dirUpdate;
			decodeBufferEntry.isSpeculative = this.isSpeculative;
			
			this.decodeBuffer ~= decodeBufferEntry;
		}
	}
	
	ReorderBufferEntry getNextReorderBufferEntryToDispatch(ref bool dispatchStalled) {
		foreach(reorderBufferEntry; this.reorderBuffer) {
			if(!reorderBufferEntry.isDispatched) {
				dispatchStalled = false;
				return reorderBufferEntry;
			}
		}
		
		dispatchStalled = true;
		return null;
	}
	
	void refreshLoadStoreQueue() {
		uint[] stdUnknowns;
	
		/* search in lsq for ready load's until an unresolved store is found */
		foreach(loadStoreQueueEntry; this.loadStoreQueue) {
			/* if it is a store */
			if(loadStoreQueueEntry.dynamicInst.staticInst.isStore) {
				if(loadStoreQueueEntry.storeAddressReady) {
					break;
				}
				else if(!loadStoreQueueEntry.allOperandsReady) {
					stdUnknowns ~= loadStoreQueueEntry.ea;
				}
				else {
					/* we know addr & data; a resolved store shadows a previous unresolved one */
					foreach(ref addr; stdUnknowns) {
						if(addr == loadStoreQueueEntry.ea) {
							addr = 0;
						}
					}
				}
			}
	
			/* if it is a load */
			if(loadStoreQueueEntry.dynamicInst.staticInst.isLoad &&
				loadStoreQueueEntry.isDispatched &&
				!loadStoreQueueEntry.isInReadyQueue &&
				!loadStoreQueueEntry.isIssued &&
				!loadStoreQueueEntry.isCompleted &&
				loadStoreQueueEntry.allOperandsReady) {
				/* no addr conflict here; check data conflict, if no conflict, send to readyq */
				if(count(stdUnknowns, loadStoreQueueEntry.ea) == 0) {
					this.core.readyQueue ~= loadStoreQueueEntry;
					loadStoreQueueEntry.isInReadyQueue = true;
				}
			}
		}
	}
	
	void commit() {
		if(currentCycle - this.lastCommitCycle > COMMIT_TIMEOUT) {
			logging.infof(LogCategory.SIMULATOR, "this.reorderBuffer.size=%d", this.reorderBuffer.size);
			
			foreach(reorderBufferEntry; this.reorderBuffer) {
				logging.infof(LogCategory.SIMULATOR, "%s", reorderBufferEntry);
			}
			
			logging.fatalf(LogCategory.SIMULATOR, "No instruction committed for %d cycles.", COMMIT_TIMEOUT);
		}
		
		uint numCommitted = 0;
		
		while(!this.reorderBuffer.empty && numCommitted < this.commitWidth) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.front;
	
			/* head of line blocking if inst not completed */
			if(!reorderBufferEntry.isCompleted) {
				break;
			}
	
			/* for memory inst, extract element from lsq */
			if(reorderBufferEntry.isEAComputation) {
				ReorderBufferEntry loadStoreQueueEntry = this.loadStoreQueue.front;
	
				/* if not completed, cannot commit */
				if(!loadStoreQueueEntry.isCompleted) {
					break;
				}
	
				/* stores access memory here */
				if(loadStoreQueueEntry.dynamicInst.staticInst.isStore) {
					this.core.fuPool.acquire(loadStoreQueueEntry,
										(ReorderBufferEntry loadStoreQueueEntry)
					{
						this.core.seqD.store(this.core.mmu.translate(loadStoreQueueEntry.ea), false, {});
					});
				}
	
				/* commit lsq entry */
				foreach(oDep; loadStoreQueueEntry.oDeps) {
					loadStoreQueueEntry.oldPhysRegs[oDep].dealloc();
					loadStoreQueueEntry.physRegs[oDep].commit();
				}
				
				this.loadStoreQueue.takeFront();
			}
	
			/* retire rob entry */
			foreach(oDep; reorderBufferEntry.oDeps) {
				reorderBufferEntry.oldPhysRegs[oDep].dealloc();
				reorderBufferEntry.physRegs[oDep].commit();
			}
	
			/* update branch predictor */
			if(reorderBufferEntry.dynamicInst.staticInst.isControl) {
				this.bpred.update(
					/* branch address */ reorderBufferEntry.dynamicInst.physPc,
					/* actual target address */ reorderBufferEntry.nnpc,
				    /* taken? */ reorderBufferEntry.nnpc != (reorderBufferEntry.npc + uint.sizeof),
					/* pred taken? */ reorderBufferEntry.predNnpc != (reorderBufferEntry.npc + uint.sizeof),
					/* correct pred? */ reorderBufferEntry.predNnpc == reorderBufferEntry.nnpc,
					/* dynamic inst */ reorderBufferEntry.dynamicInst,
					/* dir predictor update */ reorderBufferEntry.dirUpdate
				);
			}
			
			this.reorderBuffer.takeFront();

			this.stat.totalInsts.value = this.stat.totalInsts.value + 1;
			
			this.lastCommitCycle = currentCycle;
			
			numCommitted++;
			
			//logging.infof(LogCategory.DEBUG, "t%d instruction committed (dynamicInst=%s)", this.num,  reorderBufferEntry.dynamicInst);
		}
	}
	
	void recoverReorderBuffer(ReorderBufferEntry branchReorderBufferEntry) {
		logging.infof(LogCategory.SIMULATOR, "recovering at %s", branchReorderBufferEntry);
		
		ReorderBufferEntry[] toSquash;
		
		while(!this.reorderBuffer.empty) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.back;
			
			if(!reorderBufferEntry.isSpeculative) {
				break;
			}
			
			if(reorderBufferEntry.isEAComputation) {
				ReorderBufferEntry loadStoreQueueEntry = this.loadStoreQueue.back;
				
				loadStoreQueueEntry.invalidate();
				
				foreach(oDep; loadStoreQueueEntry.oDeps) { //TODO: is it necessary or correct?
					loadStoreQueueEntry.physRegs[oDep].dealloc();
					this.renameTable[oDep] = loadStoreQueueEntry.oldPhysRegs[oDep];
				}
				
				loadStoreQueueEntry.physRegs.clear(); //TODO: is it necessary or correct?
				
				this.loadStoreQueue.takeBack();
			}
			
			reorderBufferEntry.invalidate();
			
			foreach(oDep; reorderBufferEntry.oDeps) {
				reorderBufferEntry.physRegs[oDep].dealloc();
				this.renameTable[oDep] = reorderBufferEntry.oldPhysRegs[oDep];
			}
			
			reorderBufferEntry.physRegs.clear();
			
			this.reorderBuffer.takeBack();
		}
		
		// FIXME: could reset functional units at squash time
		// TODO: when branch misprediction, empty speculative instructions from decode buffer
	}

	uint getSyscallArg(int i) {
		assert(i < 6);
		return this.regs.intRegs.get(FirstArgumentReg + i);
	}

	void setSyscallArg(int i, uint val) {
		assert(i < 6);
		this.regs.intRegs.set(FirstArgumentReg + i, val);
	}

	void setSyscallReturn(uint return_value) {
		this.regs.intRegs.set(ReturnValueReg, return_value);
		this.regs.intRegs.set(SyscallSuccessReg, (return_value == cast(uint) -EINVAL ? 1 : 0));
	}

	void syscall(uint callnum) {
		this.syscallEmul.syscall(callnum, this);
	}

	void clearArchRegs() {
		this.regs = new CombinedRegisterFile();
		this.regs.pc = 0;
		this.regs.npc = 0;
		this.regs.nnpc = 0;
	}
	
	void halt(int exitCode) {
		if(this.state != ThreadState.Halted) {
			logging.infof(LogCategory.SIMULATOR, "target called exit(%d)", exitCode);
			this.state = ThreadState.Halted;
			this.core.processor.activeThreadCount--;
			
			//assert(0); //TODO: should stop thread from running!!
		}
		else {
			assert(0);
		}
	}
	
	Memory mem() {
		return this.core.mem;
	}
	
	uint num;

	Core core;
	
	Process process;
	SyscallEmul syscallEmul;
	
	CombinedRegisterFile regs;
	
	uint fetchPc, fetchNpc, fetchNnpc;
	
	bool fetchStalled;
	uint lastFetchedBlock;
	
	Bpred bpred;
	
	RegisterRenameTable renameTable;
	
	uint commitWidth;
	ulong lastCommitCycle;
	
	ThreadState state;
	
	ContextStat stat;
	
	DecodeBuffer decodeBuffer;
	ReorderBuffer reorderBuffer;
	LoadStoreQueue loadStoreQueue;
	
	bool isSpeculative;
	
	static const uint COMMIT_TIMEOUT = 1000000;
}

class CPUSimulator : Simulator {	
	this(Simulation simulation) {
		this.simulation = simulation;
		this.processor = new Processor(this);
		
		SimulationConfig simulationConfig = simulation.config;
		
		for(uint i = 0; i < simulationConfig.architecture.processor.cores.length; i++) {
			Core core = new Core(this.processor, simulationConfig.architecture.processor, i);
				
			for(uint j = 0; j < simulationConfig.architecture.processor.numThreadsPerCore; j++) {
				ContextConfig context = simulationConfig.contexts[i * simulationConfig.architecture.processor.numThreadsPerCore + j];
				
				writefln("context.cwd: %s, args: %s", context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));
				Process process = new Process(context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));

				uint threadNum = i * simulationConfig.architecture.processor.numThreadsPerCore + j;
				ContextStat contextStat = simulation.stat.processor.contexts[threadNum];
				
				Thread thread = new Thread(core, simulation.config.architecture.processor, contextStat, threadNum, process);
				
				core.threads ~= thread;
				
				this.processor.activeThreadCount++;
			}
			
			this.processor.cores ~= core;
		}

		this.memorySystem = new MemorySystem(simulation);
		
		this.simulation.stat.totalCycles.value = currentCycle = 0;
	}

	override void run() {		
		Ticks beginTime = apptime();

		while(!this.eventQueue.halted && this.processor.canRun && this.simulation.isRunning) {
			this.processor.run();

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.simulation.stat.totalCycles.value = ++currentCycle;
			
			this.duration = (apptime() - beginTime).toMilliseconds!(ulong);
		}
	}
	
	ulong duration() {
		return this.simulation.stat.duration.value;
	}
	
	void duration(ulong value) {
		this.simulation.stat.duration.value = value;
	}
	
	Processor processor;
	MemorySystem memorySystem;
	
	Simulation simulation;
}
