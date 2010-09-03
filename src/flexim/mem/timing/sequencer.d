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
	
	override void service(LoadCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.receiveRequest(%s)", this.name, request);

		this.sendCacheRequest(request);
	}
	
	override void service(StoreCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.receiveRequest(%s)", this.name, request);

		this.sendCacheRequest(request);
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