/*
 * flexim/cpu/core.d
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

module flexim.cpu.core;

import flexim.all;

import core.stdc.errno;

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

class FunctionalUnit {
	this(FunctionalUnitCategory master, FunctionalUnitType fuType, uint opLat, uint issueLat) {
		this.master = master;
		this.fuType = fuType;
		this.opLat = opLat;
		this.issueLat = issueLat;
	}

	override string toString() {
		return format("%s[master=%s, fuType=%s, opLat=%d, issueLat=%d]", "FunctionalUnit", this.master.name, to!(string)(this.fuType), this.opLat, this.issueLat);
	}

	FunctionalUnitCategory master;

	FunctionalUnitType fuType;
	uint opLat;
	uint issueLat;
}

class FunctionalUnitCategory {
	this(string name, uint quantity, uint busy) {
		this.name = name;
		this.quantity = quantity;
		this.busy = busy;
	}

	override string toString() {
		return format("%s[name=%s, quantity=%d, busy=%d]", "FunctionalUnitCategory", this.name, this.quantity, this.busy);
	}

	string name;
	uint quantity;
	uint busy;

	FunctionalUnit[] entities;
}

class FunctionalUnitPool {
	this() {		
		FunctionalUnitCategory categoryIntegerAlu =
			new FunctionalUnitCategory("integer-ALU", 4, 0);
		categoryIntegerAlu.entities ~=
			new FunctionalUnit(categoryIntegerAlu, FunctionalUnitType.IntALU, 1, 1);
			
		FunctionalUnitCategory categoryIntegerMultDiv =
			new FunctionalUnitCategory("integer-MULT/DIV", 1, 0);
		categoryIntegerMultDiv.entities ~=
			new FunctionalUnit(categoryIntegerMultDiv, FunctionalUnitType.IntMULT, 3, 1);
		categoryIntegerMultDiv.entities ~=
			new FunctionalUnit(categoryIntegerMultDiv, FunctionalUnitType.IntDIV, 20, 19);
			
		FunctionalUnitCategory categoryMemoryPort =
			new FunctionalUnitCategory("memory-port", 2, 0);
		categoryMemoryPort.entities ~=
			new FunctionalUnit(categoryMemoryPort, FunctionalUnitType.RdPort, 1, 1);
		categoryMemoryPort.entities ~=
			new FunctionalUnit(categoryMemoryPort, FunctionalUnitType.WrPort, 1, 1);
			
		FunctionalUnitCategory categoryFPAdder =
			new FunctionalUnitCategory("FP-adder", 4, 0);
		categoryFPAdder.entities ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatADD, 2, 1);
		categoryFPAdder.entities ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatCMP, 2, 1);
		categoryFPAdder.entities ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatCVT, 2, 1);
				
		FunctionalUnitCategory categoryFPMultDiv =
			new FunctionalUnitCategory("FP-MULT/DIV", 1, 0);
		categoryFPMultDiv.entities ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatMULT, 4, 1);
		categoryFPMultDiv.entities ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatDIV, 12, 12);
		categoryFPMultDiv.entities ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatSQRT, 24, 24);
		
		this.categories ~= categoryIntegerAlu;
		this.categories ~= categoryIntegerMultDiv;
		this.categories ~= categoryMemoryPort;
		this.categories ~= categoryFPAdder;
		this.categories ~= categoryFPMultDiv;
	}
	
	FunctionalUnit getFree(FunctionalUnitType fuType) {		
		foreach(cat; this.categories) {
			foreach(entity; cat.entities) {
				if(!entity.master.busy) {
					return entity;
				}
			}
		}
		
		return null;
	}
	
	FunctionalUnitCategory[] categories;
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
	this(Core core) {
		this(1024, core);
	}
	
	this(uint capacity, Core core) {
		this.capacity = capacity;
		this.core = core;
		
		this.entries = new PhysicalRegister[this.capacity];
		for(uint i = 0; i < this.capacity; i++) {
			this.entries[i] = new PhysicalRegister();
		}
	}
	
	PhysicalRegister findFree() {
		foreach(entry; this.entries) {
			if(entry.state == PhysicalRegisterState.FREE) {
				return entry;
			}
		}

		return null;
	}
	
	uint alloc() {
		PhysicalRegister freeReg = this.findFree();
		assert(freeReg !is null);
		freeReg.state = PhysicalRegisterState.ALLOC;
		return this.entries.indexOf(freeReg);
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
	
	uint capacity;
	Core core;
	PhysicalRegister[] entries;
}

enum PhysicalRegisterType: string {
	NONE = "NONE",
	INT = "INT",
	FP = "FP"
}

class DecodeBufferEntry {
	this(DynamicInst dynamicInst) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
	}
	
	ulong id;
	DynamicInst dynamicInst;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class DecodeBuffer: Queue!(DecodeBufferEntry) {
	this() {
		this(4);
	}
	
	this(uint capacity) {
		super("decodeBuffer", capacity);
	}
}

class ReorderBufferEntry {
	this(DynamicInst dynamicInst) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
		
		this.isCompleted = false;
	}
	
	bool operandReady(RegisterDependency[] iDeps, uint opNum) {		
		PhysicalRegisterFile regFile = this.dynamicInst.thread.core.getPhysicalRegisterFile(iDeps[opNum].type);
		assert(opNum in this.srcPhysRegs, format("opNum=%d, this.srcPhysRegs.length=%d", opNum, this.srcPhysRegs.length));
		return regFile[this.srcPhysRegs[opNum]].isReady;
	}
	
	bool operandReady(uint opNum) {
		return this.operandReady(this.dynamicInst.staticInst.iDeps, opNum);
	}
	
	bool allOperandsReady() {
		/*foreach(i, iDep; this.dynamicInst.staticInst.iDeps) {
			if(!this.operandReady(i)) {
				return false;
			}
		}*/ //TODO
		
		return true;
	}
	
	bool isDispatched() {
		return this.isReady || this.isWaiting;
	}
	
	bool isWaiting() {
		return this.dynamicInst.thread.core.waitingQueue.indexOf(this) != -1;
	}
	
	bool isReady() {
		return this.dynamicInst.thread.core.readyQueue.indexOf(this) != -1;
	}
	
	bool isInLoadStoreQueue() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry is null;
	}
	
	override string toString() {
		//return format("ReorderBufferEntry(id=%d, dynamicInst=%s, isEffectiveAddressComputation=%s, effectiveAddress=0x%x, isCompleted=%s)",
		//	this.id, this.dynamicInst, this.isEffectiveAddressComputation, this.effectiveAddress, this.isCompleted);
		return format("ReorderBufferEntry(id=%d, isEffectiveAddressComputation=%s, isCompleted=%s)",
			this.id, this.isEffectiveAddressComputation, this.isCompleted);
	}
	
	ulong id;
	DynamicInst dynamicInst;
	bool isEffectiveAddressComputation;
	uint effectiveAddress;
	
	ReorderBufferEntry loadStoreQueueEntry;
	
	bool isCompleted;

	uint[uint] oldPhysRegs;
	uint[uint] physRegs;
	uint[uint] srcPhysRegs;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class ReadyQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(32);
	}
	
	this(uint capacity) {
		super("readyQueue", capacity);
	}
}

class WaitingQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(32);
	}
	
	this(uint capacity) {
		super("waitingQueue", capacity);
	}
}

class ReorderBuffer: Queue!(ReorderBufferEntry) {
	this() {
		this(8);
	}
	
	this(uint capacity) {
		super("reorderBuffer", capacity);
	}
}

class LoadStoreQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(4);
	}
	
	this(uint capacity) {
		super("loadStoreQueue", capacity);
	}
}

class Processor {
	public:
		this(CPUSimulator simulator) {
			this(simulator, "");
		}

		this(CPUSimulator simulator, string name) {
			this.simulator = simulator;
			this.name = name;
			
			this.mem = new Memory();
			
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
		
		Memory mem;

		CPUSimulator simulator;
		string name;
		Core[] cores;
		
		int activeThreadCount;
}

abstract class Core {	
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
	}
	
	void releaseFunctionalUnits() {
		logging.infof(LogCategory.DEBUG, "releaseFunctionalUnits()");
		
		foreach(category; this.fuPool.categories) {
			if(category.busy > 0) {
				category.busy--;
			}
		}
	}
	
	abstract void run();
	
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
	
	uint numThreads() {
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
	
	Memory mem() {
		return this.processor.mem;
	}
	
	uint fetchWidth() {
		return this.decodeWidth * this.fetchSpeed;
	}

	uint num;
	Processor processor;
	Thread[] threads;
	
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

abstract class Thread {
	this(Core core, Simulation simulation, uint num, string name, Process process) {
		this.core = core;
		
		this.num = num;
		
		this.name = name;
		
		this.process = process;
		
		this.syscallEmul = new SyscallEmul();

		this.clearArchRegs();

		this.process.load(this);
		
		this.commitWidth = 4;
		
		this.stat = new ThreadStat(this.num);
		simulation.stat.processorStat.threadStats ~= this.stat;
		
		this.state = ThreadState.Active;
		
		for(uint i = 0; i < NumIntRegs; i++) {
			this.renameTables[RegisterDependencyType.INT][i] = i;
		}
		
		for(uint i = 0; i < NumFloatRegs; i++) {
			this.renameTables[RegisterDependencyType.FP][i] = i;
		}
		
		for(uint i = 0; i < NumMiscRegs; i++) {
			this.renameTables[RegisterDependencyType.MISC][i] = i;
		}
		
		this.decodeBuffer = new DecodeBuffer();
		this.reorderBuffer = new ReorderBuffer();
		this.loadStoreQueue = new LoadStoreQueue();
	}
	
	abstract void fetch();
	
	abstract void registerRename();
	
	abstract void dispatch();
	
	abstract void issue();
	
	abstract void commit();

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
		this.intRegs[SyscallSuccessReg] = return_value == cast(uint) -EINVAL ? 1 : 0;
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
		logging.infof(LogCategory.SIMULATOR, "target called exit(%d)", exitCode);
		this.state = ThreadState.Halted;
		this.core.processor.activeThreadCount--;
	}
	
	Memory mem() {
		return this.core.processor.mem;
	}
	
	ISA isa() {
		return this.core.isa;
	}
	
	uint num;
	string name;

	Core core;
	
	IntRegisterFile intRegs;
	FloatRegisterFile floatRegs;
	MiscRegisterFile miscRegs;
	
	Process process;
	SyscallEmul syscallEmul;

	uint pc, npc, nnpc;
	
	uint[uint][RegisterDependencyType] renameTables;
	
	uint commitWidth;
	ulong lastCommitCycle;
	
	ThreadState state;
	
	ThreadStat stat;
	
	DecodeBuffer decodeBuffer;
	ReorderBuffer reorderBuffer;
	LoadStoreQueue loadStoreQueue;
	
	static const uint COMMIT_TIMEOUT = 1000000;
}

class CoreImpl: Core {	
	this(Processor processor, uint num) {
		super(processor, num);
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
	
	override void run() {
		this.fetch();
		this.registerRename();
		this.dispatch();
		this.issue();
		this.commit();
	}
}

class ThreadImpl: Thread {
	this(Core core, Simulation simulation, uint num, string name, Process process) {
		super(core, simulation, num, name, process);
	}
	
	override void fetch() {
		uint blockToFetch = aligned(this.npc, this.core.seqI.blockSize);
		if(blockToFetch != this.lastFetchedBlock) {
			this.lastFetchedBlock = blockToFetch;
			
			this.core.seqI.load(this.core.mmu.translate(this.npc), false, 
				{
					this.fetchStalled = false;
				});
			
			this.fetchStalled = true;
		}
		
		while(!this.decodeBuffer.full && !this.fetchStalled && aligned(this.npc, this.core.seqI.blockSize) == blockToFetch) {		
			this.pc = this.npc;
			this.npc = this.nnpc;
		    this.nnpc += uint.sizeof;
		    
			StaticInst staticInst = this.isa.decode(this.pc, this.mem);
		    DynamicInst dynamicInst = new DynamicInst(this, this.pc, staticInst);
			dynamicInst.execute();
		    
		    DecodeBufferEntry decodeBufferEntry = new DecodeBufferEntry(dynamicInst);
		    this.decodeBuffer ~= decodeBufferEntry;
		}
	}
	
	override void registerRename() {
		while(!this.decodeBuffer.empty && !this.reorderBuffer.full && !this.loadStoreQueue.full) {
			DecodeBufferEntry decodeBufferEntry = this.decodeBuffer.front;
			
			this.intRegs[ZeroReg] = 0;
			
			DynamicInst dynamicInst = decodeBufferEntry.dynamicInst;
			
			if(!dynamicInst.staticInst.isNop) {
				ReorderBufferEntry dispatchBufferEntry = new ReorderBufferEntry(dynamicInst);
				
				foreach(i, iDep; dynamicInst.staticInst.iDeps) {
					dispatchBufferEntry.srcPhysRegs[i] = this.renameTables[iDep.type][iDep.num];
				}
				
				foreach(i, oDep; dynamicInst.staticInst.oDeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					dispatchBufferEntry.oldPhysRegs[i] = this.renameTables[oDep.type][oDep.num];
					dispatchBufferEntry.physRegs[i] = regFile.alloc();
					this.renameTables[oDep.type][oDep.num] = dispatchBufferEntry.physRegs[i];
				}
				
				this.reorderBuffer ~= dispatchBufferEntry;
				
				
				if(dynamicInst.staticInst.isMem) {
					dispatchBufferEntry.isEffectiveAddressComputation = true;
					
					ReorderBufferEntry loadStoreQueueEntry = new ReorderBufferEntry(dynamicInst);
					loadStoreQueueEntry.isEffectiveAddressComputation = false;
					loadStoreQueueEntry.effectiveAddress = (cast(MemoryOp) dynamicInst.staticInst).ea(this);
					
					dispatchBufferEntry.loadStoreQueueEntry = loadStoreQueueEntry; 
					
					foreach(i, iDep; (cast(MemoryOp) dynamicInst.staticInst).memIDeps) {
						loadStoreQueueEntry.srcPhysRegs[i] = this.renameTables[iDep.type][iDep.num];
					}
					
					foreach(i, oDep; (cast(MemoryOp) dynamicInst.staticInst).memODeps) {
						PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
						loadStoreQueueEntry.oldPhysRegs[i] = this.renameTables[oDep.type][oDep.num]; //TODO: is it correct?
						loadStoreQueueEntry.physRegs[i] = regFile.alloc();
						this.renameTables[oDep.type][oDep.num] = loadStoreQueueEntry.physRegs[i];
					}
					
					this.loadStoreQueue ~= loadStoreQueueEntry;
				}
			}
			
			this.decodeBuffer.popFront();
		}
	}
	
	override void dispatch() {		
		foreach(dispatchBufferEntry; this.reorderBuffer) {
			if(dispatchBufferEntry.allOperandsReady) {
				this.core.readyQueue ~= dispatchBufferEntry;
			}
			else {
				this.core.waitingQueue ~= dispatchBufferEntry;
			}
			
			if(dispatchBufferEntry.loadStoreQueueEntry !is null) {
				ReorderBufferEntry loadStoreQueueEntry = dispatchBufferEntry.loadStoreQueueEntry;
				
				if(loadStoreQueueEntry.dynamicInst.staticInst.isStore && loadStoreQueueEntry.allOperandsReady) {
					this.core.readyQueue ~= loadStoreQueueEntry;
				}
				else {
					this.core.waitingQueue ~= loadStoreQueueEntry;
				}
			}
		}
	}
	
	override void issue() {
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
				this.core.seqD.store(this.core.mmu.translate(readyQueueEntry.effectiveAddress), false, {});
				
				readyQueueEntry.isCompleted = true;
			}
			else if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isLoad) {
				this.core.seqD.load(this.core.mmu.translate(readyQueueEntry.effectiveAddress), false, readyQueueEntry,
					(ReorderBufferEntry readyQueueEntry)
					{
						foreach(i, oDep; readyQueueEntry.dynamicInst.staticInst.oDeps) {
							PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
							regFile[readyQueueEntry.physRegs[i]].state = PhysicalRegisterState.WB;
						}
						
						readyQueueEntry.isCompleted = true;
					});
			}
			else {
				//TODO: functional unit access				
				foreach(i, oDep; readyQueueEntry.dynamicInst.staticInst.oDeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					regFile[readyQueueEntry.physRegs[i]].state = PhysicalRegisterState.WB;
				}
				
				readyQueueEntry.isCompleted = true;
			}
			
			this.core.readyQueue.popFront();
		}
	}
	
	override void commit() {
		while(!this.reorderBuffer.empty) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.front;
			
			if(!reorderBufferEntry.isCompleted) {
				break;
			}
			
			if(reorderBufferEntry.isEffectiveAddressComputation) {
				ReorderBufferEntry loadStoreQueueEntry = this.loadStoreQueue.front;
				
				if(!loadStoreQueueEntry.isCompleted) {
					break;
				}
				
				foreach(i, oDep; (cast(MemoryOp) loadStoreQueueEntry.dynamicInst.staticInst).memODeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					regFile[loadStoreQueueEntry.oldPhysRegs[i]].state = PhysicalRegisterState.FREE;
					regFile[loadStoreQueueEntry.physRegs[i]].state = PhysicalRegisterState.ARCH;
				}
				
				this.loadStoreQueue.popFront();
			}
			
			foreach(i, oDep; reorderBufferEntry.dynamicInst.staticInst.oDeps) {
				PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
				regFile[reorderBufferEntry.oldPhysRegs[i]].state = PhysicalRegisterState.FREE;
				regFile[reorderBufferEntry.physRegs[i]].state = PhysicalRegisterState.ARCH;
			}
			
			this.reorderBuffer.popFront();

			this.stat.totalInsts++;
			
			logging.infof(LogCategory.DEBUG, "t%s one instruction committed (dynamicInst=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, 
				reorderBufferEntry.dynamicInst);
		}
	}
	
	bool fetchStalled;
	uint lastFetchedBlock;
}