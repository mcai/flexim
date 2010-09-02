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

const uint STORE_ADDR_INDEX = 0;
const uint STORE_OP_INDEX = 1;

ulong currentInstructionSequenceID = 0;

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

enum RUUStationStatus : string {
	FETCHED = "FETCHED",
	READY = "READY",
	ISSUED = "ISSUED",
	COMPLETED = "COMPLETED"
}

class RUUStation {
	this(uint pc, DynamicInst uop) {
		this.pc = pc;
		this.uop = uop;

		this.inLsq = false;
		this.eaComp = false;
		this.ea = 0;

		this.seq = ++currentInstructionSequenceID;

		this.status = RUUStationStatus.FETCHED;
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
		
		str ~= format("RUUStation[uop=%s, inLsq=%s, eaComp=%s, ea=%d, seq=%d, status=%s, operandsReady=%s]",
				this.uop, this.inLsq, this.eaComp, this.ea, this.seq, this.status, this.operandsReady);
		
		if(this.uop.isStore) {
			str ~= format("\n     storeOpReady=%s, operandsReady=%s", this.storeOpReady, this.operandsReady);
		}
		
		foreach(i, idep; this.ideps) {
			str ~= format("\n     ideps[%d]=%s\n", i, to!(string)(idep));
		}
		
		return str;
	}

	uint pc;
	DynamicInst uop;
	bool inLsq;
	bool eaComp;
	uint ea;

	ulong seq;

	RUUStationStatus status;

	RUUStation[uint] ideps;
	uint[MAX_ODEPS] onames;
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

enum EventQEventType: string {
	DEFAULT = "default"
}

class EventQ: EventQueue!(EventQEventType, RUUStation) {
	public:
		this(string name) {
			super(name);

			this.registerHandler(EventQEventType.DEFAULT, &this.haltHandler);
		}

		void haltHandler(EventQEventType eventType, RUUStation context, ulong when) {
			this.buffer ~= context;
		}

		void enqueue(RUUStation rs, ulong delay) {
			this.schedule(EventQEventType.DEFAULT, rs, delay);
		}

		bool empty() {
			return this.buffer.empty;
		}

		uint size() {
			return this.buffer.length;
		}

		int opApply(int delegate(ref uint, ref RUUStation) dg) {
			int result;

			foreach(ref uint i, ref RUUStation p; this.buffer) {
				result = dg(i, p);
				if(result)
					break;
			}
			return result;
		}

		int opApply(int delegate(ref RUUStation) dg) {
			int result;

			foreach(ref RUUStation p; this.buffer) {
				result = dg(p);
				if(result)
					break;
			}
			return result;
		}

		void popFront() {			
			this.buffer.popFront;
		}

		RUUStation front() {
			return this.buffer.front;
		}

		override string toString() {
			string str;

			str ~= format("%s[size=%d]\n", this.name, this.size);

			foreach(i, entry; this) {
				str ~= format("  %2d: %s\n", i, to!(string)(entry));
			}

			return str;
		}

		RUUStation[] buffer;
}

enum FetchStatus: string {
	RUNNING = "RUNNING",
	ICACHE_WAIT_RESPONSE = "ICACHE_WAIT_RESPONSE",
	ICACHE_WAIT_RETRY = "ICACHE_WAIT_RETRY",
	ICACHE_ACCESS_COMPLETE = "ICACHE_ACCESS_COMPLETE"
}

class OoOThread: Thread {
	this(Simulation simulation, uint num, string name, Process process) {
		super(num, name, process);
		
		this.stat = new ThreadStat(this.num);
		
		simulation.stat.processorStat.threadStats ~= this.stat;

		this.fetchWidth = 4;
		this.decodeWidth = 4;
		this.issueWidth = 4;
		this.commitWidth = 4;

		this.fetchStatus = FetchStatus.RUNNING;

		this.fetchq = new IFQ("IFQ" ~ "-" ~ this.name);
		this.readyq = new ReadyQ("ReadyQ" ~ "-" ~ this.name);
		this.ruu = new RUU("RUU" ~ "-" ~ this.name);
		this.lsq = new LSQ("LSQ" ~ "-" ~ this.name);
		this.eventq = new EventQ("EventQ" ~ "-" ~ this.name);

		this.setFetchNpcFromNpc();
		this.setFetchNnpcFromNnpc();
		
		Simulator.singleInstance.addEventProcessor(this.eventq);
	}

	void commit() {
		for(uint numCommitted = 0; !this.ruu.empty && numCommitted < this.commitWidth; ) {
			RUUStation rs = this.ruu.front;

			if(rs.status != RUUStationStatus.COMPLETED) {
				break;
			}

			if(rs.eaComp) {
				if(this.lsq.front.status != RUUStationStatus.COMPLETED) {
					break;
				}

				this.lsq.popFront();
			}

			this.ruu.popFront();

			this.stat.totalInsts++;

			logging.infof(LogCategory.DEBUG, "t%s one instruction committed (uop=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, rs.uop);
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
								this.readyq ~= dependent;
								dependent.status = RUUStationStatus.READY;
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

	void writeback() {
		while(!this.eventq.empty) {
			RUUStation rs = this.eventq.front;
			rs.status = RUUStationStatus.COMPLETED;

			this.clearRegDeps(rs);

			this.eventq.popFront();
		}
	}

	void refreshLsq() {
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
			} else if(rs.uop.isLoad && rs.status == RUUStationStatus.FETCHED && rs.operandsReady) {
				if(count(stdUnknowns, rs.ea) == 0) {
					this.readyq ~= rs;
					rs.status = RUUStationStatus.READY;
				}
			}

			//////TODO remove below
			if(rs.status == RUUStationStatus.FETCHED && rs.operandsReady) {
				this.readyq ~= rs;
				rs.status = RUUStationStatus.READY;
			}
			//////TODO remove above
		}

		//////TODO remove below
		foreach(rs; this.ruu) {
			if(rs.status == RUUStationStatus.FETCHED && rs.operandsReady) {
				this.readyq ~= rs;
				rs.status = RUUStationStatus.READY;
			}
		}
		//////TODO remove above
	}

	void issue() {
		for(uint numIssued = 0; !this.readyq.empty && numIssued < this.issueWidth; numIssued++) {
			RUUStation rs = this.readyq.front;

			if(rs.inLsq && rs.uop.isStore) {
				uint ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);

				StoreCacheRequest req = new StoreCacheRequest(this.seqD, this.mmu.translate(ea), {});
				this.seqD.receiveRequest(req);

				rs.status = RUUStationStatus.COMPLETED;
				this.readyq.popFront();
			} else if(rs.inLsq && rs.uop.isLoad) {
				void loadCallback(LoadCacheRequest req) {
					this.eventq.enqueue(req.rs, 1);
				}
				
				uint ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);

				LoadCacheRequest req = new LoadCacheRequest(this.seqD, this.mmu.translate(ea), rs, &loadCallback);
				this.seqD.receiveRequest(req);
				
				rs.status = RUUStationStatus.ISSUED;
				this.readyq.popFront();
			} else {
				this.eventq.enqueue(rs, 1);

				rs.status = RUUStationStatus.ISSUED;
				this.readyq.popFront();
			}
		}
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
						rs.status = RUUStationStatus.READY;
					}

					if(uop.isStore && rsMem.operandsReady) {
						this.readyq ~= rsMem;
						rsMem.status = RUUStationStatus.READY;
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
						rs.status = RUUStationStatus.READY;
					}
				}
			}

			numDispatched++;

			this.fetchq.popFront();
		}
	}

	DynamicInst fetchAndDecodeAt(uint pc) {		
		StaticInst staticInst = this.isa.decode(pc, this.mem);
		DynamicInst uop = new DynamicInst(this, pc, staticInst);

		return uop;
	}

	bool canFetch = true;

	uint fetchBlock;

	void fetch() {
		uint block = aligned(this.fetchNpc, this.seqI.blockSize);

		assert(this.fetchNpc);

		if(block != this.fetchBlock) {
			this.fetchBlock = block;

			LoadCacheRequest req = new LoadCacheRequest(this.seqI, this.mmu.translate(this.fetchNpc), null, {this.canFetch = true;});
			this.seqI.receiveRequest(req);
			
			this.canFetch = false;
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

	override void run() {
		this.commit();
	
		this.writeback();
	
		this.refreshLsq();
	
		this.issue();
	
		this.dispatch();
	
		this.fetch();
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
	
	MMU mmu() {
		return this.core.processor.simulator.memorySystem.mmu;
	}
	
	uint fetchWidth;
	uint decodeWidth;
	uint issueWidth;
	uint commitWidth;
	
	uint fetchPc, fetchNpc, fetchNnpc;
	
	ulong lastCommittedCycle;
	
	FetchStatus fetchStatus;
	
	IFQ fetchq;
	ReadyQ readyq;
	RUU ruu;
	LSQ lsq;
	EventQ eventq;
	
	RegisterDependency[uint] regDeps;
}