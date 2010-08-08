module flexim.drivers.simulations;

import flexim.all;

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible {
	this(string title, string cwd, CPUConfig cpuConfig, CacheConfig cacheConfig, ContextConfig contextConfig) {
		this.title = title;
		this.cwd = cwd;
		this.cpuConfig = cpuConfig;
		this.cacheConfig = cacheConfig;
		this.contextConfig = contextConfig;
	}
	
	override void beforeRun() {
		//TODO
	}
	
	override void run() {
		//TODO
	}
	
	override void afterRun() {
		//TODO
	}
	
	string title;
	string cwd;
	CPUConfig cpuConfig;
	CacheConfig cacheConfig;
	ContextConfig contextConfig;
}

class Experiment: Reproducible {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, Simulation[] simulations) {
		this.title = title;
		this.cwd = cwd;
		this.simulations = simulations;
	}
	
	override void beforeRun() {
		foreach(simulation; this.simulations) {
			simulation.beforeRun();
		}
	}
	
	override void run() {
		foreach(simulation; this.simulations) {
			simulation.run();
		}
	}
	
	override void afterRun() {
		foreach(simulation; this.simulations) {
			simulation.afterRun();
		}
	}
	
	string title;
	string cwd;
	Simulation[] simulations;
}