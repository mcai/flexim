/*
 * flexim/cpu/ooo/pipelines.d
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

module flexim.cpu.ooo.pipelines;

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
	this(Core core, Simulation simulation, uint num, Process process) {
		this.core = core;
		
		this.num = num;
		
		this.process = process;
		
		this.syscallEmul = new SyscallEmul();

		this.bpred = new CombinedBpred();

		this.clearArchRegs();

		this.process.load(this);
		
		this.commitWidth = 4;
		
		this.stat = new ThreadStat(this.num);
		simulation.stat.processorStat.threadStats ~= this.stat;
		
		this.state = ThreadState.Active;
		
		for(uint i = 0; i < NumIntRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumIntRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTables[RegisterDependencyType.INT][i] = physReg;
		}
		
		for(uint i = 0; i < NumFloatRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumFloatRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTables[RegisterDependencyType.FP][i] = physReg;
		}
		
		for(uint i = 0; i < NumMiscRegs; i++) {
			PhysicalRegister physReg = this.core.intRegFile[this.num * NumMiscRegs + i];
			physReg.state = PhysicalRegisterState.ARCH;
			this.renameTables[RegisterDependencyType.MISC][i] = physReg;
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
			
			if(!this.isSpeculative) {
				if(this.npc != this.fetchNpc) {
					this.isSpeculative = true;
					decodeBufferEntry.isRecoverInst = true;
				}
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
						foreach(i, oDep; readyQueueEntry.oDeps) {
							readyQueueEntry.physRegs[i].state = PhysicalRegisterState.WB;
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
								readyQueueEntry.physRegs[i].state = PhysicalRegisterState.WB;
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
				
				foreach(i, oDep; loadStoreQueueEntry.oDeps) {
					loadStoreQueueEntry.oldPhysRegs[i].state = PhysicalRegisterState.FREE;
					loadStoreQueueEntry.physRegs[i].state = PhysicalRegisterState.ARCH;
				}
				
				this.loadStoreQueue.popFront();
			}
			
			foreach(i, oDep; reorderBufferEntry.oDeps) {
				reorderBufferEntry.oldPhysRegs[i].state = PhysicalRegisterState.FREE;
				reorderBufferEntry.physRegs[i].state = PhysicalRegisterState.ARCH;
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

			this.stat.totalInsts++;
			
			this.lastCommitCycle = Simulator.singleInstance.currentCycle;
			
			//logging.infof(LogCategory.DEBUG, "t%s one instruction committed (dynamicInst=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, 
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
			
			foreach(i, oDep; reorderBufferEntry.dynamicInst.staticInst.oDeps) {
				reorderBufferEntry.physRegs[i].state = PhysicalRegisterState.FREE;
				this.renameTables[oDep.type][oDep.num] = reorderBufferEntry.oldPhysRegs[i];
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
		if(this.state != ThreadState.Halted) {
			logging.infof(LogCategory.SIMULATOR, "target called exit(%d)", exitCode);
			this.state = ThreadState.Halted;
			this.core.processor.activeThreadCount--;
			
			assert(0); //TODO: should stop thread from running!!
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
	
	PhysicalRegister[uint][RegisterDependencyType] renameTables;
	
	uint commitWidth;
	ulong lastCommitCycle;
	
	ThreadState state;
	
	ThreadStat stat;
	
	DecodeBuffer decodeBuffer;
	ReorderBuffer reorderBuffer;
	LoadStoreQueue loadStoreQueue;
	
	bool isSpeculative;
	
	static const uint COMMIT_TIMEOUT = 1000000;
}