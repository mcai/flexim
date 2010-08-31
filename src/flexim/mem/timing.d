/*
 * flexim/mem/timing.d
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

module flexim.mem.timing;

import flexim.all;

abstract class PendingRequest {
	this(uint addr) {
		this.addr = addr;
		
		this.set = this.way = this.tag = 0;
		
		this.state = MESIState.INVALID;
		
		this.isShared = false;
	}
	
	abstract bool isRead();
	abstract bool isBlocking();
	
	uint addr;
	
	CoherentCacheNode except;

	uint set, way, tag;
	uint srcSet, srcWay, srcTag;
	
	DirLock dirLock;

	MESIState state;
	
	uint pendings;
	
	bool isShared;
	bool isWriteback;
	bool isEviction;
}

class PendingCPURequest(CPURequestT): PendingRequest {
	this(CPURequestT cpuRequest, Sequencer source) {
		super(cpuRequest.phaddr);
		
		this.cpuRequest = cpuRequest;
		this.source = source;
	}
	
	override bool isRead() {
		return (this.cpuRequest.type == CPURequestType.READ);
	}
	
	override bool isBlocking() {
		return false;
	}
	
	override string toString() {
		return format("PendingCPURequest[cpuRequest=%s, source=%s]", this.cpuRequest, this.source);
	}
	
	CPURequestT cpuRequest;
	Sequencer source;
}

alias PendingCPURequest!(ReadCPURequest) PendingReadCPURequest;
alias PendingCPURequest!(WriteCPURequest) PendingWriteCPURequest;

enum CacheRequestType: string {
	EVICT = "EVICT",
	UPDOWN_READ = "UPDOWN_READ",
	DOWNUP_READ = "DOWNUP_READ",
	WRITE = "WRITE",
	INVALIDATE = "INVALIDATE"
}

abstract class CacheRequest {
	this(CacheRequestType type, CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, uint addr, void delegate() onCompletedCallback) {
		this.id = currentId++;
		
		this.type = type;
		
		this.source = source;
		this.target = target;
		
		this.cpuRequest = cpuRequest;
		
		this.addr = addr;
		
		this.onCompletedCallback = onCompletedCallback;
	}
	
	void complete() {
		if(this.onCompletedCallback !is null) {
			this.onCompletedCallback();
		}
	}
	
	override string toString() {
		return format("CacheRequest[id=%d, type=%s, cpuRequest=%s, source=%s, target=%s, addr=0x%x]", this.id, this.type, this.cpuRequest, this.source, this.target, this.addr);
	}
	
	ulong id;
	
	CacheRequestType type;
	
	CoherentCacheNode source;
	CoherentCacheNode target;
	
	CPURequest cpuRequest;
	
	uint addr;
	
	void delegate() onCompletedCallback;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class EvictCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, uint addr, uint set, uint way, void delegate() onCompletedCallback) {
		super(CacheRequestType.EVICT, source, target, cpuRequest, addr, onCompletedCallback);
		
		this.set = set;
		this.way = way;
	}
	
	uint set, way;
	
	EvictCacheResponse cacheResponse;
}

class UpdownReadCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, void delegate() onCompletedCallback) {
		super(CacheRequestType.UPDOWN_READ, source, target, cpuRequest, cpuRequest.phaddr, onCompletedCallback);
	}
	
	UpdownReadCacheResponse cacheResponse;
}

class DownupReadCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, void delegate() onCompletedCallback) {
		super(CacheRequestType.DOWNUP_READ, source, target, cpuRequest, cpuRequest.phaddr, onCompletedCallback);
	}
	
	DownupReadCacheResponse cacheResponse;
}

class WriteCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, void delegate() onCompletedCallback) {
		super(CacheRequestType.WRITE, source, target, cpuRequest, cpuRequest.phaddr, onCompletedCallback);
	}
	
	WriteCacheResponse cacheResponse;
}

class InvalidateCacheRequest: CacheRequest {
	this(CoherentCacheNode source, CoherentCacheNode target, CPURequest cpuRequest, uint addr, void delegate() onCompletedCallback) {
		super(CacheRequestType.INVALIDATE, source, target, cpuRequest, addr, onCompletedCallback);
	}
	
	InvalidateCacheResponse cacheResponse;
}

class CacheResponse(CacheRequestT) {
	this(CacheRequestT cacheRequest) {
		this.cacheRequest = cacheRequest;
	}
	
	ulong id() {
		return this.cacheRequest.id;
	}
	
	override string toString() {
		return format("CacheResponse[cacheRequest=%s]", this.cacheRequest);
	}
	
	CacheRequestT cacheRequest;
}

class EvictCacheResponse: CacheResponse!(EvictCacheRequest) {
	this(EvictCacheRequest cacheRequest) {
		super(cacheRequest);
		
		this.cacheRequest.cacheResponse = this;
	}
}

class UpdownReadCacheResponse: CacheResponse!(UpdownReadCacheRequest) {
	this(UpdownReadCacheRequest cacheRequest, bool isShared) {
		super(cacheRequest);
		
		this.isShared = isShared;
		
		this.cacheRequest.cacheResponse = this;
	}
	
	bool isShared;
}

class DownupReadCacheResponse: CacheResponse!(DownupReadCacheRequest) {
	this(DownupReadCacheRequest cacheRequest) {
		super(cacheRequest);
		
		this.cacheRequest.cacheResponse = this;
	}
}

class WriteCacheResponse: CacheResponse!(WriteCacheRequest) {
	this(WriteCacheRequest cacheRequest) {
		super(cacheRequest);
		
		this.cacheRequest.cacheResponse = this;
	}
}

class InvalidateCacheResponse: CacheResponse!(InvalidateCacheRequest) {
	this(InvalidateCacheRequest cacheRequest) {
		super(cacheRequest);
		
		this.cacheRequest.cacheResponse = this;
	}
}

class PendingCacheRequest(CacheRequestT): PendingRequest {
	this(CacheRequestT cacheRequest) {
		super(cacheRequest.addr);
		
		this.cacheRequest = cacheRequest;
	}
	
	ulong id() {
		return this.cacheRequest.id;
	}
	
	CPURequest cpuRequest() {
		return this.cacheRequest.cpuRequest;
	}
	
	override bool isRead() {
		return (this.cpuRequest.type == CPURequestType.READ);
	}
	
	override string toString() {
		return format("PendingCacheRequest[cacheRequest=%s]", this.cacheRequest);
	}
	
	CacheRequestT cacheRequest;
}

class PendingEvictCacheRequest: PendingCacheRequest!(EvictCacheRequest) {
	this(EvictCacheRequest cacheRequest) {
		super(cacheRequest);
	}
	
	override bool isBlocking() {
		return true;
	}
}

class PendingUpdownReadCacheRequest: PendingCacheRequest!(UpdownReadCacheRequest) {
	this(UpdownReadCacheRequest cacheRequest) {
		super(cacheRequest);
	}
	
	override bool isBlocking() {
		return false;
	}
}

class PendingDownupReadCacheRequest: PendingCacheRequest!(DownupReadCacheRequest) {
	this(DownupReadCacheRequest cacheRequest) {
		super(cacheRequest);
	}
	
	override bool isBlocking() {
		return true;
	}
}

class PendingWriteCacheRequest: PendingCacheRequest!(WriteCacheRequest) {
	this(WriteCacheRequest cacheRequest) {
		super(cacheRequest);
	}
	
	override bool isBlocking() {
		return false;
	}
}

class PendingInvalidateCacheRequest: PendingCacheRequest!(InvalidateCacheRequest) {
	this(InvalidateCacheRequest cacheRequest) {
		super(cacheRequest);
	}
	
	override bool isBlocking() {
		return true;
	}
}

abstract class CoherentCacheNode: MemorySystemNode {
	this(string name, MemorySystem memorySystem) {
		super(name, memorySystem);
	}
	
	abstract void receiveLoad(ReadCPURequest cpuRequest, Sequencer source);
	abstract void receiveStore(WriteCPURequest cpuRequest, Sequencer source);

	abstract void receiveEvict(EvictCacheRequest cacheRequest);
	abstract void receiveUpdownRead(UpdownReadCacheRequest cacheRequest);
	abstract void receiveDownupRead(DownupReadCacheRequest cacheRequest);
	abstract void receiveWrite(WriteCacheRequest cacheRequest);
	abstract void receiveInvalidate(InvalidateCacheRequest cacheRequest);

	abstract void receiveEvictResponse(EvictCacheResponse cacheRespone);
	abstract void receiveUpdownReadResponse(UpdownReadCacheResponse cacheResponse);
	abstract void receiveDownupReadResponse(DownupReadCacheResponse cacheResponse);
	abstract void receiveWriteResponse(WriteCacheResponse cacheResponse);
	abstract void receiveInvalidateResponse(InvalidateCacheResponse cacheResponse);
	
	override string toString() {
		return format("CoherentCacheNode[name=%s]", this.name);
	}
	
	CoherentCacheNode next;	
	
	DelegateEventQueue eventQueue;
}

class CoherentCache: CoherentCacheNode {
	alias List!(PendingReadCPURequest) PendingReadCPURequestQueue;
	alias List!(PendingWriteCPURequest) PendingWriteCPURequestQueue;

	alias List!(PendingEvictCacheRequest) PendingEvictCacheRequestQueue;
	alias List!(PendingUpdownReadCacheRequest) PendingUpdownReadCacheRequestQueue;
	alias List!(PendingDownupReadCacheRequest) PendingDownupReadCacheRequestQueue;
	alias List!(PendingWriteCacheRequest) PendingWriteCacheRequestQueue;
	alias List!(PendingInvalidateCacheRequest) PendingInvalidateCacheRequestQueue;
	
	this(MemorySystem memorySystem, CacheConfig cacheConfig) {
		super(cacheConfig.name, memorySystem);
		
		this.cacheConfig = cacheConfig;
		
		this.cache = new Cache(cacheConfig);
		
		this.stat = new CacheStat(this.name);
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
		
		this.pendingReadCpuRequests = new PendingReadCPURequestQueue();
		this.pendingWriteCpuRequests = new PendingWriteCPURequestQueue();

		this.pendingEvictCacheRequests = new PendingEvictCacheRequestQueue();
		this.pendingUpdownReadCacheRequests = new PendingUpdownReadCacheRequestQueue();
		this.pendingDownupReadCacheRequests = new PendingDownupReadCacheRequestQueue();
		this.pendingWriteCacheRequests = new PendingWriteCacheRequestQueue();
		this.pendingInvalidateCacheRequests = new PendingInvalidateCacheRequestQueue();
	}
	
	uint retryLat() {
		return this.cacheConfig.hitLatency + uniform(0, this.cacheConfig.hitLatency + 2);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveLoad(ReadCPURequest cpuRequest, Sequencer source) {
		logging.infof(LogCategory.MESI, "%s.receiveLoad(%s, %s)", this.name, cpuRequest, source);
		
		PendingReadCPURequest pendingCpuRequest = new PendingReadCPURequest(cpuRequest, source);
		this.pendingReadCpuRequests.add(pendingCpuRequest);
		
		this.beginServicingLoad(pendingCpuRequest);
	}
	
	void sendLoadResponse(ReadCPURequest cpuRequest, Sequencer source) {
		logging.infof(LogCategory.MESI, "%s.sendLoadResponse(%s, %s)", this.name, cpuRequest, source);
		
		source.receiveLoadResponse(cpuRequest, this);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveStore(WriteCPURequest cpuRequest, Sequencer source) {
		logging.infof(LogCategory.MESI, "%s.receiveStore(%s, %s)", this.name, cpuRequest, source);
		
		PendingWriteCPURequest pendingCpuRequest = new PendingWriteCPURequest(cpuRequest, source);
		this.pendingWriteCpuRequests.add(pendingCpuRequest);

		this.beginServicingStore(pendingCpuRequest);
	}
	
	///////////////////////////////////////////////////
	
	void sendEvict(EvictCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendEvict(%s)", this.name, cacheRequest);
		
		cacheRequest.target.receiveEvict(cacheRequest);
	}
	
	override void receiveEvict(EvictCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.receiveEvict(%s)", this.name, cacheRequest);
		
		PendingEvictCacheRequest pendingCacheRequest = new PendingEvictCacheRequest(cacheRequest);
		this.pendingEvictCacheRequests.add(pendingCacheRequest);

		this.beginServicingEvict(pendingCacheRequest);
	}
	
	void sendEvictResponse(EvictCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendEvictResponse(%s)", this.name, cacheRequest);
		
		EvictCacheResponse cacheResponse = new EvictCacheResponse(cacheRequest);
		cacheRequest.source.receiveEvictResponse(cacheResponse);
	}
	
	override void receiveEvictResponse(EvictCacheResponse cacheResponse) {
		logging.infof(LogCategory.MESI, "%s.receiveEvictResponse(%s)", this.name, cacheResponse);

		cacheResponse.cacheRequest.complete();
	}
	
	///////////////////////////////////////////////////
	
	void sendUpdownRead(UpdownReadCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendUpdownRead(%s)", this.name, cacheRequest);
		
		cacheRequest.target.receiveUpdownRead(cacheRequest);
	}
	
	override void receiveUpdownRead(UpdownReadCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.receiveUpdownRead(%s)", this.name, cacheRequest);
		
		PendingUpdownReadCacheRequest pendingCacheRequest = new PendingUpdownReadCacheRequest(cacheRequest);
		this.pendingUpdownReadCacheRequests.add(pendingCacheRequest);

		this.beginServicingUpdownRead(pendingCacheRequest);
	}
	
	void sendUpdownReadResponse(UpdownReadCacheRequest cacheRequest, bool isShared) {
		logging.infof(LogCategory.MESI, "%s.sendUpdownReadResponse(%s)", this.name, cacheRequest);
		
		UpdownReadCacheResponse cacheResponse = new UpdownReadCacheResponse(cacheRequest, isShared);
		cacheRequest.source.receiveUpdownReadResponse(cacheResponse);
	}
	
	override void receiveUpdownReadResponse(UpdownReadCacheResponse cacheResponse) {
		logging.infof(LogCategory.MESI, "%s.receiveUpdownReadResponse(%s)", this.name, cacheResponse);
		
		cacheResponse.cacheRequest.complete();
	}
	
	///////////////////////////////////////////////////
	
	void sendDownupRead(DownupReadCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendDownupRead(%s)", this.name, cacheRequest);
		
		cacheRequest.target.receiveDownupRead(cacheRequest);
	}
	
	override void receiveDownupRead(DownupReadCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.receiveDownupRead(%s)", this.name, cacheRequest);
		
		PendingDownupReadCacheRequest pendingCacheRequest = new PendingDownupReadCacheRequest(cacheRequest);
		this.pendingDownupReadCacheRequests.add(pendingCacheRequest);

		this.beginServicingDownupRead(pendingCacheRequest);
	}
	
	void sendDownupReadResponse(DownupReadCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendDownupReadResponse(%s)", this.name, cacheRequest);
		
		DownupReadCacheResponse cacheResponse = new DownupReadCacheResponse(cacheRequest);
		cacheRequest.source.receiveDownupReadResponse(cacheResponse);
	}
	
	override void receiveDownupReadResponse(DownupReadCacheResponse cacheResponse) {
		logging.infof(LogCategory.MESI, "%s.receiveDownupReadResponse(%s)", this.name, cacheResponse);
		
		cacheResponse.cacheRequest.complete();
	}
	
	///////////////////////////////////////////////////
	
	void sendWrite(WriteCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendWrite(%s)", this.name, cacheRequest);
		
		cacheRequest.target.receiveWrite(cacheRequest);
	}
	
	override void receiveWrite(WriteCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.receiveWrite(%s)", this.name, cacheRequest);
		
		PendingWriteCacheRequest pendingCacheRequest = new PendingWriteCacheRequest(cacheRequest);
		this.pendingWriteCacheRequests.add(pendingCacheRequest);

		this.beginServicingWrite(pendingCacheRequest);
	}
	
	void sendWriteResponse(WriteCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendWriteResponse(%s)", this.name, cacheRequest);
		
		WriteCacheResponse cacheResponse = new WriteCacheResponse(cacheRequest);
		cacheRequest.source.receiveWriteResponse(cacheResponse);
	}
	
	override void receiveWriteResponse(WriteCacheResponse cacheResponse) {
		logging.infof(LogCategory.MESI, "%s.receiveWriteResponse(%s)", this.name, cacheResponse);
		
		cacheResponse.cacheRequest.complete();
	}
	
	///////////////////////////////////////////////////
	
	void sendInvalidate(InvalidateCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendInvalidate(%s)", this.name, cacheRequest);
		
		cacheRequest.target.receiveInvalidate(cacheRequest);
	}
	
	override void receiveInvalidate(InvalidateCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.receiveInvalidate(%s)", this.name, cacheRequest);
		
		PendingInvalidateCacheRequest pendingCacheRequest = new PendingInvalidateCacheRequest(cacheRequest);
		this.pendingInvalidateCacheRequests.add(pendingCacheRequest);

		this.beginServicingInvalidate(pendingCacheRequest);
	}
	
	void sendInvalidateResponse(InvalidateCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.sendInvalidateResponse(%s)", this.name, cacheRequest);
		
		InvalidateCacheResponse cacheResponse = new InvalidateCacheResponse(cacheRequest);
		cacheRequest.source.receiveInvalidateResponse(cacheResponse);
	}
	
	override void receiveInvalidateResponse(InvalidateCacheResponse cacheResponse) {
		logging.infof(LogCategory.MESI, "%s.receiveInvalidateResponse(%s)", this.name, cacheResponse);
		
		cacheResponse.cacheRequest.complete();
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	
	void findAndLock(PendingRequestT)(PendingRequestT pendingRequest, void delegate() callback) {
		logging.infof(LogCategory.MESI, "%s.findAndLock(%s)", this.name, pendingRequest);
		
		bool hit = this.cache.findBlock(pendingRequest.addr, pendingRequest.set, pendingRequest.way, pendingRequest.tag, pendingRequest.state);
		
		this.stat.accesses++;
		if(hit) {
			this.stat.hits++;
		}
		if(pendingRequest.isRead) {
			this.stat.reads++;
			pendingRequest.isBlocking ? this.stat.blockingReads++ : this.stat.nonblockingReads++;
			if(hit) {
				this.stat.readHits++;
			}
		}
		else {
			this.stat.writes++;
			pendingRequest.isBlocking ? this.stat.blockingWrites++ : this.stat.nonblockingWrites++;
			if(hit) {
				this.stat.writeHits++;
			}
		}
		
		uint dumbTag = 0;
		
		if(!hit) {
			pendingRequest.way = this.cache.replaceBlock(pendingRequest.set);
			this.cache.getBlock(pendingRequest.set, pendingRequest.way, dumbTag, pendingRequest.state);
		}
		
		if(!hit && pendingRequest.state != MESIState.INVALID) {
			pendingRequest.isEviction = true;
			
			uint srcSet = pendingRequest.set;
			uint srcWay = pendingRequest.way;

			this.eventQueue.schedule(
				{
					EvictCacheRequest cacheRequest = new EvictCacheRequest(this, this.next, pendingRequest.cpuRequest, pendingRequest.addr, pendingRequest.set, pendingRequest.way, 
						{
							this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
							
							this.findAndLockFinish(pendingRequest, callback);
						});
					
					this.initiateEvict(cacheRequest);
				}, this.cacheConfig.hitLatency);
		}
		else {
			this.eventQueue.schedule({this.findAndLockFinish(pendingRequest, callback);}, this.cacheConfig.hitLatency);
		}
	}
	
	void findAndLockFinish(PendingRequestT)(PendingRequestT pendingRequest, void delegate() callback) {
		logging.infof(LogCategory.MESI, "%s.findAndLockFinish(%s)", this.name, pendingRequest);
		
		if(pendingRequest.isEviction) {
			this.stat.evictions++;
			uint dumbTag = 0;
			this.cache.getBlock(pendingRequest.set, pendingRequest.way, dumbTag, pendingRequest.state); 
		}
		
		callback();
	}
	
	void beginServicingLoad(PendingReadCPURequest pendingCpuRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingLoad(%s)", this.name, pendingCpuRequest);
		
		this.findAndLock(pendingCpuRequest, 
			{
				if(!isReadHit(pendingCpuRequest.state)) {
					UpdownReadCacheRequest cacheRequest = new UpdownReadCacheRequest(this, this.next, pendingCpuRequest.cpuRequest, 
						{					
							this.cache.setBlock(pendingCpuRequest.set, pendingCpuRequest.way, pendingCpuRequest.tag, pendingCpuRequest.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
							this.endServicingLoad(pendingCpuRequest);
						});
					this.sendUpdownRead(cacheRequest);
				}
				else {
					this.endServicingLoad(pendingCpuRequest);
				}
			});
	}
	
	void endServicingLoad(PendingReadCPURequest pendingCpuRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingLoad(%s)", this.name, pendingCpuRequest);
		
		this.cache.accessBlock(pendingCpuRequest.set, pendingCpuRequest.way);
		this.sendLoadResponse(pendingCpuRequest.cpuRequest, pendingCpuRequest.source);
	}
	
	///////////////////////////////////////////////////
	
	void beginServicingStore(PendingWriteCPURequest pendingCpuRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingStore(%s)", this.name, pendingCpuRequest);
		
		this.findAndLock(pendingCpuRequest, 
			{
				if(!isWriteHit(pendingCpuRequest.state)) {
					WriteCacheRequest cacheRequest = new WriteCacheRequest(this, this.next, pendingCpuRequest.cpuRequest,
						{
							this.endServicingStore(pendingCpuRequest);
						});
					this.sendWrite(cacheRequest);
				}
				else {
					this.endServicingStore(pendingCpuRequest);
				}
			});
	}
	
	void endServicingStore(PendingWriteCPURequest pendingCpuRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingStore(%s)", this.name, pendingCpuRequest);
		
		this.cache.accessBlock(pendingCpuRequest.set, pendingCpuRequest.way);
		this.cache.setBlock(pendingCpuRequest.set, pendingCpuRequest.way, pendingCpuRequest.tag, MESIState.MODIFIED);
	}
	
	///////////////////////////////////////////////////
	
	void initiateEvict(EvictCacheRequest cacheRequest) {
		logging.infof(LogCategory.MESI, "%s.initiateEvict(%d, %d)", this.name, cacheRequest);
				
		PendingEvictCacheRequest pendingCacheRequest = new PendingEvictCacheRequest(cacheRequest);
		this.pendingEvictCacheRequests.add(pendingCacheRequest);

		this.initiateInvalidate(pendingCacheRequest, 
			{
				if(pendingCacheRequest.state == MESIState.INVALID) {
					cacheRequest.complete();
				}
				else if(pendingCacheRequest.state == MESIState.MODIFIED) {
					this.sendEvict(cacheRequest);
					pendingCacheRequest.isWriteback = true;
				}
				else {
					this.sendEvict(cacheRequest);
				}
			});
	}
	
	void beginServicingEvict(PendingEvictCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingEvict(%s)", this.name, pendingCacheRequest);
		
		this.findAndLock(pendingCacheRequest, 
			{
				if(!pendingCacheRequest.isWriteback) {
					this.endServicingEvict(pendingCacheRequest);
				}
				else {
					this.initiateInvalidate(pendingCacheRequest,
					{
						if(pendingCacheRequest.state == MESIState.SHARED) {
							WriteCacheRequest cacheRequest = new WriteCacheRequest(this, this.next, pendingCacheRequest.cpuRequest,
								{
									this.cache.setBlock(pendingCacheRequest.set, pendingCacheRequest.way, pendingCacheRequest.tag, MESIState.MODIFIED);
									this.cache.accessBlock(pendingCacheRequest.set, pendingCacheRequest.way);
									this.endServicingEvict(pendingCacheRequest);
								});
							this.sendWrite(cacheRequest);
						}
						else {
							this.cache.setBlock(pendingCacheRequest.set, pendingCacheRequest.way, pendingCacheRequest.tag, MESIState.MODIFIED);
							this.cache.accessBlock(pendingCacheRequest.set, pendingCacheRequest.way);
							this.endServicingEvict(pendingCacheRequest);
						}
					});
				}
			});
	}
	
	void endServicingEvict(PendingEvictCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingEvict(%s)", this.name, pendingCacheRequest);
		
		DirEntry dirEntry = this.cache.dir.dirEntries[pendingCacheRequest.set][pendingCacheRequest.way];
		dirEntry.unsetSharer(pendingCacheRequest.cacheRequest.source);
		if(dirEntry.owner == pendingCacheRequest.cacheRequest.source) {
			dirEntry.owner = null;
		}
		
		this.sendEvictResponse(pendingCacheRequest.cacheRequest);
	}
	
	///////////////////////////////////////////////////
	
	void beginServicingUpdownRead(PendingUpdownReadCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingUpdownRead(%s)", this.name, pendingCacheRequest);
		
		this.findAndLock(pendingCacheRequest, 
			{
				if(!isReadHit(pendingCacheRequest.state)) {
					UpdownReadCacheRequest cacheRequest = new UpdownReadCacheRequest(this, this.next, pendingCacheRequest.cpuRequest,
						{
							this.endServicingUpdownRead(pendingCacheRequest);
						});
					this.sendUpdownRead(cacheRequest);
				}
				else {
					this.endServicingUpdownRead(pendingCacheRequest);
				}
			});
	}
	
	void endServicingUpdownRead(PendingUpdownReadCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingUpdownRead(%s)", this.name, pendingCacheRequest);
		
		this.pendingUpdownReadCacheRequests.remove(pendingCacheRequest);
		this.sendUpdownReadResponse(pendingCacheRequest.cacheRequest, pendingCacheRequest.isShared);
	}
	
	///////////////////////////////////////////////////
	
	void beginServicingDownupRead(PendingDownupReadCacheRequest pendingCacheRequest) {		
		logging.infof(LogCategory.MESI, "%s.beginServicingDownupRead(%s)", this.name, pendingCacheRequest);
		
		this.findAndLock(pendingCacheRequest, 
			{
				DirEntry dirEntry = this.cache.dir.dirEntries[pendingCacheRequest.set][pendingCacheRequest.way];
				dirEntry.owner = null;
				
				this.cache.setBlock(pendingCacheRequest.set, pendingCacheRequest.way, pendingCacheRequest.tag, MESIState.SHARED);
				this.cache.accessBlock(pendingCacheRequest.set, pendingCacheRequest.way);
				
				this.endServicingDownupRead(pendingCacheRequest);
			});
	}
	
	void endServicingDownupRead(PendingDownupReadCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingDownupRead(%s)", this.name, pendingCacheRequest);
		
		this.pendingDownupReadCacheRequests.remove(pendingCacheRequest);
		this.sendDownupReadResponse(pendingCacheRequest.cacheRequest);
	}
	
	///////////////////////////////////////////////////
	
	void beginServicingWrite(PendingWriteCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingWrite(%s)", this.name, pendingCacheRequest);
								
		this.findAndLock(pendingCacheRequest, 
			{
				if(!isWriteHit(pendingCacheRequest.state)) {
					WriteCacheRequest cacheRequest = new WriteCacheRequest(this, this.next, pendingCacheRequest.cacheRequest.cpuRequest,
						{
							this.endServicingWrite(pendingCacheRequest);
						});
					this.sendWrite(cacheRequest);
				}
				else {
					this.endServicingWrite(pendingCacheRequest);
				}
			});
	}
	
	void endServicingWrite(PendingWriteCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingWrite(%s)", this.name, pendingCacheRequest);
		
		DirEntry dirEntry = this.cache.dir.dirEntries[pendingCacheRequest.set][pendingCacheRequest.way];
		dirEntry.setSharer(pendingCacheRequest.cacheRequest.source);
		dirEntry.owner = pendingCacheRequest.cacheRequest.source;
		
		this.cache.accessBlock(pendingCacheRequest.set, pendingCacheRequest.way);
		if(pendingCacheRequest.state != MESIState.MODIFIED) {
			this.cache.setBlock(pendingCacheRequest.set, pendingCacheRequest.way, pendingCacheRequest.tag, MESIState.EXCLUSIVE);
		}
		
		this.pendingWriteCacheRequests.remove(pendingCacheRequest);
		this.sendWriteResponse(pendingCacheRequest.cacheRequest);
	}
	
	///////////////////////////////////////////////////
	
	void initiateInvalidate(PendingCacheRequestT)(PendingCacheRequestT pendingCacheRequest, void delegate() callback) {
		logging.infof(LogCategory.MESI, "%s.initiateInvalidate(%s)", this.name, pendingCacheRequest);
		
		uint tag = this.cache[pendingCacheRequest.set][pendingCacheRequest.way].tag;
		pendingCacheRequest.pendings = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[pendingCacheRequest.set][pendingCacheRequest.way];
		
		CoherentCacheNode[] sharersToRemove;
		
		foreach(sharer; dirEntry.sharers) {
			if(sharer != pendingCacheRequest.except) {
				sharersToRemove ~= sharer;
			}
		}
		
		foreach(sharer; sharersToRemove) {
			dirEntry.unsetSharer(sharer);
			if(dirEntry.owner == sharer) {
				dirEntry.owner = null;
			}
			
			InvalidateCacheRequest cacheRequest = new InvalidateCacheRequest(this, sharer, pendingCacheRequest.cpuRequest, pendingCacheRequest.addr,
			{
				pendingCacheRequest.pendings--;
				
				if(pendingCacheRequest.pendings == 0) {
					callback();
				}				
			});
			this.sendInvalidate(cacheRequest);			
			pendingCacheRequest.pendings++;
		}
		
		pendingCacheRequest.pendings--;
		
		if(pendingCacheRequest.pendings == 0) {
			callback();
		}
	}
	
	void beginServicingInvalidate(PendingInvalidateCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.beginServicingInvalidate(%s)", this.name, pendingCacheRequest);
								
		this.findAndLock(pendingCacheRequest, 
			{
				this.initiateInvalidate(pendingCacheRequest, 
					{
						this.cache.setBlock(pendingCacheRequest.set, pendingCacheRequest.way, 0, MESIState.INVALID);
						this.endServicingInvalidate(pendingCacheRequest);				
					});
			});
	}
	
	void endServicingInvalidate(PendingInvalidateCacheRequest pendingCacheRequest) {
		logging.infof(LogCategory.MESI, "%s.endServicingInvalidate(%s)", this.name, pendingCacheRequest);
		
		this.pendingInvalidateCacheRequests.remove(pendingCacheRequest);
		this.sendInvalidateResponse(pendingCacheRequest.cacheRequest);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	
	PendingReadCPURequestQueue pendingReadCpuRequests;
	PendingWriteCPURequestQueue pendingWriteCpuRequests;

	PendingEvictCacheRequestQueue pendingEvictCacheRequests;
	PendingUpdownReadCacheRequestQueue pendingUpdownReadCacheRequests;
	PendingDownupReadCacheRequestQueue pendingDownupReadCacheRequests;
	PendingWriteCacheRequestQueue pendingWriteCacheRequests;
	PendingInvalidateCacheRequestQueue pendingInvalidateCacheRequests;
	
	CacheConfig cacheConfig;
	
	CacheStat stat;

	Cache cache;
	
	static bool isUpdownRequest(CoherentCache source, CoherentCache target) {
		return source.cacheConfig.level < target.cacheConfig.level;
	}
}

class MemoryController: CoherentCacheNode {
	this(MemorySystem memorySystem) {
		super("mem", memorySystem);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override void receiveLoad(ReadCPURequest cpuRequest, Sequencer source){
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveStore(WriteCPURequest cpuRequest, Sequencer source){
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveEvict(EvictCacheRequest cacheRequest) {
		assert(0);
	}
	
	override void receiveEvictResponse(EvictCacheResponse cacheResponse) {
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveUpdownRead(UpdownReadCacheRequest cacheRequest){
		logging.infof(LogCategory.MESI, "%s.receiveReadRequest(%s)", this.name, cacheRequest);
		this.sendUpdownReadResponse(cacheRequest);
	}
	
	void sendUpdownReadResponse(UpdownReadCacheRequest cacheRequest){
		logging.infof(LogCategory.MESI, "%s.sendReadRequestResponse(%s)", this.name, cacheRequest);
		
		UpdownReadCacheResponse cacheResponse = new UpdownReadCacheResponse(cacheRequest, false);
		cacheRequest.source.receiveUpdownReadResponse(cacheResponse);
	}
	
	override void receiveUpdownReadResponse(UpdownReadCacheResponse cacheResponse){
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveDownupRead(DownupReadCacheRequest cacheRequest){
		assert(0);
	}
	
	override void receiveDownupReadResponse(DownupReadCacheResponse cacheResponse){
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveWrite(WriteCacheRequest cacheRequest){
		logging.infof(LogCategory.MESI, "%s.receiveWriteRequest(%s)", this.name, cacheRequest);
	}
	
	override void receiveWriteResponse(WriteCacheResponse cacheResponse){
		assert(0);
	}
	
	///////////////////////////////////////////////////
	
	override void receiveInvalidate(InvalidateCacheRequest cacheRequest){
		assert(0);
	}
	
	override void receiveInvalidateResponse(InvalidateCacheResponse cacheResponse){
		assert(0);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////
}
