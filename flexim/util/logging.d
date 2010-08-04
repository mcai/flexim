module flexim.util.logging;

import flexim.all;

string message(string caption, string text) {
	string strCurrentCycle = Simulator.singleInstance !is null ? to!(string)(Simulator.singleInstance.currentCycle) : "INIT";
	//	return format("[%s: %s] %s", strCurrentCycle, caption, text);
	return format("[%s] %s", strCurrentCycle, text);
}

enum LogCategory: string {
	EVENT_QUEUE = "EVENT_QUEUE",
	SIMULATOR = "SIMULATOR",
	PROCESSOR = "PROCESSOR",
	CORE = "CORE",
	THREAD = "THREAD",
	PROCESS = "PROCESS",
	REGISTER = "REGISTER",
	REQUEST = "REQUEST",
	CACHE = "CACHE",
	MOESI = "MOESI",
	MEMORY = "MEMORY",
	NET = "NET",
	INSTRUCTION = "INSTRUCTION",
	SYSCALL = "SYSCALL",
	ELF = "ELF",
	CONFIG = "CONFIG",
	STAT = "STAT",
	MISC = "MISC",
	OOO = "OOO",
	TEST = "TEST",
	DEBUG = "DEBUG"
}

class Logging {
	static this() {
		singleInstance = new Logging();
	}

	this() {
//		this.enable(LogCategory.EVENT_QUEUE);
		this.enable(LogCategory.SIMULATOR);
//		this.enable(LogCategory.PROCESSOR);
//		this.enable(LogCategory.REQUEST);
//		this.enable(LogCategory.CACHE);
//		this.enable(LogCategory.MOESI);
//		this.enable(LogCategory.MEMORY);
//		this.enable(LogCategory.NET);
		this.enable(LogCategory.CONFIG);
		this.enable(LogCategory.STAT);
//		this.enable(LogCategory.MISC);
//		this.enable(LogCategory.OOO);
		this.enable(LogCategory.TEST);
		this.enable(LogCategory.DEBUG);
	}

	Logger opIndex(LogCategory index) {
		if(!(index in this.loggers)) {
			this.loggers[index] = new Logger(this, index);
		}
		return this.loggers[index];
	}

	void enable(LogCategory category) {
		this.logSwitches[category] = true;
	}

	void disable(LogCategory category) {
		this.logSwitches[category] = false;
	}

	bool enabled(LogCategory category) {
		return category in this.logSwitches && this.logSwitches[category];
	}

	bool[LogCategory] logSwitches;
	Logger[LogCategory] loggers;

	static Logging singleInstance;
}

alias Logging.singleInstance logging;

class Logger {
	this(Logging logging, LogCategory category) {
		this.logging = logging;
		this.category = category;
	}

	void infof(T...)(T args) {
		this.info(format(args));
	}

	void info(string text) {
		if(this.logging.enabled(this.category)) {
			stdout.writeln(message(this.category ~ "|" ~ "info", text));
		}
	}

	void warnf(T...)(T args) {
		this.warn(format(args));
	}

	void warn(string text) {
		stderr.writeln(message(this.category ~ "|" ~ "warn", text));
	}

	void fatalf(T...)(T args) {
		this.fatal(format(args));
	}

	void fatal(string text) {		
		Simulator.singleInstance.eventQueue.schedule(SimulatorEventType.FATAL, new SimulatorEventContext(message(this.category ~ "|" ~ "fatal", text)), 0);
	}

	void panicf(T...)(T args) {
		this.panic(format(args));
	}

	void panic(string text) {
		stderr.writeln(message(this.category ~ "|" ~ "panic", text));
		
		Simulator.singleInstance.eventQueue.schedule(SimulatorEventType.PANIC, new SimulatorEventContext(message(this.category ~ "|" ~ "panic", text)), 0);
	}

	void haltf(T...)(T args) {		
		this.halt(format(args));
	}

	void halt(string text) {
		stderr.writeln(message(this.category ~ "|" ~ "halt", text));
		
		Simulator.singleInstance.eventQueue.schedule(SimulatorEventType.HALT, new SimulatorEventContext(message(this.category ~ "|" ~ "halt", text)), 0);
	}

	Logging logging;
	LogCategory category;
}