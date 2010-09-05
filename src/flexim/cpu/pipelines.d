/*
 * flexim/cpu/pipelines.d
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

module flexim.cpu.pipelines;

import flexim.all;

import core.stdc.errno;

class FU {
	this(FUCategory master, FUType fuType, uint opLat, uint issueLat) {
		this.master = master;
		this.fuType = fuType;
		this.opLat = opLat;
		this.issueLat = issueLat;
	}

	override string toString() {
		return format("%s[master=%s, fuType=%s, opLat=%d, issueLat=%d]", "FU", this.master.name, to!(string)(this.fuType), this.opLat, this.issueLat);
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
		return format("%s[name=%s, quantity=%d, busy=%d]", "FUCategory", this.name, this.quantity, this.busy);
	}

	string name;
	uint quantity;
	uint busy;

	FU[] x;
}

const uint STORE_ADDR_INDEX = 0;
const uint STORE_OP_INDEX = 1;

class Link(LinkT, EntryT) {
	this(string name, EntryT entry) {
		this.name = name;
		this.entry = entry;
		this.next = null;
	}

	string name;

	EntryT entry;
	LinkT next;
}

class FetchRecord {
	this(uint pc, DynamicInst uop) {
		this.pc = pc;
		this.uop = uop;
	}

	override string toString() {
		return format("FetchRecord[uop=%s]", uop);
	}

	uint pc;
	DynamicInst uop;
}

enum RUUStationState : string {
	FETCHED = "FETCHED",
	READY = "READY",
	ISSUED = "ISSUED",
	COMPLETED = "COMPLETED"
}

class RUUStation {
	this(uint pc, DynamicInst uop) {
		this.id = ++currentId;
		
		this.pc = pc;
		this.uop = uop;

		this.inLsq = false;
		this.eaComp = false;
		this.ea = 0;

		this.state = RUUStationState.FETCHED;
	}

	bool storeAddrReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.uop.staticInst));		
		assert(memOp !is null);		
		return !(memOp.memSrcRegIdx[STORE_ADDR_INDEX] in this.ideps);
	}

	bool storeOpReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.uop.staticInst));		
		assert(memOp !is null);		
		return !(memOp.memSrcRegIdx[STORE_OP_INDEX] in this.ideps);
	}

	bool operandsReady() {
		return this.ideps.length == 0;
	}

	override string toString() {
		string str;
		
		str ~= format("RUUStation[uop=%s, inLsq=%s, eaComp=%s, ea=%d, id=%d, state=%s, operandsReady=%s]",
				this.uop, this.inLsq, this.eaComp, this.ea, this.id, this.state, this.operandsReady);
		
		if(this.uop.isStore) {
			str ~= format("\n     storeOpReady=%s, operandsReady=%s", this.storeOpReady, this.operandsReady);
		}
		
		foreach(i, idep; this.ideps) {
			str ~= format("\n     ideps[%d]=%s\n", i, to!(string)(idep));
		}
		
		return str;
	}

	ulong id;

	uint pc;
	DynamicInst uop;
	bool inLsq;
	bool eaComp;
	uint ea;

	RUUStationState state;

	RUUStation[uint] ideps;
	uint[MAX_ODEPS] onames;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class RegisterDependency {
	this(uint regName, RUUStation creator) {
		this.regName = regName;
		this.creator = creator;
	}

	bool ready() {
		return this.creator is null;
	}

	uint regName;
	RUUStation creator;
	RUUStation[] dependents;
}

class IFQ: Queue!(FetchRecord) {
	this(string name) {
		super(name, 4);
	}
}

class ReadyQ: Queue!(RUUStation) {
	this(string name) {
		super(name, 80);
	}
}

class RUU: Queue!(RUUStation) {
	this(string name) {
		super(name, 16);
	}
}

class LSQ: Queue!(RUUStation) {
	this(string name) {
		super(name, 8);
	}
}

class EventQ: Queue!(RUUStation), EventProcessor {
	this(string name) {
		super(name, 1024);
		
		this.eventQueue = new DelegateEventQueue();
	}
	
	void enqueue(RUUStation rs, ulong delay) {
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
			
			this.activeThreadCount = 0;
		}

		Core core(string name) {
			if(name in this.cores) {
				return this.cores[name];
			}

			return null;
		}

		void addCore(Core core) {
			this.cores[core.name] = core;
			this.cores[core.name].processor = this;
		}

		void removeCore(Core core) {
			if(core.name in this.cores) {
				this.cores[core.name].processor = null;
				this.cores.remove(core.name);
			}
		}
		
		void commit() {
			foreach(core; this.cores) {
				core.commit();
			}
		}
		
		void writeback() {
			foreach(core; this.cores) {
				core.writeback();
			}
		}
		
		void issue() {
			foreach(core; this.cores) {
				core.issue();
			}
		}
		
		void dispatch() {
			foreach(core; this.cores) {
				core.dispatch();
			}
		}
		
		void decode() {
			foreach(core; this.cores) {
				core.decode();
			}
		}
		
		void fetch() {
			foreach(core; this.cores) {
				core.fetch();
			}
		}
		
		bool canRun() {
			return this.activeThreadCount > 0;
		}

		void run() {
			this.commit();
			this.writeback();
			this.issue();
			this.dispatch();
			this.decode();
			this.fetch();
		}

		CPUSimulator simulator;
		string name;
		Core[string] cores;
		
		int activeThreadCount;
}

class Core {
	this(string name) {
		this.name = name;
		
		this.eventq = new EventQ("EventQ" ~ "-" ~ this.name);
		Simulator.singleInstance.addEventProcessor(this.eventq);
	}

	void addThread(Thread thread) { //TODO: merge with this.threads ~= thread
		thread.core = this;
		this.threads ~= thread;
	}
	
	void commit() {
		foreach(thread; this.threads) { //TODO: commit width
			thread.commit();
		}
	}
	
	void writeback() {
		while(!this.eventq.empty) {
			RUUStation rs = this.eventq.front;
			rs.state = RUUStationState.COMPLETED;

			rs.uop.thread.clearRegDeps(rs);

			this.eventq.popFront();
		}
	}
	
	void issue() {
		foreach(thread; this.threads) { //TODO: issue width
			thread.issueIq();
			thread.issueLsq();
		}
	}
	
	void dispatch() {
		foreach(thread; this.threads) { //TODO: dispatch width
			thread.dispatch();
		}
	}
	
	void decode() {
		foreach(thread; this.threads) {
			thread.decode();
		}
	}
	
	void fetch() {
		foreach(thread; this.threads) {
			if(thread.canFetch) {
				thread.fetch();
			}
		}
	}

	string name;
	Processor processor;
	Thread[] threads;
	
	EventQ eventq;
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

		this.mem = new Memory();
		
		this.isa = new MipsISA();
		
		this.syscallEmul = new SyscallEmul();

		this.bpred = new CombinedBpred();

		this.clearArchRegs();

		this.process.load(this);

		this.setFetchNpcFromNpc();
		this.setFetchNnpcFromNnpc();

		this.fetchq = new IFQ("IFQ" ~ "-" ~ this.name);
		this.readyq = new ReadyQ("ReadyQ" ~ "-" ~ this.name);
		this.ruu = new RUU("RUU" ~ "-" ~ this.name);
		this.lsq = new LSQ("LSQ" ~ "-" ~ this.name);

		this.fetchWidth = 4;
		this.decodeWidth = 4;
		this.issueWidth = 4;
		this.commitWidth = 4;
		
		this.stat = new ThreadStat(this.num);
		simulation.stat.processorStat.threadStats ~= this.stat;
		
		this.state = ThreadState.Active;
	}
	
	void commit() {
		for(uint numCommitted = 0; !this.ruu.empty && numCommitted < this.commitWidth; ) {
			RUUStation rs = this.ruu.front;

			if(rs.state != RUUStationState.COMPLETED) {
				break;
			}

			if(rs.eaComp) {
				if(this.lsq.front.state != RUUStationState.COMPLETED) {
					break;
				}

				this.lsq.popFront();
			}

			this.ruu.popFront();

			this.stat.totalInsts++;

			//logging.infof(LogCategory.DEBUG, "t%s one instruction committed (uop=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, rs.uop);
		}
	}
	
	void issueIq() {
		for(uint numIssued = 0; !this.readyq.empty && numIssued < this.issueWidth; numIssued++) {
			RUUStation rs = this.readyq.front;

			if(rs.inLsq && rs.uop.isStore) {
				uint ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);
				
				this.seqD.store(this.mmu.translate(ea), false, {});

				rs.state = RUUStationState.COMPLETED;
				this.readyq.popFront();
			} else if(rs.inLsq && rs.uop.isLoad) {
				uint ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);
				
				this.seqD.load(this.mmu.translate(ea), false, rs, 
					(RUUStation rs)
					{
						this.core.eventq.enqueue(rs, 1);
					});
				
				rs.state = RUUStationState.ISSUED;
				this.readyq.popFront();
			} else {
				this.core.eventq.enqueue(rs, 1);

				rs.state = RUUStationState.ISSUED;
				this.readyq.popFront();
			}
		}
	}
	
	void issueLsq() {
		uint[] stdUnknowns;

		foreach(rs; this.lsq) {
			if(rs.uop.isStore) {
				if(!rs.storeAddrReady) {
					break;
				} else if(!rs.operandsReady) {
					stdUnknowns ~= rs.ea;
				} else {
					foreach(ref addr; stdUnknowns) {
						if(addr == rs.ea) {
							addr = 0;
						}
					}
				}
			} else if(rs.uop.isLoad && rs.state == RUUStationState.FETCHED && rs.operandsReady) {
				if(count(stdUnknowns, rs.ea) == 0) {
					this.readyq ~= rs;
					rs.state = RUUStationState.READY;
				}
			}

			//////TODO remove below
			if(rs.state == RUUStationState.FETCHED && rs.operandsReady) {
				this.readyq ~= rs;
				rs.state = RUUStationState.READY;
			}
			//////TODO remove above
		}

		//////TODO remove below
		foreach(rs; this.ruu) {
			if(rs.state == RUUStationState.FETCHED && rs.operandsReady) {
				this.readyq ~= rs;
				rs.state = RUUStationState.READY;
			}
		}
		//////TODO remove above
	}

	void linkIdep(RUUStation rs, uint idepNum, uint idepName) {
		if(idepName != ZeroReg && idepName in this.regDeps) {
			rs.ideps[idepName] = this.regDeps[idepName].creator;
			this.regDeps[idepName].dependents ~= rs;
		}
	}

	void installOdep(RUUStation rs, uint odepNum, uint odepName) {
		if(odepName == ZeroReg) {
			rs.onames[odepNum] = ZeroReg;
		} else {
			rs.onames[odepNum] = odepName;
			this.regDeps[odepName] = new RegisterDependency(odepName, rs);
		}
	}

	void clearRegDeps(RUUStation rs) {
		foreach(i, oname; rs.onames) {
			if(oname != ZeroReg) {
				if(oname in this.regDeps) {
					foreach(dependent; this.regDeps[oname].dependents) {
						dependent.ideps.remove(oname);

						if(dependent.operandsReady) {
							if(!dependent.inLsq || dependent.uop.isStore) {
								this.readyq ~= dependent; //TODO: uncomment it
								dependent.state = RUUStationState.READY;
							}
						}
					}

					//////TODO remove below
					foreach(lsq; this.lsq) {
						if(oname in lsq.ideps) {
							lsq.ideps.remove(oname);
						}
					}
					//////TODO remove above

					//////TODO remove below
					foreach(ruu; this.ruu) {
						if(oname in ruu.ideps) {
							ruu.ideps.remove(oname);
						}
					}
					//////TODO remove above

					this.regDeps.remove(oname);
				}
			}
		}
	}
	
	void dispatch() {
		for(uint numDispatched = 0; numDispatched < this.fetchWidth && !this.ruu.full && !this.lsq.full && !this.fetchq.empty; ) {
			FetchRecord fr = this.fetchq.front;

			this.intRegs[ZeroReg] = 0;

			uint pc = fr.pc;
			DynamicInst uop = fr.uop;

			if(!uop.isNop) {
				RUUStation rs = new RUUStation(pc, uop);
				this.ruu ~= rs;

				if(uop.isMem) {
					rs.eaComp = true;

					RUUStation rsMem = new RUUStation(pc, uop);
					rsMem.eaComp = false;
					rsMem.ea = (cast(MemoryOp) uop.staticInst).ea(this);

					this.lsq ~= rsMem;
					rsMem.inLsq = true;

					foreach(i, idep; (cast(MemoryOp) uop.staticInst).eaSrcRegIdx) {
						this.linkIdep(rs, i, idep);
					}

					foreach(i, odep; (cast(MemoryOp) uop.staticInst).eaDestRegIdx) {
						this.installOdep(rs, i, odep);
					}

					foreach(i, idep; (cast(MemoryOp) uop.staticInst).memSrcRegIdx) {
						this.linkIdep(rsMem, i, idep);
					}

					foreach(i, odep; (cast(MemoryOp) uop.staticInst).memDestRegIdx) {
						this.installOdep(rsMem, i, odep);
					}

					if(rs.operandsReady) {
						this.readyq ~= rs;
						rs.state = RUUStationState.READY;
					}

					if(uop.isStore && rsMem.operandsReady) {
						this.readyq ~= rsMem;
						rsMem.state = RUUStationState.READY;
					}
				} else {
					foreach(i, idep; uop.staticInst.srcRegIdx) {
						this.linkIdep(rs, i, idep);
					}

					foreach(i, odep; uop.staticInst.destRegIdx) {
						this.installOdep(rs, i, odep);
					}

					if(rs.operandsReady) {
						this.readyq ~= rs;
						rs.state = RUUStationState.READY;
					}
				}
			}

			numDispatched++;

			this.fetchq.popFront();
		}
	}
	
	void decode() {
		//TODO: split fetch and decode operations
	}

	DynamicInst fetchAndDecodeAt(uint pc) {		
		StaticInst staticInst = this.isa.decode(pc, this.mem);
		return new DynamicInst(this, pc, staticInst);
	}
	
	bool canFetch() {
		return this.state == ThreadState.Active && !this.fetchStalled;
	}
	
	void fetch() {
		uint block = aligned(this.fetchNpc, this.seqI.blockSize);

		if(block != this.fetchBlock) {
			this.fetchBlock = block;
			
			this.seqI.load(this.mmu.translate(this.fetchNpc), false, 
				{
					this.fetchStalled = false;
				});
			
			this.fetchStalled = true;
		}

		for(uint i = 0; i < this.fetchWidth; i++) {
			if(this.fetchq.full || !this.canFetch || aligned(this.fetchNpc, this.seqI.blockSize) != block) {
				break;
			}
			this.fetchPc = this.fetchNpc;
			this.fetchNpc = this.fetchNnpc;

			DynamicInst uop = this.fetchAndDecodeAt(this.fetchPc);

			this.setNpcFromFetchNpc();

			this.pc = this.npc;
			this.npc = this.nnpc;
			this.nnpc += uint.sizeof;

			uop.execute();

			this.setFetchNpcFromNpc();
			this.setFetchNnpcFromNnpc();

			FetchRecord fr = new FetchRecord(uop.pc, uop);
			this.fetchq ~= fr;
		}
	}
	
	void setFetchNpcFromNpc() {
		this.fetchNpc = this.npc;
	}
	
	void setFetchNnpcFromNnpc() {
		this.fetchNnpc = this.nnpc;
	}
	
	void setNpcFromFetchNpc() {
		this.npc = this.fetchNpc;
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

	Sequencer seqI() {
		return this.core.processor.simulator.memorySystem.seqIs[this.num];
	}
	
	CoherentCacheNode l1I() {
		return this.core.processor.simulator.memorySystem.l1Is[this.num];
	}

	Sequencer seqD() {
		return this.core.processor.simulator.memorySystem.seqDs[this.num];
	}
	
	CoherentCacheNode l1D() {
		return this.core.processor.simulator.memorySystem.l1Ds[this.num];
	}
	
	MMU mmu() {
		return this.core.processor.simulator.memorySystem.mmu;
	}
	
	uint num;
	string name;
	
	ISA isa;
	
	IntRegisterFile intRegs;
	FloatRegisterFile floatRegs;
	MiscRegisterFile miscRegs;
	
	Memory mem;

	Core core;
	
	Process process;
	SyscallEmul syscallEmul;

	uint pc, npc, nnpc;
	uint fetchPc, fetchNpc, fetchNnpc;

	Bpred bpred;
	uint stackRecoverIdx;

	bool fetchStalled;
	uint fetchBlock;
	
	uint fetchWidth;
	uint decodeWidth;
	uint issueWidth;
	uint commitWidth;
	
	IFQ fetchq;
	ReadyQ readyq;
	RUU ruu;
	LSQ lsq;
	
	RegisterDependency[uint] regDeps;
	
	ThreadState state;
	
	ThreadStat stat;
}