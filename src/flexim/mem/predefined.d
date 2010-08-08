/*
 * flexim/mem/predefined.d
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

module flexim.mem.predefined;

import flexim.all;

class MemorySystem(RequestT, alias CacheT = MESICache, alias InterconnectT = P2PInterconnect, alias EventQueueT = MESIEventQueue): CacheHierarchy!(MESICache, MESIState) {
	alias Sequencer!(RequestT, CacheT) SequencerT;
	
	this(uint endNodeCount) {
		this.endNodeCount = endNodeCount;

		this.mmu = new MMU!(MESIState)();

		this.createMemoryHierarchy();
		
		this.m_eventQueue = new EventQueueT();
	}
	
	override EventQueueT eventQueue() {
		return this.m_eventQueue;
	}

	void createMemoryHierarchy() {
		this.l2 = new CacheT(this, "l2", false, 64, 4, 1024, 4, 7, false, true);
//		this.l2 = new CacheT(this, "l2", false, 64, 4, 2, 4, 7, false, true);
		this.caches ~= this.l2;

		//		this.mem = new MESIMemory(this, "mem", 400, 300);
		this.mem = new MESIMemory(this, "mem", 4, 3);

		this.seqIs = new SequencerT[this.endNodeCount];
		this.l1Is = new CacheT[this.endNodeCount];

		this.seqDs = new SequencerT[this.endNodeCount];
		this.l1Ds = new CacheT[this.endNodeCount];

		Interconnect l1_l2 = new InterconnectT("l1_l2");
		this.interconnects ~= l1_l2;

		l1_l2.nodes ~= this.l2;

		this.l2.upperInterconnect = l1_l2;

		Interconnect l2_mem = new InterconnectT("l2_mem");
		this.interconnects ~= l2_mem;

		l2_mem.nodes ~= this.l2;
		l2_mem.nodes ~= this.mem;

		this.l2.lowerInterconnect = l2_mem;
		this.mem.upperInterconnect = l2_mem;
		
		l2.next = this.mem;

		for(uint i = 0; i < this.endNodeCount; i++) {
			CacheT l1I = new CacheT(this, "l1I" ~ "-" ~ to!(string)(i), true, 64, 4, 64, 1, 3, true, false);
//			CacheT l1I = new CacheT(this, "l1I" ~ "-" ~ to!(string)(i), true, 64, 4, 1, 1, 3, true, false);
			SequencerT seqI = new SequencerT("seqI" ~ "-" ~ to!(string)(i), l1I);

			CacheT l1D = new CacheT(this, "l1D" ~ "-" ~ to!(string)(i), true, 64, 4, 64, 1, 3, true, false);
//			CacheT l1D = new CacheT(this, "l1D" ~ "-" ~ to!(string)(i), true, 64, 4, 1, 1, 3, true, false);
			SequencerT seqD = new SequencerT("seqD" ~ "-" ~ to!(string)(i), l1D);

			this.seqIs[i] = seqI;
			this.l1Is[i] = l1I;

			this.seqDs[i] = seqD;
			this.l1Ds[i] = l1D;

			this.caches ~= l1I;
			this.caches ~= l1D;

			Interconnect seqI_l1I = new InterconnectT("seqI_l1I" ~ "-" ~ to!(string)(i));
			this.interconnects ~= seqI_l1I;

			seqI_l1I.nodes ~= seqI;
			seqI_l1I.nodes ~= l1I;

			seqI.lowerInterconnect = seqI_l1I;
			l1I.upperInterconnect = seqI_l1I;

			Interconnect seqD_l1D = new InterconnectT("seqD_l1D" ~ "-" ~ to!(string)(i));
			this.interconnects ~= seqD_l1D;

			seqD_l1D.nodes ~= seqD;
			seqD_l1D.nodes ~= l1D;

			seqD.lowerInterconnect = seqD_l1D;
			l1D.upperInterconnect = seqD_l1D;

			l1_l2.nodes ~= l1I;
			l1_l2.nodes ~= l1D;

			l1I.lowerInterconnect = l1_l2;
			l1D.lowerInterconnect = l1_l2;
			
			l1I.next = l2;
			l1D.next = l2;
		}
	}
	
	MMU!(MESIState) mmu() {
		return this.m_mmu;
	}
	
	void mmu(MMU!(MESIState) value) {
		this.m_mmu = value;
	}
	
	MMU!(MESIState) m_mmu;

	uint endNodeCount;

	CacheT[] l1Is;
	CacheT[] l1Ds;

	SequencerT[] seqIs;
	SequencerT[] seqDs;

	CacheT l2;
	MESIMemory mem;

	CacheT[] caches;

	Interconnect[] interconnects;
	
	EventQueueT m_eventQueue;
}