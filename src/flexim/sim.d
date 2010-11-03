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

class Benchmark {
	this(string title, string cwd, string exe, string argsLiteral, string stdin = null, string stdout = null, uint numThreadsPerCore = 1) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.argsLiteral = argsLiteral;
		this.stdin = stdin;
		this.stdout = stdout;
		this.numThreadsPerCore = numThreadsPerCore;
	}
	
	string args() {
		return sub(this.argsLiteral, r"\$\{nthreads\}", format("%d", this.numThreadsPerCore), "g");
	}
	
	override string toString() {
		return format("Benchmark[title=%s, cwd=%s, exe=%s, argsLiteral=%s, stdin=%s, stdout=%s, numThreadsPerCore=%d]",
			this.title, this.cwd, this.exe, this.argsLiteral, this.stdin, this.stdout, this.numThreadsPerCore);
	}
	
	string title;
	string cwd;
	string exe;
	string argsLiteral;
	string stdin;
	string stdout;
	
	uint numThreadsPerCore;
	BenchmarkSuite suite;
}

class BenchmarkSuite {	
	this(string title) {
		this.title = title;
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
		return format("BenchmarkSuite[title=%s, benchmarks.length=%d]", this.title, this.benchmarks.length);
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
	
	string title;
	Benchmark[string] benchmarks;
}

class BenchmarkSuiteXMLFileSerializer: XMLFileSerializer!(BenchmarkSuite) {
	this() {
	}
	
	override XMLConfigFile save(BenchmarkSuite benchmarkSuite) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("BenchmarkSuite");
		
		xmlConfigFile["title"] = benchmarkSuite.title;
		
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
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(bs_title);
		
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
	this(Benchmark workload) {
		this.workload = workload;
	}
	
	string exe() {
		return this.workload.exe;
	}
	
	string args() {
		return this.workload.args;
	}
	
	string cwd() {
		return this.workload.cwd;
	}
	
	string stdin() {
		return this.workload.stdin;
	}
	
	string stdout() {
		return this.workload.stdout;
	}
	
	override string toString() {
		return format("ContextConfig[workload=%s]", this.workload);
	}

	Benchmark workload;
}

class ContextConfigXMLSerializer: XMLSerializer!(ContextConfig) {
	this() {
	}
	
	override XMLConfig save(ContextConfig contextConfig) {
		XMLConfig xmlConfig = new XMLConfig("ContextConfig");
		
		xmlConfig["benchmarkSuiteTitle"] = contextConfig.workload.suite.title;
		xmlConfig["benchmarkTitle"] = contextConfig.workload.title;
		
		return xmlConfig;
	}
	
	override ContextConfig load(XMLConfig xmlConfig) {
		string benchmarkSuiteTitle = xmlConfig["benchmarkSuiteTitle"];
		string benchmarkTitle = xmlConfig["benchmarkTitle"];
		
		Benchmark workload = benchmarkSuites[benchmarkSuiteTitle][benchmarkTitle];
		
		ContextConfig contextConfig = new ContextConfig(workload);
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
	this(ulong maxCycle, ulong maxInsts, ulong maxTime, uint numThreadsPerCore,
		uint physicalRegisterFileCapacity,
		uint commitWidth, uint decodeBufferCapacity, uint reorderBufferCapacity, uint loadStoreQueueCapacity) {
		this.maxCycle = maxCycle;
		this.maxInsts = maxInsts;
		this.maxTime = maxTime;
		this.numThreadsPerCore = numThreadsPerCore;
		
		this.physicalRegisterFileCapacity = physicalRegisterFileCapacity;
		this.commitWidth = commitWidth;
		this.decodeBufferCapacity = decodeBufferCapacity;
		this.reorderBufferCapacity = reorderBufferCapacity;
		this.loadStoreQueueCapacity = loadStoreQueueCapacity;
	}
	
	override string toString() {
		return format("ProcessorConfig[maxCycle=%d, maxInsts=%d, maxTime=%d, numThreadsPerCore=%d, cores.length=%d, " ~
			"physicalRegisterFileCapacity=%d, " ~
			"commitWidth=%d, decodeBufferCapacity=%d, reorderBufferCapacity=%d, loadStoreQueueCapacity=%d]",
			this.maxCycle, this.maxInsts, this.maxTime, this.numThreadsPerCore, this.cores.length,
			this.physicalRegisterFileCapacity,
			this.commitWidth, this.decodeBufferCapacity, this.reorderBufferCapacity, this.loadStoreQueueCapacity);
	}

	ulong maxCycle, maxInsts, maxTime;
	uint numThreadsPerCore;
	CoreConfig[] cores;
	
	uint physicalRegisterFileCapacity;
	uint commitWidth, decodeBufferCapacity, reorderBufferCapacity, loadStoreQueueCapacity;
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
			
		xmlConfig["physicalRegisterFileCapacity"] = to!(string)(processorConfig.physicalRegisterFileCapacity);
		xmlConfig["commitWidth"] = to!(string)(processorConfig.commitWidth);
		xmlConfig["decodeBufferCapacity"] = to!(string)(processorConfig.decodeBufferCapacity);
		xmlConfig["reorderBufferCapacity"] = to!(string)(processorConfig.reorderBufferCapacity);
		xmlConfig["loadStoreQueueCapacity"] = to!(string)(processorConfig.loadStoreQueueCapacity);
			
		foreach(core; processorConfig.cores) {
			xmlConfig.entries ~= CoreConfigXMLSerializer.singleInstance.save(core);
		}
		
		return xmlConfig;		
	}
	
	override ProcessorConfig load(XMLConfig xmlConfig) {
		ulong maxCycle = to!(ulong)(xmlConfig["maxCycle"]);
		ulong maxInsts = to!(ulong)(xmlConfig["maxInsts"]);
		ulong maxTime = to!(ulong)(xmlConfig["maxTime"]);
		uint numThreadsPerCore = to!(uint)(xmlConfig["numThreadsPerCore"]);
			
		uint physicalRegisterFileCapacity = to!(uint)(xmlConfig["physicalRegisterFileCapacity"]);
		uint commitWidth = to!(uint)(xmlConfig["commitWidth"]);
		uint decodeBufferCapacity = to!(uint)(xmlConfig["decodeBufferCapacity"]);
		uint reorderBufferCapacity = to!(uint)(xmlConfig["reorderBufferCapacity"]);
		uint loadStoreQueueCapacity = to!(uint)(xmlConfig["loadStoreQueueCapacity"]);
			
		ProcessorConfig processorConfig = new ProcessorConfig(maxCycle, maxInsts, maxTime, numThreadsPerCore,
			physicalRegisterFileCapacity,
			commitWidth, decodeBufferCapacity, reorderBufferCapacity, loadStoreQueueCapacity);
		
		foreach(entry; xmlConfig.entries) {
			processorConfig.cores ~= CoreConfigXMLSerializer.singleInstance.load(entry);
		}
		
		return processorConfig;
	}
	
	static this() {
		singleInstance = new ProcessorConfigXMLSerializer();
	}
	
	static ProcessorConfigXMLSerializer singleInstance;
}

class ArchitectureConfig: Config!(ArchitectureConfig) {
	this(string title, ProcessorConfig processor, CacheConfig l2Cache, MainMemoryConfig mainMemory) {
		this.title = title;
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
		return format("ArchitectureConfig[title=%s, processor=%s, l2Cache=%s, mainMemory=%s]",
			this.title, this.processor, this.l2Cache, this.mainMemory);
	}

	string title;
	ProcessorConfig processor;
	CacheConfig l2Cache;
	MainMemoryConfig mainMemory;
	
	static ArchitectureConfig loadXML(string cwd, string fileName) {
		return ArchitectureConfigXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(ArchitectureConfig architectureConfig, string cwd, string fileName) {
		ArchitectureConfigXMLFileSerializer.singleInstance.saveXML(architectureConfig, join(cwd, fileName));
	}
	
	static void saveXML(ArchitectureConfig architectureConfig) {
		saveXML(architectureConfig, "../configs/architectures", architectureConfig.title ~ ".xml");
	}
}

class ArchitectureConfigXMLFileSerializer: XMLFileSerializer!(ArchitectureConfig) {
	this() {
	}
	
	override XMLConfigFile save(ArchitectureConfig architectureConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("ArchitectureConfig");
		
		xmlConfigFile["title"] = architectureConfig.title;
		
		xmlConfigFile.entries ~= ProcessorConfigXMLSerializer.singleInstance.save(architectureConfig.processor);
		xmlConfigFile.entries ~= CacheConfigXMLSerializer.singleInstance.save(architectureConfig.l2Cache);
		xmlConfigFile.entries ~= MainMemoryConfigXMLSerializer.singleInstance.save(architectureConfig.mainMemory);
		
		return xmlConfigFile;
	}
	
	override ArchitectureConfig load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		
		ProcessorConfig processor = ProcessorConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		CacheConfig l2Cache = CacheConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		MainMemoryConfig mainMemory = MainMemoryConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[2]);
		
		ArchitectureConfig architectureConfig = new ArchitectureConfig(title, processor, l2Cache, mainMemory);
		return architectureConfig;
	}
	
	static this() {
		singleInstance = new ArchitectureConfigXMLFileSerializer();
	}
	
	static ArchitectureConfigXMLFileSerializer singleInstance;
}

class SimulationConfig: Config!(SimulationConfig) {
	this(ArchitectureConfig architecture) {
		this.architecture = architecture;
	}
	
	override string toString() {
		return format("SimulationConfig[architecture=%s, contexts.length=%d]",
			this.architecture, this.contexts.length);
	}

	ArchitectureConfig architecture;
	ContextConfig[] contexts;
}

class SimulationConfigXMLSerializer: XMLSerializer!(SimulationConfig) {
	this() {
	}
	
	override XMLConfig save(SimulationConfig simulationConfig) {
		XMLConfig xmlConfig = new XMLConfig("SimulationConfig");
		
		xmlConfig["architectureConfigTitle"] = simulationConfig.architecture.title;
		
		foreach(context; simulationConfig.contexts) {
			xmlConfig.entries ~= ContextConfigXMLSerializer.singleInstance.save(context);
		}
		
		return xmlConfig;
	}
	
	override SimulationConfig load(XMLConfig xmlConfig) {
		string architectureConfigTitle = xmlConfig["architectureConfigTitle"];
		
		ArchitectureConfig architecture = architectureConfigs[architectureConfigTitle];
		
		SimulationConfig simulationConfig = new SimulationConfig(architecture);
		
		foreach(entry; xmlConfig.entries) {
			simulationConfig.contexts ~= ContextConfigXMLSerializer.singleInstance.load(entry);
		}
		
		return simulationConfig;
	}
	
	static this() {
		singleInstance = new SimulationConfigXMLSerializer();
	}
	
	static SimulationConfigXMLSerializer singleInstance;
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
	this(uint numCores, uint numThreadsPerCore) {
		ProcessorStat processor = new ProcessorStat();
		for(uint i = 0; i < numCores; i++) {
			CoreStat core = new CoreStat();
			
			for(uint j = 0; j < numThreadsPerCore; j++) {
				ContextStat context = new ContextStat();
				processor.contexts ~= context;
			}
			
			processor.cores ~= core;
		}
		
		this(processor);
	}
	
	this(ProcessorStat processor) {
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
		return format("SimulationStat[totalCycles=%d, duration=%d, processor=%s, l2Cache=%s, mainMemory=%s]",
			this.totalCycles, this.duration, this.processor, this.l2Cache, this.mainMemory);
	}
	
	ProcessorStat processor;
	CacheStat l2Cache;
	MainMemoryStat mainMemory;

	Property!(ulong) totalCycles;
	Property!(ulong) duration;
}

class SimulationStatXMLSerializer: XMLSerializer!(SimulationStat) {
	this() {
	}
	
	override XMLConfig save(SimulationStat simulationStat) {
		XMLConfig xmlConfig = new XMLConfig("SimulationStat");
		
		xmlConfig["totalCycles"] = to!(string)(simulationStat.totalCycles.value);
		xmlConfig["duration"] = to!(string)(simulationStat.duration.value);
			
		xmlConfig.entries ~= ProcessorStatXMLSerializer.singleInstance.save(simulationStat.processor);
		xmlConfig.entries ~= CacheStatXMLSerializer.singleInstance.save(simulationStat.l2Cache);
		xmlConfig.entries ~= MainMemoryStatXMLSerializer.singleInstance.save(simulationStat.mainMemory);
		
		return xmlConfig;
	}
	
	override SimulationStat load(XMLConfig xmlConfig) {
		ulong totalCycles = to!(ulong)(xmlConfig["totalCycles"]);
		ulong duration = to!(ulong)(xmlConfig["duration"]);
			
		ProcessorStat processor = ProcessorStatXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		CacheStat l2Cache = CacheStatXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		MainMemoryStat mainMemory = MainMemoryStatXMLSerializer.singleInstance.load(xmlConfig.entries[2]);
				
		SimulationStat simulationStat = new SimulationStat(processor);
		simulationStat.l2Cache = l2Cache;
		simulationStat.mainMemory = mainMemory;
		simulationStat.totalCycles.value = totalCycles;
		simulationStat.duration.value = duration;
		
		return simulationStat;
	}
	
	static this() {
		singleInstance = new SimulationStatXMLSerializer();
	}
	
	static SimulationStatXMLSerializer singleInstance;
}

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible {
	this(string title, string cwd, SimulationConfig config, SimulationStat stat) {
		this.title = title;
		this.cwd = cwd;
		this.config = config;
		this.stat = stat;
	}
	
	this(string title, string cwd, ArchitectureConfig architectureConfig) {
		SimulationConfig simulationConfig = new SimulationConfig(architectureConfig);
		
		SimulationStat simulationStat = new SimulationStat(
			architectureConfig.processor.cores.length, 
			architectureConfig.processor.numThreadsPerCore);
			
		this(title, cwd, simulationConfig, simulationStat);
	}
	
	void execute() {
		this.beforeRun();
		this.run();
		this.afterRun();
	}
	
	override void beforeRun() {
		this.isRunning = true;
		this.stat.reset();
	}
	
	override void run() {
		Simulator simulator = new CPUSimulator(this);
		simulator.run();
	}
	
	void abort() {
		this.isRunning = false;
	}
	
	override void afterRun() {
		this.isRunning = false;
	}
	
	override string toString() {
		return format("Simulation[title=%s, cwd=%s]", this.title, this.cwd);
	}

	string title, cwd;
	SimulationConfig config;
	SimulationStat stat;
	
	bool isRunning;
	
	static Simulation loadXML(string cwd, string fileName) {
		return SimulationXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(Simulation simulation, string cwd, string fileName) {
		SimulationXMLFileSerializer.singleInstance.saveXML(simulation, join(cwd, fileName));
	}
	
	static void saveXML(Simulation simulation) {
		saveXML(simulation, "../simulations", simulation.title ~ ".xml");
	}
}

class SimulationXMLFileSerializer: XMLFileSerializer!(Simulation) {
	this() {
	}
	
	override XMLConfigFile save(Simulation simulation) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("SimulationStat");
		
		xmlConfigFile["title"] = simulation.title;
		xmlConfigFile["cwd"] = simulation.cwd;
			
		xmlConfigFile.entries ~= SimulationConfigXMLSerializer.singleInstance.save(simulation.config);
		xmlConfigFile.entries ~= SimulationStatXMLSerializer.singleInstance.save(simulation.stat);
		
		return xmlConfigFile;
	}
	
	override Simulation load(XMLConfigFile xmlConfigFile) {
		string title = xmlConfigFile["title"];
		string cwd = xmlConfigFile["cwd"];
		
		SimulationConfig connfig = SimulationConfigXMLSerializer.singleInstance.load(xmlConfigFile.entries[0]);
		SimulationStat stat = SimulationStatXMLSerializer.singleInstance.load(xmlConfigFile.entries[1]);
		
		Simulation simulation = new Simulation(title, cwd, connfig, stat);
		
		return simulation;
	}
	
	static this() {
		singleInstance = new SimulationXMLFileSerializer();
	}
	
	static SimulationXMLFileSerializer singleInstance;
}

BenchmarkSuite[string] benchmarkSuites;
ArchitectureConfig[string] architectureConfigs;
Simulation[string] simulations;

Benchmark defaultBenchmark() {
	return benchmarkSuites["WCETBench"]["fir"];
}

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
    foreach (string name; dirEntries("../configs/architectures", SpanMode.breadth))
    {
    	string baseName = basename(name, ".xml");
    	del("Loading architecture config: " ~ boldFontBeginStr ~ baseName ~ boldFontEndStr);
		architectureConfigs[baseName] = ArchitectureConfig.loadXML("../configs/architectures", basename(name));
		assert(architectureConfigs[baseName].title == baseName, baseName);
    }
    foreach (string name; dirEntries("../simulations", SpanMode.breadth))
    {
    	string baseName = basename(name, ".xml");
    	del("Loading simulation: " ~ boldFontBeginStr ~ baseName ~ boldFontEndStr);
		simulations[baseName] = Simulation.loadXML("../simulations", basename(name));
		assert(simulations[baseName].title == baseName);
    }
}

void saveConfigsAndStats() {
    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    foreach (string name; dirEntries("../configs/architectures", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    foreach (string name; dirEntries("../simulations", SpanMode.breadth))
    {
		std.file.remove(name);
    }
    
	foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
		BenchmarkSuite.saveXML(benchmarkSuite);
	}	
	foreach(simulationConfigTitle, architectureConfig; architectureConfigs) {
		ArchitectureConfig.saveXML(architectureConfig);
	}
	foreach(simulationTitle, simulation; simulations) {
		Simulation.saveXML(simulation);
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
	//string simulationTitle = "WCETBench-fir-1x1";
	//string simulationTitle = "WCETBench-fir-2x1";
	//string simulationTitle = "Olden_Custom1-em3d_original-1x1";
	string simulationTitle = "Olden_Custom1-mst_original-1x1";
	//string simulationTitle = "Olden_Custom1-mst_original-Olden_Custom1_em3d_original-2x1";
	//string simulationTitle = "Olden_Custom1-mst_original-2x1";
	
	getopt(args, "simulation", &simulationTitle);
	
	loadConfigsAndStats(delegate void(string text)
		{
			logging.info(LogCategory.SIMULATOR, text);
		}, false);

	logging.infof(LogCategory.SIMULATOR, "run simulation(title=%s)", simulationTitle);

	Simulation simulation = Simulation.loadXML("../simulations", simulationTitle ~ ".xml");
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
