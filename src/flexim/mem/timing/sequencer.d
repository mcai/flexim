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

abstract class MemorySystemNode {
	this(string name, MemorySystem memorySystem) {
		this.id = currentId++;
		this.name = name;
		this.memorySystem = memorySystem;
	}

	override string toString() {
		return format("%s", this.name);
	}

	string name;
	ulong id;
	
	MemorySystem memorySystem;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class Sequencer: CoherentCacheNode {
	this(string name, CoherentCacheBase l1Cache) {
		super(name, l1Cache.memorySystem);

		this.l1Cache = l1Cache;

		this.maxReadCapacity = 32;
	}
	
	override void receiveRequest(LoadCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.receiveRequest(%s)", this.name, request);
		
		uint blockPhaddr = this.blockAddress(request.addr);

		if(blockPhaddr in this.pendingReads) {
			this.pendingReads[blockPhaddr] ~= request;
		} else if(this.canAcceptRead(blockPhaddr)) {
			this.pendingReads[blockPhaddr] ~= request;
			this.sendLoad(request, this.l1Cache);
		} else {
			assert(0);
			//TODO: schedule retry request
		}
	}
	
	override void receiveRequest(StoreCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.receiveRequest(%s)", this.name, request);

		this.sendStore(request, this.l1Cache);
	}
	
	override void receiveRequest(EvictCacheRequest request) {
		assert(0);
	}
	
	override void receiveRequest(UpdownReadCacheRequest request) {
		assert(0);
	}
	
	override void receiveRequest(DownupReadCacheRequest request) {
		assert(0);
	}
	
	override void receiveRequest(WriteCacheRequest request) {
		assert(0);
	}
	
	override void receiveRequest(InvalidateCacheRequest request) {
		assert(0);
	}

	override void receiveResponse(LoadCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.receiveResponse(%s)", this.name, request);

		uint blockPhaddr = this.blockAddress(request.addr);
		
		assert(blockPhaddr in this.pendingReads, format("pendingReads.length=%d", this.pendingReads.length));

		if(blockPhaddr in this.pendingReads) {
			foreach(pendingRead; this.pendingReads[blockPhaddr]) {
				this.completeRequest(pendingRead);
			}

			this.pendingReads.remove(blockPhaddr);
		}
	}
	
	override void receiveResponse(StoreCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(EvictCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(UpdownReadCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(DownupReadCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(WriteCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(InvalidateCacheRequest request) {
		assert(0);
	}
	
	void sendLoad(LoadCacheRequest req, CoherentCacheNode target) {
		target.receiveRequest(req);
	}
	
	void sendStore(StoreCacheRequest req, CoherentCacheNode target) {
		target.receiveRequest(req);
	}

	bool canAcceptRead(uint addr) {
		return (this.pendingReads.length < this.maxReadCapacity);
	}

	void completeRequest(LoadCacheRequest request) {
		//logging.infof(LogCategory.REQUEST, "%s.completeRequest(%s)", this.name, request);
		
		request.complete();
	}
	
	uint blockSize() {
		return this.l1Cache.cache.blockSize;
	}

	uint blockAddress(uint addr) {
		return this.l1Cache.cache.tag(addr);
	}

	override string toString() {
		return format("%s[pendingReads.length=%d]", this.name, this.pendingReads.length);
	}

	uint maxReadCapacity;

	LoadCacheRequest[][uint] pendingReads;

	CoherentCacheBase l1Cache;
}