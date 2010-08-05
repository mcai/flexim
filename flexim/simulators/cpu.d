/*
 * flexim/simulators/cpu.d
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

module flexim.simulators.cpu;

import flexim.all;

class CPURequest: Request {	
	alias addr phaddr;
	
	this(RequestType type, DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, Callback1!(Request) onCompletedCallback) {
		super(type, pc, phaddr, onCompletedCallback);

		this.uop = uop;
		this.vtaddr = vtaddr;
		this.rs = rs;
	}

	override string toString() {
		return format("%s[ID: %d, pc: 0x%x, vtaddr: 0x%x, phaddr: 0x%x]", to!(string)(this.type), this.id, this.pc, this.vtaddr, this.phaddr);
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

alias MemorySystem!(CPURequest) CPUMemorySystem;

abstract class CPUSimulator : Simulator {
	CPUMemorySystem memorySystem;
}

class FastCPUSimulator : CPUSimulator {
	this(string cwd, string[] args) {		
		this.processor = new Processor(this);

		for(int i = 0; i <= 0; i++) { //TODO: i.max be read from config
			Core core = new Core(format("%d", i));

			for(int j = 0; j <= 0; j++) {
				Process process = new Process(cwd, args);
				Thread thread = new Thread(format("%d", j), process);
				
				core.addThread(thread);
			}

			this.processor.addCore(core);
		}

		this.memorySystem = new CPUMemorySystem(current_thread_id);

		this.addEventProcessor(this.memorySystem.eventQueue);
	}

	void dumpConfigs() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("Simulation Configurations");
		logging[LogCategory.CONFIG].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("[Simulator]");
		this.processor.dumpConfigs("  ");
		this.memorySystem.l2.dumpConfigs("  ");
		this.memorySystem.mem.dumpConfigs("  ");

		logging[LogCategory.CONFIG].info("");
	}

	void dumpStats() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].info("Simulation Statistics");
		logging[LogCategory.STAT].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].infof("[Simulator] total cycles: %d", this.currentCycle);
		this.processor.dumpStats("  ");
		this.memorySystem.l2.dumpStats("  ");
		this.memorySystem.mem.dumpStats("  ");
	}

	void run() {
		this.dumpConfigs();

		while(true) {
			this.processor.run();

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}
	}

	Processor processor;
}

class OoOCPUSimulator : CPUSimulator {
	this(string cwd, string[] args) {		
		this.processor = new Processor(this);

		for(int i = 0; i <= 0; i++) { //TODO: i.max be read from config
			Core core = new Core(format("%d", i));

			for(int j = 0; j <= 1; j++) {
				Process process = new Process(cwd, args);

				OoOThread thread = new OoOThread(format("%d", j), process);
				this.addEventProcessor(thread.eventq);
				
				core.addThread(thread);
			}

			this.processor.addCore(core);
		}

		this.memorySystem = new CPUMemorySystem(current_thread_id);

		this.addEventProcessor(this.memorySystem.eventQueue);
	}

	void dumpConfigs() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("Simulation Configurations");
		logging[LogCategory.CONFIG].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.CONFIG].info("[Simulator]");
		this.processor.dumpConfigs("  ");
		this.memorySystem.l2.dumpConfigs("  ");
		this.memorySystem.mem.dumpConfigs("  ");

		logging[LogCategory.CONFIG].info("");
	}

	void dumpStats() {
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].info("Simulation Statistics");
		logging[LogCategory.STAT].info("----------------------------------------------------------");
		logging[LogCategory.CONFIG].info("");
		logging[LogCategory.STAT].infof("[Simulator] total cycles: %d", this.currentCycle);
		this.processor.dumpStats("  ");
		this.memorySystem.l2.dumpStats("  ");
		this.memorySystem.mem.dumpStats("  ");
	}

	void run() {
		this.dumpConfigs();

		while(true) {
			this.processor.run();

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}
	}

	Processor processor;
}

