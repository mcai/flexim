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
	
	void execute() {
		this.beforeRun();
		this.run();
		this.afterRun();
	}
	
	override void beforeRun() {
	}
	
	override void run() {
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	override void afterRun() {
		SimulationStat.saveXML(this.stat, this.cwd, this.title ~ ".stat.xml");
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

void runSimulation(string simulationName, void delegate(string) del = null) {	
	logging.infof(LogCategory.SIMULATOR, "runSimulation(simulationName=%s)", simulationName);
	
	if(del !is null) {
		del(format("runSimulation(simulationName=%s)", simulationName));
	}
	
	SimulationConfig simulationConfig = SimulationConfig.loadXML("../configs/simulations", simulationName ~ ".config.xml");
	Simulation simulation = new Simulation(simulationConfig);
	simulation.execute();
}

BenchmarkSuite[string] benchmarkSuites;
SimulationConfig[string] simulationConfigs;
SimulationStat[string] simulationStats;

void loadConfigsAndStats(void delegate(string text) del) {
    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
    {
    	string baseName = basename(name, ".xml");
    	del("Loading benchmark config: <b>" ~ baseName ~ "</b>");
		benchmarkSuites[baseName] = BenchmarkSuite.loadXML("../configs/benchmarks", basename(name));
		assert(benchmarkSuites[baseName].title == baseName);
    }
    foreach (string name; dirEntries("../configs/simulations", SpanMode.breadth))
    {
    	string baseName = basename(name, ".config.xml");
    	del("Loading simulation config: <b>" ~ baseName ~ "</b>");
		simulationConfigs[baseName] = SimulationConfig.loadXML("../configs/simulations", basename(name));
		assert(simulationConfigs[baseName].title == baseName);
    }
    foreach (string name; dirEntries("../stats/simulations", SpanMode.breadth))
    {
    	string baseName = basename(name, ".stat.xml");
    	del("Loading simulation stat: <b>" ~ baseName ~ "</b>");
		simulationStats[baseName] = SimulationStat.loadXML("../stats/simulations", basename(name));
		assert(simulationStats[baseName].title == baseName);
    }
}

void saveConfigsAndStats() {
    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    foreach (string name; dirEntries("../configs/simulations", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    foreach (string name; dirEntries("../stats/simulations", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    
	foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
		BenchmarkSuite.saveXML(benchmarkSuite);
	}	
	foreach(simulationConfigTitle, simulationConfig; simulationConfigs) {
		SimulationConfig.saveXML(simulationConfig);
	}
	foreach(simulationStatTitle, simulationStat; simulationStats) {
		SimulationStat.saveXML(simulationStat);
	}
}

/*
void runSimulationCode() {
	string oldButtonLabel = button.getLabel();
	
	core.thread.Thread threadRunSimulation = new core.thread.Thread(
		{
			runSimulation(this.selectedSimulationName, delegate void(string text)
				{
					this.startup.mainWindow.setTitle(text);
				}); //TODO
			
			this.buttonSimulationStatView.setSensitive(true);
			this.buttonSimulationRun.setSensitive(true);
			this.buttonSimulationRun.setLabel(oldButtonLabel);
		});

	this.buttonSimulationStatView.setSensitive(false);
	this.buttonSimulationRun.setSensitive(false);
	this.buttonSimulationRun.setLabel("Simulating.. Please Wait");
	threadRunSimulation.start();
}
*/