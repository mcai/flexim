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

class TestMemSysMemorySystem: MemorySystem!(TestMemSysRequest) {
	this(uint endNodeCount) {
		super(endNodeCount);
		
		this.createMemoryHierarchy();
	}

	override void createMemoryHierarchy() {
		this.l2 = new CacheT(this, "l2", false, 64, 4, 1024, 4, 7, false, true);
//		this.l2 = new CacheT(this, "l2", false, 64, 4, 2, 4, 7, false, true);
		this.caches ~= this.l2;

		//		this.mem = new MESIMemory(this, "mem", 400, 300);
		this.mem = new MESIMemory(this, "mem", 4, 3);

		this.seqIs = new SequencerT[this.endNodeCount];
		this.l1Is = new CacheT[this.endNodeCount];

		this.seqDs = new SequencerT[this.endNodeCount];
		this.l1Ds = new CacheT[this.endNodeCount];

		Interconnect l1_l2 = new InterconnectT("l1_l2");
		this.interconnects ~= l1_l2;

		l1_l2.nodes ~= this.l2;

		this.l2.upperInterconnect = l1_l2;

		Interconnect l2_mem = new InterconnectT("l2_mem");
		this.interconnects ~= l2_mem;

		l2_mem.nodes ~= this.l2;
		l2_mem.nodes ~= this.mem;

		this.l2.lowerInterconnect = l2_mem;
		this.mem.upperInterconnect = l2_mem;
		
		l2.next = this.mem;

		for(uint i = 0; i < this.endNodeCount; i++) {
			CacheT l1I = new CacheT(this, "l1I" ~ "-" ~ to!(string)(i), true, 64, 4, 64, 1, 3, true, false);
//			CacheT l1I = new CacheT(this, "l1I" ~ "-" ~ to!(string)(i), true, 64, 4, 1, 1, 3, true, false);
			SequencerT seqI = new SequencerT("seqI" ~ "-" ~ to!(string)(i), l1I);

			CacheT l1D = new CacheT(this, "l1D" ~ "-" ~ to!(string)(i), true, 64, 4, 64, 1, 3, true, false);
//			CacheT l1D = new CacheT(this, "l1D" ~ "-" ~ to!(string)(i), true, 64, 4, 1, 1, 3, true, false);
			SequencerT seqD = new SequencerT("seqD" ~ "-" ~ to!(string)(i), l1D);

			this.seqIs[i] = seqI;
			this.l1Is[i] = l1I;

			this.seqDs[i] = seqD;
			this.l1Ds[i] = l1D;

			this.caches ~= l1I;
			this.caches ~= l1D;

			Interconnect seqI_l1I = new InterconnectT("seqI_l1I" ~ "-" ~ to!(string)(i));
			this.interconnects ~= seqI_l1I;

			seqI_l1I.nodes ~= seqI;
			seqI_l1I.nodes ~= l1I;

			seqI.lowerInterconnect = seqI_l1I;
			l1I.upperInterconnect = seqI_l1I;

			Interconnect seqD_l1D = new InterconnectT("seqD_l1D" ~ "-" ~ to!(string)(i));
			this.interconnects ~= seqD_l1D;

			seqD_l1D.nodes ~= seqD;
			seqD_l1D.nodes ~= l1D;

			seqD.lowerInterconnect = seqD_l1D;
			l1D.upperInterconnect = seqD_l1D;

			l1_l2.nodes ~= l1I;
			l1_l2.nodes ~= l1D;

			l1I.lowerInterconnect = l1_l2;
			l1D.lowerInterconnect = l1_l2;
			
			l1I.next = l2;
			l1D.next = l2;
		}
	}
}

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
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.CONFIG, "Simulation Configurations");
		logging.info(LogCategory.CONFIG, "----------------------------------------------------------");
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.CONFIG, "[Simulator]");
		
		this.memorySystem.mem.dumpConfigs("  ");

		foreach(cache; this.memorySystem.caches) {
			cache.dumpConfigs("  ");
		}

		logging.info(LogCategory.CONFIG, "");
	}

	void dumpStats() {
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.STAT, "Simulation Statistics");
		logging.info(LogCategory.STAT, "----------------------------------------------------------");
		logging.info(LogCategory.CONFIG, "");
		logging.infof(LogCategory.STAT, "[Simulator] total cycles: %d", this.currentCycle);
		
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
			
			logging.infof(LogCategory.DEBUG, "handler (seq: %s, req: %s)", seq, req);
			
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

	TestMemSysMemorySystem memorySystem;

	TestMemSysRequest[] pendingReadRequests;
	TestMemSysRequest[] pendingWriteRequests;
	
	ulong numRemainingRequests;

	ulong numReadRequestsSent;
	ulong numReadRequestsServiced;

	ulong[ulong] requestStartTime;
}
