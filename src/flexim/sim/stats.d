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

abstract class Stat(StatT) {
}

class CacheStat: Stat!(CacheStat) {
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

class MainMemoryStat: Stat!(MainMemoryStat) {
	this() {
	}
	
	override string toString() {
		return format("MainMemoryStat[]");
	}

	ulong accesses;
	ulong reads;
	ulong writes;
}

class MainMemoryStatXMLSerializer: XMLSerializer!(MainMemoryStat) {
	this() {
	}
	
	override XMLConfig save(MainMemoryStat mainMemoryStat) {
		XMLConfig xmlConfig = new XMLConfig("MainMemoryStat");
		
		xmlConfig["accesses"] = to!(string)(mainMemoryStat.accesses);
		xmlConfig["reads"] = to!(string)(mainMemoryStat.reads);
		xmlConfig["writes"] = to!(string)(mainMemoryStat.writes);
		
		return xmlConfig;
	}
	
	override MainMemoryStat load(XMLConfig xmlConfig) {	
		ulong accesses = to!(ulong)(xmlConfig["accesses"]);
		ulong reads = to!(ulong)(xmlConfig["reads"]);
		ulong writes = to!(ulong)(xmlConfig["writes"]);
					
		MainMemoryStat mainMemoryStat = new MainMemoryStat();
		mainMemoryStat.accesses = accesses;
		mainMemoryStat.reads = reads;
		mainMemoryStat.writes = writes;
		
		return mainMemoryStat;
	}
	
	static this() {
		singleInstance = new MainMemoryStatXMLSerializer();
	}
	
	static MainMemoryStatXMLSerializer singleInstance;
}

class ContextStat: Stat!(ContextStat) {
	this() {
	}
	
	override string toString() {
		return format("ContextStat[]");
	}
	
	ulong totalInsts;
}

class ContextStatXMLSerializer: XMLSerializer!(ContextStat) {
	this() {
	}
	
	override XMLConfig save(ContextStat contextStat) {
		XMLConfig xmlConfig = new XMLConfig("ContextStat");
		
		xmlConfig["totalInsts"] = to!(string)(contextStat.totalInsts);
		
		return xmlConfig;
	}
	
	override ContextStat load(XMLConfig xmlConfig) {	
		ulong totalInsts = to!(ulong)(xmlConfig["totalInsts"]);
				
		ContextStat contextStat = new ContextStat();
		contextStat.totalInsts = totalInsts;
		
		return contextStat;
	}
	
	static this() {
		singleInstance = new ContextStatXMLSerializer();
	}
	
	static ContextStatXMLSerializer singleInstance;
}

class CoreStat: Stat!(CoreStat) {
	this() {
	}
	
	override string toString() {
		return format("CoreStat[iCache=%s, dCache=%s]",
			this.iCache, this.dCache);
	}
	
	CacheStat iCache, dCache;
}

class CoreStatXMLSerializer: XMLSerializer!(CoreStat) {
	this() {
	}
	
	override XMLConfig save(CoreStat coreStat) {
		XMLConfig xmlConfig = new XMLConfig("CoreStat");
		
		xmlConfig.entries ~= CacheStatXMLSerializer.singleInstance.save(coreStat.iCache);
		xmlConfig.entries ~= CacheStatXMLSerializer.singleInstance.save(coreStat.dCache);
		
		return xmlConfig;
	}
	
	override CoreStat load(XMLConfig xmlConfig) {		
		CacheStat iCache = CacheStatXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		CacheStat dCache = CacheStatXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		CoreStat coreStat = new CoreStat();
		coreStat.iCache = iCache;
		coreStat.dCache = dCache;
		
		return coreStat;
	}
	
	static this() {
		singleInstance = new CoreStatXMLSerializer();
	}
	
	static CoreStatXMLSerializer singleInstance;
}

class ProcessorStat: Stat!(ProcessorStat) {
	this() {
	}
	
	override string toString() {
		return format("ProcessorStat[cores.length=%d, threads.length=%d]",
			this.cores.length, this.contexts.length);
	}
	
	CoreStat[] cores;
	ContextStat[] contexts;
}

class ProcessorStatXMLSerializer: XMLSerializer!(ProcessorStat) {
	this() {
	}
	
	override XMLConfig save(ProcessorStat processorStat) {
		XMLConfig xmlConfig = new XMLConfig("ProcessorStat");
		
		foreach(core; processorStat.cores) {
			xmlConfig.entries ~= CoreStatXMLSerializer.singleInstance.save(core);
		}
		
		foreach(context; processorStat.contexts) {
			xmlConfig.entries ~= ContextStatXMLSerializer.singleInstance.save(context);
		}
		
		return xmlConfig;		
	}
	
	override ProcessorStat load(XMLConfig xmlConfig) {			
		ProcessorStat processorStat = new ProcessorStat();
		
		foreach(entry; xmlConfig.entries) {
			if(entry.typeName == "CoreStat") {
				processorStat.cores ~= CoreStatXMLSerializer.singleInstance.load(entry);
			}
			else if(entry.typeName == "ContextStat") {
				processorStat.contexts ~= ContextStatXMLSerializer.singleInstance.load(entry);
			}
			else {
				assert(0);
			}
		}
		
		return processorStat;
	}
	
	static this() {
		singleInstance = new ProcessorStatXMLSerializer();
	}
	
	static ProcessorStatXMLSerializer singleInstance;
}

class SimulationStat: Stat!(SimulationStat) {
	this(string title, string cwd, uint numCores) {
		ProcessorStat processor = new ProcessorStat();
		for(uint i = 0; i < numCores; i++) {
			processor.cores ~= new CoreStat();
		}
		
		this(title, cwd, processor);
	}
	
	this(string title, string cwd, ProcessorStat processor) {
		this.title = title;
		this.cwd = cwd;
		this.processor = processor;
	}
	
	override string toString() {
		return format("SimulationStat[title=%s, cwd=%s, duration=%d, processor=%s, l2Cache=%s, mainMemory=%s]",
			this.title, this.cwd, this.duration, this.processor, this.l2Cache, this.mainMemory);
	}
	
	string title, cwd;
	ProcessorStat processor;
	CacheStat l2Cache;
	MainMemoryStat mainMemory;
	
	ulong duration;
	
	static SimulationStat loadXML(string cwd, string fileName) {
		return SimulationStatXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(SimulationStat simulationStat, string cwd, string fileName) {
		SimulationStatXMLFileSerializer.singleInstance.saveXML(simulationStat, join(cwd, fileName));
	}
	
	static void saveXML(SimulationStat simulationStat) {
		saveXML(simulationStat, "../stats/simulations", simulationStat.title ~ ".stat.xml");
	}
}

class SimulationStatXMLFileSerializer: XMLFileSerializer!(SimulationStat) {
	this() {
	}
	
	override XMLConfigFile save(SimulationStat simulationStat) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("SimulationStat");
		
		xmlConfigFile["title"] = simulationStat.title;
		xmlConfigFile["cwd"] = simulationStat.cwd;
		xmlConfigFile["duration"] = to!(string)(simulationStat.duration);
			
		xmlConfigFile.entries ~= ProcessorStatXMLSerializer.singleInstance.save(simulationStat.processor);
		xmlConfigFile.entries ~= CacheStatXMLSerializer.singleInstance.save(simulationStat.l2Cache);
		xmlConfigFile.entries ~= MainMemoryStatXMLSerializer.singleInstance.save(simulationStat.mainMemory);
		
		return xmlConfigFile;
	}
	
	override SimulationStat load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		ulong duration = to!(ulong)(xmlConfigFile["duration"]);
			
		ProcessorStat processor = ProcessorStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		CacheStat l2Cache = CacheStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		MainMemoryStat mainMemory = MainMemoryStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[2]);
				
		SimulationStat simulationStat = new SimulationStat(title, cwd, processor);
		simulationStat.l2Cache = l2Cache;
		simulationStat.mainMemory = mainMemory;
		simulationStat.duration = duration;
		
		return simulationStat;
	}
	
	static this() {
		singleInstance = new SimulationStatXMLFileSerializer();
	}
	
	static SimulationStatXMLFileSerializer singleInstance;
}