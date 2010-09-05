/*
 * flexim/mem/timing/sequencer.d
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

module flexim.mem.timing.sequencer;

import flexim.all;

class Sequencer: CoherentCacheNode {
	this(string name, CoherentCache l1Cache) {
		super(l1Cache.memorySystem, name);

		this.l1Cache = l1Cache;
	}
	
	void load(uint addr, bool isRetry, RUUStation rs, void delegate(RUUStation rs) onCompletedCallback2) {		
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