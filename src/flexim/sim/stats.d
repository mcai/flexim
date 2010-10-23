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

module flexim.sim.stats;

import flexim.all;

import std.path;

abstract class Stat {
}

class ThreadStat: Stat, PropertiesProvider {
	this(uint num) {
		this.num = num;
	}
	
	override string[string] properties() {
		string[string] props;
		props["num"] = to!(string)(this.num);
		props["totalInsts"] = to!(string)(this.totalInsts);
		
		return props;
	}
	
	override string toString() {
		return format("ThreadStat[num=%d]", this.num);
	}
	
	uint num;
	ulong totalInsts;
}

class ThreadStatXMLSerializer: XMLSerializer!(ThreadStat) {
	this() {
	}
	
	override XMLConfig save(ThreadStat threadStat) {
		XMLConfig xmlConfig = new XMLConfig("ThreadStat");
		
		xmlConfig["num"] = to!(string)(threadStat.num);
		xmlConfig["totalInsts"] = to!(string)(threadStat.totalInsts);
			
		return xmlConfig;
	}
	
	override ThreadStat load(XMLConfig xmlConfig) {
		uint num = to!(uint)(xmlConfig["num"]);
		ulong totalInsts = to!(ulong)(xmlConfig["totalInsts"]);
			
		ThreadStat threadStat = new ThreadStat(num);
		threadStat.totalInsts = totalInsts;

		return threadStat;
	}
	
	static this() {
		singleInstance = new ThreadStatXMLSerializer();
	}
	
	static ThreadStatXMLSerializer singleInstance;
}

class ProcessorStat: Stat, PropertiesProvider {
	this() {
	}
	
	override string[string] properties() {
		string[string] props;
		
		return props;
	}
	
	override string toString() {
		return format("ProcessorStat[threadStats.length=%d]", this.threadStats.length);
	}
	
	ThreadStat[] threadStats;
}

class ProcessorStatXMLSerializer: XMLSerializer!(ProcessorStat) {	
	this() {
	}
	
	override XMLConfig save(ProcessorStat processorStat) {
		XMLConfig xmlConfig = new XMLConfig("ProcessorStat");
		
		foreach(threadName, threadStat; processorStat.threadStats) {
			xmlConfig.entries ~= ThreadStatXMLSerializer.singleInstance.save(threadStat);
		}
		
		return xmlConfig;
	}
	
	override ProcessorStat load(XMLConfig xmlConfig) {
		ProcessorStat processorStat = new ProcessorStat();
		
		foreach(entry; xmlConfig.entries) {
			ThreadStat threadStat = ThreadStatXMLSerializer.singleInstance.load(entry);
			processorStat.threadStats ~= threadStat;
		}
		
		return processorStat;
	}
	
	static this() {
		singleInstance = new ProcessorStatXMLSerializer();
	}
	
	static ProcessorStatXMLSerializer singleInstance;
}

class CacheStat: Stat, PropertiesProvider {
	this(string name) {
		this.name = name;
	}
	
	override string[string] properties() {
		string[string] props;
		
		props["name"] = this.name;
		props["accesses"] = to!(string)(this.accesses);
		props["hits"] = to!(string)(this.hits);
		props["evictions"] = to!(string)(this.evictions);
		props["reads"] = to!(string)(this.reads);
		props["blockingReads"] = to!(string)(this.blockingReads);
		props["nonblockingReads"] = to!(string)(this.nonblockingReads);
		props["readHits"] = to!(string)(this.readHits);
		props["writes"] = to!(string)(this.writes);
		props["blockingWrites"] = to!(string)(this.blockingWrites);
		props["nonblockingWrites"] = to!(string)(this.nonblockingWrites);
		props["writeHits"] = to!(string)(this.writeHits);
		props["readRetries"] = to!(string)(this.readRetries);
		props["writeRetries"] = to!(string)(this.writeRetries);
		props["noRetryAccesses"] = to!(string)(this.noRetryAccesses);
		props["noRetryHits"] = to!(string)(this.noRetryHits);
		props["noRetryReads"] = to!(string)(this.noRetryReads);
		props["noRetryReadHits"] = to!(string)(this.noRetryReadHits);
		props["noRetryWrites"] = to!(string)(this.noRetryWrites);
		props["noRetryWriteHits"] = to!(string)(this.noRetryWriteHits);
		
		return props;
	}
	
	override string toString() {
		return format("CacheStat[name=%s]", this.name);
	}
	
	string name;
	
	ulong accesses;
	ulong hits;
	ulong evictions;
	ulong reads;
	ulong blockingReads;
	ulong nonblockingReads;
	ulong readHits;
	ulong writes;
	ulong blockingWrites;
	ulong nonblockingWrites;
	ulong writeHits;

	ulong readRetries;
	ulong writeRetries;

	ulong noRetryAccesses;
	ulong noRetryHits;
	ulong noRetryReads;
	ulong noRetryReadHits;
	ulong noRetryWrites;
	ulong noRetryWriteHits;
}

class CacheStatXMLSerializer: XMLSerializer!(CacheStat) {
	this() {
	}
	
	override XMLConfig save(CacheStat cacheStat) {
		XMLConfig xmlConfig = new XMLConfig("CacheStat");

		xmlConfig["name"] = cacheStat.name;
		xmlConfig["accesses"] = to!(string)(cacheStat.accesses);
		xmlConfig["hits"] = to!(string)(cacheStat.hits);
		xmlConfig["evictions"] = to!(string)(cacheStat.evictions);
		xmlConfig["reads"] = to!(string)(cacheStat.reads);
		xmlConfig["blockingReads"] = to!(string)(cacheStat.blockingReads);
		xmlConfig["nonblockingReads"] = to!(string)(cacheStat.nonblockingReads);
		xmlConfig["readHits"] = to!(string)(cacheStat.readHits);
		xmlConfig["writes"] = to!(string)(cacheStat.writes);
		xmlConfig["blockingWrites"] = to!(string)(cacheStat.blockingWrites);
		xmlConfig["nonblockingWrites"] = to!(string)(cacheStat.nonblockingWrites);
		xmlConfig["writeHits"] = to!(string)(cacheStat.writeHits);
		
		xmlConfig["readRetries"] = to!(string)(cacheStat.readRetries);
		xmlConfig["writeRetries"] = to!(string)(cacheStat.writeRetries);
		
		xmlConfig["noRetryAccesses"] = to!(string)(cacheStat.noRetryAccesses);
		xmlConfig["noRetryHits"] = to!(string)(cacheStat.noRetryHits);
		xmlConfig["noRetryReads"] = to!(string)(cacheStat.noRetryReads);
		xmlConfig["noRetryReadHits"] = to!(string)(cacheStat.noRetryReadHits);
		xmlConfig["noRetryWrites"] = to!(string)(cacheStat.noRetryWrites);
		xmlConfig["noRetryWriteHits"] = to!(string)(cacheStat.noRetryWriteHits);
			
		return xmlConfig;
	}
	
	override CacheStat load(XMLConfig xmlConfig) {
		string name = xmlConfig["name"];
		ulong accesses = to!(ulong)(xmlConfig["accesses"]);
		ulong hits = to!(ulong)(xmlConfig["hits"]);
		ulong evictions = to!(ulong)(xmlConfig["evictions"]);
		ulong reads = to!(ulong)(xmlConfig["reads"]);
		ulong blockingReads = to!(ulong)(xmlConfig["blockingReads"]);
		ulong nonblockingReads = to!(ulong)(xmlConfig["nonblockingReads"]);
		ulong readHits = to!(ulong)(xmlConfig["readHits"]);
		ulong writes = to!(ulong)(xmlConfig["writes"]);
		ulong blockingWrites = to!(ulong)(xmlConfig["blockingWrites"]);
		ulong nonblockingWrites = to!(ulong)(xmlConfig["nonblockingWrites"]);
		ulong writeHits = to!(ulong)(xmlConfig["writeHits"]);

		ulong readRetries = to!(ulong)(xmlConfig["readRetries"]);
		ulong writeRetries = to!(ulong)(xmlConfig["writeRetries"]);
		
		ulong noRetryAccesses = to!(ulong)(xmlConfig["noRetryAccesses"]);
		ulong noRetryHits = to!(ulong)(xmlConfig["noRetryHits"]);
		ulong noRetryReads = to!(ulong)(xmlConfig["noRetryReads"]);
		ulong noRetryReadHits = to!(ulong)(xmlConfig["noRetryReadHits"]);
		ulong noRetryWrites = to!(ulong)(xmlConfig["noRetryWrites"]);
		ulong noRetryWriteHits = to!(ulong)(xmlConfig["noRetryWriteHits"]);
			
		CacheStat cacheStat = new CacheStat(name);
		
		cacheStat.accesses = accesses;
		cacheStat.hits = hits;
		cacheStat.evictions = evictions;
		cacheStat.reads = reads;
		cacheStat.blockingReads = blockingReads;
		cacheStat.nonblockingReads = nonblockingReads;
		cacheStat.readHits = readHits;
		cacheStat.writes = writes;
		cacheStat.blockingWrites = blockingWrites;
		cacheStat.nonblockingWrites = nonblockingWrites;
		cacheStat.writeHits = writeHits;
		
		cacheStat.readRetries = readRetries;
		cacheStat.writeRetries = writeRetries;
		
		cacheStat.noRetryAccesses = noRetryAccesses;
		cacheStat.noRetryHits = noRetryHits;
		cacheStat.noRetryReads = noRetryReads;
		cacheStat.noRetryReadHits = noRetryReadHits;
		cacheStat.noRetryWrites = noRetryWrites;
		cacheStat.noRetryWriteHits = noRetryWriteHits;

		return cacheStat;
	}
	
	static this() {
		singleInstance = new CacheStatXMLSerializer();
	}
	
	static CacheStatXMLSerializer singleInstance;
}

class MemoryStat: Stat, PropertiesProvider {
	this() {
	}
	
	override string[string] properties() {
		string[string] props;
		props["accesses"] = to!(string)(this.accesses);
		props["reads"] = to!(string)(this.reads);
		props["writes"] = to!(string)(this.writes);
		
		return props;
	}
	
	override string toString() {
		return format("MemoryStat");
	}

	ulong accesses;
	ulong reads;
	ulong writes;
}

class MemoryStatXMLSerializer: XMLSerializer!(MemoryStat) {
	this() {
	}
	
	override XMLConfig save(MemoryStat memoryStat) {
		XMLConfig xmlConfig = new XMLConfig("MemoryStat");
		
		xmlConfig["accesses"] = to!(string)(memoryStat.accesses);
		xmlConfig["reads"] = to!(string)(memoryStat.reads);
		xmlConfig["writes"] = to!(string)(memoryStat.writes);
			
		return xmlConfig;
	}
	
	override MemoryStat load(XMLConfig xmlConfig) {
		ulong accesses = to!(ulong)(xmlConfig["accesses"]);
		ulong reads = to!(ulong)(xmlConfig["reads"]);
		ulong writes = to!(ulong)(xmlConfig["writes"]);
			
		MemoryStat memoryStat = new MemoryStat();
		memoryStat.accesses = accesses;
		memoryStat.reads = reads;
		memoryStat.writes = writes;
		
		return memoryStat;
	}
	
	static this() {
		singleInstance = new MemoryStatXMLSerializer();
	}
	
	static MemoryStatXMLSerializer singleInstance;
}

class MemorySystemStat: Stat, PropertiesProvider {
	this() {
	}
	
	override string[string] properties() {
		string[string] props;
		
		return props;
	}
	
	override string toString() {
		return format("MemorySystemStat[cacheStats.length=%d]", this.cacheStats.length);
	}
	
	CacheStat[] cacheStats;
	MemoryStat memoryStat;
}

class MemorySystemStatXMLSerializer: XMLSerializer!(MemorySystemStat) {	
	this() {
	}
	
	override XMLConfig save(MemorySystemStat memorySystemStat) {
		XMLConfig xmlConfig = new XMLConfig("MemorySystemStat");
		xmlConfig["numCaches"] = to!(string)(memorySystemStat.cacheStats.length);
		
		foreach(cacheStat; memorySystemStat.cacheStats) {
			xmlConfig.entries ~= CacheStatXMLSerializer.singleInstance.save(cacheStat);
		}
		
		xmlConfig.entries ~= MemoryStatXMLSerializer.singleInstance.save(memorySystemStat.memoryStat);
		
		return xmlConfig;
	}
	
	override MemorySystemStat load(XMLConfig xmlConfig) {
		MemorySystemStat memorySystemStat = new MemorySystemStat();
		uint numCaches = to!(uint)(xmlConfig["numCaches"]);
			
		for(uint i = 0; i < numCaches; i++) {
			CacheStat cacheStat = CacheStatXMLSerializer.singleInstance.load(xmlConfig.entries[i]);
			memorySystemStat.cacheStats ~= cacheStat;
		}
		
		memorySystemStat.memoryStat = MemoryStatXMLSerializer.singleInstance.load(xmlConfig.entries[numCaches]);
		
		return memorySystemStat;
	}
	
	static this() {
		singleInstance = new MemorySystemStatXMLSerializer();
	}
	
	static MemorySystemStatXMLSerializer singleInstance;
}

class SimulationStat: Stat, PropertiesProvider {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
		
		this.processorStat = new ProcessorStat();
		this.memorySystemStat = new MemorySystemStat();
	}
	
	override string[string] properties() {
		string[string] props;
		props["duration"] = to!(string)(this.duration);
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		
		return props;
	}
	
	override string toString() {
		return format("SimulationStat[title=%s, cwd=%s]", this.title, this.cwd);
	}
	
	long duration;
	
	string title;
	string cwd;
	
	ProcessorStat processorStat;
	MemorySystemStat memorySystemStat;
}

class SimulationStatXMLSerializer: XMLSerializer!(SimulationStat) {
	this() {
	}
	
	override XMLConfig save(SimulationStat simulationStat) {
		XMLConfig xmlConfig = new XMLConfig("SimulationStat");
		xmlConfig["title"] = simulationStat.title;
		xmlConfig["cwd"] = simulationStat.cwd;
		xmlConfig["duration"] = to!(string)(simulationStat.duration);
		
		xmlConfig.entries ~= ProcessorStatXMLSerializer.singleInstance.save(simulationStat.processorStat);
		xmlConfig.entries ~= MemorySystemStatXMLSerializer.singleInstance.save(simulationStat.memorySystemStat);
		
		return xmlConfig;
	}
	
	override SimulationStat load(XMLConfig xmlConfig) {
		string title = xmlConfig["title"];
		string cwd = xmlConfig["cwd"];
		long duration = to!(long)(xmlConfig["duration"]);
		
		SimulationStat simulationStat = new SimulationStat(title, cwd);		
		simulationStat.duration = duration;

		ProcessorStat processorStat = ProcessorStatXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		MemorySystemStat memorySystemStat = MemorySystemStatXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		simulationStat.processorStat = processorStat;
		simulationStat.memorySystemStat = memorySystemStat;
		
		return simulationStat;
	}
	
	static this() {
		singleInstance = new SimulationStatXMLSerializer();
	}
	
	static SimulationStatXMLSerializer singleInstance;
}

class ExperimentStat: Stat, PropertiesProvider {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, SimulationStat[] simulationStats) {
		this.title = title;
		this.cwd = cwd;
		this.simulationStats = simulationStats;
	}
	
	override string[string] properties() {
		string[string] props;
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		
		return props;
	}
	
	override string toString() {
		return format("ExperimentStat[title=%s, cwd=%s, simulationStats.length=%d]", this.title, this.cwd, this.simulationStats.length);
	}
	
	static ExperimentStat loadXML(string cwd, string fileName) {
		return ExperimentStatXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(ExperimentStat experimentStat) {
		saveXML(experimentStat, "../stats/experiments", experimentStat.title ~ ".stat.xml"); 
	}
	
	static void saveXML(ExperimentStat experimentStat, string cwd, string fileName) {
		ExperimentStatXMLFileSerializer.singleInstance.saveXML(experimentStat, join(cwd, fileName));
	}
	
	string title;
	string cwd;
	
	SimulationStat[] simulationStats;
}

class ExperimentStatXMLFileSerializer: XMLFileSerializer!(ExperimentStat) {
	this() {
	}
	
	override XMLConfigFile save(ExperimentStat experimentStat) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("ExperimentStat");
		
		xmlConfigFile["title"] = experimentStat.title;
		xmlConfigFile["cwd"] = experimentStat.cwd;
			
		foreach(simulationStat; experimentStat.simulationStats) {
			xmlConfigFile.entries ~= SimulationStatXMLSerializer.singleInstance.save(simulationStat);
		}
			
		return xmlConfigFile;
	}
	
	override ExperimentStat load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		
		ExperimentStat experimentStat = new ExperimentStat(title, cwd);

		foreach(entry; xmlConfigFile.entries) {
			experimentStat.simulationStats ~= SimulationStatXMLSerializer.singleInstance.load(entry);
		}

		return experimentStat;
	}
	
	static this() {
		singleInstance = new ExperimentStatXMLFileSerializer();
	}
	
	static ExperimentStatXMLFileSerializer singleInstance;
}