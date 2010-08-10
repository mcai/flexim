/*
 * flexim/util/logging.d
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

module flexim.util.logging;

import flexim.all;

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
	MESI = "MESI",
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

class Logger: CurrentCycleProvider, SchedulerProvider!(SimulatorEventType, SimulatorEventContext) {
	static this() {
		singleInstance = new Logger();
	}
	
	this() {		
//		this.enable(LogCategory.EVENT_QUEUE);
		this.enable(LogCategory.SIMULATOR);
//		this.enable(LogCategory.PROCESSOR);
//		this.enable(LogCategory.REQUEST);
//		this.enable(LogCategory.CACHE);
//		this.enable(LogCategory.MESI);
//		this.enable(LogCategory.MEMORY);
//		this.enable(LogCategory.NET);
		this.enable(LogCategory.CONFIG);
		this.enable(LogCategory.STAT);
//		this.enable(LogCategory.MISC);
//		this.enable(LogCategory.OOO);
		this.enable(LogCategory.TEST);
		
		debug {
			this.enable(LogCategory.DEBUG);
		}
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
	
	ulong currentCycle() {
		return Simulator.singleInstance !is null ? Simulator.singleInstance.currentCycle : 0;
	}

	void schedule(SimulatorEventType eventType, SimulatorEventContext context, ulong delay = 0) {
		Simulator.singleInstance.eventQueue.schedule(eventType, context, delay);
	}

	void execute(SimulatorEventType eventType, SimulatorEventContext context) {
		Simulator.singleInstance.eventQueue.execute(eventType, context);
	}
	
	string message(string caption, string text) {
		return format("[%d] \t%s%s", this.currentCycle, caption.endsWith("info") ? "" : "[" ~ caption ~ "] ", text);
	}

	void infof(LogCategory, T...)(LogCategory category, T args) {
		this.info(category, format(args));
	}

	void info(LogCategory category, string text) {
		if(this.enabled(category)) {
			stdout.writeln(this.message(category ~ "|" ~ "info", text));
		}
	}

	void warnf(LogCategory, T...)(LogCategory category, T args) {
		this.warn(category, format(args));
	}

	void warn(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "warn", text));
	}

	void fatalf(LogCategory, T...)(LogCategory category, T args) {
		this.fatal(category, format(args));
	}

	void fatal(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "fatal", text));
		this.execute(SimulatorEventType.FATAL, new SimulatorEventContext(this.message(category ~ "|" ~ "fatal", text)));
	}

	void panicf(LogCategory, T...)(LogCategory category, T args) {
		this.panic(category, format(args));
	}

	void panic(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "panic", text));
		this.execute(SimulatorEventType.PANIC, new SimulatorEventContext(this.message(category ~ "|" ~ "panic", text)));
	}

	void haltf(LogCategory, T...)(LogCategory category, T args) {		
		this.halt(category, format(args));
	}

	void halt(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "halt", text));
		this.execute(SimulatorEventType.HALT, new SimulatorEventContext(this.message(category ~ "|" ~ "halt", text)));
	}

	bool[LogCategory] logSwitches;
	
	static Logger singleInstance;
}

alias Logger.singleInstance logging;