/*
 * flexim/drivers/configs.d
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

module flexim.drivers.configs;

import flexim.all;

abstract class Config {
	abstract void writeTo(); //TODO: pls add stream stuff
}

class CPUConfig: Config {
	this() {
	}
	
	override void writeTo() {
		assert(0); //TODO
	}
	
	override string toString() {
		return format("CPUConfig[]");
	}
	
	ulong maxCycle;
	ulong maxInsts;
	ulong maxTime;
	
	uint numCores;
	uint numThreads;
}

class ContextConfig: Config {
	static class Context {
		this(uint num, string binariesDir, Benchmark benchmark) {
			this(num, binariesDir, benchmark, "");
		}
		
		this(uint num, string binariesDir, Benchmark benchmark, string env) {
			this(num, benchmark.exe, benchmark.args, binariesDir ~ "/" ~
				benchmark.cwd, benchmark.stdin, benchmark.stdout, env);
		}
		
		this(uint num, string exe, string args) {
			this(num, exe, args, "", "", "context-" ~ to!(string)(num) ~ ".out", "");
		}
		
		this(uint num, string exe, string args, string cwd,
			string stdin, string stdout, string env) {
			this.num = num;
			this.exe = exe;
			this.args = args;
			this.env = env;
			this.cwd = cwd;
			this.stdin = stdin;
			this.stdout = stdout;	
		}
		
		override string toString() {
			return format("Context[num: %d, exe: %s, args: %s, cwd: %s, stdin: %s, stdout: %s, env: %s]",
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
	
	this() {
	}
	
	override void writeTo() {
		assert(0); //TODO
	}
	
	override string toString() {
		return format("ContextConfig[contexts.length: %d]", this.contexts.length);
	}
	
	Context[] contexts;
}

class CacheConfig: Config {
	static class Cache {
		static enum Policy: string {
			LRU = "LRU",
			FIFO = "FIFO",
			Random = "Random"
		}
		
		this(string name, uint sets, uint assoc, uint blockSize, uint hitLatency, uint misslatency) {
			this(name, sets, assoc, blockSize, hitLatency, missLatency, Policy.LRU);
		}
		
		this(string name, uint sets, uint assoc, uint blockSize, uint hitlateny, uint missLatency, Policy policy) {
			this.name = name;
			this.sets = sets;
			this.assoc = assoc;
			this.blockSize = blockSize;
			this.hitLatency = hitLatency;
			this.policy = policy;
		}
		
		override string toString() {
			return format("Cache[name: %s, sets: %d, assoc: %d, blockSize: %d, hitLatency: %d, missLatency: %d, policy: %s]",
				this.name, this.sets, this.assoc, this.blockSize, this.hitLatency, this.missLatency, this.policy);
		}
		
		string name;
		uint sets;
		uint assoc;
		uint blockSize;
		uint hitLatency;
		uint missLatency;
		Policy policy;
	}
	
	this() {
	}
	
	override void writeTo() {
		assert(0); //TODO
	}
	
	override string toString() {
		return format("CacheConfig[caches.length: %d]", this.caches.length);
	}
	
	Cache[] caches;
}