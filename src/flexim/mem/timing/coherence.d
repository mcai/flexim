/*
 * flexim/mem/timing/coherence.d
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

module flexim.mem.timing.coherence;

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
	
	void retry(void delegate() action) {
		this.eventQueue.schedule({action();}, retryLat);
	}
	
	uint hitLatency() {
		return this.cacheConfig.hitLatency;
	}
	
	override uint level() {
		return this.cacheConfig.level;
	}
	
	override void load(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		writefln("%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, true, isRetry,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isReadHit(state)) {
						this.readRequest(this.next, addr,
						(bool hasError, bool isShared) 
						{
							if(!hasError) {
								this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
								this.cache.accessBlock(set, way);
								
								onCompletedCallback();
							}
							else {
								this.stat.readRetries++;
								dirLock.unlock();
								this.retry({this.load(addr, true, onCompletedCallback);});
							}
						});
					}
					else {
						this.cache.accessBlock(set, way);
						
						onCompletedCallback();
					}
				}
				else {
					this.stat.readRetries++;
					this.retry({this.load(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void store(uint addr, bool isRetry, void delegate() onCompletedCallback) {
		writefln("%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		this.findAndLock(addr, false, false, isRetry, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isWriteHit(state)) {
						this.writeRequest(this.next, addr,
							(bool hasError)
							{
								if(!hasError) {
									this.cache.accessBlock(set, way);
									this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
									
									dirLock.unlock();
									
									onCompletedCallback();
								}
								else {
									this.stat.writeRetries++;
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
					this.stat.writeRetries++;
					this.retry({this.store(addr, true, onCompletedCallback);});
				}
			});
	}
	
	override void findAndLock(uint addr, bool isBlocking, bool isRead, bool isRetry, 
		void delegate(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock) onCompletedCallback) {
		writefln("%s.findAndLock(addr=0x%x, isBlocking=%s, isRead=%s, isRetry=%s)", this, addr, isBlocking, isRead, isRetry);
		uint set, way, tag;
		MESIState state;
		
		bool hit = this.cache.findBlock(addr, set, way, tag, state);
		
		this.stat.accesses++;
		if(hit) {
			this.stat.hits++;
		}
		if(isRead) {
			this.stat.reads++;
			isBlocking ? this.stat.blockingReads++ : this.stat.nonblockingReads++;
			if(hit) {
				this.stat.readHits++;
			}
		}
		else {
			this.stat.writes++;
			isBlocking ? this.stat.blockingWrites++ : this.stat.nonblockingWrites++;
			if(hit) {
				this.stat.writeHits++;
			}
		}
		if(!isRetry) {
			this.stat.noRetryAccesses++;
			if(hit) {
				this.stat.noRetryHits++;					
			}
			if(isRead) {
				this.stat.noRetryReads++;
				if(hit) {
					this.stat.noRetryReadHits++;
				}
			}
			else {
				this.stat.noRetryWrites++;
				if(hit) {
					this.stat.noRetryWriteHits++;
				}
			}
		}
		
		DirLock dirLock = this.cache.dir.dirLocks[set];
		//if(!dirLock.lock()) { //TODO
		if(false) {
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
									this.stat.evictions++;
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
					uint dumbTag;
					
					this.cache.getBlock(set, way, dumbTag, state);
					onCompletedCallback(false, set, way, state, tag, dirLock);
				},
				this.hitLatency);
			}
		}
	}
	
	override void invalidate(CoherentCacheNode except, uint set, uint way, void delegate() onCompletedCallback) {
		writefln("%s.invalidate(except=%s, set=%d, way=%d)", this, except, set, way);
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
	
	override void evict(uint set, uint way,
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.evict(set=%d, way=%d)", this, set, way);
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
					target.evictReceive(this, srcTag, true, 
						(bool hasError)
						{
							if(!hasError) {
								this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
							}
							onCompletedCallback(hasError);
						});
				}
				else {
					target.evictReceive(this, srcTag, false, 
						(bool hasError)
						{
							if(!hasError) {
								this.cache.setBlock(srcSet, srcWay, 0, MESIState.INVALID);
							}
							onCompletedCallback(hasError);
						});
				}
			});		
	}
	
	override void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback,
		void delegate(bool hasError) onReceiveReplyCallback) {
		writefln("%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		this.findAndLock(addr, false, false, false, 
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(!isWriteback) {
						DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
						dirEntry.unsetSharer(source);
						if(dirEntry.owner == source) {
							dirEntry.owner = null;
						}
						dirLock.unlock();
						
						onReceiveReplyCallback(false);
					}
					else {
						this.invalidate(source, set, way, 
							{
								if(state == MESIState.SHARED) {
									this.writeRequest(this.next, addr,
										(bool hasError)
										{
											if(!hasError) {
												this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
												this.cache.accessBlock(set, way);
												
												DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
												dirEntry.unsetSharer(source);
												if(dirEntry.owner == source) {
													dirEntry.owner = null;
												}
												dirLock.unlock();
												
												onReceiveReplyCallback(false);
											}
											else {
												dirLock.unlock();
												onReceiveReplyCallback(true);
											}
										});
								}
								else {
									this.cache.setBlock(set, way, tag, MESIState.MODIFIED);
									this.cache.accessBlock(set, way);
									
									DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
									dirEntry.unsetSharer(source);
									if(dirEntry.owner == source) {
										dirEntry.owner = null;
									}
									dirLock.unlock();
									
									onReceiveReplyCallback(false);
								}
							});
					}
				}
				else {
					onReceiveReplyCallback(true);
				}
			});
	}
	
	override void readRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequest(target=%s, addr=0x%x)", this, target, addr);
		target.readRequestReceive(this, addr, onCompletedCallback);
	}
	
	override void readRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, true, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				if(!hasError) {
					if(source.next == this) {
						uint pending = 1;
						
						if(state != MESIState.INVALID) {
							DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
							
							if(dirEntry.owner !is null && dirEntry.owner != source) {
								pending++;
								this.readRequest(dirEntry.owner, tag,
									(bool hasError, bool isShared)
									{
										pending--;
										if(pending == 0) {
											if(dirEntry.owner !is null && dirEntry.owner != source) {
												dirEntry.owner = null;
											}
											
											dirEntry.setSharer(source);
											if(!dirEntry.isShared) {
												dirEntry.owner = source;
											}
											
											this.cache.accessBlock(set, way);
											dirLock.unlock();
											onCompletedCallback(false, dirEntry.isShared);
										}
									});
							}

							pending--;
							if(pending == 0) {
								if(dirEntry.owner !is null && dirEntry.owner != source) {
									dirEntry.owner = null;
								}
								
								dirEntry.setSharer(source);
								if(!dirEntry.isShared) {
									dirEntry.owner = source;
								}
								
								this.cache.accessBlock(set, way);
								dirLock.unlock();
								onCompletedCallback(false, dirEntry.isShared);
							}
						}
						else {
							this.readRequest(this.next, tag,
								(bool hasError, bool isShared)
								{
									if(!hasError) {
										this.cache.setBlock(set, way, tag, isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
										
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
											onCompletedCallback(false, dirEntry.isShared);
										}
									}
									else {
										dirLock.unlock();
										onCompletedCallback(true, false);
									}
								});
						}
					}
					else {
						uint pending = 1;
						
						DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
						
						void downUpFinish() {
							pending--;
							
							if(pending == 0) {
								dirEntry.owner = null;
								
								this.cache.setBlock(set, way, tag, MESIState.SHARED);
								this.cache.accessBlock(set, way);
								dirLock.unlock();
								onCompletedCallback(false, false);
							}
						}
						
						if(dirEntry.owner !is null) {
							pending++;
							this.readRequest(dirEntry.owner, tag,
								(bool hasError, bool isShared)
								{
									downUpFinish();
								});
						}
						
						downUpFinish();
					}
				}
				else {
					onCompletedCallback(true, false);
				}
			});
	}
	
	override void writeRequest(CoherentCacheNode target, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequest(target=%s, addr=0x%x)", this, target, addr);
		target.writeRequestReceive(this, addr, onCompletedCallback);
	}
	
	override void writeRequestReceive(CoherentCacheNode source, uint addr,
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		this.findAndLock(addr, this.next == source, false, false,
			(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock)
			{
				void writeRequestUpdownFinish(bool hasError) {
					if(!hasError) {
						DirEntry dirEntry = this.cache.dir.dirEntries[set][way];
						dirEntry.setSharer(source);
						dirEntry.owner = source;
						
						this.cache.accessBlock(set, way);
						if(state != MESIState.MODIFIED) {
							this.cache.setBlock(set, way, tag, MESIState.EXCLUSIVE);
						}
						
						dirLock.unlock();
						onCompletedCallback(false);												
					}
					else {
						dirLock.unlock();
						onCompletedCallback(true);
					}
				}
				
				if(!hasError) {
					this.invalidate(source, set, way, 
						{
							if(source.next == this) {
								if(state == MESIState.MODIFIED || state == MESIState.EXCLUSIVE) {
									writeRequestUpdownFinish(false);
								}
								else {
									this.writeRequest(this.next, tag,
										(bool hasError)
										{
											writeRequestUpdownFinish(hasError);
										});
								}
							}
							else {
								this.cache.setBlock(set, way, 0, MESIState.INVALID);
								dirLock.unlock();
								onCompletedCallback(false);
							}
						});
				}
				else {
					onCompletedCallback(true);
				}
			});
	}
	
	CacheConfig cacheConfig;
	
	CacheStat stat;

	Cache cache;
}
