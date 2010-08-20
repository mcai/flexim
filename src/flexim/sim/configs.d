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
import std.process;

const string CPU_CONFIG_XML = "cpu_config.xml";
const string CACHE_CONFIG_XML = "cache_config.xml";
const string CONTEXT_CONFIG_XML = "context_config.xml";

abstract class Config(ConfigT) {
}

class CPUConfig: Config!(CPUConfig) {
	this(ulong maxCycle, ulong maxInsts, ulong maxTime, uint numCores, uint numThreads) {
		this.maxCycle = maxCycle;
		this.maxInsts = maxInsts;
		this.maxTime = maxTime;
		this.numCores = numCores;
		this.numThreads = numThreads;
	}
	
	override string toString() {
		return format("CPUConfig[maxCycle=%d, maxInsts=%d, maxTime=%d, numCores=%d, numThreads=%d]",
			this.maxCycle, this.maxInsts, this.maxTime, this.numCores, this.numThreads);
	}
	
	static CPUConfig loadXML(string cwd, string fileName = CPU_CONFIG_XML) {
		return CPUConfigXMLSerializer.instance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(CPUConfig cpuConfig, string cwd, string fileName = CPU_CONFIG_XML) {
		CPUConfigXMLSerializer.instance.saveXML(cpuConfig, join(cwd, fileName));
	}
	
	static CPUConfig createDefault(uint numCores, uint numThreads) {
		return new CPUConfig(2000000, 2000000, 7200, numCores, numThreads);
	}
	
	ulong maxCycle;
	ulong maxInsts;
	ulong maxTime;
	
	uint numCores;
	uint numThreads;
}

class CPUConfigXMLSerializer: XMLSerializer!(CPUConfig) {
	this() {
	}
	
	override XMLConfigFile save(CPUConfig cpuConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("CPUConfig");
		
		xmlConfigFile.attributes["maxCycle"] = to!(string)(cpuConfig.maxCycle);
		xmlConfigFile.attributes["maxInsts"] = to!(string)(cpuConfig.maxInsts);
		xmlConfigFile.attributes["maxTime"] = to!(string)(cpuConfig.maxTime);
		xmlConfigFile.attributes["numCores"] = to!(string)(cpuConfig.numCores);
		xmlConfigFile.attributes["numThreads"] = to!(string)(cpuConfig.numThreads);
			
		return xmlConfigFile;
	}
	
	override CPUConfig load(XMLConfigFile xmlConfigFile) {
		ulong maxCycle = to!(ulong)(xmlConfigFile.attributes["maxCycle"]);
		ulong maxInsts = to!(ulong)(xmlConfigFile.attributes["maxInsts"]);
		ulong maxTime = to!(ulong)(xmlConfigFile.attributes["maxTime"]);
		uint numCores = to!(uint)(xmlConfigFile.attributes["numCores"]);
		uint numThreads = to!(uint)(xmlConfigFile.attributes["numThreads"]);
			
		return new CPUConfig(maxCycle, maxInsts, maxTime, numCores, numThreads);
	}
	
	static this() {
		instance = new CPUConfigXMLSerializer();
	}
	
	static CPUConfigXMLSerializer instance;
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
	
	static CacheConfig loadXML(string cwd, string fileName = CACHE_CONFIG_XML) {
		return CacheConfigXMLSerializer.instance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(CacheConfig cacheConfig, string cwd, string fileName = CACHE_CONFIG_XML) {
		CacheConfigXMLSerializer.instance.saveXML(cacheConfig, join(cwd, fileName));
	}
	
	static CacheConfig createDefault(uint numCores, uint numThreads) {
		CacheConfig cacheConfig = new CacheConfig();
		
		CacheGeometry l2 = new CacheGeometry("l2", 1024, 4, 64, 4, 7, CacheReplacementPolicy.LRU);
		cacheConfig.caches[l2.name] = l2;
		
		for(uint i = 0; i < numCores * numThreads; i++) {
			CacheGeometry l1D = new CacheGeometry("l1D" ~ "-" ~ to!(string)(i), 64, 4, 64, 1, 3, CacheReplacementPolicy.LRU);
			cacheConfig.caches[l1D.name] = l1D;
			
			CacheGeometry l1I = new CacheGeometry("l1I" ~ "-" ~ to!(string)(i), 64, 4, 64, 1, 3, CacheReplacementPolicy.LRU);
			cacheConfig.caches[l1I.name] = l1I;
		}
		
		return cacheConfig;
	}
	
	CacheGeometry[string] caches;
}

class CacheConfigXMLSerializer: XMLSerializer!(CacheConfig) {	
	this() {
	}
	
	override XMLConfigFile save(CacheConfig cacheConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("CacheConfig");
		
		foreach(cacheName, cache; cacheConfig.caches) {
			XMLConfig xmlConfig = new XMLConfig("Cache");
			xmlConfig.attributes["name"] = cache.name;
			xmlConfig.attributes["sets"] = to!(string)(cache.sets);
			xmlConfig.attributes["assoc"] = to!(string)(cache.assoc);
			xmlConfig.attributes["blockSize"] = to!(string)(cache.blockSize);
			xmlConfig.attributes["hitLatency"] = to!(string)(cache.hitLatency);
			xmlConfig.attributes["missLatency"] = to!(string)(cache.missLatency);
			xmlConfig.attributes["policy"] = to!(string)(cache.policy);
				
			xmlConfigFile.entries ~= xmlConfig;
		}
		
		return xmlConfigFile;
	}
	
	override CacheConfig load(XMLConfigFile xmlConfigFile) {
		CacheConfig cacheConfig = new CacheConfig();
		
		foreach(entry; xmlConfigFile.entries) {
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
		instance = new CacheConfigXMLSerializer();
	}
	
	static CacheConfigXMLSerializer instance;
}

class Context {
	this(uint num, string binariesDir, Benchmark benchmark) {
		this(num, binariesDir, benchmark, "");
	}
	
	this(uint num, string binariesDir, Benchmark benchmark, string env) {
		this(num, benchmark.exe, benchmark.args, join(binariesDir, benchmark.cwd), benchmark.stdin, benchmark.stdout, env);
	}
	
	this(uint num, string exe, string args) {
		this(num, exe, args, "", "", "context-" ~ to!(string)(num) ~ ".out", "");
	}
	
	this(uint num, string exe, string args, string cwd, string stdin, string stdout, string env) {
		this.num = num;
		this.exe = exe;
		this.args = args;
		this.env = env;
		this.cwd = cwd;
		this.stdin = stdin;
		this.stdout = stdout;	
	}
	
	override string toString() {
		return format("Context[num=%d, exe=%s, args=%s, cwd=%s, stdin=%s, stdout=%s, env=%s]",
			this.num, this.exe, this.args, this.cwd, this.stdin, this.stdout, this.env);
	}
	
	uint num;
	string exe;
	string args;
	string cwd;
	string stdin;
	string stdout;
	string env;
}

class ContextConfig: Config!(ContextConfig) {	
	this() {
	}
	
	override string toString() {
		return format("ContextConfig[contexts.length=%d]", this.contexts.length);
	}
	
	static ContextConfig loadXML(string cwd, string fileName = CONTEXT_CONFIG_XML) {
		return ContextConfigXMLSerializer.instance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(ContextConfig contextConfig, string cwd, string fileName = CONTEXT_CONFIG_XML) {
		ContextConfigXMLSerializer.instance.saveXML(contextConfig, join(cwd, fileName));
	}
	
	static ContextConfig createDefault(string binariesDir, Benchmark benchmark, uint numCores, uint numThreads) {
		ContextConfig contextConfig = new ContextConfig();
		
		for(uint i = 0; i < numCores * numThreads; i++) {
			Context context = new Context(i, binariesDir, benchmark);
			contextConfig.contexts ~= context;
		}
		
		return contextConfig;
	}
	
	Context[] contexts;
}

class ContextConfigXMLSerializer: XMLSerializer!(ContextConfig) {
	this() {
	}
	
	override XMLConfigFile save(ContextConfig contextConfig) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("ContextConfig");
		
		foreach(context; contextConfig.contexts) {
			XMLConfig xmlConfig = new XMLConfig("Context");
			xmlConfig.attributes["num"] = to!(string)(context.num);
			xmlConfig.attributes["exe"] = context.exe;
			xmlConfig.attributes["args"] = context.args;
			xmlConfig.attributes["cwd"] = context.cwd;
			xmlConfig.attributes["stdin"] = context.stdin;
			xmlConfig.attributes["stdout"] = context.stdout;
			xmlConfig.attributes["env"] = context.env;
			
			xmlConfigFile.entries ~= xmlConfig;
		}
		
		return xmlConfigFile;
	}
	
	override ContextConfig load(XMLConfigFile xmlConfigFile) {
		ContextConfig contextConfig = new ContextConfig();
				
		foreach(entry; xmlConfigFile.entries) {
			uint num = to!(uint)(entry.attributes["num"]);
			string exe = entry.attributes["exe"];
			string args = entry.attributes["args"];
			string cwd = entry.attributes["cwd"];
			string stdin = entry.attributes["stdin"];
			string stdout = entry.attributes["stdout"];
			string env = entry.attributes["env"];
			
			Context context = new Context(num, exe, args, cwd, stdin, stdout, env);
			contextConfig.contexts ~= context;
		}
		
		return contextConfig;
	}
	
	static this() {
		instance = new ContextConfigXMLSerializer();
	}
	
	static ContextConfigXMLSerializer instance;
}