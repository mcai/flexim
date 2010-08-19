/*
 * flexim/mem/memsys.d
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

module flexim.mem.memsys;

import flexim.all;

abstract class MemorySystem(RequestT): CacheHierarchy!(MESICache, MESIState) {
	alias MESICache CacheT;
	alias P2PInterconnect InterconnectT;
	alias MESIEventQueue EventQueueT;
	
	alias Sequencer!(RequestT, CacheT) SequencerT;
	
	this(uint endNodeCount) {
		this.endNodeCount = endNodeCount;

		this.mmu = new MMU!(MESIState)();
		
		this.m_eventQueue = new EventQueueT();
	}

	abstract void createMemoryHierarchy();
	
	override EventQueueT eventQueue() {
		return this.m_eventQueue;
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
