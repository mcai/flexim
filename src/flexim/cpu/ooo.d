/*
 * flexim/cpu/ooo.d
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

module flexim.cpu.ooo;

import flexim.all;

import core.stdc.errno;

/* 
 * Hint: functional execution logic
 *
 * this.pc = this.npc;
 * this.npc = this.nnpc;
 * this.nnpc += Addr.sizeof;
 * 	
 * StaticInst staticInst = this.isa.decode(this.pc, this.mem);
 * DynamicInst uop = new DynamicInst(this, this.pc, staticInst);
 * uop.execute();
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
		this.readyCycle = cast(ulong)-1;
		this.specReadyCycle = cast(ulong)-1;
		this.allocatedCycle = cast(ulong)-1;
		this.state = PhysicalRegisterState.FREE;
	}
	
	ulong readyCycle;
	ulong specReadyCycle;
	ulong allocatedCycle;
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
		freeReg.state = PhysicalRegisterState.ALLOC;
		freeReg.allocatedCycle = Simulator.singleInstance.currentCycle;
		freeReg.readyCycle = cast(ulong)-1;
		freeReg.specReadyCycle = cast(ulong)-1;
		return this.entries.indexOf(freeReg);
	}
	
	PhysicalRegister opIndex(uint index) {
		return this.entries[index];
	}
	
	void opIndexAssign(PhysicalRegister value, uint index) {
		this.entries[index] = value;
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

enum FetchPolicy: string {
	ICOUNT = "ICOUNT",
	ROUND_ROBBIN = "ROUND_ROBBIN"
}

class FetchRecord {	
	this(StaticInst staticInst, uint pc, uint predPc, int stackRecoverIndex, ulong fetchedCycle) {
		this.staticInst = staticInst;
		this.pc = pc;
		this.predPc = predPc;
		this.stackRecoverIndex = stackRecoverIndex;
		this.fetchedCycle = fetchedCycle;
	}

	override string toString() {
		return format("FetchRecord");
	}

	StaticInst staticInst;
	uint pc, predPc;
	BpredUpdate dirUpdate;
	int stackRecoverIndex;
	ulong fetchedCycle;
}

class FetchQueue: Queue!(FetchRecord) {
	this() {
		this(4);
	}
	
	this(uint capacity) {
		super("fetchq", capacity);
	}
}

enum IssueQueueEntryState: string {
	FREE = "FREE",
	ALLOC = "ALLOC"
}

class IssueQueueEntry {
	this() {
		this.state = IssueQueueEntryState.FREE;
	}
	
	IssueQueueEntryState state;
}

class IssueQueue: Queue!(IssueQueueEntry) {
	this() {
		this(1024);
	}
	
	this(uint capacity) {
		super("issueq", capacity);
		
		this.entries = new IssueQueueEntry[this.capacity];
		for(uint i = 0; i < this.capacity; i++) {
			this.entries[i] = new IssueQueueEntry();
		}
	}
	
	IssueQueueEntry findFree() {
		foreach(entry; this.entries) {
			if(entry.state == IssueQueueEntryState.FREE) {
				return entry;
			}
		}
		
		return null;
	}
	
	IssueQueueEntry alloc() {
		IssueQueueEntry entry = this.findFree();
		
		if(entry !is null) {
			entry.state = IssueQueueEntryState.ALLOC;
			return entry;
		}
		
		return null;
	}
}

const uint MAX_IDEPS = 3;
const uint MAX_ODEPS = 2;

const uint STORE_ADDR_INDEX = 0;
const uint STORE_OP_INDEX = 1;

class ReorderBufferEntry {
	this(uint pc, DynamicInst uop) {
		this.id = ++currentId;
		
		this.uop = uop;
		this.pc = pc;

		this.inLoadStoreQueue = false;
		this.inIssueQueue = false;
		
		this.isEffectiveAddressComputation = false;
		this.effectiveAddress = 0;
		
		this.isRecoverInstruction = false;
		this.stackRecoverIndex = -1;
		
		this.isSpeculative = false;
		
		this.isDispatched = false;
		this.isQueued = false;
		this.isIssued = false;
		this.isCompleted = false;
		this.isReplayed = false;
		
		this.execLat = cast(ulong)-1;
		
		this.renameCycle = cast(ulong)-1;
		this.dispatchCycle = cast(ulong)-1;
	}
	
	bool storeOperandReady() {
		return this.operandSpecReady(STORE_OP_INDEX);
	}
	
	bool storeAddressReady() {
		return this.operandSpecReady(STORE_ADDR_INDEX);
	}
	
	bool operandReady(RegisterDependency[] ideps, uint opNum) {		
		PhysicalRegisterFile regFile = this.uop.thread.core.getPhysicalRegisterFile(ideps[opNum].type);
		return regFile[this.srcPhysRegs[opNum]].readyCycle <= Simulator.singleInstance.currentCycle;
	}
	
	bool operandReady(uint opNum) {
		return this.operandReady(this.uop.staticInst.ideps, opNum);
	}
	
	bool operandSpecReady(RegisterDependency[] ideps, uint opNum) {
		PhysicalRegisterFile regFile = this.uop.thread.core.getPhysicalRegisterFile(ideps[opNum].type);
		return regFile[this.srcPhysRegs[opNum]].specReadyCycle <= Simulator.singleInstance.currentCycle;
	}
	
	bool operandSpecReady(uint opNum) {
		return this.operandSpecReady(this.uop.staticInst.ideps, opNum);
	}
	
	bool allOperandsReady() {
		if(this.isEffectiveAddressComputation) {
			foreach(i, iDep; (cast(MemoryOp)this.uop.staticInst).eaIdeps) {
				if(!this.operandReady((cast(MemoryOp)this.uop.staticInst).eaIdeps, i)) {
					return false;
				}
			}
			
			return true;
		}
		else {
			foreach(i, iDep; this.uop.staticInst.ideps) {
				if(!this.operandReady(i)) {
					return false;
				}
			}
			
			return true;
		}
	}
	
	bool allOperandsSpecReady() {
		if(this.isEffectiveAddressComputation) {
			foreach(i, iDep; (cast(MemoryOp)this.uop.staticInst).eaIdeps) {
				if(!this.operandSpecReady((cast(MemoryOp)this.uop.staticInst).eaIdeps, i)) {
					return false;
				}
			}
			
			return true;
		}
		else {
			foreach(i, iDep; this.uop.staticInst.ideps) {
				if(!this.operandSpecReady(i)) {
					return false;
				}
			}
			
			return true;
		}
	}

	ulong id;

	DynamicInst uop;
	uint pc, npc, predPc;
	
	bool inLoadStoreQueue;
	bool inIssueQueue;
	
	bool isEffectiveAddressComputation;
	uint effectiveAddress;
	
	bool isRecoverInstruction;
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	bool isSpeculative;
	
	bool isDispatched;
	bool isQueued;
	bool isIssued;
	bool isCompleted;
	bool isReplayed;
	
	uint[] physRegs;
	uint[] oldPhysRegs;
	uint[] srcPhysRegs;
	
	uint execLat;
	
	ulong renameCycle;
	ulong dispatchCycle;
	
	ReorderBufferEntry loadStoreQueueEntry;
	IssueQueueEntry issueQueueEntry;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class WaitingQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("waitingQueue", capacity);
	}
}

class ReadyQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("readyQueue", capacity);
	}
}

class IssueExecQueue: DelayedQueue!(ReorderBufferEntry) {
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("issueExecQueue", capacity);
	}
}

class ReorderBuffer: Queue!(ReorderBufferEntry) {
	this() {
		this(16);
	}
	
	this(uint capacity) {
		super("reorderBuffer", capacity);
	}
}

class LoadStoreQueue: Queue!(ReorderBufferEntry) {
	this() {
		this(8);
	}
	
	this(uint capacity) {
		super("loadStoreQueue", capacity);
	}
}

class OoOEventQueue: DelayedQueue!(ReorderBufferEntry) {
	this() {
		this(1024);
	}
	
	this(uint capacity) {
		super("eventQueue", capacity);
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

		void addCore(Core core) {
			core.processor = this;
			this.cores ~= core;
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

static const uint FETCH_RENAME_DELAY = 4;
static const uint RENAME_DISPATCH_DELAY = 1;
static const uint ISSUE_EXEC_DELAY = 1;

enum BpredSpecUpdate {
	ID,
	WB,
	CT
}

class Core {	
	this(uint num) {
		this.num = num;
	
		this.fetchSpeed = 1;
		this.decodeWidth = 4;
		this.issueWidth = 4;
		
		this.intRegFile = new PhysicalRegisterFile(this);
		this.fpRegFile = new PhysicalRegisterFile(this);
		this.miscRegFile = new PhysicalRegisterFile(this);
		
		this.waitingQueue = new WaitingQueue();
		this.readyQueue = new ReadyQueue();
		this.issueQueue = new IssueQueue();
		this.issueExecQueue = new IssueExecQueue();
		this.eventQueue = new OoOEventQueue();
		this.fuPool = new FunctionalUnitPool();
		
		this.fetchPolicy = FetchPolicy.ICOUNT;
		
		this.currentThreadId = 0;
		
		this.isa = new MipsISA();
		
		this.bpredSpecUpdate = BpredSpecUpdate.ID;
	}

	void addThread(Thread thread) {
		thread.core = this;
		this.threads ~= thread;
	}
	
	void releaseFunctionalUnits() {
		foreach(category; this.fuPool.categories) {
			if(category.busy > 0) {
				category.busy--;
			}
		}
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
	
	void writeback() {
		while(!this.eventQueue.empty) {
			ReorderBufferEntry rs = this.eventQueue.front;
			rs.isCompleted = true;

			if(!rs.isEffectiveAddressComputation) {
				foreach(i, physReg; rs.physRegs) {
					PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
					
					if(regFile[physReg].readyCycle != Simulator.singleInstance.currentCycle) {
						regFile[physReg].readyCycle = Simulator.singleInstance.currentCycle;
						assert(0);
					}
					
					regFile[physReg].state = PhysicalRegisterState.WB;
				}
			}
			
			if(rs.isRecoverInstruction) {				
				rs.uop.thread.recoverReorderBuffer(rs);
				rs.uop.thread.pred.recover(rs.pc, rs.stackRecoverIndex);
			}
			
			if(rs.uop.thread.pred !is null && 
				this.bpredSpecUpdate == BpredSpecUpdate.WB &&
				!rs.inLoadStoreQueue &&
				rs.uop.staticInst.isControl) {
				rs.uop.thread.pred.update(
					rs.pc,
					rs.npc,
					rs.npc != (rs.pc + uint.sizeof),
					rs.predPc != (rs.pc + uint.sizeof),
					rs.predPc == rs.npc,
					rs.uop.staticInst,
					rs.dirUpdate
				);
			}
			
			this.eventQueue.popFront();
		}
	}
	
	void wakeup() {
		ReorderBufferEntry[] toWaitq;
		
		for(;!this.waitingQueue.empty;) {
			ReorderBufferEntry rs = this.waitingQueue.front;
			
			if(rs.allOperandsSpecReady) {
				this.readyQueue ~= rs;
				rs.isQueued = true;
			}
			else {
				toWaitq ~= rs;
			}
			
			this.waitingQueue.popFront();
		}
		
		foreach(rs; toWaitq) {
			this.waitingQueue ~= rs;
		}
	}
	
	void selection() {
		ReorderBufferEntry[] toReadyq;
		
		for(uint numIssued = 0; !this.readyQueue.empty && numIssued < this.issueWidth; numIssued++) {
			ReorderBufferEntry rs = this.readyQueue.front;

			rs.isQueued = false;
			
			if(rs.inLoadStoreQueue && rs.uop.staticInst.isStore) {
				rs.isIssued = true;
				rs.isCompleted = true;
			}
			else {
				if(rs.uop.staticInst.fuType != FunctionalUnitType.NONE) {
					FunctionalUnit fu = this.fuPool.getFree(rs.uop.staticInst.fuType);
					if(fu !is null) {
						rs.isIssued = true;
						
						fu.master.busy = fu.issueLat;
						
						if(rs.inLoadStoreQueue && rs.uop.staticInst.isLoad) {							
							bool hitInLsq = false;
							
							ReorderBufferEntry lsq = rs.loadStoreQueueEntry;
							if(lsq != rs.uop.thread.loadStoreQueue.front) {
								for(;;) {
									lsq = rs.uop.thread.loadStoreQueue.before(lsq);
									
									if(lsq.uop.staticInst.isStore && lsq.effectiveAddress == rs.effectiveAddress) {
										hitInLsq = true;
									}
								}
							}
							
							if(!hitInLsq) {
								assert(0);
								/* TODO: no! go to the data cache if addr is valid */
								
							}
							
							assert(0);
							/* TODO: all loads and stores must to access D-TLB */
							
							//rs.execLat = loadLat;
							
							this.issueExecQueue.enqueue(rs, Simulator.singleInstance.currentCycle + ISSUE_EXEC_DELAY);
							
							foreach(i, physReg; rs.physRegs) {
								PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
								regFile[physReg].specReadyCycle = Simulator.singleInstance.currentCycle + rs.execLat + ISSUE_EXEC_DELAY;
								regFile[physReg].readyCycle = Simulator.singleInstance.currentCycle + rs.execLat + ISSUE_EXEC_DELAY;
							}
						}
						else {
							rs.execLat = fu.opLat;
							this.issueExecQueue.enqueue(rs, ISSUE_EXEC_DELAY);
							
							if(!rs.isEffectiveAddressComputation) {
								foreach(i, physReg; rs.physRegs) {
									PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
									regFile[physReg].specReadyCycle = Simulator.singleInstance.currentCycle + rs.execLat;
									regFile[physReg].readyCycle = Simulator.singleInstance.currentCycle + rs.execLat + ISSUE_EXEC_DELAY;
								}
							}
						}
					}
					else {
						toReadyq ~= rs;
					}
				}
				else {
					rs.isIssued = true;
					
					rs.execLat = 1;
					this.issueExecQueue.enqueue(rs, ISSUE_EXEC_DELAY);
					
					foreach(i, physReg; rs.physRegs) {
						PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
						regFile[physReg].specReadyCycle = Simulator.singleInstance.currentCycle + rs.execLat;
						regFile[physReg].readyCycle = Simulator.singleInstance.currentCycle + rs.execLat + ISSUE_EXEC_DELAY;
					}
				}
			}
			
			this.readyQueue.popFront();
		}
		
		assert(this.readyQueue.empty);
		
		foreach(rs; toReadyq) {
			this.readyQueue ~= rs;
			rs.isQueued = true;
		}
	}
	
	void execute() {		
		while(!this.issueExecQueue.empty) {
			ReorderBufferEntry rs = this.issueExecQueue.front;
			
			if(!rs.allOperandsSpecReady) {
				foreach(i, srcPhysReg; rs.srcPhysRegs) {
					PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.ideps[i].type);
					regFile[srcPhysReg].specReadyCycle = regFile[srcPhysReg].readyCycle - ISSUE_EXEC_DELAY;
				}
				
				while(rs !is null) {
					if(!rs.isEffectiveAddressComputation) {
						foreach(i, physReg; rs.physRegs) {
							PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
							regFile[physReg].specReadyCycle = cast(ulong)-1;
							regFile[physReg].readyCycle = cast(ulong)-1;
						}
					}
					
					rs.isIssued = false;
					rs.isReplayed = true;
					
					if(!rs.uop.staticInst.isLoad) {
						this.waitingQueue ~= rs;
					}
					
					this.issueExecQueue.popFront();
					rs = this.issueExecQueue.front;
				}
			}
			
			this.eventQueue.enqueue(rs, rs.execLat);
			
			if(rs.inIssueQueue) {
				this.issueQueue.remove(rs.issueQueueEntry);
				rs.inIssueQueue = false;
			}
			
			this.issueExecQueue.popFront();
		}
	}
	
	void dispatch() {
		bool[] dispatchStalled = new bool[this.numThreads];
		uint[] numDispatched = new uint[this.numThreads];
		uint dispatchThreadId = 0;
		uint numSearched = 0;
		
		for(uint i = 0; i < this.numThreads; i++) {
			dispatchStalled[i] = false;
			numDispatched[i] = 0;
		}
		
		dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
		
		for(uint numTotalDispatched = 0; numTotalDispatched < this.decodeWidth; ) {
			bool allStalled = true;
			
			for(uint i = 0; i< this.numThreads; i++) {
				if(!dispatchStalled[i]) {
					allStalled = false;
				}
			}
			
			if(allStalled) {
				break;
			}
			
			ReorderBufferEntry rs = this.threads[dispatchThreadId].reorderBuffer.front;
			
			if(rs is null) {
				dispatchStalled[dispatchThreadId] = true;
				dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
				continue;
			}
			
			while(!dispatchStalled[dispatchThreadId]) {
				if(rs == this.threads[dispatchThreadId].reorderBuffer.front && numSearched == 0) {
					if(!rs.isDispatched) {
						break;
					}
				}
				else if(rs is null) {
					dispatchStalled[dispatchThreadId] = true;
				}
				
				numSearched++;
				
				if(!rs.isDispatched) {
					break;
				}
				
				rs = this.threads[dispatchThreadId].reorderBuffer.after(rs);
			}
			
			if(dispatchStalled[dispatchThreadId]) {
				dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
			}
			
			if(rs.renameCycle + RENAME_DISPATCH_DELAY > Simulator.singleInstance.currentCycle) {
				dispatchStalled[dispatchThreadId] = true;
				dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
				continue;
			}
			
			numDispatched[dispatchThreadId]++;
			
			IssueQueueEntry issueQueueEntry = this.issueQueue.alloc();
			if(issueQueueEntry is null) {
				dispatchStalled[dispatchThreadId] = true;
				continue;
			}
			
			rs.dispatchCycle = Simulator.singleInstance.currentCycle;
			rs.isDispatched = true;
			
			rs.issueQueueEntry = issueQueueEntry;
			rs.inIssueQueue = true;
			
			if(rs.allOperandsSpecReady) {
				this.readyQueue ~= rs;
				rs.isQueued = true;
			}
			
			if(rs.loadStoreQueueEntry !is null) {
				ReorderBufferEntry lsq = rs.loadStoreQueueEntry;
				lsq.dispatchCycle = Simulator.singleInstance.currentCycle;
				lsq.isDispatched = true;
				
				if(lsq.uop.staticInst.isStore) {
					if(lsq.allOperandsSpecReady) {
						this.readyQueue ~= lsq;
						lsq.isQueued = true;
					}
					else {
						this.waitingQueue ~= lsq;
					}
				}
			}
			
			if(!rs.isQueued) {
				this.waitingQueue ~= rs;
			}

			numTotalDispatched++;			
		}
	}
	
	void registerRename() {
		bool[] fetchRedirected = new bool[this.numThreads];
		bool[] fetchStalled = new bool[this.numThreads];
		uint dispatchThreadId = 0;
		
		for(uint i = 0; i < this.numThreads; i++) {
			fetchRedirected[i] = false;
			fetchStalled[i] = false;
		}
		
		dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
		
		for(uint numRenamed = 0; numRenamed < this.decodeWidth;) {
			if(this.threads[dispatchThreadId].fetchQueue.empty ||
				this.threads[dispatchThreadId].reorderBuffer.full ||
				this.threads[dispatchThreadId].loadStoreQueue.full ||
				this.threads[dispatchThreadId].fetchQueue.front.fetchedCycle + FETCH_RENAME_DELAY > Simulator.singleInstance.currentCycle) {
				bool found = false;
				foreach(i, thread; this.threads) {
					if(!thread.fetchQueue.empty && !thread.reorderBuffer.full && !thread.loadStoreQueue.full
						&& thread.fetchQueue.front.fetchedCycle + FETCH_RENAME_DELAY <= Simulator.singleInstance.currentCycle
						&& !fetchStalled[i]) {
						dispatchThreadId = i;
						found = true;
						break;
					}
				}
				if(found) {
					continue;
				}
				else {
					break;
				}
			}
			
			if(this.threads[dispatchThreadId].notDispatchedCount > 
				(RENAME_DISPATCH_DELAY ? this.decodeWidth * RENAME_DISPATCH_DELAY : this.decodeWidth)) {
				fetchStalled[dispatchThreadId] = true;
			}
			
			if(fetchStalled[dispatchThreadId]) {
				bool allStalled = true;
				for(uint i = 0; i < this.numThreads; i++) {
					if(!fetchStalled[i]) {
						allStalled = false;
					}
				}
				
				if(allStalled) {
					break;
				}
				else {
					dispatchThreadId = (dispatchThreadId + 1) % this.numThreads;
					continue;
				}
			}
			
			if(fetchRedirected[dispatchThreadId]) {
				this.threads[dispatchThreadId].fetchQueue.popFront();
				continue;
			}
			
			if(this.inOrderIssue && this.lastOp !is null && !this.lastOp.allOperandsReady) {
				break;
			}
			
			DynamicInst uop = new DynamicInst(this.threads[dispatchThreadId], this.threads[dispatchThreadId].fetchQueue.front.pc, this.threads[dispatchThreadId].fetchQueue.front.staticInst);

			this.threads[dispatchThreadId].npc = this.threads[dispatchThreadId].pc + uint.sizeof;
			
			if(uop.staticInst.isTrap) {
				if(this.threads[dispatchThreadId].isSpeculative) {
					fetchStalled[dispatchThreadId] = true;
					continue;
				}
			}
			
			this.threads[dispatchThreadId].clearArchRegs();
			
			bool brTaken = this.threads[dispatchThreadId].npc != (this.threads[dispatchThreadId].pc + uint.sizeof);
			bool brPredTaken = this.threads[dispatchThreadId].predPc != (this.threads[dispatchThreadId].pc + uint.sizeof);
			
			if(uop.staticInst.isControl && uop.staticInst.isDirectJump && uop.staticInst.targetPc(uop.thread) != this.threads[dispatchThreadId].predPc && brPredTaken) {
				this.threads[dispatchThreadId].fetchPredPc = this.threads[dispatchThreadId].fetchPc = this.threads[dispatchThreadId].npc;
				fetchRedirected[dispatchThreadId] = true;
			}
			
			ReorderBufferEntry rs;
			
			if(!uop.staticInst.isNop) {
				rs = new ReorderBufferEntry(this.threads[dispatchThreadId].pc, uop);
				rs.npc = this.threads[dispatchThreadId].npc;
				rs.predPc = this.threads[dispatchThreadId].predPc;
				rs.inLoadStoreQueue = false;
				rs.loadStoreQueueEntry = null;
				rs.isEffectiveAddressComputation = false;
				rs.isRecoverInstruction = false;
				rs.dirUpdate = this.threads[dispatchThreadId].fetchQueue.front.dirUpdate;
				rs.stackRecoverIndex = this.threads[dispatchThreadId].fetchQueue.front.stackRecoverIndex;
				rs.isSpeculative = this.threads[dispatchThreadId].isSpeculative;
				rs.effectiveAddress = 0;
				rs.isReplayed = false;
				rs.inIssueQueue = rs.isDispatched = rs.isQueued = rs.isIssued = rs.isCompleted = false;
				rs.renameCycle = Simulator.singleInstance.currentCycle;
				rs.dispatchCycle = 0;
				
				foreach(i, iDep; rs.uop.staticInst.ideps) {
					rs.srcPhysRegs[i] = this.threads[dispatchThreadId].renameTable[iDep.num];
				}
				
				foreach(i, oDep; rs.uop.staticInst.odeps) {
					PhysicalRegisterFile regFile = this.getPhysicalRegisterFile(oDep.type);
					
					rs.oldPhysRegs[i] = rs.uop.thread.renameTable[oDep.num];
					rs.physRegs[i] = regFile.alloc();
					rs.uop.thread.renameTable[oDep.num] = rs.physRegs[i]; 
				}
				
				this.threads[dispatchThreadId].reorderBuffer ~= rs;
				
				if(uop.staticInst.isMem) {
					rs.isEffectiveAddressComputation = true;
					
					ReorderBufferEntry lsq = new ReorderBufferEntry(this.threads[dispatchThreadId].pc, uop);
					lsq.npc = this.threads[dispatchThreadId].npc;
					lsq.predPc = this.threads[dispatchThreadId].predPc;
					rs.loadStoreQueueEntry = lsq;
					lsq.inLoadStoreQueue = true;
					lsq.inIssueQueue = false;
					lsq.isEffectiveAddressComputation = false;
					lsq.isDispatched = false;
					lsq.isRecoverInstruction = false;
					lsq.dirUpdate.pdir1 = lsq.dirUpdate.pdir2 = null;
					lsq.dirUpdate.pmeta = null;
					lsq.stackRecoverIndex = 0;
					lsq.isSpeculative = this.threads[dispatchThreadId].isSpeculative;
					lsq.effectiveAddress = (cast(MemoryOp) uop.staticInst).ea(uop.thread);
					lsq.isReplayed = false;
					lsq.isQueued = lsq.isIssued = lsq.isCompleted = false;
					lsq.dispatchCycle = 0;
					lsq.renameCycle = Simulator.singleInstance.currentCycle;
					
					lsq.srcPhysRegs = rs.srcPhysRegs;
					lsq.physRegs = rs.physRegs;
					lsq.oldPhysRegs.clear();
					
					this.threads[dispatchThreadId].loadStoreQueue ~= rs;
				}
				
				numRenamed++;
			}
			else {
				rs = null;
			}
			
			if(!this.threads[dispatchThreadId].isSpeculative) {
				if(uop.staticInst.isControl) {
					if(this.threads[dispatchThreadId].pred !is null && this.bpredSpecUpdate == BpredSpecUpdate.ID) {
						this.threads[dispatchThreadId].pred.update(
							this.threads[dispatchThreadId].pc,
							this.threads[dispatchThreadId].npc,
							this.threads[dispatchThreadId].npc != this.threads[dispatchThreadId].pc + uint.sizeof,
							this.threads[dispatchThreadId].predPc != this.threads[dispatchThreadId].pc + uint.sizeof,
							this.threads[dispatchThreadId].predPc == this.threads[dispatchThreadId].npc,
							uop.staticInst,
							rs.dirUpdate);
					}
				}
			}
			
			if(this.threads[dispatchThreadId].predPc != this.threads[dispatchThreadId].npc) {
				this.threads[dispatchThreadId].isSpeculative = true;
				rs.isRecoverInstruction = true;
				this.threads[dispatchThreadId].recoverPc = this.threads[dispatchThreadId].npc;
			}
			
			this.threads[dispatchThreadId].fetchQueue.popFront();
		}
	}
	
	void fetch(ref uint[] sortedThreadIds) {
		bool[] done = new bool[this.numThreads];
		uint[] branchCnt = new uint[this.numThreads];
		uint fetchThreadId = sortedThreadIds[0];
		
		uint stackRecoverIndex;
		
		for(uint i = 0; i < this.numThreads; i++) {
			branchCnt[i] = 0;
			done[i] = false;
		}
		
		if(this.threads[0].fetchQueue.full) {
			sortedThreadIds[0] = sortedThreadIds[1];
			sortedThreadIds[1] = sortedThreadIds[2];
			sortedThreadIds[2] = sortedThreadIds[3];
		}
		
		if(this.threads[0].fetchQueue.full) {
			sortedThreadIds[0] = sortedThreadIds[1];
			sortedThreadIds[1] = sortedThreadIds[2];
			sortedThreadIds[2] = sortedThreadIds[3];
		}
		
		for(uint i = 0; i < this.decodeWidth * this.fetchSpeed; i++) {
			if(this.threads[fetchThreadId].fetchQueue.full) {
				if(fetchThreadId != sortedThreadIds[1]) {
					fetchThreadId = sortedThreadIds[1];
				}
				else {
					return;
				}
				i--;
				continue;
			}
			
			if(branchCnt[fetchThreadId] > 0) {
				if(fetchThreadId != sortedThreadIds[1]) {
					fetchThreadId = sortedThreadIds[1];
					if(branchCnt[fetchThreadId]) {
						return;
					}
				}
				else {
					return;
				}
				i--;
				continue;
			}
			
			if(done[fetchThreadId]) {
				if(fetchThreadId != sortedThreadIds[1]) {
					fetchThreadId = sortedThreadIds[1];
					if(done[fetchThreadId]) {
						return;
					}
				}
				else {
					return;
				}
				i--;
				continue;
			}
			
			if(this.threads[fetchThreadId].fetchIssueDelay > 0) {
				if(fetchThreadId != sortedThreadIds[1]) {
					fetchThreadId = sortedThreadIds[1];
					if(this.threads[fetchThreadId].fetchIssueDelay > 0) {
						return;
					}
				}
				else {
					return;
				}
				i--;
				continue;
			}
			
			this.threads[fetchThreadId].fetchPc = this.threads[fetchThreadId].fetchPredPc;
			
			StaticInst staticInst = this.isa.decode(this.threads[fetchThreadId].fetchPc, this.mem);
			//TODO: icache && tlb access
			
			if(this.threads[fetchThreadId].pred !is null) {
				if(staticInst.isControl) {
					this.threads[fetchThreadId].fetchPredPc =
						this.threads[fetchThreadId].pred.lookup(
							this.threads[fetchThreadId].fetchPc,
							0,
							staticInst,
							this.threads[fetchThreadId].fetchQueue.back.dirUpdate,
							stackRecoverIndex);
				}
				else {
					this.threads[fetchThreadId].fetchPredPc = 0;
				}
				
				if(this.threads[fetchThreadId].fetchPredPc == 0) {
					this.threads[fetchThreadId].fetchPredPc = this.threads[fetchThreadId].fetchPc + uint.sizeof;
				}
				else {
					branchCnt[fetchThreadId]++;
					done[fetchThreadId] = true;
				}
			}
			else {
				this.threads[fetchThreadId].fetchPredPc = this.threads[fetchThreadId].fetchPc + uint.sizeof;
			}
			
			FetchRecord fr = new FetchRecord(
				staticInst,
				this.threads[fetchThreadId].fetchPc,
				this.threads[fetchThreadId].fetchPredPc,
				stackRecoverIndex,
				Simulator.singleInstance.currentCycle);
			this.threads[fetchThreadId].fetchQueue ~= fr;
			
			if(i == (this.decodeWidth * this.fetchSpeed) / 2) {
				fetchThreadId = sortedThreadIds[1];
			}
		}
	}
	
	void icountFetch() {
		uint[] sortedThreadIds = new uint[this.numThreads];
		
		for(uint i = 0; i < this.numThreads; i++) {
			sortedThreadIds[i] = i;
		}
		
		bool greater(uint a, uint b)
		{
			return this.threads[a].stat.totalInsts > this.threads[b].stat.totalInsts;
		}

		sort!(greater)(sortedThreadIds);
		
		this.fetch(sortedThreadIds);
	}
	
	void roundRobinFetch(uint index) {
		uint[] sortedThreadIds = new uint[this.numThreads];
		
		for(uint i = 0; i < this.numThreads; i++) {
			sortedThreadIds[i] = (index + i) % this.numThreads;
		}
		
		this.fetch(sortedThreadIds);
	}
	
	void run() {
		foreach(thread; this.threads) {
			thread.commit();
		}
		
		this.releaseFunctionalUnits();
		
		this.writeback();
		
		foreach(thread; this.threads) {
			thread.refreshLoadStoreQueue();
		}
		
		this.wakeup();
		
		this.selection();
		
		this.execute();
		
		this.dispatch();
		
		this.registerRename();
		
		if(this.fetchPolicy == FetchPolicy.ICOUNT) {
			this.icountFetch();
		}
		else {
			this.roundRobinFetch(currentThreadId);
			currentThreadId = (currentThreadId + 1) % this.numThreads;
		}
		
		foreach(thread; this.threads) {
			if(thread.fetchIssueDelay > 0) {
				thread.fetchIssueDelay--;
			}
		}
	}
	
	uint currentThreadId;
	
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

	uint num;
	Processor processor;
	Thread[] threads;
	
	uint fetchSpeed;
	uint decodeWidth;
	uint issueWidth;
	
	PhysicalRegisterFile intRegFile;
	PhysicalRegisterFile fpRegFile;
	PhysicalRegisterFile miscRegFile;
	
	WaitingQueue waitingQueue;
	ReadyQueue readyQueue;
	IssueQueue issueQueue;
	IssueExecQueue issueExecQueue;
	OoOEventQueue eventQueue;
	FunctionalUnitPool fuPool;
	
	bool inOrderIssue;
	ReorderBufferEntry lastOp;
	FetchPolicy fetchPolicy;
	
	BpredSpecUpdate bpredSpecUpdate;
	
	ISA isa;
}

enum ThreadState {
	Inactive,
	Active,
	Halted
}

class Thread {
	this(Simulation simulation, uint num, string name, Process process) {
		this.num = num;
		
		this.name = name;
		
		this.process = process;
		
		this.syscallEmul = new SyscallEmul();

		this.pred = new CombinedBpred();

		this.clearArchRegs();

		this.process.load(this);
		
		this.commitWidth = 4;
		
		this.fetchQueue = new FetchQueue();
		this.reorderBuffer = new ReorderBuffer();
		this.loadStoreQueue = new LoadStoreQueue();
		
		this.isSpeculative = false;
		
		this.stat = new ThreadStat(this.num);
		simulation.stat.processorStat.threadStats ~= this.stat;
		
		this.state = ThreadState.Active;
	}
	
	void recoverReorderBuffer(ReorderBufferEntry branchRs) {
		ReorderBufferEntry[] toSquash;
			
		foreach_reverse(rs; this.reorderBuffer) {
			if(rs != branchRs) {
				if(rs.isEffectiveAddressComputation) {
					this.loadStoreQueue.remove(rs);
				}
				
				toSquash ~= rs;
				
				if(rs.inIssueQueue) {
					this.core.issueQueue.remove(rs.issueQueueEntry);
					rs.inIssueQueue = false;
				}
				
				foreach(i, physReg; rs.physRegs) {
					PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
					regFile[physReg].state = PhysicalRegisterState.FREE;
				}
				
				foreach(i, oDep; rs.uop.staticInst.odeps) {
					this.renameTable[oDep.num] = rs.oldPhysRegs[i];
				}
				
				rs.physRegs.clear();
			}
			else {
				break;
			}
		}
		
		foreach(rs; toSquash) {
			this.reorderBuffer.remove(rs);
		}
	}
	
	void commit() {
		if(Simulator.singleInstance.currentCycle - this.lastCommitCycle > COMMIT_TIMEOUT) {
			logging.fatal(LogCategory.SIMULATOR, "No instruction committed in one million cycles.");
		}
		
		for(uint numCommitted = 0; !this.reorderBuffer.empty && numCommitted < this.commitWidth;) {
			ReorderBufferEntry rs = this.reorderBuffer.front;

			if(!rs.isCompleted) {
				break;
			}
			
			if(rs.isEffectiveAddressComputation) {
				if(!this.loadStoreQueue.front.isCompleted) {
					break;
				}
				
				if(this.loadStoreQueue.front.uop.staticInst.isStore) {					
					FunctionalUnit fu = this.core.fuPool.getFree(this.loadStoreQueue.front.uop.staticInst.fuType);
					
					if(fu !is null) {
						fu.master.busy = fu.issueLat;
	
						assert(0);
						/* TODO: go to the data cache */
						
						assert(0);
						/* TODO: all loads and stores must to access D-TLB */						
					}
					else {
						break;
					}
				}
				
				this.loadStoreQueue.popFront();
			}
			
			if(this.pred !is null && this.core.bpredSpecUpdate == BpredSpecUpdate.ID && rs.uop.staticInst.isControl) {
				this.pred.update(
					rs.pc,
					rs.npc,
					rs.npc != (rs.pc + uint.sizeof),
					rs.predPc != (rs.pc + uint.sizeof),
					rs.predPc == rs.npc,
					rs.uop.staticInst,
					rs.dirUpdate
				);
			}
			
			foreach(i, oldPhysReg; rs.oldPhysRegs) {
				PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
				regFile[oldPhysReg].state = PhysicalRegisterState.FREE;
			}
			
			foreach(i, physReg; rs.physRegs) {
				PhysicalRegisterFile regFile = this.core.getPhysicalRegisterFile(rs.uop.staticInst.odeps[i].type);
				regFile[physReg].state = PhysicalRegisterState.ARCH;
			}
			
			this.reorderBuffer.popFront();
			
			this.stat.totalInsts++;
			
			this.lastCommitCycle = Simulator.singleInstance.currentCycle;
		}
	}
	
	void refreshLoadStoreQueue() {
		uint[] stdUnknowns;
		
		foreach(rs; this.loadStoreQueue) {
			if(rs.uop.staticInst.isStore) {
				if(!rs.storeAddressReady) {
					break;
				}
				else if (!rs.allOperandsSpecReady) {
					stdUnknowns ~= rs.effectiveAddress;
				}
				else {
					foreach(ref addr; stdUnknowns) {
						if(addr == rs.effectiveAddress) {
							addr = 0;
						}
					}
				}
			}
			else if(rs.uop.staticInst.isLoad && rs.isDispatched && rs.allOperandsSpecReady) {
				if(stdUnknowns.count(rs.effectiveAddress) == 0) {
					this.core.readyQueue ~= rs;
					rs.isQueued = true;
				}
			}
		}
	}
	
	uint notDispatchedCount() {		
		uint count = 0;
		
		foreach(rs; this.reorderBuffer) {
			if(!rs.isDispatched) {
				count++;
			}
		}
		
		return count;
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
	
	uint predPc;
	uint recoverPc;
	uint fetchPc;
	uint fetchPredPc;

	Bpred pred;

	bool fetchStalled;
	uint fetchBlock;
	
	uint[] renameTable;
	
	uint commitWidth;

	FetchQueue fetchQueue;
	ReorderBuffer reorderBuffer;
	LoadStoreQueue loadStoreQueue;
	
	ulong lastCommitCycle;
	
	bool isSpeculative;
	
	uint fetchIssueDelay;
	
	ThreadState state;
	
	ThreadStat stat;
	
	static const uint COMMIT_TIMEOUT = 1000000;
}
