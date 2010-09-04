/*
 * flexim/mem/timing/cache.d
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

module flexim.mem.timing.cache;

import flexim.all;

class DirEntry {
	this(uint x, uint y) {
		this.x = x;
		this.y = y;
	}

	void setSharer(CoherentCacheNode node) {
		assert(node !is null);		
        if(!canFind(this.sharers, node)) {			
			this.sharers ~= node;
        }
	}

	void unsetSharer(CoherentCacheNode node) {
		assert(node !is null);
		if(canFind(this.sharers, node)) {	
			uint indexFound;	
			foreach(i, sharer; this.sharers) {
				if(sharer == node) {
					indexFound = i;
					break;
				}
			}
			this.sharers = this.sharers.remove(indexFound);
		}
	}

	bool isSharer(CoherentCacheNode node) {
		return canFind(this.sharers, node);
	}
	
	bool isShared() {
		return this.sharers.length > 1;
	}
	
	bool isOwned() {
		return this.owner !is null;
	}

	bool isSharedOrOwned() {
		return this.isShared || this.isOwned;
	}

	override string toString() {
		string str;

		str ~= format("DirEntry[owner=%s, sharers.length=%d]", this.owner !is null ? this.owner.name : "NULL", this.sharers.length);

		return str;
	}

	CoherentCacheNode owner;
	CoherentCacheNode[] sharers;

	uint x;
	uint y;
}

class DirLock {
	this(uint x) {
		this.x = x;
	}

	bool lock() {
		if(this.locked) {
			return false;
		} else {			
			this.locked = true;
			return true;
		}
	}

	void unlock() {
		this.locked = false;
	}

	override string toString() {
		string str;

		str ~= format("DirLock[locked=%s]", this.locked);

		return str;
	}

	uint x;

	bool locked;
}

class Dir {
	this(uint xSize, uint ySize) {
		this.xSize = xSize;
		this.ySize = ySize;

		this.dirEntries = new DirEntry[][this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirEntries[i] = new DirEntry[this.ySize];

			for(uint j = 0; j < this.ySize; j++) {
				this.dirEntries[i][j] = new DirEntry(i, j);
			}
		}

		this.dirLocks = new DirLock[this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirLocks[i] = new DirLock(i);
		}
	}

	bool isSharedOrOwned(uint x, uint y) {
		return this.dirEntries[x][y].isSharedOrOwned;
	}

	uint xSize;
	uint ySize;

	DirEntry[][] dirEntries;
	DirLock[] dirLocks;
}

enum MESIState: string {
	MODIFIED = "MODIFIED",
	EXCLUSIVE = "EXCLUSIVE",
	SHARED = "SHARED",
	INVALID = "INVALID"
}

bool isReadHit(MESIState state) {
	return state != MESIState.INVALID;
}

bool isWriteHit(MESIState state) {
	return state == MESIState.MODIFIED || state == MESIState.EXCLUSIVE;
}

enum CacheReplacementPolicy: string {
	LRU = "LRU",
	FIFO = "FIFO",
	Random = "Random"
}

class CacheBlock {
	this(CacheSet set, uint way) {
		this.set = set;
		this.way = way;
		
		this.state = MESIState.INVALID;
		this.tag = 0;
		this.transientTag = 0;
		this.lastAccess = 0;
	}

	override string toString() {
		return format("CacheBlock[set=%s, way=%d, tag=%d, state=%s]", to!(string)(this.set), this.way, this.tag, to!(string)(this.state));
	}

	CacheSet set;
	uint way;
	
	uint tag, transientTag;
	MESIState state;

	ulong lastAccess;
}

class CacheSet {
	this(Cache cache, uint assoc, uint num) {
		this.cache = cache;
		this.assoc = assoc;
		this.num = num;

		this.blks = new CacheBlock[this.assoc];
		for(uint i = 0; i < this.assoc; i++) {
			this.blks[i] = new CacheBlock(this, i);
		}
	}

	uint length() {
		return this.blks.length;
	}

	CacheBlock opIndex(uint i) {
		return this.blks[i];
	}

	int opApply(int delegate(ref uint, ref CacheBlock) dg) {
		int result;

		foreach(ref uint i, ref CacheBlock p; this.blks) {
			result = dg(i, p);
			if(result)
				break;
		}
		return result;
	}

	int opApply(int delegate(ref CacheBlock) dg) {
		int result;

		foreach(ref CacheBlock p; this.blks) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}

	override string toString() {
		return format("CacheSet[assoc=%d]", this.assoc);
	}

	uint assoc;
	CacheBlock[] blks;

	Cache cache;
	
	uint num;
}

class Cache {
	this(CacheConfig cacheConfig) {
		this.cacheConfig = cacheConfig;

		this.sets = new CacheSet[this.numSets];
		for(uint i = 0; i < this.numSets; i++) {
			this[i] = new CacheSet(this, this.assoc, i);
		}

		this.dir = new Dir(this.numSets, this.assoc);
	}
	
	CacheBlock blockOf(uint addr) {
		uint tag = this.tag(addr);
		uint set = this.set(addr);

		foreach(way, blk; this[set]) {
			if(blk.tag == tag && blk.state != MESIState.INVALID) {
				return blk;
			}
		}

		return null;
	}
	
	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref MESIState state) {
		set = this.set(addr);
		tag = this.tag(addr);
				
		CacheBlock blkFound = blockOf(addr);
		
		if(blkFound !is null) {
			way = blkFound.way;
			state = blkFound.state;
			
			return true;
		}
		else {
			way = 0;
			state = MESIState.INVALID;
			
			return false;
		}
	}

	void setBlock(uint set, uint way, uint tag, MESIState state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		this.accessBlock(set, way);
		this[set][way].tag = tag;
		this[set][way].state = state;
	}

	void getBlock(uint set, uint way, ref uint tag, ref MESIState state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		tag = this[set][way].tag;
		state = this[set][way].state;
	}

	void accessBlock(uint set, uint way) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		this[set][way].lastAccess = Simulator.singleInstance.currentCycle;
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

	CacheSet opIndex(uint index) {
		return this.sets[index];
	}

	void opIndexAssign(CacheSet value, uint index) {
		this.sets[index] = value;
	}

	uint logBlockSize() {
		return cast(uint) std.math.log2(this.blockSize);
	}

	uint blockMask() {
		return this.blockSize - 1;
	}

	uint set(uint addr) {
		return (addr >> this.logBlockSize) % this.numSets;
	}

	uint tag(uint addr) {
		return addr & ~this.blockMask;
	}

	uint offset(uint addr) {
		return addr & this.blockMask;
	}
	
	uint assoc() {
		return this.cacheConfig.assoc;
	}
	
	uint numSets() {
		return this.cacheConfig.numSets;
	}
	
	uint blockSize() {
		return this.cacheConfig.blockSize;
	}

	CacheSet[] sets;

	Dir dir;
	
	CacheConfig cacheConfig;
}