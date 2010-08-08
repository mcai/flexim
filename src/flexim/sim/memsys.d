/*
 * flexim/sim/memsys.d
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

module flexim.sim.memsys;

import flexim.all;

class TestMemSysRequest: Request {
	this(RequestType type, Addr phaddr, void delegate(Request) del) {
		super(type, 0, phaddr, new Callback1!(Request)(this, del));
	}
}

alias MemorySystem!(TestMemSysRequest) TestMemSysMemorySystem;

class MESIMemorySystemSimulator: Simulator {
	alias Sequencer!(TestMemSysRequest, MESICache) SequencerT;

	this() {
		this.memorySystem = new TestMemSysMemorySystem(2);
		this.addEventProcessor(this.memorySystem.eventQueue);
		
		this.xxEventQueue = new XXEventQueue();
		this.addEventProcessor(this.xxEventQueue);
		
		this.init();
	}

	void dumpConfigs() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("Simulation Configurations");
		logging[LogCategory.CONFIG].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("[Simulator]");
		
		this.memorySystem.mem.dumpConfigs("  ");

		foreach(cache; this.memorySystem.caches) {
			cache.dumpConfigs("  ");
		}

		logging[LogCategory.CONFIG].info("");
	}

	void dumpStats() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].info("Simulation Statistics");
		logging[LogCategory.STAT].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].infof("[Simulator] total cycles: %d", this.currentCycle);
		
		this.memorySystem.mem.dumpStats("  ");

		foreach(cache; this.memorySystem.caches) {
			cache.dumpStats("  ");
		}
	}

	SequencerT seqI0() {
		return this.memorySystem.seqIs[0];
	}

	MESICache l1I0() {
		return this.memorySystem.l1Is[0];
	}

	SequencerT seqD0() {
		return this.memorySystem.seqDs[0];
	}

	MESICache l1D0() {
		return this.memorySystem.l1Ds[0];
	}

	SequencerT seqI1() {
		return this.memorySystem.seqIs[1];
	}

	MESICache l1I1() {
		return this.memorySystem.l1Is[1];
	}

	SequencerT seqD1() {
		return this.memorySystem.seqDs[1];
	}

	MESICache l1D1() {
		return this.memorySystem.l1Ds[1];
	}
	
	class XXSchedule {
		this(SequencerT seq, TestMemSysRequest req) {
			this.seq = seq;
			this.req = req;
		}
		
		SequencerT seq;
		TestMemSysRequest req;
	}
	
	class XXEventQueue : EventQueue!(RequestType, XXSchedule) {
		this() {
			super("XXEventQueue");
			
			this.registerHandler(RequestType.READ, &this.handler);
			this.registerHandler(RequestType.WRITE, &this.handler);
		}

		void handler(RequestType eventType, XXSchedule context, ulong when) {
			SequencerT seq = context.seq;
			TestMemSysRequest req = context.req;
			
			logging[LogCategory.DEBUG].infof("handler (seq: %s, req: %s)", seq, req);
			
			if(eventType == RequestType.READ) {
				seq.read(req);
			}
			else {
				seq.write(req);
			}
		}
	}
	
	XXEventQueue xxEventQueue;
	
	void schedule(SequencerT seq, RequestType reqType, Addr phaddr, ulong lat) {
		void callback(Request req) {
			this.numRemainingRequests--;
		}
		
		TestMemSysRequest req = new TestMemSysRequest(reqType, phaddr, &callback);
		this.xxEventQueue.schedule(reqType, new XXSchedule(seq, req), lat);
		this.numRemainingRequests++;
	}
	
	void init() {
		for(uint i = 0; i < 100; i++) {
			this.schedule(this.seqD0, RequestType.READ, i, 0 + i * 10);
			this.schedule(this.seqD1, RequestType.WRITE, i+1, 50 + i * 10);
			this.schedule(this.seqD1, RequestType.READ, i+2, 100 + i * 10);
		}
	}
	
	void run() {
		while(this.numRemainingRequests > 0 && this.currentCycle < 10000) {
			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}
	}
	
	/////////////////////////////////////////////////////////////////////////////////

	TestMemSysMemorySystem memorySystem;

	TestMemSysRequest[] pendingReadRequests;
	TestMemSysRequest[] pendingWriteRequests;
	
	ulong numRemainingRequests;

	ulong numReadRequestsSent;
	ulong numReadRequestsServiced;

	ulong[ulong] requestStartTime;
}
