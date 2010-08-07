/*
 * flexim/mem/cache.d
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

module flexim.mem.cache;

import flexim.all;

enum CacheMonitoringEventType: string {
	DIR_ENTRY_ADD_SHARER = "DIR_ENTRY_ADD_SHARER",
	DIR_ENTRY_REMOVE_SHARER = "DIR_ENTRY_REMOVE_SHARER",
	DIR_ENTRY_SET_OWNER = "DIR_ENTRY_SET_OWNER",
	DIR_LOCK_LOCK = "DIR_LOCK_LOCK",
	DIR_LOCK_UNLOCK = "DIR_LOCK_UNLOCK"
}

alias ContextCallback4!(uint, uint, CacheMonitoringEventType, string) CacheMonitoringCallback;

class CacheMonitor {
	this() {
	}

	void invoke(uint x, uint y, CacheMonitoringEventType eventType, string msg) {
		foreach(monitor; this.callbacks) {
			monitor.invoke(x, y, eventType, msg);
		}
	}

	CacheMonitoringCallback[] callbacks;
}

class DirEntry(StateT) {
	this(uint x, uint y) {
		this.x = x;
		this.y = y;
		
		this.monitor = new CacheMonitor();
	}

	alias ICache!(StateT) ICacheT;

	void addSharer(ICacheT node) {
		assert(node !is null);
		this.monitor.invoke(this.x, this.y, CacheMonitoringEventType.DIR_ENTRY_ADD_SHARER, node.name);

		this.sharers ~= node;
	}

	void removeSharer(ICacheT node) {
		assert(node !is null);
		this.monitor.invoke(this.x, this.y, CacheMonitoringEventType.DIR_ENTRY_REMOVE_SHARER, node.name);

		bool hasFound = false;
		uint indexFound;

		foreach(i, sharer; this.sharers) {
			if(sharer.name == node.name) {
				hasFound = true;
				indexFound = i;
				break;
			}
		}

//		assert(hasFound); //TODO: uncomment it

		if(hasFound) {
			this.sharers = this.sharers.remove(indexFound);
		}
	}

	bool isSharer(ICacheT node) {
		uint indexFound;

		foreach(i, sharer; this.sharers) {
			if(sharer.name == node.name) {
				return true;
			}
		}

		return false;
	}

	bool isSharedOrOwned() {
		return this.sharers.length > 0 || this.owner !is null;
	}

	override string toString() {
		string str;

		str ~= format("DirEntry[owner=%s, sharers.length=%d]", this.owner !is null ? this.owner.name : "NULL", this.sharers.length);

		return str;
	}

	ICacheT owner() {
		return this.m_owner;
	}

	void owner(ICacheT value) {
		this.monitor.invoke(this.x, this.y, CacheMonitoringEventType.DIR_ENTRY_SET_OWNER, value !is null ? value.name : "NULL");

		this.m_owner = value;
	}

	ICacheT m_owner;
	ICacheT[] sharers;

	uint x;
	uint y;
	
	CacheMonitor monitor;
}
class DirLock {
	this(uint x) {
		this.x = x;
		
		this.monitor = new CacheMonitor();
	}

	bool lock(Addr addr, Invokable callback) {
		this.monitor.invoke(this.x, -1, CacheMonitoringEventType.DIR_LOCK_LOCK, format("0x%x", addr));
			
		if(this.locked) {
			if(callback !is null) {
				this.waiters ~= callback;
			}
			return false;
		} else {			
			this.lockAddr = addr;
			this.locked = true;
			return true;
		}
	}

	void unlock() {
		this.monitor.invoke(this.x, -1, CacheMonitoringEventType.DIR_LOCK_UNLOCK, format("0x%x", this.lockAddr));

		foreach(waiter; this.waiters) {
			if(waiter !is null) {
				waiter.invoke();
			}
		}

		this.waiters.clear();
		this.locked = false;
	}

	override string toString() {
		string str;

		str ~= format("DirLock[locked: %s, waiters.length: %d]", this.locked, this.waiters.length);

		return str;
	}

	bool locked;

	Invokable[] waiters;

	uint x;
	
	Addr lockAddr;
	
	CacheMonitor monitor;
}

class Dir(StateT) {
	alias CacheBlock!(StateT) CacheBlockT;
	alias CacheSet!(StateT) CacheSetT;
	alias DirEntry!(StateT) DirEntryT;

	this(uint xSize, uint ySize) {
		this.xSize = xSize;
		this.ySize = ySize;
		
		this.monitor = new CacheMonitor();

		this.dirEntries = new DirEntryT[][this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirEntries[i] = new DirEntryT[this.ySize];

			for(uint j = 0; j < this.ySize; j++) {
				this.dirEntries[i][j] = new DirEntryT(i, j);
				this.dirEntries[i][j].monitor.callbacks ~= new CacheMonitoringCallback(&this.monitor.invoke);
			}
		}

		this.dirLocks = new DirLock[this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirLocks[i] = new DirLock(i);
			this.dirLocks[i].monitor.callbacks ~= new CacheMonitoringCallback(&this.monitor.invoke);
		}
	}

	bool isSharedOrOwned(uint x, uint y) {
		return this.dirEntries[x][y].isSharedOrOwned;
	}

	uint xSize;
	uint ySize;

	DirEntryT[][] dirEntries;
	DirLock[] dirLocks;

	CacheMonitor monitor;
}

class CacheBlock(StateT) {
	alias CacheSet!(StateT) CacheSetT;
	alias DirEntry!(StateT) DirEntryT;

	this(CacheSetT set, StateT initialState) {
		this.set = set;
		this.state = this.initialState = initialState;
		this.tag = 0;
		this.lastAccess = 0;
	}

	override string toString() {
		return format("CacheBlock[set: %s, tag: %d, state: %s]", to!(string)(this.set), this.tag, to!(string)(this.state));
	}

	CacheSetT set;
	uint tag;
	uint transientTag;
	StateT state;
	StateT initialState;

	ulong lastAccess;
}

abstract class StatsBase(ValueT) {	
	this() {
		this.init();
	}

	protected abstract void init();

	protected abstract void init(string index);

	ref ValueT opIndex(string index) {
		assert(index in this.entries, index);
		return this.entries[index];
	}

	void opIndexAssign(ValueT value, string index) {
		assert(index in this.entries, index);
		this.entries[index] = value;
	}

	ValueT[string] entries;
}

class MESICacheStats: StatsBase!(ulong) {
	protected override void init() {
		this.init("accesses");
		this.init("hits");
		this.init("evictions");
		this.init("reads");
		this.init("blockingReads");
		this.init("nonblockingReads");
		this.init("readHits");
		this.init("writes");
		this.init("blockingWrites");
		this.init("nonblockingWrites");
		this.init("writeHits");

		this.init("readRetries");
		this.init("writeRetries");

		this.init("noRetryAccesses");
		this.init("noRetryHits");
		this.init("noRetryReads");
		this.init("noRetryReadHits");
		this.init("noRetryWrites");
		this.init("noRetryWriteHits");
	}

	protected override void init(string index) {
		this.entries[index] = 0;
	}
}

alias MESICacheStats Stats;

interface ICache(StateT) {
	alias CacheBlock!(StateT) CacheBlockT;
	alias CacheSet!(StateT) CacheSetT;
	alias Cache!(StateT) CacheT;

	alias DirEntry!(StateT) DirEntryT;
	alias Dir!(StateT) DirT;

	alias CacheHierarchy!(typeof(this), StateT) CacheHierarchyT;

	string name();

	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref StateT state);

	void getBlock(uint set, uint way, ref uint tag, ref StateT state);

	uint blockSize();

	DirT getDir();

	DirEntryT getDirEntry(uint set, uint way);

	DirLock getDirLock(uint set);

	bool isMem();

	uint hitLatency();

	uint missLatency();

	typeof(this) next();

	CacheHierarchyT cacheHierarchy();

	void dumpConfigs(string indent);

	void dumpStats(string indent);

	Stats stats();

	CacheT getCache();
}

class CacheSet(StateT) {
	alias CacheBlock!(StateT) CacheBlockT;
	alias Cache!(StateT) CacheT;

	this(CacheT cache, uint assoc, StateT initialState) {
		this.cache = cache;
		this.assoc = assoc;

		this.blks = new CacheBlockT[this.assoc];
		for(uint i = 0; i < this.assoc; i++) {
			this.blks[i] = new CacheBlockT(this, initialState);
		}
	}

	uint length() {
		return this.blks.length;
	}

	CacheBlockT opIndex(uint i) {
		return this.blks[i];
	}

	void opIndexAssign(CacheBlockT value, uint i) {
		this.blks[i] = value;
	}

	int opApply(int delegate(ref uint, ref CacheBlockT) dg) {
		int result;

		foreach(ref uint i, ref CacheBlockT p; this.blks) {
			result = dg(i, p);
			if(result)
				break;
		}
		return result;
	}

	int opApply(int delegate(ref CacheBlockT) dg) {
		int result;

		foreach(ref CacheBlockT p; this.blks) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}

	string toString() {
		return format("CacheSet[assoc: %d]", this.assoc);
	}

	uint assoc;
	CacheBlockT[] blks;

	CacheT cache;
}

class Cache(StateT) {
	alias CacheBlock!(StateT) CacheBlockT;
	alias CacheSet!(StateT) CacheSetT;
	alias Dir!(StateT) DirT;

	this(uint blockSize, uint assoc, uint numSets, StateT initialState) {
		this.blockSize = blockSize;
		this.assoc = assoc;
		this.numSets = numSets;

		this.initialState = initialState;

		this.sets = new CacheSetT[this.numSets];
		for(uint i = 0; i < this.numSets; i++) {
			this[i] = new CacheSetT(this, this.assoc, initialState);
		}

		this.dir = new DirT(this.numSets, this.assoc);
	}

	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref StateT state) {
		tag = this.tag(addr);
		set = this.set(addr);

		uint wayFound = this.assoc;

		foreach(way, blk; this[set]) {
			if(blk.tag == tag && blk.state != this.initialState) {
				wayFound = way;
				break;
			}
		}

		if(wayFound == this.assoc) {
			return false;
		} else {
			way = wayFound;
			state = this[set][wayFound].state;

			return true;
		}
	}

	void setBlock(uint set, uint way, uint tag, StateT state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		this.accessBlock(set, way);
		this[set][way].tag = tag;
		this[set][way].state = state;
	}

	void getBlock(uint set, uint way, ref uint tag, ref StateT state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		tag = this[set][way].tag;
		state = this[set][way].state;
	}

	void accessBlock(uint set, uint way) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		CacheBlockT blk = this[set][way];
		blk.lastAccess = Simulator.singleInstance.currentCycle;
	}

	uint replaceBlock(uint set) {
		assert(set >= 0 && set < this.numSets);

		ulong smallestTime = this[set][0].lastAccess;
		uint smallestIndex = 0;

		foreach(way, blk; this[set]) {
			ulong time = blk.lastAccess;
			if(time < smallestTime) {
				smallestIndex = way;
				smallestTime = time;
			}
		}

		return smallestIndex;
	}

	CacheSetT opIndex(uint index) {
		return this.sets[index];
	}

	void opIndexAssign(CacheSetT value, uint index) {
		this.sets[index] = value;
	}

	uint logBlockSize() {
		return cast(uint) std.math.log2(this.blockSize);
	}

	uint blockMask() {
		return this.blockSize - 1;
	}

	uint set(Addr addr) {
		return (addr >> this.logBlockSize) % this.numSets;
	}

	uint tag(Addr addr) {
		return addr & ~this.blockMask;
	}

	uint offset(Addr addr) {
		return addr & this.blockMask;
	}

	int assoc;
	int numSets;
	Addr blockSize;

	StateT initialState;

	CacheSetT[] sets;

	DirT dir;
}

class CacheQueueEntry(StateT: CacheBlockState) {
	alias CacheBlock!(StateT) CacheBlockT;

	this(Interconnect src, Interconnect dest, Node sender, Request request) {
		this.src = src;
		this.dest = dest;
		this.sender = sender;
		this.request = request;
	}

	override string toString() {
		return format("CacheQueueEntry[src: %s, dest: %s, sender: %s, request: %s]", this.src, this.dest, this.sender, this.request);
	}

	Interconnect src;
	Interconnect dest;
	Node sender;
	Request request;
}

class CacheBlockState {
	this(string name) {
		this.name = name;
	}

	string name;
}