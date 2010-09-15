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
	this(FunctionalUnitPool pool, FunctionalUnitType type, uint quantity, uint opLat, uint issueLat) {
		this.pool = pool;
		this.type = type;
		this.quantity = quantity;
		this.opLat = opLat;
		this.issueLat = issueLat;
		
		this.busy = false;
	}

	override string toString() {
		return format("%s[type=%s, quantity=%d, opLat=%d, issueLat=%d, busy=%d]", "FunctionalUnit",
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
	uint quantity;
	uint opLat;
	uint issueLat;
	bool busy;
}

class FunctionalUnitPool {
	this() {		
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.IntALU, 4, 1, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.IntMULT, 1, 3, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.IntDIV, 1, 20, 19);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.RdPort, 2, 1, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.WrPort, 2, 1, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatADD, 4, 2, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatCMP, 4, 2, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatCVT, 4, 2, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatMULT, 1, 4, 1);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatDIV, 1, 12, 12);
		this.entities ~= new FunctionalUnit(this, FunctionalUnitType.FloatSQRT, 1, 24, 24);
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
	}
	
	FunctionalUnit findFree(FunctionalUnitType type) {
		foreach(entity; this.entities) {
			if(entity.type == type && !entity.busy) {
				return entity;
			}
		}
		return null;
	}
	
	void acquire(ReorderBufferEntry reorderBufferEntry, void delegate(ReorderBufferEntry rs) onCompletedCallback2) {
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

	FunctionalUnit[] entities;
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
	this(Core core) {
		this(128, core);
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
	
	override string toString() {
		return format("DecodeBufferEntry[id=%d, dynamicInst=%s]", this.id, this.dynamicInst);
	}
	
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
	this(DynamicInst dynamicInst, RegisterDependency[] iDeps, RegisterDependency[] oDeps) {
		this.id = currentId++;
		this.dynamicInst = dynamicInst;
		this.iDeps = iDeps;
		this.oDeps = oDeps;
		
		this.isCompleted = false;
	}
	
	bool operandReady(uint opNum) {		
		PhysicalRegisterFile regFile = this.dynamicInst.thread.core.getPhysicalRegisterFile(this.iDeps[opNum].type);
		return regFile[this.srcPhysRegs[opNum]].isReady;
	}
	
	bool allOperandsReady() {
		foreach(i, iDep; this.iDeps) {
			if(!this.operandReady(i)) {
				return false;
			}
		}
		
		return true;
	}
	
	string operandsReadyToString() {
		string str = "\n";
	
		foreach(i, iDep; this.iDeps) {
			str ~= format("[%s] idep=%s, isReady=%s\n", i, iDep, this.operandReady(i));
		}
		
		return str;
	}
	
	bool isInLoadStoreQueue() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry is null;
	}
	
	bool isEAComputation() {
		return this.dynamicInst.staticInst.isMem && this.loadStoreQueueEntry !is null;
	}
	
	override string toString() {
		return format("ReorderBufferEntry(id=%d, dynamicInst=%s, isEAComputation=%s, isDispatched=%s, isInReadyQueue=%s, isIssued=%s, isCompleted=%s) %s",
			this.id, this.dynamicInst, this.isEAComputation, this.isDispatched, this.isInReadyQueue, this.isIssued, this.isCompleted,
				this.operandsReadyToString);
	}
	
	ulong id;
	DynamicInst dynamicInst;
	uint ea;
	
	ReorderBufferEntry loadStoreQueueEntry;
	
	bool isDispatched;
	bool isInReadyQueue;
	bool isIssued;
	bool isCompleted;
	
	RegisterDependency[] iDeps, oDeps;

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
			this.core.intRegFile[this.num * NumIntRegs + i].state = PhysicalRegisterState.ARCH;
			this.renameTables[RegisterDependencyType.INT][i] = i;
		}
		
		for(uint i = 0; i < NumFloatRegs; i++) {
			this.core.fpRegFile[this.num * NumFloatRegs + i].state = PhysicalRegisterState.ARCH;
			this.renameTables[RegisterDependencyType.FP][i] = i;
		}
		
		for(uint i = 0; i < NumMiscRegs; i++) {
			this.core.miscRegFile[this.num * NumMiscRegs + i].state = PhysicalRegisterState.ARCH;
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
				ReorderBufferEntry dispatchBufferEntry = new ReorderBufferEntry(dynamicInst, dynamicInst.staticInst.iDeps, dynamicInst.staticInst.oDeps);
				
				foreach(i, iDep; dispatchBufferEntry.iDeps) {
					dispatchBufferEntry.srcPhysRegs[i] = this.renameTables[iDep.type][iDep.num];
				}
				
				foreach(i, oDep; dispatchBufferEntry.oDeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					dispatchBufferEntry.oldPhysRegs[i] = this.renameTables[oDep.type][oDep.num];
					dispatchBufferEntry.physRegs[i] = regFile.alloc();
					this.renameTables[oDep.type][oDep.num] = dispatchBufferEntry.physRegs[i];
				}
				
				this.reorderBuffer ~= dispatchBufferEntry;
				
				
				if(dynamicInst.staticInst.isMem) {					
					ReorderBufferEntry loadStoreQueueEntry = new ReorderBufferEntry(dynamicInst, 
						(cast(MemoryOp) dynamicInst.staticInst).memIDeps, (cast(MemoryOp) dynamicInst.staticInst).memODeps);
					loadStoreQueueEntry.ea = (cast(MemoryOp) dynamicInst.staticInst).ea(this);
					
					dispatchBufferEntry.loadStoreQueueEntry = loadStoreQueueEntry; 
					
					foreach(i, iDep; loadStoreQueueEntry.iDeps) {
						loadStoreQueueEntry.srcPhysRegs[i] = this.renameTables[iDep.type][iDep.num];
					}
					
					foreach(i, oDep; loadStoreQueueEntry.oDeps) {
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
				this.core.seqD.store(this.core.mmu.translate(readyQueueEntry.ea), false, {});

				readyQueueEntry.isIssued = true;
				readyQueueEntry.isCompleted = true;
			}
			else if(readyQueueEntry.isInLoadStoreQueue && readyQueueEntry.dynamicInst.staticInst.isLoad) {
				this.core.seqD.load(this.core.mmu.translate(readyQueueEntry.ea), false, readyQueueEntry,
					(ReorderBufferEntry readyQueueEntry)
					{
						foreach(i, oDep; readyQueueEntry.oDeps) {
							PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
							regFile[readyQueueEntry.physRegs[i]].state = PhysicalRegisterState.WB;
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
							foreach(i, oDep; readyQueueEntry.oDeps) {
								PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
								regFile[readyQueueEntry.physRegs[i]].state = PhysicalRegisterState.WB;
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
	
	override void commit() {
		if(Simulator.singleInstance.currentCycle - this.lastCommitCycle > COMMIT_TIMEOUT) {
			logging.warnf(LogCategory.SIMULATOR, 
				"decodeBuffer.full(size)=%s(%d), " ~
				"core.readyQueue.size=%d, " ~
				"core.waitingQueue.size=%d, " ~
				"reorderBuffer.full(size)=%s(%d), " ~
				"loadStoreQueue.full(size)=%s(%d)",
				this.decodeBuffer.full, this.decodeBuffer.size, 
				this.core.readyQueue.size,
				this.core.waitingQueue.size,
				this.reorderBuffer.full, this.reorderBuffer.size,
				this.loadStoreQueue.full, this.loadStoreQueue.size);
			
			writefln("Printing the content of decodeBuffer");
			foreach(i, entry; this.decodeBuffer) {
				writefln("[%d] %s", i, entry);
			}
			
			writefln("Printing the content of core.readyQueue");
			foreach(i, entry; this.core.readyQueue) {
				writefln("[%d] %s", i, entry);
			}
			
			writefln("Printing the content of core.waitingQueue");
			foreach(i, entry; this.core.waitingQueue) {
				writefln("[%d] %s", i, entry);
			}
			
			writefln("Printing the content of reorderBuffer");
			foreach(i, entry; this.reorderBuffer) {
				writefln("[%d] %s", i, entry);
			}
			
			writefln("Printing the content of loadStoreQueue");
			foreach(i, entry; this.loadStoreQueue) {
				writefln("[%d] %s", i, entry);
			}
			
			logging.fatalf(LogCategory.SIMULATOR, "No instruction committed for %d cycles.", COMMIT_TIMEOUT);
		}
		
		while(!this.reorderBuffer.empty) {
			ReorderBufferEntry reorderBufferEntry = this.reorderBuffer.front;
			
			if(!reorderBufferEntry.isCompleted) {
				break;
			}
			
			if(reorderBufferEntry.isEAComputation) {
				ReorderBufferEntry loadStoreQueueEntry = this.loadStoreQueue.front;
				
				if(!loadStoreQueueEntry.isCompleted) {
					break;
				}
				
				foreach(i, oDep; loadStoreQueueEntry.oDeps) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
					regFile[loadStoreQueueEntry.oldPhysRegs[i]].state = PhysicalRegisterState.FREE;
					regFile[loadStoreQueueEntry.physRegs[i]].state = PhysicalRegisterState.ARCH;
				}
				
				this.loadStoreQueue.popFront();
			}
			
			foreach(i, oDep; reorderBufferEntry.oDeps) {
				PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(oDep.type);
				regFile[reorderBufferEntry.oldPhysRegs[i]].state = PhysicalRegisterState.FREE;
				regFile[reorderBufferEntry.physRegs[i]].state = PhysicalRegisterState.ARCH;
			}
			
			this.reorderBuffer.popFront();

			this.stat.totalInsts++;
			
			this.lastCommitCycle = Simulator.singleInstance.currentCycle;
			
			//logging.infof(LogCategory.DEBUG, "t%s one instruction committed (dynamicInst=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, 
			//	reorderBufferEntry.dynamicInst);
		}
	}
	
	bool fetchStalled;
	uint lastFetchedBlock;
}