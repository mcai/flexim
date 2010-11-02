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
	uint lookup(uint baddr, uint btarget, StaticInst staticInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx);

	void recover(uint baddr, uint stackRecoverIdx);
	
	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, StaticInst staticInst, ref BpredUpdate dirUpdate);	
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
	uint lookup(uint baddr, uint btarget, StaticInst staticInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx) {		
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

	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, StaticInst staticInst, ref BpredUpdate dirUpdate) {
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
		
		return format("ReorderBufferEntry(dynamicInst=%s, isEAComputation=%s, isDispatched=%s, isInReadyQueue=%s, isIssued=%s, isCompleted=%s) %s",
			this.dynamicInst, this.isEAComputation, this.isDispatched, this.isInReadyQueue, this.isIssued, this.isCompleted,
				operandsReadyToString);
	}
	
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
	this(Processor processor, uint num) {
		this.processor = processor;
		this.num = num;
	
		this.fetchSpeed = 1;
		this.decodeWidth = 4;
		this.issueWidth = 4;
		
		this.intRegFile = new PhysicalRegisterFile(this);
		this.fpRegFile = new PhysicalRegisterFile(this);
		this.miscRegFile = new PhysicalRegisterFile(this);
		
		this.fuPool = new FunctionalUnitPool();
		
		this.isa = new MipsISA();
		
		this.readyQueue = new ReadyQueue();
		this.waitingQueue = new WaitingQueue();
		
		this.mem = new Memory();
	}
	
	void fetch() {
		foreach(thread; this.threads) {
			thread.fetch();
		}
	}
	
	void registerRename() {
		foreach(thread; this.threads) {
			thread.registerRename();
		}
	}
	
	void dispatch() {
		foreach(thread; this.threads) {
			thread.dispatch();
		}
	}
	
	void issue() {
		foreach(thread; this.threads) {
			thread.issue();
		}
	}
	
	void commit() {
		foreach(thread; this.threads) {
			thread.commit();
		}
	}
	
	void run() {
		this.fetch();
		this.registerRename();
		this.dispatch();
		this.issue();
		this.commit();
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
	
	uint fetchWidth() {
		return this.decodeWidth * this.fetchSpeed;
	}

	uint num;
	Processor processor;
	Thread[] threads;
	
	Memory mem;
	
	uint fetchSpeed;
	uint decodeWidth;
	uint issueWidth;

	FunctionalUnitPool fuPool;
	
	PhysicalRegisterFile intRegFile;
	PhysicalRegisterFile fpRegFile;
	PhysicalRegisterFile miscRegFile;
	
	ISA isa;
	
	ReadyQueue readyQueue;
	WaitingQueue waitingQueue;
}

enum ThreadState: string {
	Inactive = "Inactive",
	Active = "Active",
	Halted = "Halted"
}

class Thread {
	this(Core core, ContextStat stat, uint num, Process process) {
		this.core = core;
		
		this.num = num;
		
		this.process = process;
		
		this.syscallEmul = new SyscallEmul();

		this.bpred = new CombinedBpred();
		
		this.renameTable = new RegisterRenameTable();

		this.clearArchRegs();

		this.process.load(this);
		
		this.commitWidth = 4;
		
		this.stat = stat;
		
		this.state = ThreadState.Active;
		
		for(uint i = 0; i < NumIntRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumIntRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTable[RegisterDependencyType.INT, i] = physReg;
		}
		
		for(uint i = 0; i < NumFloatRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumFloatRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTable[RegisterDependencyType.FP, i] = physReg;
		}
		
		for(uint i = 0; i < NumMiscRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumMiscRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTable[RegisterDependencyType.MISC, i] = physReg;
		}
		
		this.decodeBuffer = new DecodeBuffer();
		this.reorderBuffer = new ReorderBuffer();
		this.loadStoreQueue = new LoadStoreQueue();
		
		this.fetchNpc = this.npc;
		this.fetchNnpc = this.nnpc;
		
		this.isSpeculative = false;
	}
	
	void fetch() {
		uint blockToFetch = aligned(this.npc, this.core.seqI.blockSize);
		if(blockToFetch != this.lastFetchedBlock) {
			this.lastFetchedBlock = blockToFetch;
			
			this.core.seqI.load(this.core.mmu.translate(this.npc), false, 
				{
					this.fetchStalled = false;
				});
			
			this.fetchStalled = true;
		}
		
		bool done = false;
		
		while(!done && !this.decodeBuffer.full && !this.fetchStalled) {
			if(this.fetchNpc != this.fetchPc + uint.sizeof) {
				done = true;
			}
			
			if(aligned(this.npc, this.core.seqI.blockSize) == blockToFetch) {
				done = true;
			}
				
			this.fetchPc = this.fetchNpc;
			this.fetchNpc = this.fetchNnpc;			
				
			StaticInst staticInst = this.core.isa.decode(this.fetchPc, this.mem);
			DynamicInst dynamicInst = new DynamicInst(this, this.fetchPc, staticInst);
				
			this.npc = this.fetchNpc;
				
			this.pc = this.npc;
			this.npc = this.nnpc;
			this.nnpc += uint.sizeof;
				
			dynamicInst.execute();
				
			this.fetchNpc = this.npc;
			this.fetchNnpc = this.nnpc;
			
			uint stackRecoverIndex;
			BpredUpdate dirUpdate = new BpredUpdate();
			
			uint dest = this.bpred.lookup(
				this.fetchPc,
				0,
				staticInst,
				dirUpdate,
				stackRecoverIndex);
	
			this.fetchNnpc = dest <= 1 ? this.fetchNpc + uint.sizeof : dest;
				
			DecodeBufferEntry decodeBufferEntry = new DecodeBufferEntry(dynamicInst);
			decodeBufferEntry.npc = this.npc;
			decodeBufferEntry.nnpc = this.nnpc;
			decodeBufferEntry.predNpc = this.fetchNpc;
			decodeBufferEntry.predNnpc = this.fetchNnpc;
			decodeBufferEntry.stackRecoverIndex = stackRecoverIndex;
			decodeBufferEntry.dirUpdate = dirUpdate;
			decodeBufferEntry.isSpeculative = this.isSpeculative;
			
			if(!this.isSpeculative && this.npc != this.fetchNpc) { //TODO:???
				this.isSpeculative = true;
				decodeBufferEntry.isRecoverInst = true;
			}
			
			this.decodeBuffer ~= decodeBufferEntry;
		}
	}
	
	void registerRename() {
		while(!this.decodeBuffer.empty && !this.reorderBuffer.full && !this.loadStoreQueue.full) {
			DecodeBufferEntry decodeBufferEntry = this.decodeBuffer.front;
			
			this.intRegs[ZeroReg] = 0;
			
			DynamicInst dynamicInst = decodeBufferEntry.dynamicInst;
			
			if(!dynamicInst.staticInst.isNop) {
				ReorderBufferEntry dispatchBufferEntry = new ReorderBufferEntry(dynamicInst, dynamicInst.staticInst.iDeps, dynamicInst.staticInst.oDeps);
				dispatchBufferEntry.npc = decodeBufferEntry.npc;
				dispatchBufferEntry.nnpc = decodeBufferEntry.nnpc;
				dispatchBufferEntry.predNpc = decodeBufferEntry.predNpc;
				dispatchBufferEntry.predNnpc = decodeBufferEntry.predNnpc;
				dispatchBufferEntry.stackRecoverIndex = decodeBufferEntry.stackRecoverIndex;
				dispatchBufferEntry.dirUpdate = decodeBufferEntry.dirUpdate;
				dispatchBufferEntry.isSpeculative = decodeBufferEntry.isSpeculative;
				dispatchBufferEntry.isRecoverInst = decodeBufferEntry.isRecoverInst;
				
				
				foreach(iDep; dispatchBufferEntry.iDeps) {
					dispatchBufferEntry.srcPhysRegs[iDep] = this.renameTable[iDep];
				}
				
				foreach(oDep; dispatchBufferEntry.oDeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					dispatchBufferEntry.oldPhysRegs[oDep] = this.renameTable[oDep];
					dispatchBufferEntry.physRegs[oDep] = regFile.alloc();
					this.renameTable[oDep] = dispatchBufferEntry.physRegs[oDep];
				}
				
				this.reorderBuffer ~= dispatchBufferEntry;
				
				
				if(dynamicInst.staticInst.isMem) {					
					ReorderBufferEntry loadStoreQueueEntry = new ReorderBufferEntry(dynamicInst, 
						(cast(MemoryOp) dynamicInst.staticInst).memIDeps, (cast(MemoryOp) dynamicInst.staticInst).memODeps);
					
					loadStoreQueueEntry.npc = decodeBufferEntry.npc;
					loadStoreQueueEntry.nnpc = decodeBufferEntry.nnpc;
					loadStoreQueueEntry.predNpc = decodeBufferEntry.predNpc;
					loadStoreQueueEntry.predNnpc = decodeBufferEntry.predNnpc;
					loadStoreQueueEntry.stackRecoverIndex = 0;
					loadStoreQueueEntry.dirUpdate = null;
					loadStoreQueueEntry.isSpeculative = decodeBufferEntry.isSpeculative;
					loadStoreQueueEntry.isRecoverInst = false;
					
					loadStoreQueueEntry.ea = (cast(MemoryOp) dynamicInst.staticInst).ea(this);
					
					dispatchBufferEntry.loadStoreQueueEntry = loadStoreQueueEntry; 
					
					foreach(iDep; loadStoreQueueEntry.iDeps) {
						loadStoreQueueEntry.srcPhysRegs[iDep] = this.renameTable[iDep];
					}
					
					foreach(oDep; loadStoreQueueEntry.oDeps) {
						PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
						loadStoreQueueEntry.oldPhysRegs[oDep] = this.renameTable[oDep]; //TODO: is it correct?
						loadStoreQueueEntry.physRegs[oDep] = regFile.alloc();
						this.renameTable[oDep] = loadStoreQueueEntry.physRegs[oDep];
					}
					
					this.loadStoreQueue ~= loadStoreQueueEntry;
				}
			}
			
			this.decodeBuffer.popFront();
		}
	}
	
	void dispatch() {
		foreach(dispatchBufferEntry; this.reorderBuffer) {
			if(!dispatchBufferEntry.isDispatched && !dispatchBufferEntry.isCompleted) {
				if(dispatchBufferEntry.allOperandsReady) {
					this.core.readyQueue ~= dispatchBufferEntry;
					dispatchBufferEntry.isInReadyQueue = true;
				}
				else {
					this.core.waitingQueue ~= dispatchBufferEntry;
				}
				dispatchBufferEntry.isDispatched = true;
			}
			
			if(dispatchBufferEntry.loadStoreQueueEntry !is null) {
				ReorderBufferEntry loadStoreQueueEntry = dispatchBufferEntry.loadStoreQueueEntry;
				if(!loadStoreQueueEntry.isDispatched && !loadStoreQueueEntry.isCompleted) {
					if(loadStoreQueueEntry.dynamicInst.staticInst.isStore && loadStoreQueueEntry.allOperandsReady) {
						this.core.readyQueue ~= loadStoreQueueEntry;
						loadStoreQueueEntry.isInReadyQueue = true;
					}
					else {
						this.core.waitingQueue ~= loadStoreQueueEntry;
					}
					loadStoreQueueEntry.isDispatched = true;
				}
			}
		}
	}
	
	void issue() {
		ReorderBufferEntry[] toWaitingQueue;
		
		while(!this.core.waitingQueue.empty) {
			ReorderBufferEntry waitingQueueEntry = this.core.waitingQueue.front;
			
			if(waitingQueueEntry.allOperandsReady) {
				this.core.readyQueue ~= waitingQueueEntry;
			}
			else {
				toWaitingQueue ~= waitingQueueEntry;
			}
			
			this.core.waitingQueue.popFront();
		}
		
		foreach(waitingQueueEntry; toWaitingQueue) {
			this.core.waitingQueue ~= waitingQueueEntry;
		}
		
		while(!this.core.readyQueue.empty) {
			ReorderBufferEntry readyQueueEntry = this.core.readyQueue.front;
			
			if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isStore) {
				this.core.seqD.store(this.core.mmu.translate(readyQueueEntry.ea), false, {});

				readyQueueEntry.isIssued = true;
				readyQueueEntry.isCompleted = true;
			}
			else if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isLoad) {
				this.core.seqD.load(this.core.mmu.translate(readyQueueEntry.ea), false, readyQueueEntry,
					(ReorderBufferEntry readyQueueEntry)
					{
						foreach(oDep; readyQueueEntry.oDeps) {
							readyQueueEntry.physRegs[oDep].state = PhysicalRegisterState.WB;
						}
						
						readyQueueEntry.isCompleted = true;
					});
				readyQueueEntry.isIssued = true;
			}
			else {
				if(readyQueueEntry.dynamicInst.staticInst.fuType != FunctionalUnitType.NONE) {
					this.core.fuPool.acquire(readyQueueEntry,
						(ReorderBufferEntry readyQueueEntry)
						{
							foreach(oDep; readyQueueEntry.oDeps) {
								readyQueueEntry.physRegs[oDep].state = PhysicalRegisterState.WB;
							}
							
							readyQueueEntry.isCompleted = true;
						});
					readyQueueEntry.isIssued = true;
				}
				else {
					readyQueueEntry.isIssued = true;
					readyQueueEntry.isCompleted = true;
				}
			}
			
			this.core.readyQueue.popFront();
			readyQueueEntry.isInReadyQueue = false;
		}
	}
	
	void commit() {
		if(currentCycle - this.lastCommitCycle > COMMIT_TIMEOUT) {			
			logging.fatalf(LogCategory.SIMULATOR, "No instruction committed for %d cycles.", COMMIT_TIMEOUT);
		}
		
		while(!this.reorderBuffer.empty) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.front;
			
			if(!reorderBufferEntry.isCompleted) {
				break;
			}
			
			if(reorderBufferEntry.isRecoverInst) {
				this.bpred.recover(reorderBufferEntry.dynamicInst.pc, reorderBufferEntry.stackRecoverIndex);
				
				this.isSpeculative = false;

				this.fetchNpc = this.npc;
				this.fetchNnpc = this.nnpc;
				
				this.recoverReorderBuffer(reorderBufferEntry);
			}
			
			if(reorderBufferEntry.isEAComputation) {
				ReorderBufferEntry loadStoreQueueEntry = this.loadStoreQueue.front;
				
				if(!loadStoreQueueEntry.isCompleted) {
					break;
				}
				
				foreach(oDep; loadStoreQueueEntry.oDeps) {
					loadStoreQueueEntry.oldPhysRegs[oDep].state = PhysicalRegisterState.FREE;
					loadStoreQueueEntry.physRegs[oDep].state = PhysicalRegisterState.ARCH;
				}
				
				this.loadStoreQueue.popFront();
			}
			
			foreach(oDep; reorderBufferEntry.oDeps) {
				reorderBufferEntry.oldPhysRegs[oDep].state = PhysicalRegisterState.FREE;
				reorderBufferEntry.physRegs[oDep].state = PhysicalRegisterState.ARCH;
			}
			
			if(reorderBufferEntry.dynamicInst.staticInst.isControl) {
				this.bpred.update(
					reorderBufferEntry.dynamicInst.pc,
					reorderBufferEntry.nnpc,
					reorderBufferEntry.nnpc != (reorderBufferEntry.npc + uint.sizeof),
					reorderBufferEntry.predNnpc != (reorderBufferEntry.npc + uint.sizeof),
					reorderBufferEntry.predNnpc == reorderBufferEntry.nnpc,
					reorderBufferEntry.dynamicInst.staticInst,
					reorderBufferEntry.dirUpdate
				);
			}
			
			this.reorderBuffer.popFront();

			this.stat.totalInsts.value = this.stat.totalInsts.value + 1;
			
			this.lastCommitCycle = currentCycle;
			
			//logging.infof(LogCategory.DEBUG, "t%d one instruction committed (dynamicInst=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.num, 
			//	reorderBufferEntry.dynamicInst);
		}
	}
	
	void recoverReorderBuffer(ReorderBufferEntry branchReorderBufferEntry) {
		ReorderBufferEntry[] toSquash;
		
		while(!this.reorderBuffer.empty) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.back;
			
			if(reorderBufferEntry == branchReorderBufferEntry) {
				break;
			}
			
			if(reorderBufferEntry.isEAComputation) {
				this.loadStoreQueue.remove(reorderBufferEntry);
			}
			
			foreach(oDep; reorderBufferEntry.dynamicInst.staticInst.oDeps) {
				reorderBufferEntry.physRegs[oDep].state = PhysicalRegisterState.FREE;
				this.renameTable[oDep] = reorderBufferEntry.oldPhysRegs[oDep];
			}
			
			reorderBufferEntry.physRegs.clear();
			
			this.reorderBuffer.popBack();
		}
	}

	uint getSyscallArg(int i) {
		assert(i < 6);
		return this.intRegs[FirstArgumentReg + i];
	}

	void setSyscallArg(int i, uint val) {
		assert(i < 6);
		this.intRegs[FirstArgumentReg + i] = val;
	}

	void setSyscallReturn(uint return_value) {
		this.intRegs[ReturnValueReg] = return_value;
		this.intRegs[SyscallSuccessReg] = (return_value == cast(uint) -EINVAL ? 1 : 0);
	}

	void syscall(uint callnum) {
		this.syscallEmul.syscall(callnum, this);
	}

	void clearArchRegs() {
		this.pc = 0;
		this.npc = 0;
		this.nnpc = 0;
		
		this.intRegs = new IntRegisterFile();
		this.floatRegs = new FloatRegisterFile();
		this.miscRegs = new MiscRegisterFile();
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
	
	IntRegisterFile intRegs;
	FloatRegisterFile floatRegs;
	MiscRegisterFile miscRegs;
	
	Process process;
	SyscallEmul syscallEmul;

	uint pc, npc, nnpc;
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
		
		for(uint i = 0; i < simulationConfig.architecture.processor.numCores; i++) {
			Core core = new Core(this.processor, i);
				
			for(uint j = 0; j < simulationConfig.architecture.processor.numThreadsPerCore; j++) {
				ContextConfig context = simulationConfig.contexts[i * simulationConfig.architecture.processor.numThreadsPerCore + j];
				
				writefln("context.cwd: %s, args: %s", context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));
				Process process = new Process(context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));

				uint threadNum = i * simulationConfig.architecture.processor.numThreadsPerCore + j;
				ContextStat contextStat = simulation.stat.processor.contexts[threadNum];
				
				Thread thread = new Thread(core, contextStat, threadNum, process);
				
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
