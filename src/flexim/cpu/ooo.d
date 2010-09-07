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

	FunctionalUnit[] x;
}

class FunctionalUnitPool {
	this() {		
		FunctionalUnitCategory categoryIntegerAlu =
			new FunctionalUnitCategory("integer-ALU", 4, 0);
		categoryIntegerAlu.x ~=
			new FunctionalUnit(categoryIntegerAlu, FunctionalUnitType.IntALU, 1, 1);
			
		FunctionalUnitCategory categoryIntegerMultDiv =
			new FunctionalUnitCategory("integer-MULT/DIV", 1, 0);
		categoryIntegerMultDiv.x ~=
			new FunctionalUnit(categoryIntegerMultDiv, FunctionalUnitType.IntMULT, 3, 1);
		categoryIntegerMultDiv.x ~=
			new FunctionalUnit(categoryIntegerMultDiv, FunctionalUnitType.IntDIV, 20, 19);
			
		FunctionalUnitCategory categoryMemoryPort =
			new FunctionalUnitCategory("memory-port", 2, 0);
		categoryMemoryPort.x ~=
			new FunctionalUnit(categoryMemoryPort, FunctionalUnitType.RdPort, 1, 1);
		categoryMemoryPort.x ~=
			new FunctionalUnit(categoryMemoryPort, FunctionalUnitType.WrPort, 1, 1);
			
		FunctionalUnitCategory categoryFPAdder =
			new FunctionalUnitCategory("FP-adder", 4, 0);
		categoryFPAdder.x ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatADD, 2, 1);
		categoryFPAdder.x ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatCMP, 2, 1);
		categoryFPAdder.x ~=
			new FunctionalUnit(categoryFPAdder, FunctionalUnitType.FloatCVT, 2, 1);
				
		FunctionalUnitCategory categoryFPMultDiv =
			new FunctionalUnitCategory("FP-MULT/DIV", 1, 0);
		categoryFPMultDiv.x ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatMULT, 4, 1);
		categoryFPMultDiv.x ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatDIV, 12, 12);
		categoryFPMultDiv.x ~=
			new FunctionalUnit(categoryFPMultDiv, FunctionalUnitType.FloatSQRT, 24, 24);
		
		this.categories ~= categoryIntegerAlu;
		this.categories ~= categoryIntegerMultDiv;
		this.categories ~= categoryMemoryPort;
		this.categories ~= categoryFPAdder;
		this.categories ~= categoryFPMultDiv;
	}
	
	FunctionalUnit getFree(FunctionalUnitType fuType) {
		assert(0);
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
		this.state = PhysicalRegisterState.FREE;
	}
	
	ulong readyCycle;
	ulong specReadyCycle;
	PhysicalRegisterState state;
}

class PhysicalRegisterFile {
	this() {
		this(1024);
	}
	
	this(uint capacity) {
		this.capacity = capacity;
		
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
	
	PhysicalRegister opIndex(uint index) {
		return this.entries[index];
	}
	
	void opIndexAssign(PhysicalRegister value, uint index) {
		this.entries[index] = value;
	}
	
	uint capacity;
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
	this(StaticInst staticInst, uint regsPc, uint predPc, BpredUpdate dirUpdate, int stackRecoverIndex, ulong fetchedCycle) {
		this.staticInst = staticInst;
		this.regsPc = regsPc;
		this.predPc = predPc;
		this.dirUpdate = dirUpdate;
		this.stackRecoverIndex = stackRecoverIndex;
		this.fetchedCycle = fetchedCycle;
	}

	override string toString() {
		return format("FetchRecord");
	}

	StaticInst staticInst;
	uint regsPc, predPc;
	BpredUpdate dirUpdate;
	int stackRecoverIndex;
	ulong fetchedCycle;
}

class FetchQueue: Queue!(FetchRecord) { //FIFO Queue
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
		
		this.isRecoverInst = false;
		//this.stackRecoverIndex = -1; //TODO
		
		this.isSpeculative = false;
		
		this.dispatched = false;
		this.queued = false;
		this.issued = false;
		this.completed = false;
		this.replayed = false;
		
		this.execLat = 0; //TODO: correct?
		
		this.renameCycle = 0; //TODO: correct?
		this.dispatchCycle = 0; //TODO: correct?
	}
	
	bool storeAddressReady() {
		assert(0);
	}
	
	bool operandReady(uint opNum) {
		assert(0);
	}
	
	bool operandSpecReady(uint opNum) {
		assert(0);
	}
	
	bool allOperandsReady() {
		assert(0);
	}
	
	bool oneOperandReady() {
		assert(0);
	}
	
	bool allOperandsSpecReady() {
		assert(0);
	}

	ulong id;

	DynamicInst uop;
	uint pc, npc, predPc;
	
	bool inLoadStoreQueue;
	bool inIssueQueue;
	
	bool isEffectiveAddressComputation;
	uint effectiveAddress;
	
	bool isRecoverInst;
	uint stackRecoverIndex;
	BpredUpdate dirUpdate;
	
	bool isSpeculative;
	
	bool dispatched;
	bool queued;
	bool issued;
	bool completed;
	bool replayed;
	
	uint[] physRegs;
	uint[] oldPhysRegs;
	uint[] srcPhysregs;
	
	uint execLat;
	
	ulong renameCycle;
	ulong dispatchCycle;
	
	IssueQueueEntry issueQueueEntry;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class WaitingQueue: Queue!(ReorderBufferEntry) { //FIFO Queue
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("waitingQueue", capacity);
	}
}

class ReadyQueue: Queue!(ReorderBufferEntry) { //FIFO Queue
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("readyQueue", capacity);
	}
}

class IssueExecQueue: Queue!(ReorderBufferEntry) { //FIFO Queue
	this() {
		this(80);
	}
	
	this(uint capacity) {
		super("issueExecQueue", capacity);
	}
}

class ReorderBuffer: Queue!(ReorderBufferEntry) { //Circular Buffer
	this() {
		this(16);
	}
	
	this(uint capacity) {
		super("reorderBuffer", capacity);
	}
}

class LoadStoreQueue: Queue!(ReorderBufferEntry) { //Circular Buffer
	this() {
		this(8);
	}
	
	this(uint capacity) {
		super("loadStoreQueue", capacity);
	}
}

class OoOEventQueue: Queue!(ReorderBufferEntry), EventProcessor { //Priority queue
	this() {
		this(1024);
	}
	
	this(uint capacity) {
		super("eventQueue", capacity);
		
		this.eventQueue = new DelegateEventQueue();
	}
	
	void enqueue(ReorderBufferEntry rs, ulong delay) {
		this.eventQueue.schedule({this ~= rs;}, delay);
	}
	
	override void processEvents() {
		this.eventQueue.processEvents();
	}
	
	DelegateEventQueue eventQueue;
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
		
		this.intRegFile = new PhysicalRegisterFile();
		this.fpRegFile = new PhysicalRegisterFile();
		this.miscRegFile = new PhysicalRegisterFile();
		
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
			rs.completed = true;

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
			
			if(rs.isRecoverInst) {
				if(rs.inLoadStoreQueue) {
					assert(0);
				}
				
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
				rs.queued = true;
			}
			else {
				toWaitq ~= rs;
			}
			
			this.waitingQueue.popFront();
		}
		
		assert(this.waitingQueue.empty); //TODO: temporarily added, to remove
		
		foreach(rs; toWaitq) {
			this.waitingQueue ~= rs;
		}
	}
	
	void selection() {
		ReorderBufferEntry[] toReadyq;
		
		for(uint numIssued = 0; !this.readyQueue.empty && numIssued < this.issueWidth; numIssued++) {
			ReorderBufferEntry rs = this.readyQueue.front;

			rs.queued = false;
			
			if(rs.inLoadStoreQueue && rs.uop.staticInst.isStore) {
				rs.issued = true;
				rs.completed = true;
			}
			else {
				if(rs.uop.staticInst.fuType != FunctionalUnitType.NONE) {
					FunctionalUnit fu = this.fuPool.getFree(rs.uop.staticInst.fuType);
					if(fu !is null) {
						rs.issued = true;
						
						fu.master.busy = fu.issueLat;
						
						if(rs.inLoadStoreQueue && rs.uop.staticInst.isLoad) {
							uint loadLat = 0;

							assert(0);
							/* TODO: for loads, determine cache access latency:
							   first scan LSQ to see if a store forward is
							   possible, if not, access the data cache */
							
							if(loadLat == 0) {
								assert(0);
								/* TODO: no! go to the data cache if addr is valid */
								
							}
							
							assert(0);
							/* TODO: all loads and stores must to access D-TLB */
							
							rs.execLat = loadLat;
		
							assert(0);
							this.issueExecQueue ~= rs; //TODO
							
							assert(0);
							//TODO
						}
						else {
							rs.execLat = fu.opLat;
							assert(0);
							this.issueExecQueue ~= rs; //TODO
							
							assert(0);
							//TODO: memory accesses are woken up differently via the LSQ
						}
					}
					else {
						toReadyq ~= rs;
					}
				}
				else {
					rs.issued = true;
					
					rs.execLat = 1;
					assert(0);
					this.issueExecQueue ~= rs; //TODO
					
					assert(0);
					/* TODO: wakeup dependents */
				}
			}
			
			this.readyQueue.popFront();
		}
		
		assert(this.readyQueue.empty);
		
		foreach(rs; toReadyq) {
			this.readyQueue ~= rs;
			rs.queued = true;
		}
	}
	
	void execute() {		
		while(!this.issueExecQueue.empty) {
			ReorderBufferEntry rs = this.issueExecQueue.front;
			
			if(!rs.allOperandsSpecReady) {
				foreach(i, srcPhysReg; rs.srcPhysregs) {
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
					
					rs.issued = false;
					rs.replayed = true;
					
					if(!rs.uop.staticInst.isLoad) {
						this.waitingQueue ~= rs; //TODO
					}
					
					rs = null;
					
					//TODO
				}
			}
			
			this.eventQueue.enqueue(rs, rs.execLat);
			
			if(rs.inIssueQueue) {
				assert(0);
				//this.iq.remove(rs); //TODO: uncomment it
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
		
		dispatchThreadId = (dispatchThreadId + 1) % this.numThreads; //TODO: necessary?
		
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
	
			assert(0);
			/* TODO: find the next instruction awaiting dispatch */
			
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
			rs.dispatched = true;
			
			rs.issueQueueEntry = issueQueueEntry;
			rs.inIssueQueue = true;
			
			if(rs.allOperandsSpecReady) {
				this.readyQueue ~= rs;
				rs.queued = true;
			}
			
			assert(0);
			//TODO
			
			if(!rs.queued) {
				assert(0);
				this.waitingQueue ~= rs; //TODO
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
			
			assert(0);
			/* TODO: get the next instruction from the IFETCH -> RENAME queue */
			
			assert(0);
			/* TODO: decode the inst */

			this.threads[dispatchThreadId].npc = this.threads[dispatchThreadId].pc + uint.sizeof;
			
			/*if(uop.isTrap) { //TODO
				if(this.threads[dispatchThreadId].isSpeculative) {
					fetchStalled[dispatchThreadId] = true;
					continue;
				}
			}*/
			
			this.threads[dispatchThreadId].clearArchRegs();
			
			assert(0);
			//TODO:................................
			
			numRenamed++;
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
			
			bool bogus = false; //TODO
			
			StaticInst staticInst = null;
			
			if(!bogus) {
				staticInst = this.isa.decode(this.threads[fetchThreadId].fetchPc, this.mem);
				//TODO
			}
			else {
				//inst = NOP; //TODO
			}
			
			assert(staticInst !is null); //TODO: temporarily added; to remove
			
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
				null, //TODO
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
		this.loadLatPred = new CombinedBpred();

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
	
	void recoverReorderBuffer(ReorderBufferEntry rs) {
		assert(0);
	}
	
	void commit() {
		if(Simulator.singleInstance.currentCycle - this.lastCommitCycle > COMMIT_TIMEOUT) {
			logging.fatal(LogCategory.SIMULATOR, "No instruction committed in one million cycles.");
		}
		
		for(uint numCommitted = 0; !this.reorderBuffer.empty && numCommitted < this.commitWidth;) {
			ReorderBufferEntry rs = this.reorderBuffer.front;

			if(!rs.completed) {
				break;
			}
			
			if(rs.isEffectiveAddressComputation) {
				if(this.loadStoreQueue.front.uop.staticInst.isStore) {
					assert(0); //TODO: in commit()
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
			
			assert(0); //TODO: handle register deallocations
			
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
			else if(rs.uop.staticInst.isLoad && rs.dispatched && rs.allOperandsSpecReady) {
				if(stdUnknowns.count(rs.effectiveAddress) == 0) {
					this.core.readyQueue ~= rs;
					rs.queued = true;
				}
			}
		}
	}
	
	uint notDispatchedCount() {		
		uint count = 0;
		
		foreach(rs; this.reorderBuffer) {
			if(!rs.dispatched) {
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
	Bpred loadLatPred; 

	bool fetchStalled;
	uint fetchBlock;
	
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
