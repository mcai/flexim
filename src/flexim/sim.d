/*
 * flexim/sim.d
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

module flexim.sim;

import flexim.all;

import std.file;
import std.getopt;
import std.path;
import std.regexp;

interface PropertiesProvider {
	string[string] properties();
}

class Benchmark : PropertiesProvider {
	this(string title, string cwd, string exe, string argsLiteral, string stdin = null, string stdout = null, uint numThreadsPerCore = 1) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.argsLiteral = argsLiteral;
		this.stdin = stdin;
		this.stdout = stdout;
		this.numThreadsPerCore = numThreadsPerCore;
	}
	
	override string toString() {
		return format("Benchmark[title=%s, cwd=%s, exe=%s, argsLiteral=%s, stdin=%s, stdout=%s, numThreadsPerCore=%d]",
			this.title, this.cwd, this.exe, this.argsLiteral, this.stdin, this.stdout, this.numThreadsPerCore);
	}
	
	override string[string] properties() {
		string[string] props;
		
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		props["exe"] = this.exe;
		props["argsLiteral"] = this.argsLiteral;
		props["stdin"] = this.stdin;
		props["stdout"] = this.stdout;
		props["numThreadsPerCore"] = to!(string)(this.numThreadsPerCore);
		
		return props;
	}
	
	string title;
	string cwd;
	string exe;
	string argsLiteral;
	string stdin;
	string stdout;
	
	string args() {
		return sub(this.argsLiteral, r"\$\{nthreads\}", format("%d", this.numThreadsPerCore), "g");
	}
	
	uint numThreadsPerCore;
	
	BenchmarkSuite suite;
}

class BenchmarkSuite : PropertiesProvider {	
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	void register(Benchmark benchmark) {
		assert(!(benchmark.title in this.benchmarks), format("%s.%s", this.title, benchmark.title));
		benchmark.suite = this;
		this.benchmarks[benchmark.title] = benchmark;
	}
	
	Benchmark opIndex(string index) {
		return this.benchmarks[index];
	}
	
	override string toString() {
		return format("BenchmarkSuite[title=%s, cwd=%s, benchmarks.length=%d]", this.title, this.cwd, this.benchmarks.length);
	}
	
	static BenchmarkSuite loadXML(string cwd, string fileName) {
		return BenchmarkSuiteXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite) {
		saveXML(benchmarkSuite, "../configs/benchmarks", benchmarkSuite.title ~ ".xml");
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite, string cwd, string fileName) {
		BenchmarkSuiteXMLFileSerializer.singleInstance.saveXML(benchmarkSuite, join(cwd, fileName));
	}
	
	override string[string] properties() {
		string[string] props;
		
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		
		return props;
	}
	
	string title;
	string cwd;
	
	Benchmark[string] benchmarks;
}

class BenchmarkSuiteXMLFileSerializer: XMLFileSerializer!(BenchmarkSuite) {
	this() {
	}
	
	override XMLConfigFile save(BenchmarkSuite benchmarkSuite) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("BenchmarkSuite");
		
		xmlConfigFile["title"] = benchmarkSuite.title;
		xmlConfigFile["cwd"] = benchmarkSuite.cwd;
		
		foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
			XMLConfig xmlConfig = new XMLConfig("Benchmark");
			xmlConfig["title"] = benchmark.title;
			xmlConfig["cwd"] = benchmark.cwd;
			xmlConfig["exe"] = benchmark.exe;
			xmlConfig["argsLiteral"] = benchmark.argsLiteral;
			xmlConfig["stdin"] = benchmark.stdin;
			xmlConfig["stdout"] = benchmark.stdout;
			
			xmlConfigFile.entries ~= xmlConfig;
		}
			
		return xmlConfigFile;
	}
	
	override BenchmarkSuite load(XMLConfigFile xmlConfigFile) {
		string bs_title = xmlConfigFile["title"];
		string bs_cwd = xmlConfigFile["cwd"];
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(bs_title, bs_cwd);
		
		foreach(entry; xmlConfigFile.entries) {
			string title = entry["title"];
			string cwd = entry["cwd"];
			string exe = entry["exe"];
			string argsLiteral = entry["argsLiteral"];
			string stdin = entry["stdin"];
			string stdout = entry["stdout"];
			
			Benchmark benchmark = new Benchmark(title, cwd, exe, argsLiteral, stdin, stdout);
			benchmarkSuite.register(benchmark);
		}
		
		return benchmarkSuite;
	}
	
	static this() {
		singleInstance = new BenchmarkSuiteXMLFileSerializer();
	}
	
	static BenchmarkSuiteXMLFileSerializer singleInstance;
}

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
	
	static CacheConfig newL1(string name) {
		return new CacheConfig(name, 0, 64, 4, 64, 1, 3, CacheReplacementPolicy.LRU);
	}
	
	static CacheConfig newL2() {
		return new CacheConfig("l2", 1, 1024, 4, 64, 4, 7, CacheReplacementPolicy.LRU);
	}
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
		return format("ContextConfig[binariesDir=%s, workload=%s]",
			this.binariesDir, this.workload);
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
		xmlConfig["benchmarkSuiteTitle"] = contextConfig.workload.suite.title;
		xmlConfig["benchmarkTitle"] = contextConfig.workload.title;
		
		return xmlConfig;
	}
	
	override ContextConfig load(XMLConfig xmlConfig) {
		string binariesDir = xmlConfig["binariesDir"];
		string benchmarkSuiteTitle = xmlConfig["benchmarkSuiteTitle"];
		string benchmarkTitle = xmlConfig["benchmarkTitle"];
		
		Benchmark workload = benchmarkSuites[benchmarkSuiteTitle][benchmarkTitle];
		
		ContextConfig contextConfig = new ContextConfig(binariesDir, workload);
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
	
	static void saveXML(SimulationConfig simulationConfig, string cwd, string fileName) {
		SimulationConfigXMLFileSerializer.singleInstance.saveXML(simulationConfig, join(cwd, fileName));
	}
	
	static void saveXML(SimulationConfig simulationConfig) {
		saveXML(simulationConfig, "../configs/simulations", simulationConfig.title ~ ".config.xml");
	}
}

class SimulationConfigXMLFileSerializer: XMLFileSerializer!(SimulationConfig) {
	this() {
	}
	
	override XMLConfigFile save(SimulationConfig simulationConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("SimulationConfig");
		
		xmlConfigFile["title"] = simulationConfig.title;
		xmlConfigFile["cwd"] = simulationConfig.cwd;
		
		xmlConfigFile.entries ~= ProcessorConfigXMLSerializer.singleInstance.save(simulationConfig.processor);
		xmlConfigFile.entries ~= CacheConfigXMLSerializer.singleInstance.save(simulationConfig.l2Cache);
		xmlConfigFile.entries ~= MainMemoryConfigXMLSerializer.singleInstance.save(simulationConfig.mainMemory);
		
		return xmlConfigFile;
	}
	
	override SimulationConfig load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		
		ProcessorConfig processor = ProcessorConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		CacheConfig l2Cache = CacheConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		MainMemoryConfig mainMemory = MainMemoryConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[2]);
		
		SimulationConfig simulationConfig = new SimulationConfig(title, cwd, processor, l2Cache, mainMemory);
		return simulationConfig;
	}
	
	static this() {
		singleInstance = new SimulationConfigXMLFileSerializer();
	}
	
	static SimulationConfigXMLFileSerializer singleInstance;
}

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

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible, EventProcessor {
	this(SimulationConfig config, void delegate(Simulation) del = null) {
		this.config = config;
		this.del = del;
		
		if(this.config.title in simulationStats) {
			this.stat = simulationStats[this.config.title];
			this.stat.reset();
		}
		else {
			simulationStats[this.config.title] = this.stat = new SimulationStat(this.title, this.cwd, this.config.processor.cores.length, this.config.processor.numThreadsPerCore);
		}
		
		this.isRunning = false;
	}
	
	void execute() {
		this.beforeRun();
		
		this.isRunning = true;
		
		this.run();
		
		this.isRunning = false;
		
		this.afterRun();
	}
	
	override void beforeRun() {
	}
	
	override void run() {
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	override void afterRun() {
	}
	
	override void processEvents() {
		if(this.del !is null) {
			this.del(this);
		}
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
	
	void delegate(Simulation) del;
	
	bool isRunning;
}

BenchmarkSuite[string] benchmarkSuites;
SimulationConfig[string] simulationConfigs;
SimulationStat[string] simulationStats;

void loadConfigsAndStats(void delegate(string text) del, bool useGtk = false) {
	string boldFontBeginStr = (useGtk ? "<b>" : "");
	string boldFontEndStr = (useGtk ? "</b>" : "");
	
    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
    {
    	string baseName = basename(name, ".xml");
    	del("Loading benchmark config: " ~ boldFontBeginStr ~ baseName ~ boldFontEndStr);
		benchmarkSuites[baseName] = BenchmarkSuite.loadXML("../configs/benchmarks", basename(name));
		assert(benchmarkSuites[baseName].title == baseName);
    }
    foreach (string name; dirEntries("../configs/simulations", SpanMode.breadth))
    {
    	string baseName = basename(name, ".config.xml");
    	del("Loading simulation config: " ~ boldFontBeginStr ~ baseName ~ boldFontEndStr);
		simulationConfigs[baseName] = SimulationConfig.loadXML("../configs/simulations", basename(name));
		assert(simulationConfigs[baseName].title == baseName);
    }
    foreach (string name; dirEntries("../stats/simulations", SpanMode.breadth))
    {
    	string baseName = basename(name, ".stat.xml");
    	del("Loading simulation stat: " ~ boldFontBeginStr ~ baseName ~ boldFontEndStr);
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

enum SimulatorEventType: string {
	GENERAL = "GENERAL",
	HALT = "HALT",
	FATAL = "FATAL",
	PANIC = "PANIC"
}

class SimulatorEventContext {	
	this(string name) {
		this.name = name;
	}
	
	override string toString() {		
		return format("SimulatorEventContext[name=%s]", this.name);
	}

	string name;
}

class SimulatorEventQueue: EventQueue!(SimulatorEventType, SimulatorEventContext) {
	this(Simulator simulator) {
		super("SimulatorEventQueue");
		
		this.simulator = simulator;
		
		this.halted = false;

		this.registerHandler(SimulatorEventType.GENERAL, &this.generalHandler);
		this.registerHandler(SimulatorEventType.HALT, &this.haltHandler);
		this.registerHandler(SimulatorEventType.FATAL, &this.fatalHandler);
		this.registerHandler(SimulatorEventType.PANIC, &this.panicHandler);
	}

	void generalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
	}

	void haltHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		this.halted = true;
		//exit(0);
	}

	void fatalHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		core.stdc.stdlib.exit(1);
	}

	void panicHandler(SimulatorEventType eventType, SimulatorEventContext context, ulong when) {
		core.stdc.stdlib.exit(-1);
	}
	
	Simulator simulator;
	bool halted;
}

abstract class Simulator {
	this() {
		this.eventQueue = new SimulatorEventQueue(this);
		this.addEventProcessor(this.eventQueue);
		
		Simulator.singleInstance = this;
	}

	abstract void run();

	void addEventProcessor(EventProcessor eventProcessor) {
		this.eventProcessors ~= eventProcessor;
	}
	
	SimulatorEventQueue eventQueue;
	
	EventProcessor[] eventProcessors;

	static Simulator singleInstance;
}

static this() {
	currentCycle = 0;
}

ulong currentCycle;

void scheduleEvent(SimulatorEventType eventType, SimulatorEventContext context, ulong delay = 0) {
	Simulator.singleInstance.eventQueue.schedule(eventType, context, delay);
}

void executeEvent(SimulatorEventType eventType, SimulatorEventContext context) {
	Simulator.singleInstance.eventQueue.execute(eventType, context);
}

void mainConsole(string[] args) {
	string simulationTitle = "WCETBench-fir-1x1";
	//string simulationTitle = "WCETBench-fir-2x1";
	//string simulationTitle = "Olden_Custom1-em3d_original-1x1";
	//string simulationTitle = "Olden_Custom1-mst_original-1x1";
	//string simulationTitle = "Olden_Custom1-mst_original-Olden_Custom1_em3d_original-2x1";
	//string simulationTitle = "Olden_Custom1-mst_original-2x1";
	
	getopt(args, "simulation", &simulationTitle);
	
	loadConfigsAndStats(delegate void(string text)
		{
			logging.info(LogCategory.SIMULATOR, text);
		}, false);

	logging.infof(LogCategory.SIMULATOR, "run simulation(title=%s)", simulationTitle);

	SimulationConfig simulationConfig = SimulationConfig.loadXML("../configs/simulations", simulationTitle ~ ".config.xml");
	Simulation simulation = new Simulation(simulationConfig);
	simulation.execute();
	
	saveConfigsAndStats();
}

void mainGui(string[] args) {
	new Startup(args);
}

void main(string[] args) {
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (C) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");
	
	bool gui = false;
	gui ? mainGui(args) : mainConsole(args);
}