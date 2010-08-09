/*
 * flexim/sim/common.d
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

module flexim.sim.common;

import flexim.all;

import std.c.stdlib;

enum SimulatorEventType: string {
	GENERAL = "GENERAL",
	HALT = "HALT",
	FATAL = "FATAL",
	PANIC = "PANIC"
}

class SimulatorEventContext {
	void dummyDel() {		
	}
	
	this(string name) {
		this(name, &this.dummyDel);
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
		
//		str ~= format("SimulatorEventContext[name: %s, callback: %s]", this.name, this.callback);
		str ~= format("SimulatorEventContext[name: %s]", this.name);
		
		return str;
	}

	string name;
	Invokable callback;
}

class SimulatorEventQueue: EventQueue!(SimulatorEventType, SimulatorEventContext) {
	public:
		this(Simulator simulator) {
			super("SimulatorEventQueue");
			
			this.simulator = simulator;

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
			this.simulator.dumpStats();
			exit(0);
		}

		void fatalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
			stderr.writeln(context.name);
			
			if(context.callback !is null) {
				context.callback.invoke();
			}
			this.simulator.dumpStats();
			exit(1);
		}

		void panicHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
			if(context.callback !is null) {
				context.callback.invoke();
			}
			this.simulator.dumpStats();
			exit(-1);
		}

		Simulator simulator;
}

abstract class Simulator {
	this() {
		this.currentCycle = 0;
		this.eventQueue = new SimulatorEventQueue(this);

		this.addEventProcessor(this.eventQueue);
		
		Simulator.singleInstance = this;
	}

	abstract void dumpConfigs();

	abstract void dumpStats();

	abstract void run();

	void addEventProcessor(EventProcessor eventProcessor) {
		this.eventProcessors ~= eventProcessor;
	}
	
	SimulatorEventQueue eventQueue;
	EventProcessor[] eventProcessors;
	ulong currentCycle;

	static Simulator singleInstance;
}