module flexim.memsys.mmu;

import flexim.all;

import std.c.stdlib;

class CAM(T, K, V) {
	this() {

	}

	K tag;
	V content;
	T next;
}

class MMUPage(StateT): CAM!(MMUPage, Addr, Addr) {
	alias tag vtladdr;
	alias content phaddr;
	
	alias Dir!(StateT) DirT;
	
	DirT dir;
}

class MMU(StateT) {	
	alias Dir!(StateT) DirT;
	alias MMUPage!(StateT) MMUPageT;
	
	this() {
	}

	uint page(Addr vtladdr) {
		return vtladdr >> MEM_LOGPAGESIZE;
	}

	uint tag(Addr vtladdr) {
		return vtladdr & ~MEM_PAGEMASK;
	}

	uint offset(Addr vtladdr) {
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

	MMUPageT getPage(Addr vtladdr) {
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
				new DirT(MEM_PAGESIZE / MEM_BLOCK_SIZE, 1);
			
			page.vtladdr = tag;
			page.phaddr = this.pageCount << MEM_LOGPAGESIZE;

			page.next = this[idx];
			this[idx] = page;
			
			this.pageCount++;
		}

		return page;
	}

	Addr translate(Addr vtladdr) {
		MMUPageT page = this.getPage(vtladdr);
		return page.phaddr | this.offset(vtladdr);
	}
	
	DirT getDir(Addr phaddr) {
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
