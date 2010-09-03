/*
 * flexim/mem/timing/protocol.d
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

module flexim.mem.timing.protocol;

import flexim.all;

class CoherentCache: CoherentCacheNode {
	this(MemorySystem memorySystem, CacheConfig cacheConfig) {
		super(memorySystem, cacheConfig.name);
		
		this.cacheConfig = cacheConfig;
		
		this.cache = new Cache(cacheConfig);
		
		this.stat = new CacheStat(this.name);
	}
	
	uint retryLat() {
		return this.cacheConfig.hitLatency + uniform(0, this.cacheConfig.hitLatency + 2);
	}
	
	void findAndLock(RequestT)(RequestT request, void delegate() callback) {
		//logging.infof(LogCategory.MESI, "%s.findAndLock(%s)", this.name, request);
		
		bool hit = this.cache.findBlock(request.addr, request.set, request.way, request.tag, request.state);
		
		this.stat.accesses++;
		if(hit) {
			this.stat.hits++;
		}
		if(request.isRead) {
			this.stat.reads++;
			request.isBlocking ? this.stat.blockingReads++ : this.stat.nonblockingReads++;
			if(hit) {
				this.stat.readHits++;
			}
		}
		else {
			this.stat.writes++;
			request.isBlocking ? this.stat.blockingWrites++ : this.stat.nonblockingWrites++;
			if(hit) {
				this.stat.writeHits++;
			}
		}
		
		uint dumbTag = 0;
		
		if(!hit) {
			request.way = this.cache.replaceBlock(request.set);
			this.cache.getBlock(request.set, request.way, dumbTag, request.state);
		}
		
		if(!hit && request.state != MESIState.INVALID) {
			request.isEviction = true;
			
			uint srcSet = request.set;
			uint srcWay = request.way;

			this.eventQueue.schedule(
				{
					EvictCacheRequest newRequest = new EvictCacheRequest(this, this.next, request.addr, 
						{
							this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
							
							this.findAndLockFinish(request, callback);
						});
					
					newRequest.set = request.set;
					newRequest.way = request.way;
					
					this.initiateEvict(newRequest);
				}, this.cacheConfig.hitLatency);
		}
		else {
			this.eventQueue.schedule({this.findAndLockFinish(request, callback);}, this.cacheConfig.hitLatency);
		}
	}
	
	void findAndLockFinish(PendingRequestT)(PendingRequestT request, void delegate() callback) {
		//logging.infof(LogCategory.MESI, "%s.findAndLockFinish(%s)", this.name, request);
		
		if(request.isEviction) {
			this.stat.evictions++;
			uint dumbTag = 0;
			this.cache.getBlock(request.set, request.way, dumbTag, request.state); 
		}
		
		callback();
	}
	
	override void service(LoadCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				if(!isReadHit(request.state)) {
					UpdownReadCacheRequest newRequest = new UpdownReadCacheRequest(this, this.next, request.addr, 
						{					
							this.cache.setBlock(request.set, request.way, request.tag, request.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
							this.serviceCompleted(request);
						});
					this.sendCacheRequest(newRequest);
				}
				else {
					this.serviceCompleted(request);
				}
			});
	}
	
	void serviceCompleted(LoadCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		this.cache.accessBlock(request.set, request.way);
		
		this.sendCacheResponse(request);
	}
	
	override void service(StoreCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				if(!isWriteHit(request.state)) {
					WriteCacheRequest newRequest = new WriteCacheRequest(this, this.next, request.addr,
						{
							this.serviceCompleted(request);
						});
					this.sendCacheRequest(newRequest);
				}
				else {
					this.serviceCompleted(request);
				}
			});
	}
	
	void serviceCompleted(StoreCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		this.cache.accessBlock(request.set, request.way);
		this.cache.setBlock(request.set, request.way, request.tag, MESIState.MODIFIED);
		
		this.sendCacheResponse(request);
	}
	
	void initiateEvict(EvictCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.initiateEvict(%s)", this.name, request);
		
		//this.pendingRequests.add(request); //TODO

		this.initiateInvalidate(request, 
			{
				if(request.state == MESIState.INVALID) {
					request.complete();
				}
				else if(request.state == MESIState.MODIFIED) {
					this.eventQueue.schedule({this.sendCacheRequest(request);}, 2);
					request.isWriteback = true;
				}
				else {
					this.eventQueue.schedule({this.sendCacheRequest(request);}, 2);
				}
			});
	}
	
	override void service(EvictCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				if(!request.isWriteback) {
					this.serviceCompleted(request);
				}
				else {
					this.initiateInvalidate(request,
					{
						if(request.state == MESIState.SHARED) {
							WriteCacheRequest newRequest = new WriteCacheRequest(this, this.next, request.addr,
								{
									this.cache.setBlock(request.set, request.way, request.tag, MESIState.MODIFIED);
									this.cache.accessBlock(request.set, request.way);
									this.serviceCompleted(request);
								});
							this.sendCacheRequest(newRequest);
						}
						else {
							this.cache.setBlock(request.set, request.way, request.tag, MESIState.MODIFIED);
							this.cache.accessBlock(request.set, request.way);
							this.serviceCompleted(request);
						}
					});
				}
			});
	}
	
	void serviceCompleted(EvictCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
		dirEntry.unsetSharer(request.source);
		if(dirEntry.owner == request.source) {
			dirEntry.owner = null;
		}
		
		this.sendCacheResponse(request);
	}
	
	override void service(UpdownReadCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				request.pendings = 1;
				
				if(!isReadHit(request.state)) {
					UpdownReadCacheRequest newRequest = new UpdownReadCacheRequest(this, this.next, request.addr,
						{
							this.cache.setBlock(request.set, request.way, request.tag, request.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
							this.serviceCompleted(request);
						});
					this.sendCacheRequest(newRequest);
				}
				else {
					DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
					
					if(dirEntry.owner !is null && dirEntry.owner != request.source) {
						request.pendings++;

						UpdownReadCacheRequest newRequest = new UpdownReadCacheRequest(this, dirEntry.owner, request.addr,
							{
								this.serviceCompleted(request);
							});
						this.sendCacheRequest(newRequest);
					}
						
					this.serviceCompleted(request);
				}
			});
	}
	
	void serviceCompleted(UpdownReadCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		request.pendings--;
		if(request.pendings > 0) {
			return;
		}
		
		DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
		if(dirEntry.owner !is null && dirEntry.owner != request.source) {
			dirEntry.owner = null;
		}
		
		dirEntry.setSharer(request.source);
		bool isShared = dirEntry.isShared;
		
		if(!isShared) {
			dirEntry.owner = request.source;
		}
		
		this.cache.accessBlock(request.set, request.way);
		
		this.sendCacheResponse(request);
	}
	
	override void service(DownupReadCacheRequest request) {		
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				request.pendings = 1;
				
				DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
				if(dirEntry.owner !is null) {
					request.pendings++;

					DownupReadCacheRequest newRequest = new DownupReadCacheRequest(this, dirEntry.owner, request.addr,
						{
							this.serviceCompleted(request);
						});
					this.sendCacheRequest(newRequest);
				}
				
				this.serviceCompleted(request);
			});
	}
	
	void serviceCompleted(DownupReadCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		request.pendings--;
		if(request.pendings > 0) {
			return;
		}
		
		DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
		dirEntry.owner = null;
		
		this.cache.setBlock(request.set, request.way, request.tag, MESIState.SHARED);
		this.cache.accessBlock(request.set, request.way);
		
		this.sendCacheResponse(request);
	}
	
	override void service(WriteCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				this.initiateInvalidate(request,
				{
					if(!isWriteHit(request.state)) {
						WriteCacheRequest newRequest = new WriteCacheRequest(this, this.next, request.addr,
							{
								this.serviceCompleted(request);
							});
						this.sendCacheRequest(newRequest);
					}
					else {
						this.serviceCompleted(request);
					}
				});
			});
	}
	
	void serviceCompleted(WriteCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
		dirEntry.setSharer(request.source);
		dirEntry.owner = request.source;
		
		this.cache.accessBlock(request.set, request.way);
		if(request.state != MESIState.MODIFIED) {
			this.cache.setBlock(request.set, request.way, request.tag, MESIState.EXCLUSIVE);
		}
		
		this.sendCacheResponse(request);
	}
	
	void initiateInvalidate(RequestT)(RequestT request, void delegate() callback) {
		//logging.infof(LogCategory.MESI, "%s.initiateInvalidate(%s)", this.name, request);
		
		uint tag = this.cache[request.set][request.way].tag;
		request.pendings = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[request.set][request.way];
		
		CoherentCacheNode[] sharersToRemove;
		
		foreach(sharer; dirEntry.sharers) {
			if(sharer != request.source) {
				sharersToRemove ~= sharer;
			}
		}
		
		foreach(sharer; sharersToRemove) {
			dirEntry.unsetSharer(sharer);
			if(dirEntry.owner == sharer) {
				dirEntry.owner = null;
			}
			
			InvalidateCacheRequest newRequest = new InvalidateCacheRequest(this, sharer, request.addr,
			{
				request.pendings--;
				
				if(request.pendings == 0) {
					callback();
				}				
			});
			this.sendCacheRequest(newRequest);
			request.pendings++;
		}
		
		request.pendings--;
		
		if(request.pendings == 0) {
			callback();
		}
	}
	
	override void service(InvalidateCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.service(%s)", this.name, request);
		
		this.findAndLock(request, 
			{
				this.initiateInvalidate(request, 
					{
						this.cache.setBlock(request.set, request.way, 0, MESIState.INVALID);
						this.serviceCompleted(request);
					});
			});
	}
	
	void serviceCompleted(InvalidateCacheRequest request) {
		//logging.infof(LogCategory.MESI, "%s.serviceCompleted(%s)", this.name, request);
		
		this.sendCacheResponse(request);
	}
	
	override uint level() {
		return this.cacheConfig.level;
	}
	
	CacheConfig cacheConfig;
	
	CacheStat stat;

	Cache cache;
}
