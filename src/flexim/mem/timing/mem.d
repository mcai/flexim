/*
 * flexim/mem/timing/mem.d
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

module flexim.mem.timing.mem;

import flexim.all;

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