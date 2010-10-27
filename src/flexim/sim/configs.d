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
			this.name, this.level, this.numSets, this.assoc,  this.blockSize, this.hitLatency, this.missLatency, this.policy);
	}

	string name;
	uint level, numSets, assoc, blockSize, hitLatency, missLatency;
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

class MainMemoryConfig: Config!(MainMemoryConfig) {
	this(uint latency) {
		this.latency = latency;
	}
	
	override string toString() {
		return format("MainMemoryConfig[latency=%d]", this.latency);
	}

	uint latency;
}

class MainMemoryConfigXMLSerializer: XMLSerializer!(MainMemoryConfig) {
	this() {
	}
	
	override XMLConfig save(MainMemoryConfig mainMemoryConfig) {
		XMLConfig xmlConfig = new XMLConfig("MainMemoryConfig");
		
		xmlConfig["latency"] = to!(string)(mainMemoryConfig.latency);
		
		return xmlConfig;
	}
	
	override MainMemoryConfig load(XMLConfig xmlConfig) {
		uint latency = to!(uint)(xmlConfig["latency"]);
			
		MainMemoryConfig mainMemoryConfig = new MainMemoryConfig(latency);
		
		return mainMemoryConfig;
	}
	
	static this() {
		singleInstance = new MainMemoryConfigXMLSerializer();
	}
	
	static MainMemoryConfigXMLSerializer singleInstance;
}

class ContextConfig: Config!(ContextConfig) {
	this(string binariesDir, Benchmark workload) {
		this.binariesDir = binariesDir;
		this.workload = workload;
	}
	
	this(string binariesDir, string benchmarkSuiteTitle, string benchmarkTitle) {
		this(binariesDir, benchmarkSuites[benchmarkSuiteTitle][benchmarkTitle]);
	}
	
	string benchmarkSuiteTitle() {
		return this.workload.suite.title;
	}
	
	string benchmarkTitle() {
		return this.workload.title;
	}
	
	string exe() {
		return this.workload.exe;
	}
	
	string args() {
		return this.workload.args;
	}
	
	string cwd() {
		return join(this.binariesDir, this.workload.suite.cwd, this.workload.cwd);
	}
	
	string stdin() {
		return this.workload.stdin;
	}
	
	string stdout() {
		return this.workload.stdout;
	}
	
	override string toString() {
		return format("ContextConfig[binariesDir=%s, benchmarkSuiteTitle=%s, benchmarkTitle=%s]",
			this.binariesDir, this.benchmarkSuiteTitle, this.benchmarkTitle);
	}

	string binariesDir;
	Benchmark workload;
}

class ContextConfigXMLSerializer: XMLSerializer!(ContextConfig) {
	this() {
	}
	
	override XMLConfig save(ContextConfig contextConfig) {
		XMLConfig xmlConfig = new XMLConfig("ContextConfig");
		xmlConfig["binariesDir"] = contextConfig.binariesDir;
		xmlConfig["benchmarkSuiteTitle"] = contextConfig.benchmarkSuiteTitle;
		xmlConfig["benchmarkTitle"] = contextConfig.benchmarkTitle;
		
		return xmlConfig;
	}
	
	override ContextConfig load(XMLConfig xmlConfig) {
		string binariesDir = xmlConfig["binariesDir"];
		string benchmarkSuiteTitle = xmlConfig["benchmarkSuiteTitle"];
		string benchmarkTitle = xmlConfig["benchmarkTitle"];
		
		ContextConfig contextConfig = new ContextConfig(binariesDir, benchmarkSuiteTitle, benchmarkTitle);
		return contextConfig;
	}
	
	static this() {
		singleInstance = new ContextConfigXMLSerializer();
	}
	
	static ContextConfigXMLSerializer singleInstance;
}

class CoreConfig: Config!(CoreConfig) {
	this(CacheConfig iCache, CacheConfig dCache) {
		this.iCache = iCache;
		this.dCache = dCache;
	}
	
	override string toString() {
		return format("CoreConfig[iCache=%s, dCache=%s]",
			this.iCache, this.dCache);
	}

	CacheConfig iCache, dCache;
}

class CoreConfigXMLSerializer: XMLSerializer!(CoreConfig) {
	this() {
	}
	
	override XMLConfig save(CoreConfig coreConfig) {
		XMLConfig xmlConfig = new XMLConfig("CoreConfig");
		
		xmlConfig.entries ~= CacheConfigXMLSerializer.singleInstance.save(coreConfig.iCache);
		xmlConfig.entries ~= CacheConfigXMLSerializer.singleInstance.save(coreConfig.dCache);
		
		return xmlConfig;
	}
	
	override CoreConfig load(XMLConfig xmlConfig) {
		CacheConfig iCache = CacheConfigXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		CacheConfig dCache = CacheConfigXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		CoreConfig coreConfig = new CoreConfig(iCache, dCache);
		
		return coreConfig;
	}
	
	static this() {
		singleInstance = new CoreConfigXMLSerializer();
	}
	
	static CoreConfigXMLSerializer singleInstance;
}

class ProcessorConfig: Config!(ProcessorConfig) {
	this(ulong maxCycle, ulong maxInsts, ulong maxTime, uint numThreadsPerCore) {
		this.maxCycle = maxCycle;
		this.maxInsts = maxInsts;
		this.maxTime = maxTime;
		this.numThreadsPerCore = numThreadsPerCore;
	}
	
	uint numCores() {
		return this.cores.length;
	}
	
	override string toString() {
		return format("ProcessorConfig[maxCycle=%d, maxInsts=%d, maxTime=%d, numThreadsPerCore=%d, cores.length=%d, contexts.length=%d]",
			this.maxCycle, this.maxInsts, this.maxTime, this.numThreadsPerCore, this.cores.length, this.contexts.length);
	}

	ulong maxCycle, maxInsts, maxTime;
	uint numThreadsPerCore;
	CoreConfig[] cores;
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
		xmlConfig["numThreadsPerCore"] = to!(string)(processorConfig.numThreadsPerCore);
			
		foreach(core; processorConfig.cores) {
			xmlConfig.entries ~= CoreConfigXMLSerializer.singleInstance.save(core);
		}
		
		foreach(context; processorConfig.contexts) {
			xmlConfig.entries ~= ContextConfigXMLSerializer.singleInstance.save(context);
		}
		
		return xmlConfig;		
	}
	
	override ProcessorConfig load(XMLConfig xmlConfig) {
		ulong maxCycle = to!(ulong)(xmlConfig["maxCycle"]);
		ulong maxInsts = to!(ulong)(xmlConfig["maxInsts"]);
		ulong maxTime = to!(ulong)(xmlConfig["maxTime"]);
		uint numThreadsPerCore = to!(uint)(xmlConfig["numThreadsPerCore"]);
			
		ProcessorConfig processorConfig = new ProcessorConfig(maxCycle, maxInsts, maxTime, numThreadsPerCore);
		
		foreach(entry; xmlConfig.entries) {
			if(entry.typeName == "CoreConfig") {
				processorConfig.cores ~= CoreConfigXMLSerializer.singleInstance.load(entry);
			}
			else if(entry.typeName == "ContextConfig") {
				processorConfig.contexts ~= ContextConfigXMLSerializer.singleInstance.load(entry);
			}
			else {
				assert(0);
			}
		}
		
		return processorConfig;
	}
	
	static this() {
		singleInstance = new ProcessorConfigXMLSerializer();
	}
	
	static ProcessorConfigXMLSerializer singleInstance;
}

class SimulationConfig: Config!(SimulationConfig) {
	this(string title, string cwd, ProcessorConfig processor, CacheConfig l2Cache, MainMemoryConfig mainMemory) {
		this.title = title;
		this.cwd = cwd;
		this.processor = processor;
		this.l2Cache = l2Cache;
		this.mainMemory = mainMemory;
	}
	
	CacheConfig[string] caches() {
		CacheConfig[string] cacheMap;
		
		foreach(i, core; processor.cores) {
			cacheMap[format("l1I-%d", i)] = core.iCache;
			cacheMap[format("l1D-%d", i)] = core.dCache;
		}
		
		cacheMap["l2"] = this.l2Cache;
		
		return cacheMap;
	}
	
	override string toString() {
		return format("SimulationConfig[title=%s, cwd=%s, processor=%s, l2Cache=%s, mainMemory=%s]",
			this.title, this.cwd, this.processor, this.l2Cache, this.mainMemory);
	}

	string title, cwd;
	ProcessorConfig processor;
	CacheConfig l2Cache;
	MainMemoryConfig mainMemory;
	
	static SimulationConfig loadXML(string cwd, string fileName) {
		return SimulationConfigXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(SimulationConfig sharedL2MulticoreConfig, string cwd, string fileName) {
		SimulationConfigXMLFileSerializer.singleInstance.saveXML(sharedL2MulticoreConfig, join(cwd, fileName));
	}
	
	static void saveXML(SimulationConfig sharedL2MulticoreConfig) {
		saveXML(sharedL2MulticoreConfig, "../configs/simulations", sharedL2MulticoreConfig.title ~ ".config.xml");
	}
}

class SimulationConfigXMLFileSerializer: XMLFileSerializer!(SimulationConfig) {
	this() {
	}
	
	override XMLConfigFile save(SimulationConfig sharedL2MulticoreConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("SimulationConfig");
		xmlConfigFile["title"] = sharedL2MulticoreConfig.title;
		xmlConfigFile["cwd"] = sharedL2MulticoreConfig.cwd;
		
		xmlConfigFile.entries ~= ProcessorConfigXMLSerializer.singleInstance.save(sharedL2MulticoreConfig.processor);
		xmlConfigFile.entries ~= CacheConfigXMLSerializer.singleInstance.save(sharedL2MulticoreConfig.l2Cache);
		xmlConfigFile.entries ~= MainMemoryConfigXMLSerializer.singleInstance.save(sharedL2MulticoreConfig.mainMemory);
		
		return xmlConfigFile;
	}
	
	override SimulationConfig load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		
		ProcessorConfig processor = ProcessorConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		CacheConfig l2Cache = CacheConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		MainMemoryConfig mainMemory = MainMemoryConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[2]);
		
		SimulationConfig sharedL2MulticoreConfig = new SimulationConfig(title, cwd, processor, l2Cache, mainMemory);
		return sharedL2MulticoreConfig;
	}
	
	static this() {
		singleInstance = new SimulationConfigXMLFileSerializer();
	}
	
	static SimulationConfigXMLFileSerializer singleInstance;
}