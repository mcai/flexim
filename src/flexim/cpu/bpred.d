/*
 * flexim/cpu/bpred.d
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

module flexim.cpu.bpred;

import flexim.all;

class BpredBtbEntry {
	this() {

	}

	uint addr;
	StaticInst staticInst;
	uint target;
	BpredBtbEntry prev, next;
}

const uint MD_BR_SHIFT = 3;

class BimodBpredDir {
	this(uint size) {
		this.size = size;
		this.table = new ubyte[this.size];

		ubyte flipflop = 1;
		for(uint cnt = 0; cnt < this.size; cnt++) {
			this.table[cnt] = flipflop;
			flipflop = cast(ubyte) (3 - flipflop);
		}
	}

	uint hash(uint baddr) {
		return (baddr >> 19) ^ (baddr >> MD_BR_SHIFT) & (this.size - 1);
	}

	ubyte* lookup(uint baddr) {
		return &this.table[this.hash(baddr)];
	}

	uint size;
	ubyte[] table;
}

class TwoLevelBpredDir {
	this(uint l1Size, uint l2Size, uint shiftWidth, bool xor) {
		this.l1Size = l1Size;
		this.l2Size = l2Size;
		this.shiftWidth = shiftWidth;
		this.xor = xor;

		this.shiftRegs = new uint[this.l1Size];
		this.l2Table = new ubyte[this.l2Size];

		ubyte flipflop = 1;
		for(uint cnt = 0; cnt < this.l2Size; cnt++) {
			this.l2Table[cnt] = flipflop;
			flipflop = cast(ubyte) (3 - flipflop);
		}
	}

	ubyte* lookup(uint baddr) {
		uint l1Index = (baddr >> MD_BR_SHIFT) & (this.l1Size - 1);
		uint l2Index = this.shiftRegs[l1Index];

		if(this.xor) {
			l2Index = (((l2Index ^ (baddr >> MD_BR_SHIFT)) & ((1 << this.shiftWidth) - 1)) | ((baddr >> MD_BR_SHIFT) << this.shiftWidth));
		}
		else {
			l2Index |= (baddr >> MD_BR_SHIFT) << this.shiftWidth;
		}
		
		l2Index &= (this.l2Size - 1);
		
		return &this.l2Table[l2Index];
	}

	uint l1Size;
	uint l2Size;
	uint shiftWidth;
	bool xor;
	uint[] shiftRegs;
	ubyte[] l2Table;
}

class BTB {
	this(uint sets, uint assoc) {
		this.sets = sets;
		this.assoc = assoc;

		this.entries = new BpredBtbEntry[this.sets * this.assoc];
		for(uint i = 0; i < this.sets * this.assoc; i++) {
			this[i] = new BpredBtbEntry();
		}

		if(this.assoc > 1) {
			for(uint i = 0; i < this.sets * this.assoc; i++) {
				if(i % this.assoc != (this.assoc - 1)) {
					this[i].next = this[i + 1];
				} else {
					this[i].next = null;
				}

				if(i % this.assoc != (this.assoc - 1)) {
					this[i + 1].prev = this[i];
				}
			}
		}
	}

	BpredBtbEntry opIndex(uint index) {
		return this.entries[index];
	}

	void opIndexAssign(BpredBtbEntry value, uint index) {
		this.entries[index] = value;
	}

	uint sets;
	uint assoc;
	BpredBtbEntry[] entries;
}

class RAS {
	this(uint size) {
		this.size = size;
		this.entries = new BpredBtbEntry[this.size];
		for(uint i = 0; i < this.size; i++) {
			this[i] = new BpredBtbEntry();
		}

		this.tos = this.size - 1;
	}

	BpredBtbEntry opIndex(uint index) {
		return this.entries[index];
	}

	void opIndexAssign(BpredBtbEntry value, uint index) {
		this.entries[index] = value;
	}

	uint size;
	uint tos;
	BpredBtbEntry[] entries;
}

class BpredUpdate {
	this() {

	}

	ubyte* pdir1;
	ubyte* pdir2;
	ubyte* pmeta;

	bool ras;
	bool bimod;
	bool twoLevel;
	bool meta;
}

interface Bpred {
	uint lookup(uint baddr, uint btarget, StaticInst staticInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx);

	void recover(uint baddr, uint stackRecoverIdx);
	
	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, StaticInst staticInst, ref BpredUpdate dirUpdate);	
}

class CombinedBpred : Bpred {
	this() {
		this(65536, 1, 65536, 65536, 16, 1, 1024, 4, 1024);
	}
	
	this(uint bimodSize, uint l1Size, uint l2Size, uint metaSize, uint shiftWidth, bool xor, uint btbSets, uint btbAssoc, uint rasSize) {
		this.twoLevel = new TwoLevelBpredDir(l1Size, l2Size, shiftWidth, xor);
		this.bimod = new BimodBpredDir(bimodSize);
		this.meta = new BimodBpredDir(metaSize);

		this.btb = new BTB(btbSets, btbAssoc);
		this.retStack = new RAS(rasSize);
	}

	// btarget is for static predictors such taken or not taken, so here it is not used at all
	uint lookup(uint baddr, uint btarget, StaticInst staticInst, ref BpredUpdate dirUpdate, ref uint stackRecoverIdx) {		
		if(!staticInst.isControl) {
			return 0;
		}

		dirUpdate = new BpredUpdate();
		dirUpdate.ras = false;
		dirUpdate.pdir1 = null;
		dirUpdate.pdir2 = null;
		dirUpdate.pmeta = null;
		
		if(staticInst.isControl && !staticInst.isUnconditional) {
			ubyte* bimodCtr = this.bimod.lookup(baddr);
			ubyte* twoLevelCtr = this.twoLevel.lookup(baddr);
			ubyte* metaCtr = this.meta.lookup(baddr);
			
			dirUpdate.pmeta = metaCtr;
			dirUpdate.meta = (*metaCtr >= 2);
			dirUpdate.bimod = (*bimodCtr >= 2);
			dirUpdate.twoLevel = (*twoLevelCtr >= 2);
			
			if(*metaCtr >=2) {
				dirUpdate.pdir1 = twoLevelCtr;
				dirUpdate.pdir2 = bimodCtr;
			}
			else {
				dirUpdate.pdir1 = bimodCtr;
				dirUpdate.pdir2 = twoLevelCtr;
			}
		}
		
		if(this.retStack.size > 0) {
			stackRecoverIdx = this.retStack.tos;
		}
		else {
			stackRecoverIdx = 0;
		}
		
		if(staticInst.isReturn && this.retStack.size > 0) {
			uint target = this.retStack[this.retStack.tos].target;
			this.retStack.tos = (this.retStack.tos + this.retStack.size - 1) % this.retStack.size;
			dirUpdate.ras = true;
		}
		
		if(staticInst.isCall && this.retStack.size > 0) {
			this.retStack.tos = (this.retStack.tos + 1) % this.retStack.size;
			this.retStack[this.retStack.tos].target = baddr + uint.sizeof;
		}
		
		uint index = (baddr >> MD_BR_SHIFT) & (this.btb.sets - 1);
		
		BpredBtbEntry btbEntry;
		
		if(this.btb.assoc > 1) {
			index *= this.btb.assoc;
			
			for(uint i = index; i < (index + this.btb.assoc); i++) {
				if(this.btb[i].addr == baddr) {
					btbEntry = this.btb[i];
					break;
				}
			}
		}
		else {
			btbEntry = this.btb[index];
			if(btbEntry.addr != baddr) {
				btbEntry = null;
			}
		}
		
		if(staticInst.isControl && staticInst.isUnconditional) {
			return btbEntry !is null ? btbEntry.target : 1;
		}
		
		if(btbEntry is null) {
			return *(dirUpdate.pdir1) >= 2 ? 1 : 0;
		}
		else {
			return *(dirUpdate.pdir1) >= 2 ? btbEntry.target :0;
		}
	}

	void recover(uint baddr, uint stackRecoverIdx) {
		this.retStack.tos = stackRecoverIdx;
	}

	void update(uint baddr, uint btarget, bool taken, bool predTaken, bool correct, StaticInst staticInst, ref BpredUpdate dirUpdate) {
		BpredBtbEntry btbEntry = null;
		
		if(!staticInst.isControl) {
			return;
		}
		
		if(staticInst.isControl && !staticInst.isUnconditional) {
			uint l1Index = (baddr >> MD_BR_SHIFT) & (this.twoLevel.l1Size - 1);
			uint shiftReg = (this.twoLevel.shiftRegs[l1Index] << 1) | taken;
			this.twoLevel.shiftRegs[l1Index] = shiftReg & ((1 << this.twoLevel.shiftWidth) - 1);
		}
		
		if(taken) {
			uint index = (baddr >> MD_BR_SHIFT) & (this.btb.sets - 1);
			
			if(this.btb.assoc > 1) {
				index *= this.btb.assoc;
				
				BpredBtbEntry lruHead = null, lruItem = null;
				
				for(uint i = index; i < (index + this.btb.assoc); i++) {
					if(this.btb[i].addr == baddr) {
						assert(btbEntry is null);
						btbEntry = this.btb[i];
					}
					
					assert(this.btb[i].prev != this.btb[i].next);
					
					if(this.btb[i].prev is null) {
						assert(lruHead is null);
						lruHead = this.btb[i];
					}
					
					if(this.btb[i].next is null) {
						assert(lruItem is null);
						lruItem = this.btb[i];
					}
				}
				
				assert(lruHead !is null && lruItem !is null);
				
				if(btbEntry is null) {
					btbEntry = lruItem;
				}
				
				if(btbEntry != lruHead) {
					if(btbEntry.prev !is null) {
						btbEntry.prev.next = btbEntry.next;
					}
					
					if(btbEntry.next !is null) {
						btbEntry.next.prev = btbEntry.prev;
					}
					
					btbEntry.next = lruHead;
					btbEntry.prev = null;
					lruHead.prev = btbEntry;
					assert(btbEntry.prev !is null || btbEntry.next !is null);
					assert(btbEntry.prev != btbEntry.next);
				}
			}
			else {
				btbEntry = this.btb[index];
			}
		}
		
		if(dirUpdate.pdir1 !is null) {
			if(taken) {
				if(*dirUpdate.pdir1 < 3) {
					++*dirUpdate.pdir1;
				}
			}
			else {
				if(*dirUpdate.pdir1 > 0) {
					++*dirUpdate.pdir1;
				}
			}
		}
		
		if(dirUpdate.pdir2 !is null) {
			if(taken) {
				if(*dirUpdate.pdir2 < 3) {
					++*dirUpdate.pdir2;
				}
			}
			else {
				if(*dirUpdate.pdir2 > 0) {
					--*dirUpdate.pdir2;
				}
			}
		}
		
		if(dirUpdate.pmeta !is null) {
			if(dirUpdate.bimod != dirUpdate.twoLevel) {
				if(dirUpdate.twoLevel == taken) {
					if(*dirUpdate.pmeta < 3) {
						++*dirUpdate.pmeta;
					}
				}
				else {
					if(*dirUpdate.pmeta > 0) {
						--*dirUpdate.pmeta;
					}
				}
			}
		}
		
		if(btbEntry !is null) {
			assert(taken);
			
			if(btbEntry.addr == baddr) {
				if(!correct) {
					btbEntry.target = btarget;
				}
			}
			else {
				btbEntry.addr = baddr;
				btbEntry.staticInst = staticInst;
				btbEntry.target = btarget;
			}
		}
	}

	TwoLevelBpredDir twoLevel;
	BimodBpredDir bimod;
	BimodBpredDir meta;

	BTB btb;
	RAS retStack;
}
