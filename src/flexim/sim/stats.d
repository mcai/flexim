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

import std.signals;

class Property(T) {
	this(T v) {
		this.value = v;
	}
	
	void addListener(void delegate(T) listener) {
		this.listeners ~= listener;
	}
    
    void dispatch() {
		foreach(listener; this.listeners) {
			listener(this.value);
		}
    }
	
    T value() { 
    	return this._value;
    }

    void value(T v) {
        if (v != this._value) {
			this._value = v;
        }
    }
    
    override string toString() {
    	return to!(string)(this.value);
    }
    
	void delegate(T)[] listeners;
	private T _value;
}

abstract class Stat(StatT) {	
	abstract void reset();
	abstract void dispatch();
}

class CacheStat: Stat!(CacheStat) {
	this() {		
		this.accesses = new Property!(ulong)(0);
		this.hits = new Property!(ulong)(0);
		this.evictions = new Property!(ulong)(0);
		this.reads = new Property!(ulong)(0);
		this.blockingReads = new Property!(ulong)(0);
		this.nonblockingReads = new Property!(ulong)(0);
		this.readHits = new Property!(ulong)(0);
		this.writes = new Property!(ulong)(0);
		this.blockingWrites = new Property!(ulong)(0);
		this.nonblockingWrites = new Property!(ulong)(0);
		this.writeHits = new Property!(ulong)(0);
	
		this.readRetries = new Property!(ulong)(0);
		this.writeRetries = new Property!(ulong)(0);
	
		this.noRetryAccesses = new Property!(ulong)(0);
		this.noRetryHits = new Property!(ulong)(0);
		this.noRetryReads = new Property!(ulong)(0);
		this.noRetryReadHits = new Property!(ulong)(0);
		this.noRetryWrites = new Property!(ulong)(0);
		this.noRetryWriteHits = new Property!(ulong)(0);
	}
	
	override void reset() {
		this.accesses.value = 0;
		this.hits.value = 0;
		this.evictions.value = 0;
		this.reads.value = 0;
		this.blockingReads.value = 0;
		this.nonblockingReads.value = 0;
		this.readHits.value = 0;
		this.writes.value = 0;
		this.blockingWrites.value = 0;
		this.nonblockingWrites.value = 0;
		this.writeHits.value = 0;
	
		this.readRetries.value = 0;
		this.writeRetries.value = 0;
	
		this.noRetryAccesses.value = 0;
		this.noRetryHits.value = 0;
		this.noRetryReads.value = 0;
		this.noRetryReadHits.value = 0;
		this.noRetryWrites.value = 0;
		this.noRetryWriteHits.value = 0;
	}
	
	override void dispatch() {
		this.accesses.dispatch();
		this.hits.dispatch();
		this.evictions.dispatch();
		this.reads.dispatch();
		this.blockingReads.dispatch();
		this.nonblockingReads.dispatch();
		this.readHits.dispatch();
		this.writes.dispatch();
		this.blockingWrites.dispatch();
		this.nonblockingWrites.dispatch();
		this.writeHits.dispatch();
	
		this.readRetries.dispatch();
		this.writeRetries.dispatch();
	
		this.noRetryAccesses.dispatch();
		this.noRetryHits.dispatch();
		this.noRetryReads.dispatch();
		this.noRetryReadHits.dispatch();
		this.noRetryWrites.dispatch();
		this.noRetryWriteHits.dispatch();
	}
	
	override string toString() {
		return format("CacheStat");
	}
	
	Property!(ulong) accesses;
	Property!(ulong) hits;
	Property!(ulong) evictions;
	Property!(ulong) reads;
	Property!(ulong) blockingReads;
	Property!(ulong) nonblockingReads;
	Property!(ulong) readHits;
	Property!(ulong) writes;
	Property!(ulong) blockingWrites;
	Property!(ulong) nonblockingWrites;
	Property!(ulong) writeHits;

	Property!(ulong) readRetries;
	Property!(ulong) writeRetries;

	Property!(ulong) noRetryAccesses;
	Property!(ulong) noRetryHits;
	Property!(ulong) noRetryReads;
	Property!(ulong) noRetryReadHits;
	Property!(ulong) noRetryWrites;
	Property!(ulong) noRetryWriteHits;
}

class CacheStatXMLSerializer: XMLSerializer!(CacheStat) {
	this() {
		
	}
	
	override XMLConfig save(CacheStat cacheStat) {
		XMLConfig xmlConfig = new XMLConfig("CacheStat");

		xmlConfig["accesses"] = to!(string)(cacheStat.accesses.value);
		xmlConfig["hits"] = to!(string)(cacheStat.hits.value);
		xmlConfig["evictions"] = to!(string)(cacheStat.evictions.value);
		xmlConfig["reads"] = to!(string)(cacheStat.reads.value);
		xmlConfig["blockingReads"] = to!(string)(cacheStat.blockingReads.value);
		xmlConfig["nonblockingReads"] = to!(string)(cacheStat.nonblockingReads.value);
		xmlConfig["readHits"] = to!(string)(cacheStat.readHits.value);
		xmlConfig["writes"] = to!(string)(cacheStat.writes.value);
		xmlConfig["blockingWrites"] = to!(string)(cacheStat.blockingWrites.value);
		xmlConfig["nonblockingWrites"] = to!(string)(cacheStat.nonblockingWrites.value);
		xmlConfig["writeHits"] = to!(string)(cacheStat.writeHits.value);
		
		xmlConfig["readRetries"] = to!(string)(cacheStat.readRetries.value);
		xmlConfig["writeRetries"] = to!(string)(cacheStat.writeRetries.value);
		
		xmlConfig["noRetryAccesses"] = to!(string)(cacheStat.noRetryAccesses.value);
		xmlConfig["noRetryHits"] = to!(string)(cacheStat.noRetryHits.value);
		xmlConfig["noRetryReads"] = to!(string)(cacheStat.noRetryReads.value);
		xmlConfig["noRetryReadHits"] = to!(string)(cacheStat.noRetryReadHits.value);
		xmlConfig["noRetryWrites"] = to!(string)(cacheStat.noRetryWrites.value);
		xmlConfig["noRetryWriteHits"] = to!(string)(cacheStat.noRetryWriteHits.value);
			
		return xmlConfig;
	}
	
	override CacheStat load(XMLConfig xmlConfig) {
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

		CacheStat cacheStat = new CacheStat();
		
		cacheStat.accesses.value = accesses;
		cacheStat.hits.value = hits;
		cacheStat.evictions.value = evictions;
		cacheStat.reads.value = reads;
		cacheStat.blockingReads.value = blockingReads;
		cacheStat.nonblockingReads.value = nonblockingReads;
		cacheStat.readHits.value = readHits;
		cacheStat.writes.value = writes;
		cacheStat.blockingWrites.value = blockingWrites;
		cacheStat.nonblockingWrites.value = nonblockingWrites;
		cacheStat.writeHits.value = writeHits;
		
		cacheStat.readRetries.value = readRetries;
		cacheStat.writeRetries.value = writeRetries;
		
		cacheStat.noRetryAccesses.value = noRetryAccesses;
		cacheStat.noRetryHits.value = noRetryHits;
		cacheStat.noRetryReads.value = noRetryReads;
		cacheStat.noRetryReadHits.value = noRetryReadHits;
		cacheStat.noRetryWrites.value = noRetryWrites;
		cacheStat.noRetryWriteHits.value = noRetryWriteHits;
		
		return cacheStat;
	}
	
	static this() {
		singleInstance = new CacheStatXMLSerializer();
	}
	
	static CacheStatXMLSerializer singleInstance;
}

class MainMemoryStat: Stat!(MainMemoryStat) {
	this() {
		this.accesses = new Property!(ulong)(0);
		this.reads = new Property!(ulong)(0);
		this.writes = new Property!(ulong)(0);
	}
	
	override void reset() {
		this.accesses.value = 0;
		this.reads.value = 0;
		this.writes.value = 0;
	}
	
	override void dispatch() {
		this.accesses.dispatch();
		this.reads.dispatch();
		this.writes.dispatch();
	}
	
	override string toString() {
		return format("MainMemoryStat[]");
	}

	Property!(ulong) accesses;
	Property!(ulong) reads;
	Property!(ulong) writes;
}

class MainMemoryStatXMLSerializer: XMLSerializer!(MainMemoryStat) {
	this() {
	}
	
	override XMLConfig save(MainMemoryStat mainMemoryStat) {
		XMLConfig xmlConfig = new XMLConfig("MainMemoryStat");
		
		xmlConfig["accesses"] = to!(string)(mainMemoryStat.accesses.value);
		xmlConfig["reads"] = to!(string)(mainMemoryStat.reads.value);
		xmlConfig["writes"] = to!(string)(mainMemoryStat.writes.value);
		
		return xmlConfig;
	}
	
	override MainMemoryStat load(XMLConfig xmlConfig) {	
		ulong accesses = to!(ulong)(xmlConfig["accesses"]);
		ulong reads = to!(ulong)(xmlConfig["reads"]);
		ulong writes = to!(ulong)(xmlConfig["writes"]);
					
		MainMemoryStat mainMemoryStat = new MainMemoryStat();
		mainMemoryStat.accesses.value = accesses;
		mainMemoryStat.reads.value = reads;
		mainMemoryStat.writes.value = writes;
		
		return mainMemoryStat;
	}
	
	static this() {
		singleInstance = new MainMemoryStatXMLSerializer();
	}
	
	static MainMemoryStatXMLSerializer singleInstance;
}

class ContextStat: Stat!(ContextStat) {
	this() {
		this.totalInsts = new Property!(ulong)(0);
	}
	
	override void reset() {
		this.totalInsts.value = 0;
	}
	
	override void dispatch() {
		this.totalInsts.dispatch();
	}
	
	override string toString() {
		return format("ContextStat[]");
	}
	
	Property!(ulong) totalInsts;
}

class ContextStatXMLSerializer: XMLSerializer!(ContextStat) {
	this() {
	}
	
	override XMLConfig save(ContextStat contextStat) {
		XMLConfig xmlConfig = new XMLConfig("ContextStat");
		
		xmlConfig["totalInsts"] = to!(string)(contextStat.totalInsts.value);
		
		return xmlConfig;
	}
	
	override ContextStat load(XMLConfig xmlConfig) {	
		ulong totalInsts = to!(ulong)(xmlConfig["totalInsts"]);
				
		ContextStat contextStat = new ContextStat();
		contextStat.totalInsts.value = totalInsts;
		
		return contextStat;
	}
	
	static this() {
		singleInstance = new ContextStatXMLSerializer();
	}
	
	static ContextStatXMLSerializer singleInstance;
}

class CoreStat: Stat!(CoreStat) {
	this() {
		this.iCache = new CacheStat();
		this.dCache = new CacheStat();
	}
	
	override void reset() {
		this.iCache.reset();
		this.dCache.reset();
	}
	
	override void dispatch() {
		this.iCache.dispatch();
		this.dCache.dispatch();
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
	
	override void reset() {
		foreach(core; this.cores) {
			core.reset();
		}
		
		foreach(context; this.contexts) {
			context.reset();
		}
	}
	
	override void dispatch() {
		foreach(core; this.cores) {
			core.dispatch();
		}
		
		foreach(context; this.contexts) {
			context.dispatch();
		}
	}
	
	override string toString() {
		return format("ProcessorStat[cores.length=%d, contexts.length=%d]",
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
	this(string title, string cwd, uint numCores, uint numThreadsPerCore) {
		ProcessorStat processor = new ProcessorStat();
		for(uint i = 0; i < numCores; i++) {
			CoreStat core = new CoreStat();
			
			for(uint j = 0; j < numThreadsPerCore; j++) {
				ContextStat context = new ContextStat();
				processor.contexts ~= context;
			}
			
			processor.cores ~= core;
		}
		
		this(title, cwd, processor);
	}
	
	this(string title, string cwd, ProcessorStat processor) {
		this.title = title;
		this.cwd = cwd;
		this.processor = processor;
		
		this.l2Cache = new CacheStat();
		this.mainMemory = new MainMemoryStat();
		
		this.totalCycles = new Property!(ulong)(0);
		this.duration = new Property!(ulong)(0);
	}
	
	override void reset() {
		this.processor.reset();
		this.l2Cache.reset();
		this.mainMemory.reset();
		
		this.totalCycles.value = 0;
		this.duration.value = 0;
	}
	
	override void dispatch() {
		this.processor.dispatch();
		this.l2Cache.dispatch();
		this.mainMemory.dispatch();
		
		this.totalCycles.dispatch();
		this.duration.dispatch();
	}
	
	override string toString() {
		return format("SimulationStat[title=%s, cwd=%s, totalCycles=%d, duration=%d, processor=%s, l2Cache=%s, mainMemory=%s]",
			this.title, this.cwd, this.totalCycles, this.duration, this.processor, this.l2Cache, this.mainMemory);
	}
	
	string title, cwd;
	ProcessorStat processor;
	CacheStat l2Cache;
	MainMemoryStat mainMemory;

	Property!(ulong) totalCycles;
	Property!(ulong) duration;
	
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
		xmlConfigFile["totalCycles"] = to!(string)(simulationStat.totalCycles.value);
		xmlConfigFile["duration"] = to!(string)(simulationStat.duration.value);
			
		xmlConfigFile.entries ~= ProcessorStatXMLSerializer.singleInstance.save(simulationStat.processor);
		xmlConfigFile.entries ~= CacheStatXMLSerializer.singleInstance.save(simulationStat.l2Cache);
		xmlConfigFile.entries ~= MainMemoryStatXMLSerializer.singleInstance.save(simulationStat.mainMemory);
		
		return xmlConfigFile;
	}
	
	override SimulationStat load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		ulong totalCycles = to!(ulong)(xmlConfigFile["totalCycles"]);
		ulong duration = to!(ulong)(xmlConfigFile["duration"]);
			
		ProcessorStat processor = ProcessorStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		CacheStat l2Cache = CacheStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		MainMemoryStat mainMemory = MainMemoryStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[2]);
				
		SimulationStat simulationStat = new SimulationStat(title, cwd, processor);
		simulationStat.l2Cache = l2Cache;
		simulationStat.mainMemory = mainMemory;
		simulationStat.totalCycles.value = totalCycles;
		simulationStat.duration.value = duration;
		
		return simulationStat;
	}
	
	static this() {
		singleInstance = new SimulationStatXMLFileSerializer();
	}
	
	static SimulationStatXMLFileSerializer singleInstance;
}