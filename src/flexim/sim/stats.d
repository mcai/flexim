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

abstract class Stats {
}

class CPUStats: Stats {
	
}

class CacheStats: Stats {
	this() {
		
	}
	
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

class CacheStatsXMLSerializer: XMLSerializer!(CacheStats) {
	this() {
	}
	
	override XMLConfig save(CacheStats cacheStats) {
		XMLConfig xmlConfig = new XMLConfig("CacheStats");
		
		xmlConfig.attributes["accesses"] = to!(string)(cacheStats.accesses);
		xmlConfig.attributes["hits"] = to!(string)(cacheStats.hits);
		xmlConfig.attributes["evictions"] = to!(string)(cacheStats.evictions);
		xmlConfig.attributes["reads"] = to!(string)(cacheStats.reads);
		xmlConfig.attributes["blockingReads"] = to!(string)(cacheStats.blockingReads);
		xmlConfig.attributes["nonblockingReads"] = to!(string)(cacheStats.nonblockingReads);
		xmlConfig.attributes["readHits"] = to!(string)(cacheStats.readHits);
		xmlConfig.attributes["writes"] = to!(string)(cacheStats.writes);
		xmlConfig.attributes["blockingWrites"] = to!(string)(cacheStats.blockingWrites);
		xmlConfig.attributes["nonblockingWrites"] = to!(string)(cacheStats.nonblockingWrites);
		xmlConfig.attributes["writeHits"] = to!(string)(cacheStats.writeHits);
		
		xmlConfig.attributes["readRetries"] = to!(string)(cacheStats.readRetries);
		xmlConfig.attributes["writeRetries"] = to!(string)(cacheStats.writeRetries);
		
		xmlConfig.attributes["noRetryAccesses"] = to!(string)(cacheStats.noRetryAccesses);
		xmlConfig.attributes["noRetryHits"] = to!(string)(cacheStats.noRetryHits);
		xmlConfig.attributes["noRetryReads"] = to!(string)(cacheStats.noRetryReads);
		xmlConfig.attributes["noRetryReadHits"] = to!(string)(cacheStats.noRetryReadHits);
		xmlConfig.attributes["noRetryWrites"] = to!(string)(cacheStats.noRetryWrites);
		xmlConfig.attributes["noRetryWriteHits"] = to!(string)(cacheStats.noRetryWriteHits);
			
		return xmlConfig;
	}
	
	override CacheStats load(XMLConfig xmlConfig) {
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
			
		CacheStats cacheStats = new CacheStats();
		cacheStats.accesses = accesses;
		cacheStats.hits = hits;
		cacheStats.evictions = evictions;
		cacheStats.reads = reads;
		cacheStats.blockingReads = blockingReads;
		cacheStats.nonblockingReads = nonblockingReads;
		cacheStats.readHits = readHits;
		cacheStats.writes = writes;
		cacheStats.blockingWrites = blockingWrites;
		cacheStats.nonblockingWrites = nonblockingWrites;
		cacheStats.writeHits = writeHits;
		
		cacheStats.readRetries = readRetries;
		cacheStats.writeRetries = writeRetries;
		
		cacheStats.noRetryAccesses = noRetryAccesses;
		cacheStats.noRetryHits = noRetryHits;
		cacheStats.noRetryReads = noRetryReads;
		cacheStats.noRetryReadHits = noRetryReadHits;
		cacheStats.noRetryWrites = noRetryWrites;
		cacheStats.noRetryWriteHits = noRetryWriteHits;

		return cacheStats;
	}
	
	static this() {
		singleInstance = new CacheStatsXMLSerializer();
	}
	
	static CacheStatsXMLSerializer singleInstance;
}