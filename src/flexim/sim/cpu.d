/*
 * flexim/sim/cpu.d
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

module flexim.sim.cpu;

import flexim.all;

class CPURequest: Request {	
	alias addr phaddr;
	
	this(RequestType type, DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, Callback onCompletedCallback) {
		super(type, pc, phaddr, onCompletedCallback);

		this.uop = uop;
		this.vtaddr = vtaddr;
		this.rs = rs;
	}

	override string toString() {
		return format("%s[ID=%d, pc=0x%x, vtaddr=0x%x, phaddr=0x%x]", to!(string)(this.type), this.id, this.pc, this.vtaddr, this.phaddr);
	}

	DynamicInst uop;
	Addr vtaddr;
	RUUStation rs;
}

class ReadCPURequest: CPURequest {
	this(DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, void delegate(Request) del) {
		super(RequestType.READ, uop, pc, vtaddr, rs, phaddr, new Callback1!(Request)(this, del));
	}
}

class WriteCPURequest: CPURequest {
	this(DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, void delegate(Request) del) {
		super(RequestType.WRITE, uop, pc, vtaddr, rs, phaddr, new Callback1!(Request)(this, del));
	}
}

class CPUMemorySystem: MemorySystem!(CPURequest) {
	this(Simulation simulation) {
		super(simulation.cpuConfig.numCores * simulation.cpuConfig.numThreads);
		
		this.simulation = simulation;
		this.createMemoryHierarchy();
	}
	
	CacheT createCache(CacheGeometry cacheGeometry, bool isPrivate, bool lowestPrivate, bool llc) {
		return new CacheT(this, cacheGeometry.name, isPrivate, cacheGeometry.blockSize,
			cacheGeometry.assoc, cacheGeometry.sets,
			cacheGeometry.hitLatency, cacheGeometry.missLatency, lowestPrivate, llc);
	}

	override void createMemoryHierarchy() {
		this.l2 = this.createCache(this.simulation.cacheConfig.caches["l2"], false, false, true);
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
			CacheT l1I = this.createCache(this.simulation.cacheConfig.caches["l1I" ~ "-" ~ to!(string)(i)], true, true, false);
			SequencerT seqI = new SequencerT("seqI" ~ "-" ~ to!(string)(i), l1I);

			CacheT l1D = this.createCache(this.simulation.cacheConfig.caches["l1D" ~ "-" ~ to!(string)(i)], true, true, false);
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
	
	Simulation simulation;
}

class CPUSimulator : Simulator {	
	this(Simulation simulation) {
		this.processor = new Processor(this);
		
		for(uint i = 0; i < simulation.cpuConfig.numCores; i++) {
			Core core = new Core(format("%d", i));
				
			for(uint j = 0; j < simulation.cpuConfig.numThreads; j++) {
				string cwd = simulation.contextConfig.contexts[i * simulation.cpuConfig.numThreads + j].cwd;
				string[] args;
				args ~= simulation.contextConfig.contexts[i * simulation.cpuConfig.numThreads + j].cwd ~ "/" ~ simulation.contextConfig.contexts[i * simulation.cpuConfig.numThreads + j].exe ~ ".mipsel";
				args ~= split(simulation.contextConfig.contexts[i * simulation.cpuConfig.numThreads + j].args);
				
				Process process = new Process(cwd, args);

				Thread thread = new OoOThread(format("%d", j), process);
				
				core.addThread(thread);
			}

			this.processor.addCore(core);
		}

		this.memorySystem = new CPUMemorySystem(simulation);

		this.addEventProcessor(this.memorySystem.eventQueue);
	}

	void dumpConfigs() {
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.CONFIG, "Simulation Configurations");
		logging.info(LogCategory.CONFIG, "----------------------------------------------------------");
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.CONFIG, "[Simulator]");
		this.processor.dumpConfigs("  ");
		this.memorySystem.l2.dumpConfigs("  ");
		this.memorySystem.mem.dumpConfigs("  ");

		logging.info(LogCategory.CONFIG, "");
	}

	void dumpStats() {
		logging.info(LogCategory.CONFIG, "");
		logging.info(LogCategory.STAT, "Simulation Statistics");
		logging.info(LogCategory.STAT, "----------------------------------------------------------");
		logging.info(LogCategory.CONFIG, "");
		logging.infof(LogCategory.STAT, "[Simulator] total cycles: %d", this.currentCycle);
		this.processor.dumpStats("  ");
		this.memorySystem.l2.dumpStats("  ");
		this.memorySystem.mem.dumpStats("  ");
	}

	void run() {
		this.dumpConfigs();

		while(!this.eventQueue.halted) {
			this.processor.run();

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}
	}

	Processor processor;
	CPUMemorySystem memorySystem;
}