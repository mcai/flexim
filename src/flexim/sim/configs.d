/*
 * flexim/sim/configs.d
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

module flexim.sim.configs;

import flexim.all;

import std.path;

abstract class Config(ConfigT) {
}

class Context {	
	this(uint num, string binariesDir, string benchmarkSuiteName, string benchmarkName) {
		this.num = num;
		this.binariesDir = binariesDir;
		this.benchmarkSuiteName = benchmarkSuiteName;
		this.benchmarkName = benchmarkName;
	}
	
	override string toString() {
		return format("Context[num=%d, binariesDir=%s, benchmarkSuiteName=%s, benchmarkName=%s]",
			this.num, this.binariesDir, this.benchmarkSuiteName, this.benchmarkName);
	}
	
	string exe() {
		return this.benchmark.exe;
	}
	
	string args() {
		return this.benchmark.args;
	}
	
	string cwd() {
		return join(this.binariesDir, this.benchmark.suite.cwd, this.benchmark.cwd);
	}
	
	string stdin() {
		return this.benchmark.stdin;
	}
	
	string stdout() {
		return this.benchmark.stdout;
	}
	
	Benchmark benchmark() {
		if(this._benchmark is null) {
			BenchmarkSuite benchmarkSuite = BenchmarkSuite.loadXML("../configs/benchmarks", this.benchmarkSuiteName ~ ".xml");
			this._benchmark = benchmarkSuite[this.benchmarkName];
		}
		
		return this._benchmark;
	}
	
	uint num;
	string binariesDir;
	
	string benchmarkSuiteName;
	string benchmarkName;
	
	Benchmark _benchmark;
}

class CPUConfig: Config!(CPUConfig) {
	this(ulong maxCycle, ulong maxInsts, ulong maxTime, uint numCores, uint numThreads) {
		this.maxCycle = maxCycle;
		this.maxInsts = maxInsts;
		this.maxTime = maxTime;
		this.numCores = numCores;
		this.numThreads = numThreads;
	}
	
	static CPUConfig createDefault(string binariesDir, Benchmark benchmark, ulong maxCycle, ulong maxInsts, ulong maxTime, uint numCores, uint numThreads) {
		CPUConfig cpuConfig = new CPUConfig(maxCycle, maxInsts, maxTime, numCores, numThreads);
		
		for(uint i = 0; i < numCores * numThreads; i++) {
			Context context = new Context(i, binariesDir, benchmark.suite.title, benchmark.title);
			cpuConfig.contexts ~= context;
		}
		
		return cpuConfig;
	}
	
	override string toString() {
		return format("CPUConfig[maxCycle=%d, maxInsts=%d, maxTime=%d, numCores=%d, numThreads=%d, contexts.length=%d]",
			this.maxCycle, this.maxInsts, this.maxTime, this.numCores, this.numThreads, this.contexts.length);
	}
	
	ulong maxCycle;
	ulong maxInsts;
	ulong maxTime;
	
	uint numCores;
	uint numThreads;
	
	Context[] contexts;
}

class CPUConfigXMLSerializer: XMLSerializer!(CPUConfig) {
	this() {
	}
	
	override XMLConfig save(CPUConfig cpuConfig) {
		XMLConfig xmlConfig = new XMLConfig("CPUConfig");
		
		xmlConfig.attributes["maxCycle"] = to!(string)(cpuConfig.maxCycle);
		xmlConfig.attributes["maxInsts"] = to!(string)(cpuConfig.maxInsts);
		xmlConfig.attributes["maxTime"] = to!(string)(cpuConfig.maxTime);
		xmlConfig.attributes["numCores"] = to!(string)(cpuConfig.numCores);
		xmlConfig.attributes["numThreads"] = to!(string)(cpuConfig.numThreads);
		
		foreach(context; cpuConfig.contexts) {
			XMLConfig xmlConfigContext = new XMLConfig("Context");
			xmlConfigContext.attributes["num"] = to!(string)(context.num);
			xmlConfigContext.attributes["binariesDir"] = context.binariesDir;
			xmlConfigContext.attributes["benchmarkSuiteName"] = context.benchmarkSuiteName;
			xmlConfigContext.attributes["benchmarkName"] = context.benchmarkName;
			
			xmlConfig.entries ~= xmlConfigContext;
		}
			
		return xmlConfig;
	}
	
	override CPUConfig load(XMLConfig xmlConfig) {
		ulong maxCycle = to!(ulong)(xmlConfig.attributes["maxCycle"]);
		ulong maxInsts = to!(ulong)(xmlConfig.attributes["maxInsts"]);
		ulong maxTime = to!(ulong)(xmlConfig.attributes["maxTime"]);
		uint numCores = to!(uint)(xmlConfig.attributes["numCores"]);
		uint numThreads = to!(uint)(xmlConfig.attributes["numThreads"]);
			
		CPUConfig cpuConfig = new CPUConfig(maxCycle, maxInsts, maxTime, numCores, numThreads);
				
		foreach(entry; xmlConfig.entries) {
			uint num = to!(uint)(entry.attributes["num"]);
			string binariesDir = entry.attributes["binariesDir"];
			string benchmarkSuiteName = entry.attributes["benchmarkSuiteName"];
			string benchmarkName = entry.attributes["benchmarkName"];
			
			Context context = new Context(num, binariesDir, benchmarkSuiteName, benchmarkName);
			cpuConfig.contexts ~= context;
		}
		
		return cpuConfig;
	}
	
	static this() {
		singleInstance = new CPUConfigXMLSerializer();
	}
	
	static CPUConfigXMLSerializer singleInstance;
}

enum CacheReplacementPolicy: string {
	LRU = "LRU",
	FIFO = "FIFO",
	Random = "Random"
}

class CacheGeometry {	
	this(string name, uint sets, uint assoc, uint blockSize, uint hitLatency, uint missLatency, CacheReplacementPolicy policy) {
		this.name = name;
		this.sets = sets;
		this.assoc = assoc;
		this.blockSize = blockSize;
		this.hitLatency = hitLatency;
		this.missLatency = missLatency;
		this.policy = policy;
	}
	
	override string toString() {
		return format("Cache[name=%s, sets=%d, assoc=%d, blockSize=%d, hitLatency=%d, missLatency=%d, policy=%s]",
			this.name, this.sets, this.assoc, this.blockSize, this.hitLatency, this.missLatency, this.policy);
	}
	
	string name;
	uint sets;
	uint assoc;
	uint blockSize;
	uint hitLatency;
	uint missLatency;
	CacheReplacementPolicy policy;
}

class CacheConfig: Config!(CacheConfig) {	
	this() {
	}
	
	override string toString() {
		return format("CacheConfig[caches.length=%d]", this.caches.length);
	}
	
	CacheGeometry[string] caches;
}

class CacheConfigXMLSerializer: XMLSerializer!(CacheConfig) {	
	this() {
	}
	
	override XMLConfig save(CacheConfig cacheConfig) {
		XMLConfig xmlConfig = new XMLConfig("CacheConfig");
		
		foreach(cacheName, cache; cacheConfig.caches) {
			XMLConfig xmlConfigCache = new XMLConfig("Cache");
			xmlConfigCache.attributes["name"] = cache.name;
			xmlConfigCache.attributes["sets"] = to!(string)(cache.sets);
			xmlConfigCache.attributes["assoc"] = to!(string)(cache.assoc);
			xmlConfigCache.attributes["blockSize"] = to!(string)(cache.blockSize);
			xmlConfigCache.attributes["hitLatency"] = to!(string)(cache.hitLatency);
			xmlConfigCache.attributes["missLatency"] = to!(string)(cache.missLatency);
			xmlConfigCache.attributes["policy"] = to!(string)(cache.policy);
				
			xmlConfig.entries ~= xmlConfigCache;
		}
		
		return xmlConfig;
	}
	
	override CacheConfig load(XMLConfig xmlConfig) {
		CacheConfig cacheConfig = new CacheConfig();
		
		foreach(entry; xmlConfig.entries) {
			string name = entry.attributes["name"];
			uint sets = to!(uint)(entry.attributes["sets"]);
			uint assoc = to!(uint)(entry.attributes["assoc"]);
			uint blockSize = to!(uint)(entry.attributes["blockSize"]);
			uint hitLatency = to!(uint)(entry.attributes["hitLatency"]);
			uint missLatency = to!(uint)(entry.attributes["missLatency"]);
			CacheReplacementPolicy policy = cast(CacheReplacementPolicy) (entry.attributes["policy"]);
				
			CacheGeometry cache = new CacheGeometry(name, sets, assoc, blockSize, hitLatency, missLatency, policy);
			cacheConfig.caches[cache.name] = cache;
		}
		
		return cacheConfig;
	}
	
	static this() {
		singleInstance = new CacheConfigXMLSerializer();
	}
	
	static CacheConfigXMLSerializer singleInstance;
}

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class SimulationConfig: Reproducible {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	override void beforeRun() {
		assert(this.cpuConfig !is null && this.cacheConfig !is null);
	}
	
	override void run() {
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	override void afterRun() {
	}
	
	override string toString() {
		return format("SimulationConfig[title=%s, cwd=%s]", this.title, this.cwd);
	}
	
	string title;
	string cwd;
	
	CPUConfig cpuConfig;
	CacheConfig cacheConfig;
}

class SimulationConfigXMLSerializer: XMLSerializer!(SimulationConfig) {
	this() {
	}
	
	override XMLConfig save(SimulationConfig simulationConfig) {
		XMLConfig xmlConfig = new XMLConfig("SimulationConfig");
		xmlConfig.attributes["title"] = simulationConfig.title;
		xmlConfig.attributes["cwd"] = simulationConfig.cwd;
		
		xmlConfig.entries ~= CPUConfigXMLSerializer.singleInstance.save(simulationConfig.cpuConfig);
		xmlConfig.entries ~= CacheConfigXMLSerializer.singleInstance.save(simulationConfig.cacheConfig);
		
		return xmlConfig;
	}
	
	override SimulationConfig load(XMLConfig xmlConfig) {
		string title = xmlConfig.attributes["title"];
		string cwd = xmlConfig.attributes["cwd"];
		
		SimulationConfig simulationConfig = new SimulationConfig(title, cwd);

		CPUConfig cpuConfig = CPUConfigXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		CacheConfig cacheConfig = CacheConfigXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		simulationConfig.cpuConfig = cpuConfig;
		simulationConfig.cacheConfig = cacheConfig;
		
		return simulationConfig;
	}
	
	static this() {
		singleInstance = new SimulationConfigXMLSerializer();
	}
	
	static SimulationConfigXMLSerializer singleInstance;
}

class ExperimentConfig: Reproducible {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, SimulationConfig[] simulationConfigs) {
		this.title = title;
		this.cwd = cwd;
		this.simulationConfigs = simulationConfigs;
	}
	
	void execute() {
		this.beforeRun();
		this.run();
		this.afterRun();
	}
	
	override void beforeRun() {		
		foreach(simulationConfig; this.simulationConfigs) {
			simulationConfig.beforeRun();
		}
	}
	
	override void run() {
		foreach(simulationConfig; this.simulationConfigs) {
			simulationConfig.run();
		}
	}
	
	override void afterRun() {
		foreach(simulationConfig; this.simulationConfigs) {
			simulationConfig.afterRun();
		}
	}
	
	override string toString() {
		return format("ExperimentConfig[title=%s, cwd=%s, simulationConfigs.length=%d]", this.title, this.cwd, this.simulationConfigs.length);
	}
	
	static ExperimentConfig loadXML(string cwd, string fileName) {
		return ExperimentConfigXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(ExperimentConfig experimentConfig, string cwd, string fileName) {
		ExperimentConfigXMLFileSerializer.singleInstance.saveXML(experimentConfig, join(cwd, fileName));
	}
	
	string title;
	string cwd;
	SimulationConfig[] simulationConfigs;
}

class ExperimentConfigXMLFileSerializer: XMLFileSerializer!(ExperimentConfig) {
	this() {
	}
	
	override XMLConfigFile save(ExperimentConfig experimentConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("ExperimentConfig");
		
		xmlConfigFile.attributes["title"] = experimentConfig.title;
		xmlConfigFile.attributes["cwd"] = experimentConfig.cwd;
			
		foreach(simulationConfig; experimentConfig.simulationConfigs) {
			xmlConfigFile.entries ~= SimulationConfigXMLSerializer.singleInstance.save(simulationConfig);
		}
			
		return xmlConfigFile;
	}
	
	override ExperimentConfig load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile.attributes["title"];
		string cwd = xmlConfigFile.attributes["cwd"];
		
		ExperimentConfig experimentConfig = new ExperimentConfig(title, cwd);

		foreach(entry; xmlConfigFile.entries) {
			experimentConfig.simulationConfigs ~= SimulationConfigXMLSerializer.singleInstance.load(entry);
		}

		return experimentConfig;
	}
	
	static this() {
		singleInstance = new ExperimentConfigXMLFileSerializer();
	}
	
	static ExperimentConfigXMLFileSerializer singleInstance;
}