module flexim.simulators.memsys;

import flexim.all;

class TestMemSysRequest: Request {
	this(RequestType type, Addr phaddr, void delegate(Request) del) {
		super(type, 0, phaddr, new Callback1!(Request)(this, del));
	}
}

alias MemorySystem!(TestMemSysRequest) TestMemSysMemorySystem;

class MOESIMemorySystemSimulator: Simulator {
	alias Sequencer!(TestMemSysRequest, MOESICache) SequencerT;

	this() {
		this.memorySystem = new TestMemSysMemorySystem(1);

		this.addEventProcessor(this.memorySystem.eventQueue);
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

	SequencerT seqI() {
		return this.memorySystem.seqIs[0];
	}

	MOESICache l1I() {
		return this.memorySystem.l1Is[0];
	}

	SequencerT seqD() {
		return this.memorySystem.seqDs[0];
	}

	MOESICache l1D() {
		return this.memorySystem.l1Ds[0];
	}

	TestMemSysRequest newReadRequest(Addr phaddr) {
		void callback(Request req) {
			assert(req.id in this.requestStartTime);

			this.numReadRequestsServiced++;

			logging[LogCategory.TEST].infof("#################### read request completed: %s, cycles spent: %d", to!(string)(req), this.currentCycle - this.requestStartTime[req.id]);
			
			this.requestStartTime.remove(req.id);
		}

		TestMemSysRequest req = new TestMemSysRequest(RequestType.READ, phaddr, &callback);
		return req;
	}

	void readOne(SequencerT seq) {
		if(!this.pendingReadRequests.empty) {
			TestMemSysRequest req = this.pendingReadRequests.front;
			seq.read(req);
			
			this.requestStartTime[req.id] = this.currentCycle;

			this.pendingReadRequests.popFront();

			this.numReadRequestsSent++;
		}
	}

	TestMemSysRequest newWriteRequest(Addr phaddr) {
		TestMemSysRequest req = new TestMemSysRequest(RequestType.WRITE, phaddr, null);
		return req;
	}

	void writeOne(SequencerT seq) {
		if(!this.pendingWriteRequests.empty) {
			TestMemSysRequest req = this.pendingWriteRequests.front;
			seq.write(req);
			
			this.requestStartTime[req.id] = this.currentCycle;

			this.pendingWriteRequests.popFront();
		}
	}

	Addr newPhaddr() {
		return 0xFF + uniform(0, 0xFF) * 0xFF;
//				return 0x5e80;
	}

	void run() {
		this.dumpConfigs();

		while(this.currentCycle <= 10000) {

			if(this.currentCycle % 10 == 0 && this.currentCycle <= 5000)
				for(uint i = 0; i < 2; i++) {
					this.pendingReadRequests ~= this.newReadRequest(this.newPhaddr());
//					this.pendingWriteRequests ~= this.newWriteRequest(this.newPhaddr());
				}

			uint max_request_width = 1;

			for(uint i = 0; i < max_request_width && !this.pendingReadRequests.empty; i++) {
//				this.readOne(this.seqI);
				this.readOne(this.seqD);
			}

			for(uint i = 0; i < max_request_width && !this.pendingWriteRequests.empty; i++) {
//				this.writeOne(this.seqI);
				this.writeOne(this.seqD);
			}

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}

		this.dumpStats();

		logging[LogCategory.TEST].haltf("memory system test completed, numReadRequestsSent: %d, numReadRequestsServiced: %d", this.numReadRequestsSent, this.numReadRequestsServiced);
		
		ulong[] pendingReqIds;
		
		foreach(reqId, startTime; this.requestStartTime) {
			pendingReqIds ~= reqId;
		}
		
		pendingReqIds.sort();
		
		foreach(reqId; pendingReqIds) {
			writefln("pending read request, id: %d", reqId);
		}
	}

	TestMemSysMemorySystem memorySystem;

	TestMemSysRequest[] pendingReadRequests;
	TestMemSysRequest[] pendingWriteRequests;

	ulong numReadRequestsSent;
	ulong numReadRequestsServiced;

	ulong[ulong] requestStartTime;
}
