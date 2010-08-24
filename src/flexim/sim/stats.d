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

class ThreadStat {
	this(uint num) {
		this.num = num;
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
		
		xmlConfig.attributes["totalInsts"] = to!(string)(threadStat.totalInsts);
			
		return xmlConfig;
	}
	
	override ThreadStat load(XMLConfig xmlConfig) {
		uint num = to!(uint)(xmlConfig.attributes["num"]);
		ulong totalInsts = to!(ulong)(xmlConfig.attributes["totalInsts"]);
			
		ThreadStat threadStat = new ThreadStat(num);
		threadStat.totalInsts = totalInsts;

		return threadStat;
	}
	
	static this() {
		singleInstance = new ThreadStatXMLSerializer();
	}
	
	static ThreadStatXMLSerializer singleInstance;
}

class ProcessorStat: Stat {
	this() {
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

class CacheStat: Stat {
	this(string name) {
		this.name = name;
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

		xmlConfig.attributes["name"] = cacheStat.name;
		xmlConfig.attributes["accesses"] = to!(string)(cacheStat.accesses);
		xmlConfig.attributes["hits"] = to!(string)(cacheStat.hits);
		xmlConfig.attributes["evictions"] = to!(string)(cacheStat.evictions);
		xmlConfig.attributes["reads"] = to!(string)(cacheStat.reads);
		xmlConfig.attributes["blockingReads"] = to!(string)(cacheStat.blockingReads);
		xmlConfig.attributes["nonblockingReads"] = to!(string)(cacheStat.nonblockingReads);
		xmlConfig.attributes["readHits"] = to!(string)(cacheStat.readHits);
		xmlConfig.attributes["writes"] = to!(string)(cacheStat.writes);
		xmlConfig.attributes["blockingWrites"] = to!(string)(cacheStat.blockingWrites);
		xmlConfig.attributes["nonblockingWrites"] = to!(string)(cacheStat.nonblockingWrites);
		xmlConfig.attributes["writeHits"] = to!(string)(cacheStat.writeHits);
		
		xmlConfig.attributes["readRetries"] = to!(string)(cacheStat.readRetries);
		xmlConfig.attributes["writeRetries"] = to!(string)(cacheStat.writeRetries);
		
		xmlConfig.attributes["noRetryAccesses"] = to!(string)(cacheStat.noRetryAccesses);
		xmlConfig.attributes["noRetryHits"] = to!(string)(cacheStat.noRetryHits);
		xmlConfig.attributes["noRetryReads"] = to!(string)(cacheStat.noRetryReads);
		xmlConfig.attributes["noRetryReadHits"] = to!(string)(cacheStat.noRetryReadHits);
		xmlConfig.attributes["noRetryWrites"] = to!(string)(cacheStat.noRetryWrites);
		xmlConfig.attributes["noRetryWriteHits"] = to!(string)(cacheStat.noRetryWriteHits);
			
		return xmlConfig;
	}
	
	override CacheStat load(XMLConfig xmlConfig) {
		string name = xmlConfig.attributes["name"];
		ulong accesses = to!(ulong)(xmlConfig.attributes["accesses"]);
		ulong hits = to!(ulong)(xmlConfig.attributes["hits"]);
		ulong evictions = to!(ulong)(xmlConfig.attributes["evictions"]);
		ulong reads = to!(ulong)(xmlConfig.attributes["reads"]);
		ulong blockingReads = to!(ulong)(xmlConfig.attributes["blockingReads"]);
		ulong nonblockingReads = to!(ulong)(xmlConfig.attributes["nonblockingReads"]);
		ulong readHits = to!(ulong)(xmlConfig.attributes["readHits"]);
		ulong writes = to!(ulong)(xmlConfig.attributes["writes"]);
		ulong blockingWrites = to!(ulong)(xmlConfig.attributes["blockingWrites"]);
		ulong nonblockingWrites = to!(ulong)(xmlConfig.attributes["nonblockingWrites"]);
		ulong writeHits = to!(ulong)(xmlConfig.attributes["writeHits"]);

		ulong readRetries = to!(ulong)(xmlConfig.attributes["readRetries"]);
		ulong writeRetries = to!(ulong)(xmlConfig.attributes["writeRetries"]);
		
		ulong noRetryAccesses = to!(ulong)(xmlConfig.attributes["noRetryAccesses"]);
		ulong noRetryHits = to!(ulong)(xmlConfig.attributes["noRetryHits"]);
		ulong noRetryReads = to!(ulong)(xmlConfig.attributes["noRetryReads"]);
		ulong noRetryReadHits = to!(ulong)(xmlConfig.attributes["noRetryReadHits"]);
		ulong noRetryWrites = to!(ulong)(xmlConfig.attributes["noRetryWrites"]);
		ulong noRetryWriteHits = to!(ulong)(xmlConfig.attributes["noRetryWriteHits"]);
			
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

class MemorySystemStat: Stat {
	this() {
	}
	
	override string toString() {
		return format("MemorySystemStat[cacheStats.length=%d]", this.cacheStats.length);
	}
	
	CacheStat[string] cacheStats;
}

class MemorySystemStatXMLSerializer: XMLSerializer!(MemorySystemStat) {	
	this() {
	}
	
	override XMLConfig save(MemorySystemStat memorySystemStat) {
		XMLConfig xmlConfig = new XMLConfig("MemorySystemStat");
		
		foreach(cacheName, cacheStat; memorySystemStat.cacheStats) {
			xmlConfig.entries ~= CacheStatXMLSerializer.singleInstance.save(cacheStat);
		}
		
		return xmlConfig;
	}
	
	override MemorySystemStat load(XMLConfig xmlConfig) {
		MemorySystemStat memorySystemStat = new MemorySystemStat();
		
		foreach(entry; xmlConfig.entries) {
			CacheStat cacheStat = CacheStatXMLSerializer.singleInstance.load(entry);
			memorySystemStat.cacheStats[cacheStat.name] = cacheStat;
		}
		
		return memorySystemStat;
	}
	
	static this() {
		singleInstance = new MemorySystemStatXMLSerializer();
	}
	
	static MemorySystemStatXMLSerializer singleInstance;
}

class SimulationStat {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
		
		this.processorStat = new ProcessorStat();
		this.memorySystemStat = new MemorySystemStat();
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
		xmlConfig.attributes["title"] = simulationStat.title;
		xmlConfig.attributes["cwd"] = simulationStat.cwd;
		xmlConfig.attributes["duration"] = to!(string)(simulationStat.duration);
		
		xmlConfig.entries ~= ProcessorStatXMLSerializer.singleInstance.save(simulationStat.processorStat);
		xmlConfig.entries ~= MemorySystemStatXMLSerializer.singleInstance.save(simulationStat.memorySystemStat);
		
		return xmlConfig;
	}
	
	override SimulationStat load(XMLConfig xmlConfig) {
		string title = xmlConfig.attributes["title"];
		string cwd = xmlConfig.attributes["cwd"];
		long duration = to!(long)(xmlConfig.attributes["duration"]);
		
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

class ExperimentStat {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, SimulationStat[] simulationStats) {
		this.title = title;
		this.cwd = cwd;
		this.simulationStats = simulationStats;
	}
	
	override string toString() {
		return format("ExperimentStat[title=%s, cwd=%s, simulationConfigs.length=%d]", this.title, this.cwd, this.simulationStats.length);
	}
	
	static ExperimentStat loadXML(string cwd, string fileName) {
		return ExperimentStatXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
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
		
		xmlConfigFile.attributes["title"] = experimentStat.title;
		xmlConfigFile.attributes["cwd"] = experimentStat.cwd;
			
		foreach(simulationStat; experimentStat.simulationStats) {
			xmlConfigFile.entries ~= SimulationStatXMLSerializer.singleInstance.save(simulationStat);
		}
			
		return xmlConfigFile;
	}
	
	override ExperimentStat load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile.attributes["title"];
		string cwd = xmlConfigFile.attributes["cwd"];
		
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