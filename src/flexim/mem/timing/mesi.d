/*
 * flexim/mem/timing/mesi.d
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

module flexim.mem.timing.mesi;

import flexim.all;

class CoherentCache: CoherentCacheNode {
	this(MemorySystem memorySystem, CacheConfig config, CacheStat stat) {
		super(memorySystem, config.name);

		this.cache = new Cache(config);
		this.config = config;
		this.stat = stat;
	}
	
	uint retryLat() {
		return this.config.hitLatency + uniform(0, this.config.hitLatency + 2);
	}
	
	void retry(void delegate() action) {
		this.eventQueue.schedule({action();}, retryLat);
	}
	
	uint hitLatency() {
		return this.config.hitLatency;
	}
	
	override uint level() {
		return this.config.level;
	}
	
	override void findAndLock(uint addr, bool isBlocking, bool isRead, bool isRetry, 
		void delegate(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.findAndLock(addr=0x%x, isBlocking=%s, isRead=%s, isRetry=%s)", this, addr, isBlocking, isRead, isRetry);
		uint set, way, tag;
		MESIState state;
		
		bool hit = this.cache.findBlock(addr, set, way, tag, state, true);
		
		this.stat.accesses.value = this.stat.accesses.value + 1;
		if(hit) {
			this.stat.hits.value = this.stat.hits.value + 1;
		}
		if(isRead) {
			this.stat.reads.value = this.stat.reads.value + 1;
			if(isBlocking) {
				this.stat.blockingReads.value = this.stat.blockingReads.value + 1;
			}
			else {
				this.stat.nonblockingReads.value = this.stat.nonblockingReads.value + 1;
			}
			if(hit) {
				this.stat.readHits.value = this.stat.readHits.value + 1;
			}
		}
		else {
			this.stat.writes.value = this.stat.writes.value + 1;
			if(isBlocking) {
				this.stat.blockingWrites.value = this.stat.blockingWrites.value + 1;
			}
			else {
				this.stat.nonblockingWrites.value = this.stat.nonblockingWrites.value + 1;
			}
			if(hit) {
				this.stat.writeHits.value = this.stat.writeHits.value + 1;
			}
		}
		if(!isRetry) {
			this.stat.noRetryAccesses.value = this.stat.noRetryAccesses.value + 1;
			if(hit) {
				this.stat.noRetryHits.value = this.stat.noRetryHits.value + 1;
			}
			if(isRead) {
				this.stat.noRetryReads.value = this.stat.noRetryReads.value + 1;
				if(hit) {
					this.stat.noRetryReadHits.value = this.stat.noRetryReadHits.value + 1;
				}
			}
			else {
				this.stat.noRetryWrites.value = this.stat.noRetryWrites.value + 1;
				if(hit) {
					this.stat.noRetryWriteHits.value = this.stat.noRetryWriteHits.value + 1;
				}
			}
		}
		
		uint dumbTag;
		
		if(!hit) {
			way = this.cache.replaceBlock(set);
			this.cache.getBlock(set, way, dumbTag, state);
		}
		
		DirLock dirLock = this.cache.dir.dirLocks[set];
		if(!dirLock.lock()) {
			if(isBlocking) {
				onCompletedCallback(true, set, way, state, tag, dirLock);
			}
			else {
				this.retry({this.findAndLock(addr, isBlocking, isRead, true, onCompletedCallback);});
			}
		}
		else {
			this.cache[set][way].transientTag = tag;
			
			if(!hit && state != MESIState.INVALID) {
				this.schedule(
					{
						this.evict(set, way, 
							(bool hasError)
							{
								uint dumbTag;
								
								if(!hasError) {
									this.stat.evictions.value = this.stat.evictions.value + 1;
									this.cache.getBlock(set, way, dumbTag, state);
									onCompletedCallback(false, set, way, state, tag, dirLock);
								}
								else {
									this.cache.getBlock(set, way, dumbTag, state);
									dirLock.unlock();
									onCompletedCallback(true, set, way, state, tag, dirLock);
								}
							});
					}, this.hitLatency);
				
			}
			else {			
				this.schedule(
					{
						onCompletedCallback(false, set, way, state, tag, dirLock);
					},
				this.hitLatency);
			}
		}
	}
	
	override void load(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, true, isRetry,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isReadHit(state)) {
						this.readRequest(this.next, tag,
						(bool hasError, bool isShared) 
						{
							if(!hasError) {
								this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
								this.cache.accessBlock(set, way);
								dirLock.unlock();								
								onCompletedCallback();
							}
							else {
								this.stat.readRetries.value = this.stat.readRetries.value + 1;
								dirLock.unlock();
								this.retry({this.load(addr, true, onCompletedCallback);});
							}
						});
					}
					else {
						this.cache.accessBlock(set, way);	
						dirLock.unlock();					
						onCompletedCallback();
					}
				}
				else {
					this.stat.readRetries.value = this.stat.readRetries.value + 1;
					this.retry({this.load(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void store(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, false, isRetry, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isWriteHit(state)) {
						this.writeRequest(this.next, tag,
							(bool hasError)
							{
								if(!hasError) {
									this.cache.accessBlock(set, way);
									this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
									dirLock.unlock();
									onCompletedCallback();
								}
								else {
									this.stat.writeRetries.value = this.stat.writeRetries.value + 1;
									dirLock.unlock();
									this.retry({this.store(addr, true, onCompletedCallback);});
								}
							});
					}
					else {
						this.cache.accessBlock(set, way);
						this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
						dirLock.unlock();
						onCompletedCallback();
					}
				}
				else {
					this.stat.writeRetries.value = this.stat.writeRetries.value + 1;
					this.retry({this.store(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void evict(uint set, uint way,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.evict(set=%d, way=%d)", this, set, way);
		uint tag;
		MESIState state;
		
		this.cache.getBlock(set, way, tag, state);
		
		uint srcSet = set;
		uint srcWay = way;
		uint srcTag = tag;
		CoherentCacheNode target = this.next;
			
		this.invalidate(null, set, way, 
			{
				if(state == MESIState.INVALID) {
					onCompletedCallback(false);
				}
				else if(state == MESIState.MODIFIED) {
					this.schedule(
						{
							target.evictReceive(this, srcTag, true, 
								(bool hasError)
								{
									this.schedule(
										{
											this.evictReplyReceive(hasError, srcSet, srcWay, onCompletedCallback);
										}, 2);
								});
						}, 2);
				}
				else {
					this.schedule(
						{
							target.evictReceive(this, srcTag, false, 
								(bool hasError)
								{
									this.schedule(
										{
											this.evictReplyReceive(hasError, srcSet, srcWay, onCompletedCallback);
										}, 2);
								});
						}, 2);
				}
			});		
	}
	
	override void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback,
		void delegate(bool hasError) onReceiveReplyCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		
		this.findAndLock(addr, false, false, false, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					if(!isWriteback) {
						this.evictProcess(source, set, way, dirLock, onReceiveReplyCallback);
					}
					else {
						this.invalidate(source, set, way, 
							{
								if(state == MESIState.SHARED) {
									this.writeRequest(this.next, tag,
										(bool hasError)
										{
											this.evictWritebackFinish(source, hasError, set, way, tag, dirLock, onReceiveReplyCallback);
										});
								}
								else {
									this.evictWritebackFinish(source, false, set, way, tag, dirLock, onReceiveReplyCallback);
								}
							});
					}
				}
				else {
					onReceiveReplyCallback(true);
				}
			});
	}
	
	void evictWritebackFinish(CoherentCacheNode source, bool hasError, uint set, uint way, uint tag, DirLock dirLock,
		void delegate(bool hasError) onReceiveReplyCallback) {
		if(!hasError) {
			this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
			this.cache.accessBlock(set, way);
			this.evictProcess(source, set, way, dirLock, onReceiveReplyCallback);
		}
		else {
			dirLock.unlock();
			onReceiveReplyCallback(true);
		}
	}
	
	void evictProcess(CoherentCacheNode source, uint set, uint way, DirLock dirLock,
		void delegate(bool hasError) onReceiveReplyCallback) {
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		dirEntry.unsetSharer(source);
		if(dirEntry.owner == source) {
			dirEntry.owner = null;
		}
		dirLock.unlock();
		onReceiveReplyCallback(false);
	}
	
	void evictReplyReceive(bool hasError, uint srcSet, uint srcWay, void delegate(bool hasError) onCompletedCallback) {
		this.schedule(
			{
				if(!hasError) {
					this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
				}
				onCompletedCallback(hasError);
			}, 2);
	}
	
	override void readRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.readRequest(target=%s, addr=0x%x)", this, target, addr);
		this.schedule(
			{
				target.readRequestReceive(this, addr, onCompletedCallback);
			}, 2);
	}
	
	override void readRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, true, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					if(source.next == this) {
						this.readRequestUpdown(source, set, way, tag, state, dirLock, onCompletedCallback);
					}
					else {
						this.readRequestDownup(set, way, tag, dirLock, onCompletedCallback);
					}
				}
				else {
					this.schedule(
						{
							onCompletedCallback(true, false);
						}, 2);
				}
			});
	}
	
	void readRequestUpdown(CoherentCacheNode source, uint set, uint way, uint tag, MESIState state, DirLock dirLock,
		void delegate(bool hasError, bool isShard) onCompletedCallback) {
		uint pending = 1;
		
		if(state != MESIState.INVALID) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			
			if(dirEntry.owner !is null && dirEntry.owner != source) {
				pending++;
				this.readRequest(dirEntry.owner, tag,
					(bool hasError, bool isShared)
					{
						this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
					});
			}

			this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
		}
		else {
			this.readRequest(this.next, tag,
				(bool hasError, bool isShared)
				{
					if(!hasError) {
						this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
						this.readRequestUpdownFinish(source, set, way, dirLock, pending, onCompletedCallback);
					}
					else {
						dirLock.unlock();
						this.schedule(
							{
								onCompletedCallback(true, false);
							}, 2);
					}
				});
		}
	}		
	
	void readRequestUpdownFinish(CoherentCacheNode source, uint set, uint way, DirLock dirLock, ref uint pending,
			void delegate(bool hasError, bool isShard) onCompletedCallback) {
		pending--;
		if(pending == 0) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			if(dirEntry.owner !is null && dirEntry.owner != source) {
				dirEntry.owner = null;
			}
			
			dirEntry.setSharer(source);
			if(!dirEntry.isShared) {
				dirEntry.owner = source;
			}
			
			this.cache.accessBlock(set, way);
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false, dirEntry.isShared);
				}, 2);
		}
	}
			
	void readRequestDownup(uint set, uint way, uint tag, DirLock dirLock,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		uint pending = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		if(dirEntry.owner !is null) {
			pending++;
			this.readRequest(dirEntry.owner, tag,
				(bool hasError, bool isShared)
				{
					this.readRequestDownUpFinish(set, way, tag, dirLock, pending, onCompletedCallback);
				});
		}
		
		this.readRequestDownUpFinish(set, way, tag, dirLock, pending, onCompletedCallback);
	}
	
	void readRequestDownUpFinish(uint set, uint way, uint tag, DirLock dirLock, ref uint pending,
			void delegate(bool hasError, bool isShared) onCompletedCallback) {
		pending--;
		
		if(pending == 0) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			dirEntry.owner = null;
			
			this.cache.setBlock(set, way, tag, MESIState.SHARED);
			this.cache.accessBlock(set, way);
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false, false);
				}, 2);
		}
	}
	
	override void writeRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.writeRequest(target=%s, addr=0x%x)", this, target, addr);
		this.schedule(
			{
				target.writeRequestReceive(this, addr, onCompletedCallback);
			}, 2);
	}
	
	override void writeRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, false, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{				
				if(!hasError) {
					this.invalidate(source, set, way, 
						{
							if(source.next == this) {
								if(state == MESIState.MODIFIED || state == MESIState.EXCLUSIVE) {
									writeRequestUpdownFinish(source, false, set, way, tag, state, dirLock, onCompletedCallback);
								}
								else {
									this.writeRequest(this.next, tag,
										(bool hasError)
										{
											writeRequestUpdownFinish(source, hasError, set, way, tag, state, dirLock, onCompletedCallback);
										});
								}
							}
							else {
								this.cache.setBlock(set, way, 0, MESIState.INVALID);
								dirLock.unlock();
								this.schedule(
									{
										onCompletedCallback(false);
									}, 2);
							}
						});
				}
				else {
					this.schedule(
						{
							onCompletedCallback(true);
						}, 2);
				}
			});
	}
	
	void writeRequestUpdownFinish(CoherentCacheNode source, bool hasError, uint set, uint way, uint tag, MESIState state, DirLock dirLock,
			void delegate(bool hasError) onCompletedCallback) {
		if(!hasError) {
			DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
			dirEntry.setSharer(source);
			dirEntry.owner = source;
			
			this.cache.accessBlock(set, way);
			if(state != MESIState.MODIFIED) {
				this.cache.setBlock(set, way, tag, MESIState.EXCLUSIVE);
			}
			
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(false);
				}, 2);									
		}
		else {
			dirLock.unlock();
			this.schedule(
				{
					onCompletedCallback(true);
				}, 2);
		}
	}
	
	override void invalidate(CoherentCacheNode except, uint set, uint way, void delegate() onCompletedCallback) {
		//logging.infof(LogCategory.COHERENCE, "%s.invalidate(except=%s, set=%d, way=%d)", this, except, set, way);
		uint tag;
		MESIState state;
		
		this.cache.getBlock(set, way, tag, state);
		
		uint pending = 1;
		
		DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
		
		CoherentCacheNode[] sharersToRemove;
		
		foreach(sharer; dirEntry.sharers) {
			if(sharer != except) {
				sharersToRemove ~= sharer;
			}
		}
		
		foreach(sharer; sharersToRemove) {
			dirEntry.unsetSharer(sharer);
			if(dirEntry.owner == sharer) {
				dirEntry.owner = null;
			}
			
			this.writeRequest(sharer, tag,
				(bool hasError)
				{
					pending--;
					
					if(pending == 0) {
						onCompletedCallback();
					}
				});
			pending++;
		}
		
		pending--;
		
		if(pending == 0) {
			onCompletedCallback();
		}
	}

	Cache cache;
	CacheConfig config;
	CacheStat stat;
}