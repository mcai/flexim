/*
 * flexim/mem.d
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

module flexim.mem;

import flexim.all;

import std.c.string;

const uint MEM_LOGPAGESIZE = 12;
const uint MEM_PAGESHIFT = MEM_LOGPAGESIZE;
const uint MEM_PAGESIZE = 1 << MEM_LOGPAGESIZE;
const uint MEM_PAGEMASK = MEM_PAGESIZE - 1;
const uint MEM_PAGE_COUNT = 1024;

const uint MEM_BLOCK_SIZE = 64;

const uint MEM_PROT_READ = 0x01;
const uint MEM_PROT_WRITE = 0x02;

enum MemoryAccessType: uint {
	NONE = 0x00,
	READ = 0x01,
	WRITE = 0x02,
	EXEC = 0x04,
	INIT = 0x08
}

class MemoryPage {
	public:
		this() {
			this.tag = 0;
			this.perm = MemoryAccessType.NONE;
			this.next = null;
		}

		~this() {
		}

		uint tag;
		MemoryAccessType perm;
		ubyte data[MEM_PAGESIZE];

		MemoryPage next;
};

class SegmentationFaultException: Exception {
	public:
		this(uint addr) {
			super(format("SegmentationFaultException @ 0x%x", addr));
			this.addr = addr;
		}

		uint addr() {
			return this.m_addr;
		}

		void addr(uint value) {
			this.m_addr = value;
		}

	private:
		uint m_addr;
}

class Memory {
	public:
		this() {
			this.safe = true;
			//			this.safe = false;
		}

		~this() {
			this.pages.clear();
			this.pages = null;
		}

		void initByte(uint addr, ubyte data) {
			this.access(addr, 1, &data, MemoryAccessType.INIT);
		}

		void initHalfWord(uint addr, ushort data) {
			this.access(addr, 2, cast(ubyte*) &data, MemoryAccessType.INIT);
		}

		void initWord(uint addr, uint data) {
			this.access(addr, 4, cast(ubyte*) &data, MemoryAccessType.INIT);
		}

		void initDoubleWord(uint addr, ulong data) {
			this.access(addr, 8, cast(ubyte*) &data, MemoryAccessType.INIT);
		}

		void initString(uint addr, char* str) {
			this.access(addr, strlen(str) + 1, cast(ubyte*) str, MemoryAccessType.INIT);
		}

		void initBlock(uint addr, uint size, ubyte* p) {
			for(uint i = 0; i < size; i++) {
				this.initByte(addr + i, *(p + i));
			}
		}

		void writeByte(uint addr, ubyte data) {
			this.access(addr, 1, &data, MemoryAccessType.WRITE);
		}

		void writeHalfWord(uint addr, ushort data) {
			this.access(addr, 2, cast(ubyte*) &data, MemoryAccessType.WRITE);
		}

		void writeWord(uint addr, uint data) {
			this.access(addr, 4, cast(ubyte*) &data, MemoryAccessType.WRITE);
		}

		void writeDoubleWord(uint addr, ulong data) {
			this.access(addr, 8, cast(ubyte*) &data, MemoryAccessType.WRITE);
		}

		void writeString(uint addr, char* str) {
			this.access(addr, strlen(str) + 1, cast(ubyte*) str, MemoryAccessType.WRITE);
		}

		void writeBlock(uint addr, uint size, ubyte* data) {
			this.access(addr, size, data, MemoryAccessType.WRITE);
		}

		void readByte(uint addr, ubyte* data) {
			this.access(addr, 1, data, MemoryAccessType.READ);
		}

		void readHalfWord(uint addr, ushort* data) {
			this.access(addr, 2, cast(ubyte*) data, MemoryAccessType.READ);
		}

		void readWord(uint addr, uint* data) {
			this.access(addr, 4, cast(ubyte*) data, MemoryAccessType.READ);
		}

		void readDoubleWord(uint addr, ulong* data) {
			this.access(addr, 8, cast(ubyte*) data, MemoryAccessType.READ);
		}

		/* Read a string from memory and return the length of the read string.
		 * If the return length is equal to max_size, it means that the string did not
		 * fit in the destination buffer. */
		int readString(uint addr, int size, char* str) {
			int i;
			for(i = 0; i < size; i++) {
				this.access(addr + i, 1, str + i, MemoryAccessType.READ);
				if(!str[i])
					break;
			}
			return i;
		}

		void readBlock(uint addr, uint size, ubyte* p) {
			this.access(addr, size, p, MemoryAccessType.READ);
		}

		void zero(uint addr, int size) {
			ubyte zero = 0;
			while(size--) {
				this.access(addr++, 0, &zero, MemoryAccessType.WRITE);
			}
		}

		uint getTag(uint addr) {
			return addr & ~(MEM_PAGESIZE - 1);
		}

		uint getOffset(uint addr) {
			return addr & (MEM_PAGESIZE - 1);
		}

		uint getIndex(uint addr) {
			return (addr >> MEM_LOGPAGESIZE) % MEM_PAGE_COUNT;
		}

		bool isAligned(uint addr) {
			return this.getOffset(addr) == 0;
		}

		/* Return mem page corresponding to an address. */
		MemoryPage getPage(uint addr) {
			uint index, tag;
			MemoryPage prev, page;

			tag = getTag(addr);
			index = getIndex(addr);
			page = this[index];
			prev = null;

			/* Look for page */
			while(page !is null && page.tag != tag) {
				prev = page;
				page = page.next;
			}

			/* Place page into list head */
			if(prev !is null && page !is null) {
				prev.next = page.next;
				page.next = this[index];
				this[index] = page;
			}

			/* Return found page */
			return page;
		}

		/* Create new mem page */
		MemoryPage addPage(uint addr, MemoryAccessType perm) {
			uint index, tag;
			MemoryPage page;

			tag = getTag(addr);
			index = getIndex(addr);

			/* Create new page */
			page = new MemoryPage();
			page.tag = tag;
			page.perm = perm;

			/* Insert in pages hash table */
			page.next = this[index];
			this[index] = page;
			this.mapped_space += MEM_PAGESIZE;
			this.max_mapped_space = max(this.max_mapped_space, this.mapped_space);

			return page;
		}

		/* Free mem pages */
		void removePage(uint addr) {
			uint index, tag;
			MemoryPage prev, page;

			tag = this.getTag(addr);
			index = this.getIndex(addr);
			prev = null;

			/* Find page */
			page = this[index];
			while(page !is null && page.tag != tag) {
				prev = page;
				page = page.next;
			}

			if(page is null) {
				return;
			}

			/* Free page */
			if(prev !is null) {
				prev.next = page.next;
			} else {
				this[index] = page.next;
			}

			this.mapped_space -= MEM_PAGESIZE;

			page = null;
		}

		/* Copy memory pages. All parameters must be multiple of the page size.
		 * The pages in the source and destination interval must exist. */
		void copy(uint dest, uint src, int size) {
			MemoryPage page_dest, page_src;

			/* Restrictions. No overlapping allowed. */
			assert(isAligned(dest));
			assert(isAligned(src));
			assert(isAligned(size));
			if((src < dest && src + size > dest) || (dest < src && dest + size > src))
				logging.fatal(LogCategory.MEMORY, "mem_copy: cannot copy overlapping regions");

			/* Copy */
			while(size > 0) {
				page_dest = this.getPage(dest);
				page_src = this.getPage(src);
				assert(page_src !is null && page_dest !is null);
				memcpy(&page_dest.data, &page_src.data, MEM_PAGESIZE);
				src += MEM_PAGESIZE;
				dest += MEM_PAGESIZE;
				size -= MEM_PAGESIZE;
			}
		}

		/* Return the buffer corresponding to address 'addr' in the simulated
		 * mem. The returned buffer is null if addr+size exceeds the page
		 * boundaries. */
		ubyte* getBuffer(uint addr, int size, MemoryAccessType access) {
			MemoryPage page;
			uint offset;

			offset = this.getOffset(addr);
			if(offset + size > MEM_PAGESIZE)
				return null;

			page = this.getPage(addr);
			if(page is null)
				return null;

			if((page.perm & access) != access && this.safe) {
				logging.fatalf(LogCategory.MEMORY, "Memory.getBuffer: permission denied at 0x%x", addr);
			}

			return &page.data[offset];
		}

		/* Access mem without exceeding page boundaries. */
		void accessPageBoundary(uint addr, int size, void* buf, MemoryAccessType access) {
			MemoryPage page;
			uint offset;
			ubyte* data;

			/* Find memory page */
			page = this.getPage(addr);

			/* If page does not exist and we are in unsafe mode, create it on write
			 * and return 0s on read. */
			if(page is null && !this.safe) {
				switch(access) {
					/* Return 0s and exit. */
					case MemoryAccessType.READ:
					case MemoryAccessType.EXEC:
						logging.warnf(LogCategory.MEMORY, "Memory.accessPageBoundary: unsafe reading 0x%x", addr);
						memset(buf, 0, size);
						return;

						/* Create page */
					case MemoryAccessType.WRITE:
					case MemoryAccessType.INIT:
						logging.warnf(LogCategory.MEMORY, "Memory.accessPageBoundary: unsafe writing 0x%x", addr);
						page = addPage(addr, MemoryAccessType.READ | MemoryAccessType.WRITE | MemoryAccessType.EXEC | MemoryAccessType.INIT);
					break;
					default:
						logging.panic(LogCategory.MEMORY, "Memory.accessPageBoundary: unknown access");
				}
			}

			/* If we are in safe mode, check permissions. */
			if(this.safe) {
				if(page is null) {
					throw new SegmentationFaultException(addr);
				}
				if((page.perm & access) != access) {
					logging.fatalf(LogCategory.MEMORY, "Memory.accessPageBoundary: permission denied at 0x%x, page.perm: 0x%x, access: 0x%x", addr, page.perm, access);
				}
			}

			/* Access */
			offset = this.getOffset(addr);
			assert(offset + size <= MEM_PAGESIZE);
			data = &page.data[offset];
			switch(access) {
				case MemoryAccessType.READ:
				case MemoryAccessType.EXEC:
					memcpy(buf, data, size);
				break;
				case MemoryAccessType.WRITE:
				case MemoryAccessType.INIT:
					memcpy(data, buf, size);
				break;
				default:
					logging.panic(LogCategory.MEMORY, "Memory.accessPageBoundary: unknown access");
			}
		}

		/* Access mem at address 'addr'. This access can cross page boundaries. */
		void access(uint addr, int size, void* buf, MemoryAccessType access) {
			uint offset;
			int chunksize;

			this.last_address = addr;
			while(size > 0) {
				offset = this.getOffset(addr);
				chunksize = min!(int)(size, MEM_PAGESIZE - offset);
				this.accessPageBoundary(addr, chunksize, buf, access);

				size -= chunksize;
				buf += chunksize;
				addr += chunksize;
			}
		}

		/* This function finds a free memory region to allocate 'size' bytes
		 * starting at address 'addr'. */
		uint mapSpace(uint addr, int size) {
			uint tag_start, tag_end;

			assert(isAligned(addr));
			assert(isAligned(size));
			tag_start = addr;
			tag_end = addr;
			for(; ; ) {
				/* Address space overflow */
				if(tag_end == 0) {
					return cast(uint) -1;
				}

				/* Not enough free pages in current region */
				if(this.getPage(tag_end) !is null) {
					tag_end += MEM_PAGESIZE;
					tag_start = tag_end;
					continue;
				}

				/* Enough free pages */
				if(tag_end - tag_start + MEM_PAGESIZE == size)
					break;
				assert(tag_end - tag_start + MEM_PAGESIZE < size);

				/* we have a new free page */
				tag_end += MEM_PAGESIZE;
			}

			/* Return the start of the free space */
			return tag_start;
		}

		uint mapSpaceDown(uint addr, int size) {
			uint tag_start, tag_end;

			assert(isAligned(addr));
			assert(isAligned(size));
			tag_start = addr;
			tag_end = addr;
			for(; ; ) {
				/* Address space overflow */
				if(tag_start == 0) {
					return cast(uint) -1;
				}

				/* Not enough free pages in current region */
				if(this.getPage(tag_start) !is null) {
					tag_start += MEM_PAGESIZE;
					tag_end = tag_start;
					continue;
				}

				/* Enough free pages */
				if(tag_end - tag_start + MEM_PAGESIZE == size)
					break;
				assert(tag_end - tag_start + MEM_PAGESIZE < size);

				/* we have a new free page */
				tag_end -= MEM_PAGESIZE;
			}

			/* Return the start of the free space */
			return tag_start;
		}

		/* Allocate (if not already allocated) all necessary memory pages to
		 * access 'size' bytes at 'addr'. These two fields do not need to be
		 * aligned to page boundaries. If some page already exists, add permissions. */
		void map(uint addr, int size, MemoryAccessType perm) {
			//logging.infof(LogCategory.MEMORY, "Memory.map(), addr: 0x%08x ~ 0x%08x, size: %d, perm: 0x%x", addr, addr + size, size, perm);
			uint tag1, tag2, tag;
			MemoryPage page;

			/* Calculate page boundaries */
			tag1 = this.getTag(addr);
			tag2 = this.getTag(addr + size - 1);

			/* Allocate pages */
			for(tag = tag1; tag <= tag2; tag += MEM_PAGESIZE) {
				page = this.getPage(tag);
				if(page is null) {
					page = this.addPage(tag, perm);
					page.perm |= perm;
				}
			}
		}

		/* Deallocate memory pages. The addr and size parameters must be both
		 * multiple of the page size. If some page was not allocated, no action
		 * is done for that specific page. */
		void unmap(uint addr, int size) {
			uint tag1, tag2, tag;

			/* Calculate page boundaries */
			assert(isAligned(addr));
			assert(isAligned(size));
			tag1 = getTag(addr);
			tag2 = getTag(addr + size - 1);

			/* Allocate pages */
			for(tag = tag1; tag <= tag2; tag += MEM_PAGESIZE) {
				if(this.getPage(tag) !is null) {
					this.removePage(tag);
				}
			}
		}

		/* Assign protection attributes to pages */
		void protect(uint addr, int size, MemoryAccessType perm) {
			uint tag1, tag2, tag;
			MemoryPage page;

			/* Calculate page boundaries */
			assert(isAligned(addr));
			assert(isAligned(size));
			tag1 = getTag(addr);
			tag2 = getTag(addr + size - 1);

			/* Allocate pages */
			for(tag = tag1; tag <= tag2; tag += MEM_PAGESIZE) {
				page = this.getPage(tag);
				if(page !is null) {
					page.perm = perm;
				}
			}
		}

		uint last_address; /* Address of last access */

	private:
		MemoryPage opIndex(uint index) {
			if(index in this.pages) {
				return this.pages[index];
			}

			return null;
		}

		void opIndexAssign(MemoryPage page, uint index) {
			this.pages[index] = page;
		}

		MemoryPage[uint] pages;

		ulong mapped_space = 0;
		ulong max_mapped_space = 0;

		bool safe = true; /* Safe mode */
};

class CAM(T, K, V) {
	this() {

	}

	K tag;
	V content;
	T next;
}

class MMUPage: CAM!(MMUPage, uint, uint) {
	alias tag vtladdr;
	alias content phaddr;
	
	Dir dir;
}

class MMU {	
	alias MMUPage MMUPageT;
	
	this() {
	}

	uint page(uint vtladdr) {
		return vtladdr >> MEM_LOGPAGESIZE;
	}

	uint tag(uint vtladdr) {
		return vtladdr & ~MEM_PAGEMASK;
	}

	uint offset(uint vtladdr) {
		return vtladdr & MEM_PAGEMASK;
	}

	MMUPageT opIndex(uint index) {
		if(index in this.pages) {
			return this.pages[index];
		}
		
		return null;
	}

	void opIndexAssign(MMUPageT value, uint index) {
		this.pages[index] = value;
	}

	MMUPageT getPage(uint vtladdr) {
		int idx = this.page(vtladdr);
		uint tag = this.tag(vtladdr);

		MMUPageT page = this[idx];

		while(page) {
			if(page.vtladdr == tag) {
				break;
			}
			page = page.next;
		}

		if(!page) {
			page = new MMUPageT();
			page.dir =
				new Dir(MEM_PAGESIZE / MEM_BLOCK_SIZE, 1);
			
			page.vtladdr = tag;
			page.phaddr = this.pageCount << MEM_LOGPAGESIZE;

			page.next = this[idx];
			this[idx] = page;
			
			this.pageCount++;
		}

		return page;
	}

	uint translate(uint vtladdr) {
		MMUPageT page = this.getPage(vtladdr);
		return page.phaddr | this.offset(vtladdr);
	}
	
	Dir getDir(uint phaddr) {
		int idx = this.page(phaddr);
		if(idx >= this.pageCount) {
			return null;
		}
		
		return this[idx].dir;
	}

	bool validPhysicalAddress(uint phaddr) {
		return this.page(phaddr) < this.pageCount;
	}

	MMUPageT[uint] pages;
	uint pageCount;
}

class DirEntry {
	this(uint x, uint y) {
		this.x = x;
		this.y = y;
	}

	void setSharer(CoherentCacheNode node) {
		assert(node !is null);
		if(!this.sharers.canFind(node)) {			
			this.sharers ~= node;
        }
	}

	void unsetSharer(CoherentCacheNode node) {
		assert(node !is null);
		if(canFind(this.sharers, node)) {
			this.sharers = this.sharers.remove(this.sharers.indexOf(node));
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
		
		this.tag = 0;
		this.transientTag = 0;
		this.state = MESIState.INVALID;
		
		this.lastAccess = 0;
	}

	override string toString() {
		return format("CacheBlock[set=%s, way=%d, tag=%d, transientTag=%d, state=%s]",
			to!(string)(this.set), this.way, this.tag, this.transientTag, to!(string)(this.state));
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
	
	CacheBlock firstOf(T)(T pred) {
		auto res = filter!(pred)(this.blks);
		return !res.empty ? res.front : null;
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
	
	CacheBlock blockOf(uint addr, bool checkTransientTag = false) {
		uint tag = this.tag(addr);
		uint set = this.set(addr);

		foreach(way, blk; this[set]) {
			if((blk.tag == tag && blk.state != MESIState.INVALID) ||
				(checkTransientTag && blk.transientTag == tag && this.dir.dirLocks[set].locked))  {
				return blk;
			}
		}

		return null;
	}
	
	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref MESIState state, bool checkTransientTag = false) {
		set = this.set(addr);
		tag = this.tag(addr);
				
		CacheBlock blkFound = this.blockOf(addr, checkTransientTag);
		
		way = blkFound !is null ? blkFound.way : 0;
		state = blkFound !is null ? blkFound.state : MESIState.INVALID;
		return blkFound !is null;
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
		this[set][way].lastAccess = currentCycle;
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

abstract class CoherentCacheNode {	
	this(MemorySystem memorySystem, string name) {
		this.name = name;
		this.memorySystem = memorySystem;
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
	}
	
	void schedule(void delegate() event, ulong delay = 0) {
		this.eventQueue.schedule(event, delay);
	}
	
	void findAndLock(uint addr, bool isBlocking, bool isRead, bool isRetry, 
		void delegate(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock) onCompletedCallback) {
		writefln("%s.findAndLock(addr=0x%x, isBlocking=%s, isRead=%s, isRetry=%s)", this, addr, isBlocking, isRead, isRetry);
		assert(0);
	}
	
	void load(uint addr, bool isRetry, 
		void delegate() onCompletedCallback) {
		writefln("%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		assert(0);
	}
	
	void store(uint addr, bool isRetry, 
		void delegate() onCompletedCallback) {
		writefln("%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		assert(0);
	}
	
	void evict(uint set, uint way, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.evict(set=%d, way=%d)", this, set, way);
		assert(0);
	}
	
	void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback, 
		void delegate(bool hasError) onReceiveReplyCallback) {
		writefln("%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		assert(0);
	}
	
	void readRequest(CoherentCacheNode target, uint addr, 
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequest(target=%s, addr=0x%x)", this, target, addr);
		assert(0);
	}
	
	void readRequestReceive(CoherentCacheNode source, uint addr, 
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		assert(0);
	}
	void writeRequest(CoherentCacheNode target, uint addr, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequest(target=%s, addr=0x%x)", this, target, addr);
		assert(0);
	}
	
	void writeRequestReceive(CoherentCacheNode source, uint addr, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		assert(0);
	}
	
	void invalidate(CoherentCacheNode except, uint set, uint way, 
		void delegate() onCompletedCallback) {
		writefln("%s.invalidate(except=%s, set=%d, way=%d)", this, except, set, way);
		assert(0);
	}
	
	abstract uint level();
	
	override string toString() {
		return format("%s", this.name);
	}

	string name;
	MemorySystem memorySystem;
	CoherentCacheNode next;	
	DelegateEventQueue eventQueue;
}

class MSHRTarget {
	this() {
	}

	uint threadId;
}

class MSHR {
	this(uint numTargetSlots) {
		this.numTargetSlots = numTargetSlots;
		this.targets = new MSHRTarget[this.numTargetSlots];
	}
	
	uint addr;
	bool isValid;	
	MSHRTarget[] targets;
	
	uint numTargetSlots;
}

class MSHRFile {
	this(uint capacity) {
		this.capacity = capacity;
		this.entries = new MSHR[this.capacity];
	}
	
	bool isFull() {
		assert(0);
	}
	
	uint capacity;
	MSHR[] entries;
}

alias MSHRFile WriteBuffer;

class Sequencer: CoherentCacheNode {
	this(string name, CoherentCache l1Cache) {
		super(l1Cache.memorySystem, name);

		this.l1Cache = l1Cache;
	}
	
	void load(uint addr, bool isRetry, ReorderBufferEntry rs, void delegate(ReorderBufferEntry rs) onCompletedCallback2) {		
		this.load(addr, isRetry, {onCompletedCallback2(rs);});
	}
	
	override void load(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.l1Cache.load(addr, isRetry, onCompletedCallback);
	}
	
	override void store(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.l1Cache.store(addr, isRetry, onCompletedCallback);
	}
	
	uint blockSize() {
		return this.l1Cache.cache.blockSize;
	}

	uint blockAddress(uint addr) {
		return this.l1Cache.cache.tag(addr);
	}
	
	override uint level() {
		assert(0);
	}

	override string toString() {
		return format("%s", this.name);
	}

	CoherentCache l1Cache;
}

class CoherentCache: CoherentCacheNode {
	this(MemorySystem memorySystem, CacheConfig config, CacheStat stat) {
		super(memorySystem, config.name);

		this.cache = new Cache(config);
		this.config = config;
		this.stat = stat;
	}
	
	uint retryLat() {
		return this.config.hitLatency + uniform(0, this.config.hitLatency + 2);
	}
	
	void retry(void delegate() action) {
		this.eventQueue.schedule({action();}, retryLat);
	}
	
	uint hitLatency() {
		return this.config.hitLatency;
	}
	
	override uint level() {
		return this.config.level;
	}
	
	override void findAndLock(uint addr, bool isBlocking, bool isRead, bool isRetry, 
		void delegate(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.findAndLock(addr=0x%x, isBlocking=%s, isRead=%s, isRetry=%s)", this, addr, isBlocking, isRead, isRetry);
		uint set, way, tag;
		MESIState state;
		
		bool hit = this.cache.findBlock(addr, set, way, tag, state, true);
		
		this.stat.accesses.value = this.stat.accesses.value + 1;
		if(hit) {
			this.stat.hits.value = this.stat.hits.value + 1;
		}
		if(isRead) {
			this.stat.reads.value = this.stat.reads.value + 1;
			if(isBlocking) {
				this.stat.blockingReads.value = this.stat.blockingReads.value + 1;
			}
			else {
				this.stat.nonblockingReads.value = this.stat.nonblockingReads.value + 1;
			}
			if(hit) {
				this.stat.readHits.value = this.stat.readHits.value + 1;
			}
		}
		else {
			this.stat.writes.value = this.stat.writes.value + 1;
			if(isBlocking) {
				this.stat.blockingWrites.value = this.stat.blockingWrites.value + 1;
			}
			else {
				this.stat.nonblockingWrites.value = this.stat.nonblockingWrites.value + 1;
			}
			if(hit) {
				this.stat.writeHits.value = this.stat.writeHits.value + 1;
			}
		}
		if(!isRetry) {
			this.stat.noRetryAccesses.value = this.stat.noRetryAccesses.value + 1;
			if(hit) {
				this.stat.noRetryHits.value = this.stat.noRetryHits.value + 1;
			}
			if(isRead) {
				this.stat.noRetryReads.value = this.stat.noRetryReads.value + 1;
				if(hit) {
					this.stat.noRetryReadHits.value = this.stat.noRetryReadHits.value + 1;
				}
			}
			else {
				this.stat.noRetryWrites.value = this.stat.noRetryWrites.value + 1;
				if(hit) {
					this.stat.noRetryWriteHits.value = this.stat.noRetryWriteHits.value + 1;
				}
			}
		}
		
		uint dumbTag;
		
		if(!hit) {
			way = this.cache.replaceBlock(set);
			this.cache.getBlock(set, way, dumbTag, state);
		}
		
		DirLock dirLock = this.cache.dir.dirLocks[set];
		if(!dirLock.lock()) {
			if(isBlocking) {
				onCompletedCallback(true, set, way, state, tag, dirLock);
			}
			else {
				this.retry({this.findAndLock(addr, isBlocking, isRead, true, onCompletedCallback);});
			}
		}
		else {
			this.cache[set][way].transientTag = tag;
			
			if(!hit && state != MESIState.INVALID) {
				this.schedule(
					{
						this.evict(set, way, 
							(bool hasError)
							{
								uint dumbTag;
								
								if(!hasError) {
									this.stat.evictions.value = this.stat.evictions.value + 1;
									this.cache.getBlock(set, way, dumbTag, state);
									onCompletedCallback(false, set, way, state, tag, dirLock);
								}
								else {
									this.cache.getBlock(set, way, dumbTag, state);
									dirLock.unlock();
									onCompletedCallback(true, set, way, state, tag, dirLock);
								}
							});
					}, this.hitLatency);
				
			}
			else {			
				this.schedule(
					{
						onCompletedCallback(false, set, way, state, tag, dirLock);
					},
				this.hitLatency);
			}
		}
	}
	
	override void load(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, true, isRetry,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isReadHit(state)) {
						this.readRequest(this.next, tag,
						(bool hasError, bool isShared) 
						{
							if(!hasError) {
								this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
								this.cache.accessBlock(set, way);
								dirLock.unlock();								
								onCompletedCallback();
							}
							else {
								this.stat.readRetries.value = this.stat.readRetries.value + 1;
								dirLock.unlock();
								this.retry({this.load(addr, true, onCompletedCallback);});
							}
						});
					}
					else {
						this.cache.accessBlock(set, way);	
						dirLock.unlock();					
						onCompletedCallback();
					}
				}
				else {
					this.stat.readRetries.value = this.stat.readRetries.value + 1;
					this.retry({this.load(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void store(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, false, isRetry, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isWriteHit(state)) {
						this.writeRequest(this.next, tag,
							(bool hasError)
							{
								if(!hasError) {
									this.cache.accessBlock(set, way);
									this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
									dirLock.unlock();
									onCompletedCallback();
								}
								else {
									this.stat.writeRetries.value = this.stat.writeRetries.value + 1;
									dirLock.unlock();
									this.retry({this.store(addr, true, onCompletedCallback);});
								}
							});
					}
					else {
						this.cache.accessBlock(set, way);
						this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
						dirLock.unlock();
						onCompletedCallback();
					}
				}
				else {
					this.stat.writeRetries.value = this.stat.writeRetries.value + 1;
					this.retry({this.store(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void evict(uint set, uint way,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.evict(set=%d, way=%d)", this, set, way);
		uint tag;
		MESIState state;
		
		this.cache.getBlock(set, way, tag, state);
		
		uint srcSet = set;
		uint srcWay = way;
		uint srcTag = tag;
		CoherentCacheNode target = this.next;
			
		this.invalidate(null, set, way, 
			{
				if(state == MESIState.INVALID) {
					onCompletedCallback(false);
				}
				else if(state == MESIState.MODIFIED) {
					this.schedule(
						{
							target.evictReceive(this, srcTag, true, 
								(bool hasError)
								{
									this.schedule(
										{
											this.evictReplyReceive(hasError, srcSet, srcWay, onCompletedCallback);
										}, 2);
								});
						}, 2);
				}
				else {
					this.schedule(
						{
							target.evictReceive(this, srcTag, false, 
								(bool hasError)
								{
									this.schedule(
										{
											this.evictReplyReceive(hasError, srcSet, srcWay, onCompletedCallback);
										}, 2);
								});
						}, 2);
				}
			});		
	}
	
	override void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback,
		void delegate(bool hasError) onReceiveReplyCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		
		this.findAndLock(addr, false, false, false, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					if(!isWriteback) {
						this.evictProcess(source, set, way, dirLock, onReceiveReplyCallback);
					}
					else {
						this.invalidate(source, set, way, 
							{
								if(state == MESIState.SHARED) {
									this.writeRequest(this.next, tag,
										(bool hasError)
										{
											this.evictWritebackFinish(source, hasError, set, way, tag, dirLock, onReceiveReplyCallback);
										});
								}
								else {
									this.evictWritebackFinish(source, false, set, way, tag, dirLock, onReceiveReplyCallback);
								}
							});
					}
				}
				else {
					onReceiveReplyCallback(true);
				}
			});
	}
	
	void evictWritebackFinish(CoherentCacheNode source, bool hasError, uint set, uint way, uint tag, DirLock dirLock,
		void delegate(bool hasError) onReceiveReplyCallback) {
		if(!hasError) {
			this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
			this.cache.accessBlock(set, way);
			this.evictProcess(source, set, way, dirLock, onReceiveReplyCallback);
		}
		else {
			dirLock.unlock();
			onReceiveReplyCallback(true);
		}
	}
	
	void evictProcess(CoherentCacheNode source, uint set, uint way, DirLock dirLock,
		void delegate(bool hasError) onReceiveReplyCallback) {
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		dirEntry.unsetSharer(source);
		if(dirEntry.owner == source) {
			dirEntry.owner = null;
		}
		dirLock.unlock();
		onReceiveReplyCallback(false);
	}
	
	void evictReplyReceive(bool hasError, uint srcSet, uint srcWay, void delegate(bool hasError) onCompletedCallback) {
		this.schedule(
			{
				if(!hasError) {
					this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
				}
				onCompletedCallback(hasError);
			}, 2);
	}
	
	override void readRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.readRequest(target=%s, addr=0x%x)", this, target, addr);
		this.schedule(
			{
				target.readRequestReceive(this, addr, onCompletedCallback);
			}, 2);
	}
	
	override void readRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, true, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					if(source.next == this) {
						this.readRequestUpdown(source, set, way, tag, state, dirLock, onCompletedCallback);
					}
					else {
						this.readRequestDownup(set, way, tag, dirLock, onCompletedCallback);
					}
				}
				else {
					this.schedule(
						{
							onCompletedCallback(true, false);
						}, 2);
				}
			});
	}
	
	void readRequestUpdown(CoherentCacheNode source, uint set, uint way, uint tag, MESIState state, DirLock dirLock,
		void delegate(bool hasError, bool isShard) onCompletedCallback) {
		uint pending = 1;
		
		if(state != MESIState.INVALID) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			
			if(dirEntry.owner !is null && dirEntry.owner != source) {
				pending++;
				this.readRequest(dirEntry.owner, tag,
					(bool hasError, bool isShared)
					{
						this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
					});
			}

			this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
		}
		else {
			this.readRequest(this.next, tag,
				(bool hasError, bool isShared)
				{
					if(!hasError) {
						this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
						this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
					}
					else {
						dirLock.unlock();
						this.schedule(
							{
								onCompletedCallback(true, false);
							}, 2);
					}
				});
		}
	}		
	
	void readRequestUpdownFinish(CoherentCacheNode source, uint set, uint way, DirLock dirLock, ref uint pending,
			void delegate(bool hasError, bool isShard) onCompletedCallback) {
		pending--;
		if(pending == 0) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			if(dirEntry.owner !is null && dirEntry.owner != source) {
				dirEntry.owner = null;
			}
			
			dirEntry.setSharer(source);
			if(!dirEntry.isShared) {
				dirEntry.owner = source;
			}
			
			this.cache.accessBlock(set, way);
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false, dirEntry.isShared);
				}, 2);
		}
	}
			
	void readRequestDownup(uint set, uint way, uint tag, DirLock dirLock,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		uint pending = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		if(dirEntry.owner !is null) {
			pending++;
			this.readRequest(dirEntry.owner, tag,
				(bool hasError, bool isShared)
				{
					this.readRequestDownUpFinish(set, way, tag, dirLock, pending, onCompletedCallback);
				});
		}
		
		this.readRequestDownUpFinish(set, way, tag, dirLock, pending, onCompletedCallback);
	}
	
	void readRequestDownUpFinish(uint set, uint way, uint tag, DirLock dirLock, ref uint pending,
			void delegate(bool hasError, bool isShared) onCompletedCallback) {
		pending--;
		
		if(pending == 0) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			dirEntry.owner = null;
			
			this.cache.setBlock(set, way, tag, MESIState.SHARED);
			this.cache.accessBlock(set, way);
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false, false);
				}, 2);
		}
	}
	
	override void writeRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.writeRequest(target=%s, addr=0x%x)", this, target, addr);
		this.schedule(
			{
				target.writeRequestReceive(this, addr, onCompletedCallback);
			}, 2);
	}
	
	override void writeRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, false, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					this.invalidate(source, set, way, 
						{
							if(source.next == this) {
								if(state == MESIState.MODIFIED || state == MESIState.EXCLUSIVE) {
									writeRequestUpdownFinish(source, false, set, way, tag, state, dirLock, onCompletedCallback);
								}
								else {
									this.writeRequest(this.next, tag,
										(bool hasError)
										{
											writeRequestUpdownFinish(source, hasError, set, way, tag, state, dirLock, onCompletedCallback);
										});
								}
							}
							else {
								this.cache.setBlock(set, way, 0, MESIState.INVALID);
								dirLock.unlock();
								this.schedule(
									{
										onCompletedCallback(false);
									}, 2);
							}
						});
				}
				else {
					this.schedule(
						{
							onCompletedCallback(true);
						}, 2);
				}
			});
	}
	
	void writeRequestUpdownFinish(CoherentCacheNode source, bool hasError, uint set, uint way, uint tag, MESIState state, DirLock dirLock,
			void delegate(bool hasError) onCompletedCallback) {
		if(!hasError) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			dirEntry.setSharer(source);
			dirEntry.owner = source;
			
			this.cache.accessBlock(set, way);
			if(state != MESIState.MODIFIED) {
				this.cache.setBlock(set, way, tag, MESIState.EXCLUSIVE);
			}
			
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false);
				}, 2);									
		}
		else {
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(true);
				}, 2);
		}
	}
	
	override void invalidate(CoherentCacheNode except, uint set, uint way, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.invalidate(except=%s, set=%d, way=%d)", this, except, set, way);
		uint tag;
		MESIState state;
		
		this.cache.getBlock(set, way, tag, state);
		
		uint pending = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		
		CoherentCacheNode[] sharersToRemove;
		
		foreach(sharer; dirEntry.sharers) {
			if(sharer != except) {
				sharersToRemove ~= sharer;
			}
		}
		
		foreach(sharer; sharersToRemove) {
			dirEntry.unsetSharer(sharer);
			if(dirEntry.owner == sharer) {
				dirEntry.owner = null;
			}
			
			this.writeRequest(sharer, tag,
				(bool hasError)
				{
					pending--;
					
					if(pending == 0) {
						onCompletedCallback();
					}
				});
			pending++;
		}
		
		pending--;
		
		if(pending == 0) {
			onCompletedCallback();
		}
	}

	Cache cache;
	CacheConfig config;
	CacheStat stat;
}

class MemoryController: CoherentCacheNode {
	this(MemorySystem memorySystem, MainMemoryConfig config, MainMemoryStat stat) {
		super(memorySystem, "mem");
		
		this.config = config;
		this.stat = stat;
	}
	
	override uint level() {
		assert(0);
	}
	
	uint latency() {
		return this.config.latency;
	}
	
	override void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback, void delegate(bool hasError) onReceiveReplyCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		this.stat.accesses.value = this.stat.accesses.value + 1;
		this.stat.writes.value = this.stat.writes.value + 1;
		this.schedule({onReceiveReplyCallback(false);}, this.latency);
	}
	
	override void readRequestReceive(CoherentCacheNode source, uint addr, void delegate(bool hasError, bool isShared) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.stat.accesses.value = this.stat.accesses.value + 1;
		this.stat.reads.value = this.stat.reads.value + 1;
		this.schedule({onCompletedCallback(false, false);}, this.latency);
	}
	
	override void writeRequestReceive(CoherentCacheNode source, uint addr, void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.stat.accesses.value = this.stat.accesses.value + 1;
		this.stat.writes.value = this.stat.writes.value + 1;
		this.schedule({onCompletedCallback(false);}, this.latency);
	}
	
	MainMemoryConfig config;
	MainMemoryStat stat;
}

class Transaction {
	void begin() {
		//TODO
	}
	
	void commit() {
		//TODO
	}
	
	void abort() {
		//TODO
	}
	
	void resume() {
		//TODO
	}
	
	void clear() {
		//TODO
	}
	
	void clearReadSet() {
		//TODO
	}
	
	void clearWriteSet() {
		//TODO
	}
	
	void checkpointRegisters() {
		//TODO
	}
	
	void restoreRegisters() {
		//TODO
	}
	
	bool checkForReadConflict(uint addr) {
		//TODO
		return false;
	}
	
	void abortAndReset() {
		//TODO
	}
	
	void earlyRelease() {
		//TODO
	}
	
	uint nestingLevel;
	bool running;
	
	uint pc;
	uint lastLoad;
}

class MemorySystem {
	this(Simulation simulation) {	
		this.simulation = simulation;		
		this.endNodeCount = this.simulation.config.architecture.processor.numCores;
		this.createMemoryHierarchy();
	}

	void createMemoryHierarchy() {
		this.mem = new MemoryController(this, this.simulation.config.architecture.mainMemory, this.simulation.stat.mainMemory);
				
		this.l2 = new CoherentCache(this, this.simulation.config.architecture.l2Cache, this.simulation.stat.l2Cache);
		this.l2.next = this.mem;

		this.seqIs = new Sequencer[this.endNodeCount];
		this.l1Is = new CoherentCache[this.endNodeCount];

		this.seqDs = new Sequencer[this.endNodeCount];
		this.l1Ds = new CoherentCache[this.endNodeCount];

		for(uint i = 0; i < this.endNodeCount; i++) {
			CoherentCache l1I = new CoherentCache(this, this.simulation.config.architecture.processor.cores[i].iCache, this.simulation.stat.processor.cores[i].iCache);
			Sequencer seqI = new Sequencer("seqI" ~ "-" ~ to!(string)(i), l1I);

			CoherentCache l1D = new CoherentCache(this, this.simulation.config.architecture.processor.cores[i].dCache, this.simulation.stat.processor.cores[i].dCache);
			Sequencer seqD = new Sequencer("seqD" ~ "-" ~ to!(string)(i), l1D);

			this.seqIs[i] = seqI;
			this.l1Is[i] = l1I;

			this.seqDs[i] = seqD;
			this.l1Ds[i] = l1D;
			
			l1I.next = this.l2;
			l1D.next = this.l2;
		}
		
		this.mmu = new MMU();
	}

	uint endNodeCount;

	Sequencer[] seqIs;
	Sequencer[] seqDs;

	CoherentCache[] l1Is;
	CoherentCache[] l1Ds;

	CoherentCache l2;
	
	MemoryController mem;
	
	MMU mmu;
	
	Simulation simulation;
}