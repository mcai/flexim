/*
 * flexim/sim/simulator.d
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

module flexim.sim.simulator;

import flexim.all;

import std.c.stdlib;

import std.path;
import std.perf;

enum SimulatorEventType: string {
	GENERAL = "GENERAL",
	HALT = "HALT",
	FATAL = "FATAL",
	PANIC = "PANIC"
}

class SimulatorEventContext {	
	this(string name) {
		this.name = name;
	}
	
	override string toString() {		
		return format("SimulatorEventContext[name=%s]", this.name);
	}

	string name;
}

class SimulatorEventQueue: EventQueue!(SimulatorEventType, SimulatorEventContext) {
	this(Simulator simulator) {
		super("SimulatorEventQueue");
		
		this.simulator = simulator;
		
		this.halted = false;

		this.registerHandler(SimulatorEventType.GENERAL, &this.generalHandler);
		this.registerHandler(SimulatorEventType.HALT, &this.haltHandler);
		this.registerHandler(SimulatorEventType.FATAL, &this.fatalHandler);
		this.registerHandler(SimulatorEventType.PANIC, &this.panicHandler);
	}

	void generalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
	}

	void haltHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		this.halted = true;
		//exit(0);
	}

	void fatalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		core.stdc.stdlib.exit(1);
	}

	void panicHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		core.stdc.stdlib.exit(-1);
	}
	
	Simulator simulator;
	bool halted;
}

abstract class Simulator {
	this() {
		this.currentCycle = 0;
		
		this.eventQueue = new SimulatorEventQueue(this);
		this.addEventProcessor(this.eventQueue);
		
		Simulator.singleInstance = this;
	}

	abstract void run();

	void addEventProcessor(EventProcessor eventProcessor) {
		this.eventProcessors ~= eventProcessor;
	}
	
	SimulatorEventQueue eventQueue;
	
	EventProcessor[] eventProcessors;
	ulong currentCycle;

	static Simulator singleInstance;
}

class CPUSimulator : Simulator {	
	this(Simulation simulation) {
		this.simulation = simulation;
		this.processor = new Processor(this);
		
		SimulationConfig simulationConfig = simulation.config;
		
		for(uint i = 0; i < simulationConfig.processor.numCores; i++) {
			Core core = new Core(this.processor, i);
				
			for(uint j = 0; j < simulationConfig.processor.numThreadsPerCore; j++) {
				ContextConfig context = simulationConfig.processor.contexts[i * simulationConfig.processor.numThreadsPerCore + j];
				
				writefln("context.cwd: %s, args: %s", context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));
				Process process = new Process(context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));

				Thread thread = new Thread(core, simulation, i * simulationConfig.processor.numThreadsPerCore + j, process);
				
				core.threads ~= thread;
				
				this.processor.activeThreadCount++;
			}
			
			this.processor.cores ~= core;
		}

		this.memorySystem = new MemorySystem(simulation);
	}

	override void run() {		
		PerformanceCounter counter = new PerformanceCounter();
		counter.start();

		while(!this.eventQueue.halted && this.processor.canRun) {
			this.processor.run();

			foreach(eventProcessor; this.eventProcessors) {
				eventProcessor.processEvents();
			}

			this.currentCycle++;
		}
		
		counter.stop();
		
		this.duration = counter.milliseconds();
	}
	
	long duration() {
		return this.simulation.stat.duration;
	}
	
	void duration(long value) {
		this.simulation.stat.duration = value;
	}

	Processor processor;
	MemorySystem memorySystem;
	
	Simulation simulation;
}

class MemorySystem {
	this(Simulation simulation) {	
		this.simulation = simulation;		
		this.endNodeCount = simulation.config.processor.numCores;
		this.createMemoryHierarchy();
	}

	void createMemoryHierarchy() {
		this.mem = new MemoryController(this, this.simulationConfig.mainMemory);
				
		this.l2 = new CoherentCache(this, this.simulationConfig.l2Cache);
		this.l2.next = this.mem;

		this.seqIs = new Sequencer[this.endNodeCount];
		this.l1Is = new CoherentCache[this.endNodeCount];

		this.seqDs = new Sequencer[this.endNodeCount];
		this.l1Ds = new CoherentCache[this.endNodeCount];

		for(uint i = 0; i < this.endNodeCount; i++) {
			CoherentCache l1I = new CoherentCache(this, this.simulationConfig.processor.cores[i].iCache);
			Sequencer seqI = new Sequencer("seqI" ~ "-" ~ to!(string)(i), l1I);

			CoherentCache l1D = new CoherentCache(this, this.simulationConfig.processor.cores[i].dCache);
			Sequencer seqD = new Sequencer("seqD" ~ "-" ~ to!(string)(i), l1D);

			this.seqIs[i] = seqI;
			this.l1Is[i] = l1I;

			this.seqDs[i] = seqD;
			this.l1Ds[i] = l1D;
			
			l1I.next = this.l2;
			l1D.next = this.l2;
		}
		
		this.mmu = new MMU();

		for(uint i = 0; i < this.endNodeCount; i++) {
			this.simulation.stat.processor.cores[i].iCache = this.l1Is[i].stat;
			this.simulation.stat.processor.cores[i].dCache = this.l1Ds[i].stat;
		}

		this.simulation.stat.l2Cache = this.l2.stat;
		
		this.simulation.stat.mainMemory = this.mem.stat;
	}
	
	SimulationConfig simulationConfig() {
		return this.simulation.config;
	}

	uint endNodeCount;

	Sequencer[] seqIs;
	Sequencer[] seqDs;

	CoherentCache[] l1Is;
	CoherentCache[] l1Ds;

	CoherentCache l2;
	
	MemoryController mem;
	
	MMU mmu;
	
	Simulation simulation;
}

ulong currentCycle() {
	return Simulator.singleInstance !is null ? Simulator.singleInstance.currentCycle : 0;
}

void scheduleEvent(SimulatorEventType eventType, SimulatorEventContext context, ulong delay = 0) {
	Simulator.singleInstance.eventQueue.schedule(eventType, context, delay);
}

void executeEvent(SimulatorEventType eventType, SimulatorEventContext context) {
	Simulator.singleInstance.eventQueue.execute(eventType, context);
}