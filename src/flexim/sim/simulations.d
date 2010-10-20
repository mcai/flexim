/*
 * flexim/sim/stats.d
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

module flexim.sim.simulations;

import flexim.all;

import std.file;
import std.path;

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible {
	this(SimulationConfig config) {
		this.config = config;
		
		this.stat = new SimulationStat(this.title, this.cwd);
	}
	
	override void beforeRun() {
	}
	
	override void run() {
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	override void afterRun() {
	}
	
	override string toString() {
		return format("Simulation[title=%s, cwd=%s]", this.title, this.cwd);
	}
	
	string title() {
		return this.config.title;
	}
	
	string cwd() {
		return this.config.cwd;
	}

	SimulationConfig config;
	SimulationStat stat;
}

class Experiment: Reproducible {
	this(ExperimentConfig config) {
		this.config = config;
		
		this.stat = new ExperimentStat(this.title, this.cwd);
		
		foreach(simulationConfig; this.config.simulationConfigs) {
			Simulation simulation = new Simulation(simulationConfig);
			this.stat.simulationStats ~= simulation.stat;						
			this.simulations ~= simulation;
		}
	}
	
	void execute() {
		this.beforeRun();
		this.run();
		this.afterRun();
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
		
		ExperimentStat.saveXML(this.stat, this.cwd, this.title ~ ".stat.xml");
	}
	
	override string toString() {
		return format("Experiment[title=%s, cwd=%s, simulations.length=%d]", this.title, this.cwd, this.simulations.length);
	}
	
	string title() {
		return this.config.title;
	}
	
	string cwd() {
		return this.config.cwd;
	}
	
	ExperimentConfig config;
	ExperimentStat stat;
	
	Simulation[] simulations;
}

void runExperiment(string experimentName, void delegate(string) del = null) {	
	logging.infof(LogCategory.SIMULATOR, "runExperiment(experimentName=%s)", experimentName);
	
	if(del !is null) {
		del(format("runExperiment(experimentName=%s)", experimentName));
	}
	
	ExperimentConfig experimentConfig = ExperimentConfig.loadXML("../configs/experiments", experimentName ~ ".config.xml");
	Experiment experiment = new Experiment(experimentConfig);
	experiment.execute();
}

BenchmarkSuite[string] benchmarkSuites;
ExperimentConfig[string] experimentConfigs;
ExperimentStat[string] experimentStats;

void preloadConfigsAndStats(void delegate(string text) del) {
    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
    {
    	del("Loading benchmark config: <b>" ~ basename(name, ".xml") ~ "</b>");
		benchmarkSuites[basename(name, ".xml")] = BenchmarkSuite.loadXML("../configs/benchmarks", basename(name));
    }
    foreach (string name; dirEntries("../configs/experiments", SpanMode.breadth))
    {
    	del("Loading experiment config: <b>" ~ basename(name, ".config.xml") ~ "</b>");
		experimentConfigs[basename(name, ".config.xml")] = ExperimentConfig.loadXML("../configs/experiments", basename(name));
    }
    foreach (string name; dirEntries("../stats/experiments", SpanMode.breadth))
    {
    	del("Loading experiment stat: <b>" ~ basename(name, ".stat.xml") ~ "</b>");
		experimentStats[basename(name, ".stat.xml")] = ExperimentStat.loadXML("../stats/experiments", basename(name));
    }
}