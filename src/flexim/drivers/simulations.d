/*
 * flexim/drivers/simulations.d
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

module flexim.drivers.simulations;

import flexim.all;

import std.file;
import std.path;
import std.process;

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
		this.cpuConfig = CPUConfigXMLSerializer.instance.loadXML(join(this.cwd, "cpu_config.xml"), CPUConfig.createDefault(1, 1));
		this.cacheConfig = CacheConfigXMLSerializer.instance.loadXML(join(this.cwd, "cache_config.xml"), CacheConfig.createDefault(1, 1));
		this.contextConfig = ContextConfigXMLSerializer.instance.loadXML(join(this.cwd, "context_config.xml"), ContextConfig.createDefault(1, 1));
	}
	
	override void run() {		
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	override void afterRun() {
		CPUConfigXMLSerializer.instance.saveXML(this.cpuConfig, join(this.cwd, "cpu_config.xml"));
		CacheConfigXMLSerializer.instance.saveXML(this.cacheConfig, join(this.cwd, "cache_config.xml"));
		ContextConfigXMLSerializer.instance.saveXML(this.contextConfig, join(this.cwd, "context_config.xml"));
	}
	
	override string toString() {
		return format("Simulation[title=%s, cwd=%s]", this.title, this.cwd);
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
		Experiment experiment = ExperimentXMLSerializer.instance.loadXML(join(this.cwd, "experiment.xml"), Experiment.createDefault(1, 1));
		this.simulations = experiment.simulations;
		
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
		
		ExperimentXMLSerializer.instance.saveXML(this, join(this.cwd, "experiment.xml"));
	}
	
	override string toString() {
		return format("Experiment[title=%s, cwd=%s, simulations.length=%d]", this.title, this.cwd, this.simulations.length);
	}
	
	static Experiment createDefault(uint numCores = 2, uint numThreads = 2) {
		Experiment experiment = new Experiment("testExp", "./");
		
		Simulation simulation = new Simulation("testSim", "./");
		experiment.simulations ~= simulation;
		
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