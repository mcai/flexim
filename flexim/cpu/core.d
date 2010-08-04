module flexim.cpu.core;

import flexim.all;

class Core {
	this(string name) {
		this.name = name;
	}

	void addThread(Thread thread) { //TODO: merge with this.threads ~= thread
		thread.core = this;
		this.threads ~= thread;
	}

	void dumpConfigs(string indent) {
		logging[LogCategory.CONFIG].infof(indent ~ "[Core %s]", this.name);
		foreach(thread; this.threads) {
			thread.dumpConfigs(indent ~ "  ");
		}
	}

	void dumpStats(string indent) {
		logging[LogCategory.STAT].infof(indent ~ "[Core %s]", this.name);
		foreach(thread; this.threads) {
			thread.dumpStats(indent ~ "  ");
		}
	}

	void run() {
		foreach(thread; this.threads) {
			thread.run();
		}
	}

	string name;
	Processor processor;
	Thread[] threads;
}