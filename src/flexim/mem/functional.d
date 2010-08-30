/*
 * flexim/mem/functional.d
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

module flexim.mem.functional;

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
			logging.infof(LogCategory.MEMORY, "Memory.map(), addr: 0x%08x ~ 0x%08x, size: %d, perm: 0x%x", addr, addr + size, size, perm);
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