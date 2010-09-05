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

class ContextConfig: Config!(ContextConfig) {	
	this(uint num, string binariesDir, string benchmarkSuiteName, string benchmarkName) {
		this.num = num;
		this.binariesDir = binariesDir;
		this.benchmarkSuiteName = benchmarkSuiteName;
		this.benchmarkName = benchmarkName;
	}
	
	override string toString() {
		return format("ContextConfig[num=%d, binariesDir=%s, benchmarkSuiteName=%s, benchmarkName=%s]",
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

class ContextConfigXMLSerializer: XMLSerializer!(ContextConfig) {
	this() {
	}
	
	override XMLConfig save(ContextConfig contextConfig) {
		XMLConfig xmlConfig = new XMLConfig("ContextConfig");
		xmlConfig["num"] = to!(string)(contextConfig.num);
		xmlConfig["binariesDir"] = contextConfig.binariesDir;
		xmlConfig["benchmarkSuiteName"] = contextConfig.benchmarkSuiteName;
		xmlConfig["benchmarkName"] = contextConfig.benchmarkName;
			
		return xmlConfig;
	}
	
	override ContextConfig load(XMLConfig xmlConfig) {
		uint num = to!(uint)(xmlConfig["num"]);
		string binariesDir = xmlConfig["binariesDir"];
		string benchmarkSuiteName = xmlConfig["benchmarkSuiteName"];
		string benchmarkName = xmlConfig["benchmarkName"];
		
		ContextConfig contextConfig = new ContextConfig(num, binariesDir, benchmarkSuiteName, benchmarkName);
		return contextConfig;
	}
	
	static this() {
		singleInstance = new ContextConfigXMLSerializer();
	}
	
	static ContextConfigXMLSerializer singleInstance;
}

class ProcessorConfig: Config!(ProcessorConfig) {	
	this(ulong maxCycle, ulong maxInsts, ulong maxTime, uint numCores, uint numThreads) {
		this.maxCycle = maxCycle;
		this.maxInsts = maxInsts;
		this.maxTime = maxTime;
		this.numCores = numCores;
		this.numThreads = numThreads;
	}
	
	static ProcessorConfig createDefault(string binariesDir, Benchmark benchmark, ulong maxCycle, ulong maxInsts, ulong maxTime, uint numCores, uint numThreads) {
		ProcessorConfig processorConfig = new ProcessorConfig(maxCycle, maxInsts, maxTime, numCores, numThreads);
		
		for(uint i = 0; i < numCores * numThreads; i++) {
			ContextConfig contextConfig = new ContextConfig(i, binariesDir, benchmark.suite.title, benchmark.title);
			processorConfig.contexts ~= contextConfig;
		}
		
		return processorConfig;
	}
	
	override string toString() {
		return format("ProcessorConfig[maxCycle=%d, maxInsts=%d, maxTime=%d, numCores=%d, numThreads=%d, contexts.length=%d]",
			this.maxCycle, this.maxInsts, this.maxTime, this.numCores, this.numThreads, this.contexts.length);
	}
	
	ulong maxCycle;
	ulong maxInsts;
	ulong maxTime;
	
	uint numCores;
	uint numThreads;
	
	ContextConfig[] contexts;
}

class ProcessorConfigXMLSerializer: XMLSerializer!(ProcessorConfig) {
	this() {
	}
	
	override XMLConfig save(ProcessorConfig processorConfig) {
		XMLConfig xmlConfig = new XMLConfig("ProcessorConfig");
		
		xmlConfig["maxCycle"] = to!(string)(processorConfig.maxCycle);
		xmlConfig["maxInsts"] = to!(string)(processorConfig.maxInsts);
		xmlConfig["maxTime"] = to!(string)(processorConfig.maxTime);
		xmlConfig["numCores"] = to!(string)(processorConfig.numCores);
		xmlConfig["numThreads"] = to!(string)(processorConfig.numThreads);
		
		foreach(context; processorConfig.contexts) {
			xmlConfig.entries ~= ContextConfigXMLSerializer.singleInstance.save(context);
		}
			
		return xmlConfig;
	}
	
	override ProcessorConfig load(XMLConfig xmlConfig) {
		ulong maxCycle = to!(ulong)(xmlConfig["maxCycle"]);
		ulong maxInsts = to!(ulong)(xmlConfig["maxInsts"]);
		ulong maxTime = to!(ulong)(xmlConfig["maxTime"]);
		uint numCores = to!(uint)(xmlConfig["numCores"]);
		uint numThreads = to!(uint)(xmlConfig["numThreads"]);
			
		ProcessorConfig processorConfig = new ProcessorConfig(maxCycle, maxInsts, maxTime, numCores, numThreads);
				
		foreach(entry; xmlConfig.entries) {
			processorConfig.contexts ~= ContextConfigXMLSerializer.singleInstance.load(entry);
		}
		
		return processorConfig;
	}
	
	static this() {
		singleInstance = new ProcessorConfigXMLSerializer();
	}
	
	static ProcessorConfigXMLSerializer singleInstance;
}

class CacheConfig: Config!(CacheConfig) {
	this(string name, uint level, uint numSets, uint assoc, uint blockSize, uint hitLatency, uint missLatency, CacheReplacementPolicy policy) {
		this.name = name;
		this.level = level;
		this.numSets = numSets;
		this.assoc = assoc;
		this.blockSize = blockSize;
		this.hitLatency = hitLatency;
		this.missLatency = missLatency;
		this.policy = policy;
	}
	
	override string toString() {
		return format("CacheConfig[name=%s, level=%d, numSets=%d, assoc=%d, blockSize=%d, hitLatency=%d, missLatency=%d, policy=%s]",
			this.name, this.level, this.numSets, this.assoc, this.blockSize, this.hitLatency, this.missLatency, this.policy);
	}
	
	string name;
	uint level;
	uint numSets;
	uint assoc;
	uint blockSize;
	uint hitLatency;
	uint missLatency;
	CacheReplacementPolicy policy;
}

class CacheConfigXMLSerializer: XMLSerializer!(CacheConfig) {	
	this() {
	}
	
	override XMLConfig save(CacheConfig cacheConfig) {
		XMLConfig xmlConfig = new XMLConfig("CacheConfig");
		
		xmlConfig["name"] = cacheConfig.name;
		xmlConfig["level"] = to!(string)(cacheConfig.level);
		xmlConfig["numSets"] = to!(string)(cacheConfig.numSets);
		xmlConfig["assoc"] = to!(string)(cacheConfig.assoc);
		xmlConfig["blockSize"] = to!(string)(cacheConfig.blockSize);
		xmlConfig["hitLatency"] = to!(string)(cacheConfig.hitLatency);
		xmlConfig["missLatency"] = to!(string)(cacheConfig.missLatency);
		xmlConfig["policy"] = to!(string)(cacheConfig.policy);
		
		return xmlConfig;
	}
	
	override CacheConfig load(XMLConfig xmlConfig) {
		string name = xmlConfig["name"];
		uint level = to!(uint)(xmlConfig["level"]);
		uint numSets = to!(uint)(xmlConfig["numSets"]);
		uint assoc = to!(uint)(xmlConfig["assoc"]);
		uint blockSize = to!(uint)(xmlConfig["blockSize"]);
		uint hitLatency = to!(uint)(xmlConfig["hitLatency"]);
		uint missLatency = to!(uint)(xmlConfig["missLatency"]);
		CacheReplacementPolicy policy = cast(CacheReplacementPolicy) (xmlConfig["policy"]);
			
		CacheConfig cacheConfig = new CacheConfig(name, level, numSets, assoc, blockSize, hitLatency, missLatency, policy);
		
		return cacheConfig;
	}
	
	static this() {
		singleInstance = new CacheConfigXMLSerializer();
	}
	
	static CacheConfigXMLSerializer singleInstance;
}

class MemoryConfig: Config!(MemoryConfig) {
	this(uint latency) {
		this.latency = latency;
	}
	
	override string toString() {
		return format("MemoryConfig[latency=%d]", this.latency);
	}
	
	uint latency;
}

class MemoryConfigXMLSerializer: XMLSerializer!(MemoryConfig) {
	this() {
	}
	
	override XMLConfig save(MemoryConfig memoryConfig) {
		XMLConfig xmlConfig = new XMLConfig("MemoryConfig");
		
		xmlConfig["latency"] = to!(string)(memoryConfig.latency);
		
		return xmlConfig;
	}
	
	override MemoryConfig load(XMLConfig xmlConfig) {
		uint latency = to!(uint)(xmlConfig["latency"]);
			
		MemoryConfig memoryConfig = new MemoryConfig(latency);
		
		return memoryConfig;
	}
	
	static this() {
		singleInstance = new MemoryConfigXMLSerializer();
	}
	
	static MemoryConfigXMLSerializer singleInstance;
}

class MemorySystemConfig: Config!(MemorySystemConfig) {		
	this() {
	}
	
	override string toString() {
		return format("MemorySystemConfig[caches.length=%d]", this.caches.length);
	}
	
	CacheConfig[string] caches;	
	MemoryConfig mem;
}

class MemorySystemConfigXMLSerializer: XMLSerializer!(MemorySystemConfig) {	
	this() {
	}
	
	override XMLConfig save(MemorySystemConfig memorySystemConfig) {
		XMLConfig xmlConfig = new XMLConfig("MemorySystemConfig");
		xmlConfig["numCaches"] = to!(string)(memorySystemConfig.caches.length);
		
		foreach(cacheName, cache; memorySystemConfig.caches) {
			xmlConfig.entries ~= CacheConfigXMLSerializer.singleInstance.save(cache);
		}
		
		xmlConfig.entries ~= MemoryConfigXMLSerializer.singleInstance.save(memorySystemConfig.mem);
		
		return xmlConfig;
	}
	
	override MemorySystemConfig load(XMLConfig xmlConfig) {
		MemorySystemConfig memorySystemConfig = new MemorySystemConfig();
		uint numCaches = to!(uint)(xmlConfig["numCaches"]);
			
		for(uint i = 0; i < numCaches; i++) {
			CacheConfig cacheConfig = CacheConfigXMLSerializer.singleInstance.load(xmlConfig.entries[i]);
			memorySystemConfig.caches[cacheConfig.name] = cacheConfig;
		}
		
		memorySystemConfig.mem = MemoryConfigXMLSerializer.singleInstance.load(xmlConfig.entries[numCaches]);
		
		return memorySystemConfig;
	}
	
	static this() {
		singleInstance = new MemorySystemConfigXMLSerializer();
	}
	
	static MemorySystemConfigXMLSerializer singleInstance;
}

class SimulationConfig {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	override string toString() {
		return format("SimulationConfig[title=%s, cwd=%s]", this.title, this.cwd);
	}
	
	string title;
	string cwd;
	
	ProcessorConfig processorConfig;
	MemorySystemConfig memorySystemConfig;
}

class SimulationConfigXMLSerializer: XMLSerializer!(SimulationConfig) {
	this() {
	}
	
	override XMLConfig save(SimulationConfig simulationConfig) {
		XMLConfig xmlConfig = new XMLConfig("SimulationConfig");
		xmlConfig["title"] = simulationConfig.title;
		xmlConfig["cwd"] = simulationConfig.cwd;
		
		xmlConfig.entries ~= ProcessorConfigXMLSerializer.singleInstance.save(simulationConfig.processorConfig);
		xmlConfig.entries ~= MemorySystemConfigXMLSerializer.singleInstance.save(simulationConfig.memorySystemConfig);
		
		return xmlConfig;
	}
	
	override SimulationConfig load(XMLConfig xmlConfig) {
		string title = xmlConfig["title"];
		string cwd = xmlConfig["cwd"];
		
		SimulationConfig simulationConfig = new SimulationConfig(title, cwd);

		ProcessorConfig processorConfig = ProcessorConfigXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		MemorySystemConfig memorySystemConfig = MemorySystemConfigXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		simulationConfig.processorConfig = processorConfig;
		simulationConfig.memorySystemConfig = memorySystemConfig;
		
		return simulationConfig;
	}
	
	static this() {
		singleInstance = new SimulationConfigXMLSerializer();
	}
	
	static SimulationConfigXMLSerializer singleInstance;
}

class ExperimentConfig {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, SimulationConfig[] simulationConfigs) {
		this.title = title;
		this.cwd = cwd;
		this.simulationConfigs = simulationConfigs;
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
		
		xmlConfigFile["title"] = experimentConfig.title;
		xmlConfigFile["cwd"] = experimentConfig.cwd;
			
		foreach(simulationConfig; experimentConfig.simulationConfigs) {
			xmlConfigFile.entries ~= SimulationConfigXMLSerializer.singleInstance.save(simulationConfig);
		}
			
		return xmlConfigFile;
	}
	
	override ExperimentConfig load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		
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