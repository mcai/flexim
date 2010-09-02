/*
 * flexim/mem/timing/coherentcache.d
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

module flexim.mem.timing.coherentcache;

import flexim.all;

enum CacheRequestType: string {
	LOAD = "LOAD",
	STORE = "STORE",
	EVICT = "EVICT",
	UPDOWN_READ = "UPDOWN_READ",
	DOWNUP_READ = "DOWNUP_READ",
	WRITE = "WRITE",
	INVALIDATE = "INVALIDATE"
}

abstract class CacheRequest {
	this(CacheRequestType type, CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		this.id = currentId++;
		
		this.type = type;
		
		this.source = source;
		this.target = target;
		
		this.addr = addr;
		this.onCompletedCallback = onCompletedCallback;
		
		this.set = this.way = this.tag = 0;
		
		this.state = MESIState.INVALID;
		
		this.isShared = false;
	}
	
	void complete() {
		if(this.onCompletedCallback !is null) {
			this.onCompletedCallback();
		}
	}

	override string toString() {
		return format("%s[ID=%d, addr=0x%x]", to!(string)(this.type), this.id, this.addr);
	}

	ulong id;
	
	CacheRequestType type;
	
	CoherentCacheNode source;
	CoherentCacheNode target;
	
	uint addr;
	
	void delegate() onCompletedCallback;

	uint set, way, tag;
	
	DirLock dirLock;

	MESIState state;
	
	uint pendings;
	
	bool hasError;
	bool isShared;
	bool isWriteback;
	bool isEviction;
	
	bool isRead;
	bool isBlocking;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class LoadCacheRequest: CacheRequest {
	this(Sequencer source, uint phaddr, RUUStation rs, void delegate(LoadCacheRequest) del) {
		this(source, phaddr, rs, {del(this);});
	}
	
	this(Sequencer source, uint phaddr, RUUStation rs, void delegate() onCompletedCallback) {
		super(CacheRequestType.LOAD, source, source.l1Cache, phaddr, onCompletedCallback);
		
		this.isRead = true;
		this.isBlocking = false;
		
		this.rs = rs;
	}
	
	RUUStation rs;
}

class StoreCacheRequest: CacheRequest {
	this(Sequencer source, uint phaddr, void delegate() onCompletedCallback) {
		super(CacheRequestType.STORE, source, source.l1Cache, phaddr, onCompletedCallback);
		
		this.isRead = false;
		this.isBlocking = false;
	}
}

class EvictCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.EVICT, source, target, addr, onCompletedCallback);
		
		this.isRead = false;
		this.isBlocking = true;
	}
}

class UpdownReadCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.UPDOWN_READ, source, target, addr, onCompletedCallback);
		
		this.isRead = true;
		this.isBlocking = false;
	}
}

class DownupReadCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.DOWNUP_READ, source, target, addr, onCompletedCallback);
		
		this.isRead = true;
		this.isBlocking = true;
	}
}

class WriteCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.WRITE, source, target, addr, onCompletedCallback);
		
		this.isRead = false;
		this.isBlocking = false;
	}
}

class InvalidateCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.INVALIDATE, source, target, addr, onCompletedCallback);
		
		this.isRead = false;
		this.isBlocking = true;
	}
}

abstract class CoherentCacheNode: MemorySystemNode {
	this(string name, MemorySystem memorySystem) {
		super(name, memorySystem);
	}
	
	abstract void receiveRequest(LoadCacheRequest request);
	abstract void receiveRequest(StoreCacheRequest request);
	abstract void receiveRequest(EvictCacheRequest request);
	abstract void receiveRequest(UpdownReadCacheRequest request);
	abstract void receiveRequest(DownupReadCacheRequest request);
	abstract void receiveRequest(WriteCacheRequest request);
	abstract void receiveRequest(InvalidateCacheRequest request);

	abstract void receiveResponse(LoadCacheRequest request);
	abstract void receiveResponse(StoreCacheRequest request);
	abstract void receiveResponse(EvictCacheRequest request);
	abstract void receiveResponse(UpdownReadCacheRequest request);
	abstract void receiveResponse(DownupReadCacheRequest request);
	abstract void receiveResponse(WriteCacheRequest request);
	abstract void receiveResponse(InvalidateCacheRequest request);
	
	override string toString() {
		return format("CoherentCacheNode[name=%s]", this.name);
	}
	
	CoherentCacheNode next;	
	
	DelegateEventQueue eventQueue;
}

abstract class CoherentCacheBase: CoherentCacheNode, EventProcessor {
	alias List!(CacheRequest) CacheRequestQueue;
	
	this(MemorySystem memorySystem, CacheConfig cacheConfig) {
		super(cacheConfig.name, memorySystem);
		
		this.cacheConfig = cacheConfig;
		
		this.cache = new Cache(cacheConfig);
		
		this.stat = new CacheStat(this.name);
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
		
		this.pendingRequests = new CacheRequestQueue();
		
		Simulator.singleInstance.addEventProcessor(this);
	}
	
	uint retryLat() {
		return this.cacheConfig.hitLatency + uniform(0, this.cacheConfig.hitLatency + 2);
	}
	
	override void processEvents() {
		//assert(0); //TODO
	}
	
	abstract void service(LoadCacheRequest pendingCpuRequest);
	abstract void service(StoreCacheRequest pendingCpuRequest);
	abstract void service(EvictCacheRequest pendingCacheRequest); 
	abstract void service(UpdownReadCacheRequest pendingCacheRequest); 
	abstract void service(DownupReadCacheRequest pendingCacheRequest);
	abstract void service(WriteCacheRequest pendingCacheRequest);
	abstract void service(InvalidateCacheRequest pendingCacheRequest);
	
	void sendCacheRequest(RequestT)(RequestT request) {
		//logging.infof(LogCategory.MESI, "%s.sendCacheRequest(%s)", this.name, request);
		
		request.target.receiveRequest(request);
	}
		
	void receiveCacheRequest(RequestT)(RequestT request) {
		//logging.infof(LogCategory.MESI, "%s.receiveCacheRequest(%s)", this.name, request);

		this.pendingRequests.add(request);
		this.service(request);
	}
	
	void sendCacheResponse(RequestT)(RequestT request) {
		//logging.infof(LogCategory.MESI, "%s.sendCacheResponse(%s)", this.name, response);

		this.pendingRequests.remove(request);
		request.source.receiveResponse(request);
	}
	
	void receiveCacheResponse(CacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.receiveCacheResponse(%s)", this.name, request);
		
		request.complete();
	}
	
	override void receiveRequest(LoadCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(StoreCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(EvictCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(UpdownReadCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(DownupReadCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(WriteCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveRequest(InvalidateCacheRequest request) {
		this.receiveCacheRequest(request);
	}
	
	override void receiveResponse(LoadCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(StoreCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(EvictCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(UpdownReadCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(DownupReadCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(WriteCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	override void receiveResponse(InvalidateCacheRequest request) {
		this.receiveCacheResponse(request);
	}
	
	CacheRequestQueue pendingRequests;
	
	CacheConfig cacheConfig;
	
	CacheStat stat;

	Cache cache;
	
	static bool isUpdownRequest(CoherentCacheBase source, CoherentCacheBase target) {
		return source.cacheConfig.level < target.cacheConfig.level;
	}
}
