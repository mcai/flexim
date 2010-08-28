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
		this(name, {});
	}

	this(string name, void delegate() del) {
		this(name, new Callback0(del));
	}

	this(string name, Invokable callback) {
		this.name = name;
		this.callback = callback;
	}
	
	override string toString() {
		string str;
		
//		str ~= format("SimulatorEventContext[name=%s, callback=%s]", this.name, this.callback);
		str ~= format("SimulatorEventContext[name=%s]", this.name);
		
		return str;
	}

	string name;
	Invokable callback;
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
		if(context.callback !is null) {
			context.callback.invoke();
		}
	}

	void haltHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		if(context.callback !is null) {
			context.callback.invoke();
		}
		
		this.halted = true;
		//exit(0);
	}

	void fatalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {			
		if(context.callback !is null) {
			context.callback.invoke();
		}
		exit(1);
	}

	void panicHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		if(context.callback !is null) {
			context.callback.invoke();
		}
		exit(-1);
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
		
		for(uint i = 0; i < simulationConfig.processorConfig.numCores; i++) {
			Core core = new Core(format("%d", i));
				
			for(uint j = 0; j < simulationConfig.processorConfig.numThreads; j++) {
				ContextConfig context = simulationConfig.processorConfig.contexts[i * simulationConfig.processorConfig.numThreads + j];
				
				Process process = new Process(context.cwd, split(join(context.cwd, context.exe ~ ".mipsel") ~ " " ~ context.args));

				Thread thread = new OoOThread(simulation, i * simulationConfig.processorConfig.numThreads + j, format("%d", j), process);
				
				core.addThread(thread);
			}

			this.processor.addCore(core);
		}

		this.memorySystem = new MemorySystem(simulation);
	}

	void run() {		
		PerformanceCounter counter = new PerformanceCounter();
		counter.start();

		while(!this.eventQueue.halted) {
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
		
		this.endNodeCount = simulation.config.processorConfig.numCores * simulation.config.processorConfig.numThreads;	
		
		this.createMemoryHierarchy();
	}
	
	CoherentCache createCache(CacheConfig cacheGeometry, uint level) {
		CoherentCache cache = new CoherentCache(cacheGeometry.name, this, cacheGeometry.blockSize,
			cacheGeometry.assoc, cacheGeometry.sets, cacheGeometry.hitLatency, cacheGeometry.missLatency, level);
		
		this.simulation.stat.memorySystemStat.cacheStats[cache.name] = cache.stat;
		
		return cache;
	}

	void createMemoryHierarchy() {
		this.l2 = this.createCache(this.simulationConfig.memorySystemConfig.caches["l2"], 1);
		
		this.mem = new PhysicalMemory(this);

		this.seqIs = new Sequencer[this.endNodeCount];
		this.l1Is = new CoherentCache[this.endNodeCount];

		this.seqDs = new Sequencer[this.endNodeCount];
		this.l1Ds = new CoherentCache[this.endNodeCount];
		
		l2.next = null;

		for(uint i = 0; i < this.endNodeCount; i++) {
			CoherentCache l1I = this.createCache(this.simulationConfig.memorySystemConfig.caches["l1I" ~ "-" ~ to!(string)(i)], 0);
			Sequencer seqI = new Sequencer("seqI" ~ "-" ~ to!(string)(i), l1I);

			CoherentCache l1D = this.createCache(this.simulationConfig.memorySystemConfig.caches["l1D" ~ "-" ~ to!(string)(i)], 0);
			Sequencer seqD = new Sequencer("seqD" ~ "-" ~ to!(string)(i), l1D);

			this.seqIs[i] = seqI;
			this.l1Is[i] = l1I;

			this.seqDs[i] = seqD;
			this.l1Ds[i] = l1D;
			
			l1I.next = l2;
			l1D.next = l2;
		}
		
		this.mmu = new MMU();
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
	
	PhysicalMemory mem;
	
	MMU mmu;
	
	Simulation simulation;
}