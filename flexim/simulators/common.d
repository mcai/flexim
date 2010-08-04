module flexim.simulators.common;

import flexim.all;

import std.c.stdlib;

enum SimulatorEventType: string {
	GENERAL = "GENERAL",
	HALT = "HALT",
	FATAL = "FATAL",
	PANIC = "PANIC",
	NET = "NET"
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

	this(string name, Callback callback) {
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
	Callback callback;
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
			this.registerHandler(SimulatorEventType.NET, &this.netHandler);
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

		void netHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
			if(context.callback !is null) {
				context.callback.invoke();
			}
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