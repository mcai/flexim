/*
 * flexim/cpu/ooo/thread.d
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

module flexim.cpu.ooo.thread;

import flexim.all;

enum FetchStatus: string {
	RUNNING = "RUNNING",
	ICACHE_WAIT_RESPONSE = "ICACHE_WAIT_RESPONSE",
	ICACHE_WAIT_RETRY = "ICACHE_WAIT_RETRY",
	ICACHE_ACCESS_COMPLETE = "ICACHE_ACCESS_COMPLETE"
}

class OoOThread: Thread {
	this(string name, Process process) {
		super(name, process);

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

			this.totalInsts++;

			logging[LogCategory.DEBUG].infof("thread %s one instruction committed (uop=%s) !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", this.name, rs.uop);
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
		Addr[] stdUnknowns;

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
				Addr ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);

				WriteCPURequest writeReq = new WriteCPURequest(rs.uop, rs.pc, ea, rs, this.mmu.translate(ea), null);
				this.seqD.write(writeReq);

				rs.status = RUUStationStatus.COMPLETED;
				this.readyq.popFront();
			} else if(rs.inLsq && rs.uop.isLoad) {
				void readCallback(Request req) {
					this.eventq.enqueue((cast(ReadCPURequest) req).rs, 1);
				}

				Addr ea = (cast(MemoryOp) (rs.uop.staticInst)).ea(this);

				ReadCPURequest req = new ReadCPURequest(rs.uop, rs.pc, ea, rs, this.mmu.translate(ea), &readCallback);

				this.seqD.read(req);
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

			Addr pc = fr.pc;
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

	DynamicInst fetchAndDecodeAt(Addr pc) {
		MachInst machInst;

		this.mem.readWord(pc, &machInst.data);

		StaticInst staticInst = this.isa.decode(machInst);

		assert(staticInst !is null, format("failed to decode machine instructon 0x%08x", machInst.data));

		DynamicInst uop = new DynamicInst(this, pc, staticInst);

		return uop;
	}

	bool canFetch = true;

	uint fetchBlock;

	void fetch() {
		uint block = aligned(this.fetchNpc, this.seqI.blockSize);

		assert(this.fetchNpc);

		if(block != this.fetchBlock) {
			void callback(Request req) {
				this.canFetch = true;
			}

			this.fetchBlock = block;

			ReadCPURequest req = new ReadCPURequest(null, this.fetchNpc, this.fetchNpc, null, this.mmu.translate(this.fetchNpc), &callback);

			this.seqI.read(req);
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
			this.nnpc += Addr.sizeof;

			uop.execute();

			this.setFetchNpcFromNpc();
			this.setFetchNnpcFromNnpc();

			FetchRecord fr = new FetchRecord(uop.pc, uop);
			this.fetchq ~= fr;
		}
}

override void run() {
	this.dump();

	this.commit();

	this.dump();

	this.writeback();

	this.dump();

	this.refreshLsq();

	this.dump();

	this.issue();

	this.dump();

	this.dispatch();

	this.dump();

	this.fetch();
}

void dump() {
	//		writefln("[%d] %s.size: %d, %s.size: %d, %s.size: %d, %s.size: %d, %s.size: %d", Simulator.singleInstance.currentCycle, 
	//				this.fetchq.name, this.fetchq.size, 
	//				this.readyq.name, this.readyq.size,
	//				this.ruu.name, this.ruu.size,
	//				this.lsq.name, this.lsq.size, 
	//				this.eventq.name, this.eventq.size);
	//		if(this.lsq.full) {
	//			writeln(this.fetchq);
	//			writeln(this.readyq);
	//			writeln(this.ruu);
	//			writeln(this.lsq);
	//			writeln(this.eventq);
	//		}
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

MMU!(MOESIState) mmu() {
	return this.core.processor.simulator.memorySystem.mmu;
}

uint fetchWidth;
uint decodeWidth;
uint issueWidth;
uint commitWidth;

Addr fetchPc, fetchNpc, fetchNnpc;

ulong lastCommittedCycle;

FetchStatus fetchStatus;

IFQ fetchq;
ReadyQ readyq;
RUU ruu;
LSQ lsq;
EventQ eventq;

RegisterDependency[uint] regDeps;}