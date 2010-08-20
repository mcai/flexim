/*
 * flexim/sim/simulations.d
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
import std.process;

const string EXPERIMENT_CONFIG_XML =  "experiment_config.xml";

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	override void beforeRun() {
		assert(this.cpuConfig !is null && this.cacheConfig !is null && this.contextConfig !is null);
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
	
	static Simulation loadXML(string title, string cwd) {
		Simulation simulation = new Simulation(title, cwd);
		
		simulation.cpuConfig = CPUConfig.loadXML(cwd);
		simulation.cacheConfig = CacheConfig.loadXML(cwd);
		simulation.contextConfig = ContextConfig.loadXML(cwd);
		
		return simulation;
	}
	
	static void saveXML(Simulation simulation, string cwd) {
		CPUConfig.saveXML(simulation.cpuConfig,cwd);
		CacheConfig.saveXML(simulation.cacheConfig, cwd);
		ContextConfig.saveXML(simulation.contextConfig, cwd);
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
	}
	
	override string toString() {
		return format("Experiment[title=%s, cwd=%s, simulations.length=%d]", this.title, this.cwd, this.simulations.length);
	}
	
	static Experiment loadXML(string cwd, string fileName = EXPERIMENT_CONFIG_XML) {
		return ExperimentXMLSerializer.instance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(Experiment experiment, string cwd, string fileName = EXPERIMENT_CONFIG_XML) {
		ExperimentXMLSerializer.instance.saveXML(experiment, join(cwd, fileName));
	}
	
	static Experiment createDefault(string title, string cwd, string binariesDir, Benchmark benchmark, uint numCores, uint numThreads) {
		Experiment experiment = new Experiment(title, cwd);
		
		Simulation simulation = new Simulation("testSim", "./");
		experiment.simulations ~= simulation;
		
		CPUConfig cpuConfig = CPUConfig.createDefault(numCores, numThreads);
		CacheConfig cacheConfig = CacheConfig.createDefault(numCores, numThreads);
		
		ContextConfig contextConfig = ContextConfig.createDefault(binariesDir, benchmark, numCores, numThreads);
		
		simulation.cpuConfig = cpuConfig;
		simulation.cacheConfig = cacheConfig;
		simulation.contextConfig = contextConfig;
		
		return experiment;
	}
	
	string title;
	string cwd;
	Simulation[] simulations;
}

class ExperimentXMLSerializer: XMLSerializer!(Experiment) {
	this() {
	}
	
	override XMLConfigFile save(Experiment experiment) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("Experiment");
		
		xmlConfigFile.attributes["title"] = experiment.title;
		xmlConfigFile.attributes["cwd"] = experiment.cwd;
			
		foreach(simulation; experiment.simulations) {
			XMLConfig xmlConfig = new XMLConfig("Simulation");
			xmlConfig.attributes["title"] = simulation.title;
			xmlConfig.attributes["cwd"] = simulation.cwd;
			
			xmlConfigFile.entries ~= xmlConfig;
		}
			
		return xmlConfigFile;
	}
	
	override Experiment load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile.attributes["title"];
		string cwd = xmlConfigFile.attributes["cwd"];
		
		Experiment experiment = new Experiment(title, cwd);

		foreach(entry; xmlConfigFile.entries) {
			string simulationTitle = entry.attributes["title"];
			string simulationCwd = entry.attributes["cwd"];
			
			Simulation simulation = new Simulation(simulationTitle, simulationCwd);
			experiment.simulations ~= simulation;
		}

		return experiment;
	}
	
	static this() {
		instance = new ExperimentXMLSerializer();
	}
	
	static ExperimentXMLSerializer instance;
}