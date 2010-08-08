/*
 * flexim/mem/mesi.d
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

module flexim.mem.mesi;

import flexim.all;

uint retry_lat(ICache)(ICache ccache) {
	return ccache.hitLatency + uniform(0, ccache.hitLatency + 2);
}

class MESIState: CacheBlockState {
	this(string name) {
		super(name);
	}

	override string toString() {
		return format("%s", this.name);
	}

	static this() {
		MODIFIED = new MESIState("MODIFIED");
		EXCLUSIVE = new MESIState("EXCLUSIVE");
		SHARED = new MESIState("SHARED");
		INVALID = new MESIState("INVALID");
	}

	static MESIState MODIFIED;
	static MESIState EXCLUSIVE;
	static MESIState SHARED;
	static MESIState INVALID;
}

enum MESIEventType: string {
	FIND_AND_LOCK = "FIND_AND_LOCK",
	FIND_AND_LOCK_FINISH = "FIND_AND_LOCK_FINISH",

	LOAD = "LOAD",
	LOAD_ACTION = "LOAD_ACTION",
	LOAD_MISS = "LOAD_MISS",
	LOAD_FINISH = "LOAD_FINISH",

	STORE = "STORE",
	STORE_ACTION = "STORE_ACTION",
	STORE_FINISH = "STORE_FINISH",

	EVICT = "EVICT",
	EVICT_ACTION = "EVICT_ACTION",
	EVICT_RECEIVE = "EVICT_RECEIVE",
	EVICT_WRITEBACK = "EVICT_WRITEBACK",
	EVICT_WRITEBACK_EXCLUSIVE = "EVICT_WRITEBACK_EXCLUSIVE",
	EVICT_WRITEBACK_FINISH = "EVICT_WRITEBACK_FINISH",
	EVICT_PROCESS = "EVICT_PROCESS",
	EVICT_REPLY = "EVICT_REPLY",
	EVICT_REPLY_RECEIVE = "EVICT_REPLY_RECEIVE",
	EVICT_FINISH = "EVICT_FINISH",

	READ_REQUEST = "READ_REQUEST",
	READ_REQUEST_RECEIVE = "READ_REQUEST_RECEIVE",
	READ_REQUEST_ACTION = "READ_REQUEST_ACTION",
	READ_REQUEST_UPDOWN = "READ_REQUEST_UPDOWN",
	READ_REQUEST_UPDOWN_MISS = "READ_REQUEST_UPDOWN_MISS",
	READ_REQUEST_UPDOWN_FINISH = "READ_REQUEST_UPDOWN_FINISH",
	READ_REQUEST_DOWNUP = "READ_REQUEST_DOWNUP",
	READ_REQUEST_DOWNUP_FINISH = "READ_REQUEST_DOWNUP_FINISH",
	READ_REQUEST_REPLY = "READ_REQUEST_REPLY",
	READ_REQUEST_FINISH = "READ_REQUEST_FINISH",

	WRITE_REQUEST = "WRITE_REQUEST",
	WRITE_REQUEST_RECEIVE = "WRITE_REQUEST_RECEIVE",
	WRITE_REQUEST_ACTION = "WRITE_REQUEST_ACTION",
	WRITE_REQUEST_EXCLUSIVE = "WRITE_REQUEST_EXCLUSIVE",
	WRITE_REQUEST_UPDOWN = "WRITE_REQUEST_UPDOWN",
	WRITE_REQUEST_UPDOWN_FINISH = "WRITE_REQUEST_UPDOWN_FINISH",
	WRITE_REQUEST_DOWNUP = "WRITE_REQUEST_DOWNUP",
	WRITE_REQUEST_REPLY = "WRITE_REQUEST_REPLY",
	WRITE_REQUEST_FINISH = "WRITE_REQUEST_FINISH",

	INVALIDATE = "INVALIDATE",
	INVALIDATE_FINISH = "INVALIDATE_FINISH"
}

class MESICacheStats: Stats!(ulong) {
	protected override void init() {
		this.init("accesses");
		this.init("hits");
		this.init("evictions");
		this.init("reads");
		this.init("blockingReads");
		this.init("nonblockingReads");
		this.init("readHits");
		this.init("writes");
		this.init("blockingWrites");
		this.init("nonblockingWrites");
		this.init("writeHits");

		this.init("readRetries");
		this.init("writeRetries");

		this.init("noRetryAccesses");
		this.init("noRetryHits");
		this.init("noRetryReads");
		this.init("noRetryReadHits");
		this.init("noRetryWrites");
		this.init("noRetryWriteHits");
	}

	protected override void init(string index) {
		this.entries[index] = 0;
	}
}

class MESICache: Node {
	alias MESIState StateT;

	alias CacheBlock!(StateT) CacheBlockT;
	alias CacheSet!(StateT) CacheSetT;
	alias Cache!(StateT) CacheT;

	alias CacheQueueEntry!(StateT) CacheQueueEntryT;
   
    alias DirEntry!(StateT) DirEntryT;
    alias Dir!(StateT) DirT;
	
	alias CacheHierarchy!(typeof(this), StateT) CacheHierarchyT;

	this(CacheHierarchyT cacheHierarchy, string name, bool isPrivate, uint blockSize, uint assoc, uint numSets, uint hitLatency, uint missLatency, bool lowestPrivate, bool llc) {
		super(name, isPrivate);

		this.cacheHierarchy = cacheHierarchy;

		this.cache = new CacheT(blockSize, assoc, numSets, MESIState.INVALID);
		
		this.cache.monitor.callbacks ~= new CacheMonitoringCallback(&this.monitor);

		this.hitLatency = hitLatency;
		this.missLatency = missLatency;

		this.lowestPrivate = lowestPrivate;
		this.llc = llc;

		this.stats = new MESICacheStats();

		this.upperInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleUpperInterconnectMessage);
		this.lowerInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleLowerInterconnectMessage);
	}
	
	void monitor(uint set, uint way, CacheMonitoringEventType eventType, string msg) {
		logging[LogCategory.DEBUG].infof("  %s %s (set=%d, way=%s) %s", this.name, eventType, set, way != -1 ? format("%d", way) : "N/A", msg);
	}

	void dumpConfigs(string indent) {
		logging[LogCategory.CONFIG].infof(indent ~ "[%s] number of sets: %d, block size: %d, assoc: %d, hit latency: %d, miss latency: %d", this.name, this.cache.numSets, this.cache.blockSize,
				this.cache.assoc, this.hitLatency, this.missLatency);
	}
	
	void appendStatStr(T)(ref string str, string indent, string key, T value) {
		str ~= format(indent ~ "  " ~ "%s: %s\n", key, to!(string)(value));
	}

	void dumpStats(string indent) {
		string str;

		str ~= format(indent ~ "[%s] -----\n", this.name);
		
		appendStatStr(str, indent, "Accesses", this.stats["accesses"]);
		appendStatStr(str, indent, "Hits", this.stats["hits"]);
		appendStatStr(str, indent, "Misses", this.stats["accesses"] - this.stats["hits"]);
		appendStatStr(str, indent, "HitRatio", this.stats["accesses"] != 0 ? cast(double)(this.stats["hits"]) / cast(double)(this.stats["accesses"]) : 0.0);
		appendStatStr(str, indent, "Evictions", this.stats["evictions"]);
		appendStatStr(str, indent, "Retries", this.stats["readRetries"] + this.stats["writeRetries"]);
		appendStatStr(str, indent, "ReadRetries", this.stats["readRetries"]);
		appendStatStr(str, indent, "WriteRetries", this.stats["writeRetries"]);
		appendStatStr(str, indent, "NoRetryAccesses", this.stats["noRetryAccesses"]);
		appendStatStr(str, indent, "NoRetryHits", this.stats["noRetryHits"]);
		appendStatStr(str, indent, "NoRetryMisses", this.stats["noRetryAccesses"] - this.stats["noRetryHits"]);
		appendStatStr(str, indent, "NoRetryHitRatio", this.stats["noRetryAccesses"] != 0 ? cast(double)(this.stats["noRetryHits"]) / cast(double)(this.stats["noRetryAccesses"]) : 0.0);
		appendStatStr(str, indent, "NoRetryReads", this.stats["noRetryReads"]);
		appendStatStr(str, indent, "NoRetryReadHits", this.stats["noRetryReadHits"]);
		appendStatStr(str, indent, "NoRetyrReadMisses", this.stats["noRetryReads"] - this.stats["noRetryReadHits"]);
		appendStatStr(str, indent, "NoRetryWrites", this.stats["noRetryWrites"]);
		appendStatStr(str, indent, "NoRetryWriteHits", this.stats["noRetryWriteHits"]);
		appendStatStr(str, indent, "NoRetryWriteMisses", this.stats["noRetryWrites"] - this.stats["noRetryWriteHits"]);
		appendStatStr(str, indent, "Reads", this.stats["reads"]);
		appendStatStr(str, indent, "BlockingReads", this.stats["blockingReads"]);
		appendStatStr(str, indent, "NonblockingReads", this.stats["nonblockingReads"]);
		appendStatStr(str, indent, "ReadHits", this.stats["readHits"]);
		appendStatStr(str, indent, "ReadMisses", this.stats["reads"] - this.stats["readHits"]);
		appendStatStr(str, indent, "Writes", this.stats["writes"]);
		appendStatStr(str, indent, "BlockingWrites", this.stats["blockingWrites"]);
		appendStatStr(str, indent, "NonblockingWrites", this.stats["nonblockingWrites"]);
		appendStatStr(str, indent, "WriteHits", this.stats["writeHits"]);
		appendStatStr(str, indent, "WriteMisses", this.stats["writes"] - this.stats["writeHits"]);

		logging[LogCategory.CONFIG].info(str);
	}

	CacheQueueEntryT findMatchingRequest(Request request) {
		logging[LogCategory.CACHE].infof("%s.findMatchingRequest(%s)", this.name, request);

		if(request.addr in this.pendingRequests) {
			foreach(queueEntry; this.pendingRequests[request.addr]) {
				if(queueEntry.request == request || queueEntry.request.addr == request.addr) {
					return queueEntry;
				}
			}
		}

		return null;
	}

	void removePendingRequest(CacheQueueEntryT queueEntry) {
		logging[LogCategory.CACHE].infof("%s.removePendingRequest(%s)", this.name, queueEntry);

		if(queueEntry.request.addr in this.pendingRequests) {
			foreach(indexFound, queueEntryFound; this.pendingRequests[queueEntry.request.addr]) {
				if(queueEntryFound == queueEntry) {
					this.pendingRequests[queueEntry.request.addr] = this.pendingRequests[queueEntry.request.addr].remove(indexFound);
				}
			}
		}
	}

	void handleUpperInterconnectMessage(Interconnect interconnect, Message m, Node sender) {
		logging[LogCategory.MESI].infof("%s.handleUpperInterconnectMessage(%s, %s)", this.name, interconnect, m);

		if(m.request.type == RequestType.READ) {
			CacheQueueEntryT queueEntry = new CacheQueueEntryT(interconnect, null, sender, m.request);
			this.pendingRequests[m.request.addr] ~= queueEntry;
			
			MESIStack newStack = new MESIStack(m.request.id, this, m.request.addr, new Callback1!(Addr)(m.request.addr, &this.endReadAccess));
			this.cacheHierarchy.eventQueue.schedule(MESIEventType.LOAD, newStack, 0);
		} else if(m.request.type == RequestType.WRITE) {
			MESIStack newStack = new MESIStack(m.request.id, this, m.request.addr, new Callback0({}));
			this.cacheHierarchy.eventQueue.schedule(MESIEventType.STORE, newStack, 0);
		}
	}

	void handleLowerInterconnectMessage(Interconnect interconnect, Message m, Node sender) {
		logging[LogCategory.MESI].infof("%s.handleLowerInterconnectMessage(%s, %s)", this.name, interconnect, m);
		assert(0);
	}

	void endReadAccess(Addr addr) {
		assert(addr in this.pendingRequests);
		
		foreach(queueEntry; this.pendingRequests[addr]) {
			queueEntry.src.send(new Message(queueEntry.request), this, queueEntry.sender);
		}		
		
		this.pendingRequests.remove(addr);
	}

	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref StateT state) {
		tag = this.cache.tag(addr);
		set = this.cache.set(addr);

		uint wayFound = this.cache.assoc;

		foreach(way, blk; this.cache[set]) {
			if(blk.tag == tag && blk.state != this.cache.initialState) {
				wayFound = way;
				break;
			}
			if(blk.transientTag == tag) {
				if(this.cache.dir.dirLocks[set].locked) {
					wayFound = way;
					break;
				}
			}
		}

		if(wayFound == this.cache.assoc) {
			way = 0;
			state = this.cache.initialState;

			return false;
		} else {
			way = wayFound;
			state = this.cache[set][wayFound].state;

			return true;
		}
	}

	void getBlock(uint set, uint way, ref uint tag, ref StateT state) {
		this.cache.getBlock(set, way, tag, state);
	}

	uint blockSize() {
		return this.cache.blockSize;
	}
	
	DirT getDir() {
		return this.cache.dir;
	}
	
	DirEntryT getDirEntry(uint set, uint way) {
		return this.getDir().dirEntries[set][way];
	}
	
	DirLock getDirLock(uint set) {
		return this.getDir().dirLocks[set];
	}

	bool isMem() {
		return false;
	}

	uint hitLatency() {
		return this.m_hitLatency;
	}

	void hitLatency(uint value) {
		this.m_hitLatency = value;
	}

	uint missLatency() {
		return this.m_missLatency;
	}

	void missLatency(uint value) {
		this.m_missLatency = value;
	}

	MESICache next() {
		return this.m_next;
	}

	void next(MESICache value) {
		this.m_next = value;
	}

	CacheHierarchyT cacheHierarchy() {
		return this.m_cacheHierarchy;
	}

	void cacheHierarchy(CacheHierarchyT value) {
		this.m_cacheHierarchy = value;
	}
	
	MESICacheStats stats() {
		return this.m_stats;
	}
	
	void stats(MESICacheStats value) {
		this.m_stats = value;
	}

	CacheT cache;

	uint m_hitLatency;
	uint m_missLatency;

	bool lowestPrivate;
	bool llc;

	private MESICache m_next;

	CacheHierarchyT m_cacheHierarchy;

	CacheQueueEntryT[][Addr] pendingRequests;
	
	private MESICacheStats m_stats;	
}

class MESIMemory: MESICache {
	alias MESIState StateT;

	this(CacheHierarchyT cacheHierarchy, string name, uint readLatency, uint writeLatency) {
		super(cacheHierarchy, name, false, 64, 4, 1024, 0, 400, false, false);

		this.readLatency = readLatency;
		this.writeLatency = writeLatency;

		this.upperInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleUpperInterconnectMessage);
	}

	void handleUpperInterconnectMessage(Interconnect interconnect, Message m, Node sender) {
		logging[LogCategory.MESI].infof("%s.handleUpperInterconnectMessage(%s, %s, %s)", this.name, interconnect, m, sender);

		Message message = new Message(m.request);
		message.hasData = true;

		this.upperInterconnect.send(message, this, sender, 1);
	}

	uint readLatency;
	uint writeLatency;

	uint logBlockSize() {
		return this.cache.logBlockSize;
	}

	override bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref StateT state) {
		set = addr >> this.logBlockSize;
		way = 0;
		tag = addr & ~(this.blockSize - 1);
		state = StateT.EXCLUSIVE;
		return true;
	}

	override void getBlock(uint set, uint way, ref uint tag, ref StateT state) {
		tag = set << this.logBlockSize;
		state = MESIState.EXCLUSIVE;
	}
	
	override DirEntryT getDirEntry(uint set, uint way) {
		DirT dir = this.getDir();
		set = set % dir.xSize;
		return dir.dirEntries[set][way];
	}
	
	override DirLock getDirLock(uint set) {
		DirT dir = this.getDir();		
		set = set % dir.xSize;
		return dir.dirLocks[set];
	}

	override bool isMem() {
		return true;
	}

	MESICache next() {
		return null;
	}
}

ulong mesi_stack_id = 0;

class MESIStack {
	this(ulong id, MESICache ccache, uint addr, Invokable callback) {
		this.id = id;
		this.ccache = ccache;
		this.addr = addr;
		this.callback = callback;
	}

	this(ulong id, MESICache ccache, uint addr, MESIEventQueue eventQueue, MESIEventType retEvent, MESIStack retStack) {
		this.retEvent = retEvent;
		this.retStack = retStack;

		this(id, ccache, addr, new Callback3!(MESIEventType, MESIStack, ulong)(retEvent, retStack, 0, &eventQueue.schedule));
	}

	void ret() {
		if(this.callback !is null) {
			this.callback.invoke();
		}
	}

	override string toString() {
		return format(
				"MESIStack[id: %d, ccache: %s, target: %s, except: %s, addr: 0x%x, set: %d, way: %d, tag: %d, srcSet: %d, srcWay: %d, srcTag: %d, dirLock: %s, state: %s, pending: %d, isErr: %s, isShared: %s, isRead: %s, isBlocking: %s, isWriteback: %s, isEviction: %s, isRetry: %s, retEvent: %s, retStack ID: %s]",
				this.id, this.ccache !is null ? this.ccache.name : "NULL", this.target !is null ? this.target.name : "NULL", this.except !is null ? this.except.name : "NULL", this.addr, this.set,
				this.way, this.tag, this.srcSet, this.srcWay, this.srcTag, this.dirLock !is null ? to!(string)(this.dirLock) : "NULL", this.state !is null ? to!(string)(this.state) : "NULL",
				this.pending, this.isErr, this.isShared, this.isRead, this.isBlocking, this.isWriteback, this.isEviction, this.isRetry, this.retEvent !is null ? to!(string)(this.retEvent) : "NULL",
				this.retStack !is null ? to!(string)(this.retStack.id) : "N/A");
	}

	ulong id;

	MESICache ccache, target, except;

	uint addr, set, way, tag;
	uint srcSet, srcWay, srcTag;

	DirLock dirLock;

	MESIState state;

	int pending;

	bool isErr;
	bool isShared;
	bool isRead;
	bool isBlocking;
	bool isWriteback;
	bool isEviction;
	bool isRetry;

	Invokable callback;

	MESIEventType retEvent;
	MESIStack retStack;
}


class MESIEventQueue: EventQueue!(MESIEventType, MESIStack) {
	public:
		this() {
			super("MESIEventQueue");

			this.registerHandler(MESIEventType.FIND_AND_LOCK, &this.FIND_AND_LOCK);
			this.registerHandler(MESIEventType.FIND_AND_LOCK_FINISH, &this.FIND_AND_LOCK_FINISH);

			this.registerHandler(MESIEventType.LOAD, &this.LOAD);
			this.registerHandler(MESIEventType.LOAD_ACTION, &this.LOAD_ACTION);
			this.registerHandler(MESIEventType.LOAD_MISS, &this.LOAD_MISS);
			this.registerHandler(MESIEventType.LOAD_FINISH, &this.LOAD_FINISH);

			this.registerHandler(MESIEventType.STORE, &this.STORE);
			this.registerHandler(MESIEventType.STORE_ACTION, &this.STORE_ACTION);
			this.registerHandler(MESIEventType.STORE_FINISH, &this.STORE_FINISH);

			this.registerHandler(MESIEventType.EVICT, &this.EVICT);
			this.registerHandler(MESIEventType.EVICT_ACTION, &this.EVICT_ACTION);
			this.registerHandler(MESIEventType.EVICT_RECEIVE, &this.EVICT_RECEIVE);
			this.registerHandler(MESIEventType.EVICT_WRITEBACK, &this.EVICT_WRITEBACK);
			this.registerHandler(MESIEventType.EVICT_WRITEBACK_EXCLUSIVE, &this.EVICT_WRITEBACK_EXCLUSIVE);
			this.registerHandler(MESIEventType.EVICT_WRITEBACK_FINISH, &this.EVICT_WRITEBACK_FINISH);
			this.registerHandler(MESIEventType.EVICT_PROCESS, &this.EVICT_PROCESS);
			this.registerHandler(MESIEventType.EVICT_REPLY, &this.EVICT_REPLY);
			this.registerHandler(MESIEventType.EVICT_REPLY_RECEIVE, &this.EVICT_REPLY_RECEIVE);
			this.registerHandler(MESIEventType.EVICT_FINISH, &this.EVICT_FINISH);

			this.registerHandler(MESIEventType.READ_REQUEST, &this.READ_REQUEST);
			this.registerHandler(MESIEventType.READ_REQUEST_RECEIVE, &this.READ_REQUEST_RECEIVE);
			this.registerHandler(MESIEventType.READ_REQUEST_ACTION, &this.READ_REQUEST_ACTION);
			this.registerHandler(MESIEventType.READ_REQUEST_UPDOWN, &this.READ_REQUEST_UPDOWN);
			this.registerHandler(MESIEventType.READ_REQUEST_UPDOWN_MISS, &this.READ_REQUEST_UPDOWN_MISS);
			this.registerHandler(MESIEventType.READ_REQUEST_UPDOWN_FINISH, &this.READ_REQUEST_UPDOWN_FINISH);
			this.registerHandler(MESIEventType.READ_REQUEST_DOWNUP, &this.READ_REQUEST_DOWNUP);
			this.registerHandler(MESIEventType.READ_REQUEST_DOWNUP_FINISH, &this.READ_REQUEST_DOWNUP_FINISH);
			this.registerHandler(MESIEventType.READ_REQUEST_REPLY, &this.READ_REQUEST_REPLY);
			this.registerHandler(MESIEventType.READ_REQUEST_FINISH, &this.READ_REQUEST_FINISH);

			this.registerHandler(MESIEventType.WRITE_REQUEST, &this.WRITE_REQUEST);
			this.registerHandler(MESIEventType.WRITE_REQUEST_RECEIVE, &this.WRITE_REQUEST_RECEIVE);
			this.registerHandler(MESIEventType.WRITE_REQUEST_ACTION, &this.WRITE_REQUEST_ACTION);
			this.registerHandler(MESIEventType.WRITE_REQUEST_EXCLUSIVE, &this.WRITE_REQUEST_EXCLUSIVE);
			this.registerHandler(MESIEventType.WRITE_REQUEST_UPDOWN, &this.WRITE_REQUEST_UPDOWN);
			this.registerHandler(MESIEventType.WRITE_REQUEST_UPDOWN_FINISH, &this.WRITE_REQUEST_UPDOWN_FINISH);
			this.registerHandler(MESIEventType.WRITE_REQUEST_DOWNUP, &this.WRITE_REQUEST_DOWNUP);
			this.registerHandler(MESIEventType.WRITE_REQUEST_REPLY, &this.WRITE_REQUEST_REPLY);
			this.registerHandler(MESIEventType.WRITE_REQUEST_FINISH, &this.WRITE_REQUEST_FINISH);

			this.registerHandler(MESIEventType.INVALIDATE, &this.INVALIDATE);
			this.registerHandler(MESIEventType.INVALIDATE_FINISH, &this.INVALIDATE_FINISH);
		}

		void FIND_AND_LOCK(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.FIND_AND_LOCK(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s find and lock (blocking=%s)",
					stack.id, stack.addr, ccache.name, stack.isBlocking);

			/* Default return values */
			ret.isErr = false;
			ret.set = 0;
			ret.way = 0;
			ret.state = MESIState.INVALID;
			ret.tag = 0;

			/* Look for block. */
			bool hit = ccache.findBlock(stack.addr, stack.set, stack.way, stack.tag, stack.state);
			if(hit) {
				logging[LogCategory.DEBUG].infof("  0x%x %s hit: set=%d, way=%d, state=%s",
						stack.tag, ccache.name, stack.set, stack.way, stack.state);
			}
			
			/* Stats */
			ccache.stats["accesses"]++;
			if(hit) {
				ccache.stats["hits"]++;
			}
			if(stack.isRead) {
				ccache.stats["reads"]++;
				stack.isBlocking ? ccache.stats["blockingReads"]++ : ccache.stats["nonblockingReads"]++;
				if(hit) {
					ccache.stats["readHits"]++;
				}
			}
			else {
				ccache.stats["writes"]++;
				stack.isBlocking ? ccache.stats["blockingWrites"]++ : ccache.stats["nonblockingWrites"]++;
				if(hit) {
					ccache.stats["writeHits"]++;
				}
			}
			if(!stack.isRetry) {
				ccache.stats["noRetryAccesses"]++;
				if(hit) {
					ccache.stats["noRetryHits"]++;					
				}
				if(stack.isRead) {
					ccache.stats["noRetryReads"]++;
					if(hit) {
						ccache.stats["noRetryReadHits"]++;
					}
				}
				else {
					ccache.stats["noRetryWrites"]++;
					if(hit) {
						ccache.stats["noRetryWriteHits"]++;
					}
				}
			}

			uint dumbTag = 0;

			/* Miss */
			if(!hit) {
				assert(!stack.isBlocking);
				assert(!ccache.isMem);

				/* Find victim */
				stack.way = ccache.cache.replaceBlock(stack.set);
				ccache.cache.getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state != MESIState.INVALID || !ccache.getDir().isSharedOrOwned(stack.set, stack.way), 
						format("stack.state=%s, ccache.getDirEntry(set=%d, way=%d)=%s", 
								stack.state, stack.set, stack.way, ccache.getDirEntry(stack.set, stack.way)));
				logging[LogCategory.DEBUG].infof("  0x%x %s miss -> lru: set=%d, way=%d, state=%s",
						stack.tag, ccache.name, stack.set, stack.way, stack.state);
			}

			/* Lock entry */
			stack.dirLock = ccache.getDirLock(stack.set);
			if(!stack.dirLock.lock(stack.id)) {
				logging[LogCategory.DEBUG].infof("  0x%x %s block already locked: set=%d, way=%d, lockerStackId=%d",
						stack.tag, ccache.name, stack.set, stack.way, stack.dirLock.lockerStackId);
				ret.isErr = true;
				stack.ret();
				return;
			}

			/* Entry is locked. Record the transient tag so that a subsequent lookup
			 * detects that the block is being brought. */
			if(!ccache.isMem) {
				ccache.cache[stack.set][stack.way].transientTag = stack.tag;
			}

			/* On miss, evict if victim is a valid block. */
			if(!hit && stack.state != MESIState.INVALID) {
				stack.isEviction = true;

				MESIStack newStack = new MESIStack(stack.id, ccache, 0, this, MESIEventType.FIND_AND_LOCK_FINISH, stack);
				newStack.set = stack.set;
				newStack.way = stack.way;
				this.schedule(MESIEventType.EVICT, newStack, ccache.hitLatency);
			}
			else {
				/* Access latency */
				this.schedule(MESIEventType.FIND_AND_LOCK_FINISH, stack, ccache.hitLatency);
			}
		}

		void FIND_AND_LOCK_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.FIND_AND_LOCK_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s find and lock finish (err=%s)",
					stack.id, stack.tag, ccache.name, stack.isErr);

			uint dumbTag = 0;

			/* If evict produced err, return err */
			if(stack.isErr) {
				ccache.cache.getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state != MESIState.INVALID);
				assert(stack.isEviction);
				ret.isErr = true;
				stack.dirLock.unlock();
				stack.ret();
				return;
			}

			/* Eviction */
			if(stack.isEviction) {
				ccache.stats["evictions"]++;
				ccache.cache.getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state == MESIState.INVALID);
			}

			/* Return */
			ret.isErr = false;
			ret.set = stack.set;
			ret.way = stack.way;
			ret.state = stack.state;
			ret.tag = stack.tag;
			ret.dirLock = stack.dirLock;

			stack.ret();
		}

		void LOAD(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.LOAD(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load", stack.id, stack.addr, ccache.name);

			/* Call find and lock */
			MESIStack newStack = new MESIStack(stack.id, ccache, stack.addr, this, MESIEventType.LOAD_ACTION, stack);
			newStack.isBlocking = false;
			newStack.isRead = true;
			newStack.isRetry = stack.isRetry;
			this.schedule(MESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void LOAD_ACTION(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.LOAD_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
				
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load action", stack.id, stack.tag, ccache.name);

			/* Error locking */
			if(stack.isErr) {
				ccache.stats["readRetries"]++;
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MESIEventType.LOAD, stack, retryLat);
				return;
			}

			/* Hit */
			if(stack.state != MESIState.INVALID) {
				this.schedule(MESIEventType.LOAD_FINISH, stack, 0);
			}
			/* Miss */
			else {
				MESIStack newStack = new MESIStack(stack.id, ccache, stack.tag, this, MESIEventType.LOAD_MISS, stack);
				newStack.target = ccache.next;
				this.schedule(MESIEventType.READ_REQUEST, newStack, 0);
			}
		}

		void LOAD_MISS(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.LOAD_MISS(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load miss", stack.id, stack.tag, ccache.name);

			/* Error on read request. Unlock block and retry load. */
			if(stack.isErr) {
				ccache.stats["readRetries"]++;
				stack.dirLock.unlock();
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MESIEventType.LOAD, stack, retryLat);
				return;
			}

			/* Set block state to excl/shared depending on return var 'shared'. Also set the tag of the block. */
			ccache.cache.setBlock(stack.set, stack.way, stack.tag, stack.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);

			/* Continue */
			this.schedule(MESIEventType.LOAD_FINISH, stack, 0);
		}

		void LOAD_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.LOAD_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load finish", stack.id, stack.tag, ccache.name);

			/* Update LRU, unlock, and return. */
			if(!ccache.isMem) {
				ccache.cache.accessBlock(stack.set, stack.way);
			}
			stack.dirLock.unlock();
			stack.ret();
		}

		void STORE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.STORE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store", stack.id, stack.addr, ccache.name);

			/* Call find and lock */
			MESIStack newStack = new MESIStack(stack.id, ccache, stack.addr, this, MESIEventType.STORE_ACTION, stack);
			newStack.isBlocking = false;
			newStack.isRead = false;
			newStack.isRetry = stack.isRetry;
			this.schedule(MESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void STORE_ACTION(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.STORE_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store action", stack.id, stack.tag, ccache.name);

			/* Error locking */
			if(stack.isErr) {
				ccache.stats["writeRetries"]++;
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MESIEventType.STORE, stack, retryLat);
				return;
			}

			/* Hit - status=M/E */
			if(stack.state == MESIState.MODIFIED || stack.state == MESIState.EXCLUSIVE) {
				this.schedule(MESIEventType.STORE_FINISH, stack, 0);
			}
			/* Miss - status=S/I */
			else {
				MESIStack newStack = new MESIStack(stack.id, ccache, stack.tag, this, MESIEventType.STORE_FINISH, stack);
				newStack.target = ccache.next;
				this.schedule(MESIEventType.WRITE_REQUEST, newStack, 0);
			}
		}

		void STORE_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.STORE_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store finish", stack.id, stack.tag, ccache.name);

			/* Error in write request, unlock block and retry store. */
			if(stack.isErr) {
				ccache.stats["writeRetries"]++;
				stack.dirLock.unlock();
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MESIEventType.STORE, stack, retryLat);
				return;
			}

			/* Update LRU, tag/status, unlock, and return. */
			if(!ccache.isMem) {
				ccache.cache.accessBlock(stack.set, stack.way);
				ccache.cache.setBlock(stack.set, stack.way, stack.tag, MESIState.MODIFIED);
			}
			stack.dirLock.unlock();
			stack.ret();
		}

		void EVICT(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;

			/* Default ret value */
			ret.isErr = false;

			/* Get block info */
			ccache.getBlock(stack.set, stack.way, stack.tag, stack.state);
			assert(stack.state != MESIState.INVALID || !ccache.getDir().isSharedOrOwned(stack.set, stack.way));
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict (set=%d, way=%d, state=%s)",
					stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);

			/* Save some data */
			stack.srcSet = stack.set;
			stack.srcWay = stack.way;
			stack.srcTag = stack.tag;
			stack.target = target = ccache.next;

			/* Send write request to all sharers */
			MESIStack newStack = new MESIStack(stack.id, ccache, 0, this, MESIEventType.EVICT_ACTION, stack);
			newStack.except = null;
			newStack.set = stack.set;
			newStack.way = stack.way;
			this.schedule(MESIEventType.INVALIDATE, newStack, 0);
		}

		void EVICT_ACTION(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict action", stack.id, stack.tag, ccache.name);

			/* status = I */
			if(stack.state == MESIState.INVALID) {
				this.schedule(MESIEventType.EVICT_FINISH, stack, 0);
			} 
			/* status = M */
			else if(stack.state == MESIState.MODIFIED) {
				this.schedule(MESIEventType.EVICT_RECEIVE, stack, 2);
				stack.isWriteback = true;
			}
			/* status = S/E */
			else {
				this.schedule(MESIEventType.EVICT_RECEIVE, stack, 2);
			}
		}

		void EVICT_RECEIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict receive", stack.id, stack.tag, target.name);

			/* Find and lock */
			MESIStack newStack = new MESIStack(stack.id, target, stack.srcTag, this, MESIEventType.EVICT_WRITEBACK, stack);
			newStack.isBlocking = false;
			newStack.isRead = false;
			newStack.isRetry = false;
			this.schedule(MESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void EVICT_WRITEBACK(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_WRITEBACK(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback", stack.id, stack.tag, target.name);

			/* Error locking block */
			if(stack.isErr) {
				ret.isErr = true;
				this.schedule(MESIEventType.EVICT_REPLY, stack, 0);
				return;
			}

			/* No writeback */
			if(!stack.isWriteback) {
				this.schedule(MESIEventType.EVICT_PROCESS, stack, 0);
			}
			/* Writeback */
			else {				
				MESIStack newStack = new MESIStack(stack.id, target, 0, this, MESIEventType.EVICT_WRITEBACK_EXCLUSIVE, stack);
				newStack.except = ccache;
				newStack.set = stack.set;
				newStack.way = stack.way;
				this.schedule(MESIEventType.INVALIDATE, newStack, 0);
			}
		}

		void EVICT_WRITEBACK_EXCLUSIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_WRITEBACK_EXCLUSIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback exclusive", stack.id, stack.tag, target.name);

			/* Status = S/I */
			assert(stack.state != MESIState.INVALID, to!(string)(stack));
			if(stack.state == MESIState.SHARED) {
				MESIStack newStack = new MESIStack(stack.id, target, stack.tag, this, MESIEventType.EVICT_WRITEBACK_FINISH, stack);
				newStack.target = target.next;
				this.schedule(MESIEventType.WRITE_REQUEST, newStack, 0);
			} 
			/* Status = M/E */
			else {
				this.schedule(MESIEventType.EVICT_WRITEBACK_FINISH, stack, 0);
			}
		}

		void EVICT_WRITEBACK_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_WRITEBACK_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback finish", stack.id, stack.tag, target.name);

			/* Error in write request */
			if(stack.isErr) {
				ret.isErr = true;
				stack.dirLock.unlock();
				this.schedule(MESIEventType.EVICT_REPLY, stack, 0);
				return;
			}

			/* Set tag, status and lru */
			if(!target.isMem) {
				target.cache.setBlock(stack.set, stack.way, stack.tag, MESIState.MODIFIED);
				target.cache.accessBlock(stack.set, stack.way);
			}
			this.schedule(MESIEventType.EVICT_PROCESS, stack, 0);
		}

		void EVICT_PROCESS(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_PROCESS(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict process", stack.id, stack.tag, target.name);

			/* Remove sharer, owner, and unlock */
			DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			dirEntry.unsetSharer(ccache);
			if(dirEntry.owner == ccache) {
				dirEntry.owner = null;
			}
			stack.dirLock.unlock();

			this.schedule(MESIEventType.EVICT_REPLY, stack, 0);
		}

		void EVICT_REPLY(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict reply", stack.id, stack.tag, target.name);

			this.schedule(MESIEventType.EVICT_REPLY_RECEIVE, stack, 2);
		}

		void EVICT_REPLY_RECEIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_REPLY_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict reply receive", stack.id, stack.tag, ccache.name);

			/* Invalidate block if there was no error. */
			if(!stack.isErr) {
				ccache.cache.setBlock(stack.srcSet, stack.srcWay, 0, MESIState.INVALID);
			}
			assert(!ccache.getDir().isSharedOrOwned(stack.srcSet, stack.srcWay));
			this.schedule(MESIEventType.EVICT_FINISH, stack, 0);
		}

		void EVICT_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.EVICT_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void READ_REQUEST(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request", stack.id, stack.addr, ccache.name);

			/* Default return values*/
			ret.isShared = false;
			ret.isErr = false;

			/* Send request to target */
			assert(ccache.next == target || target.next == ccache);
			this.schedule(MESIEventType.READ_REQUEST_RECEIVE, stack, 8);
		}

		void READ_REQUEST_RECEIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request receive", stack.id, stack.addr, target.name);

			/* Find and lock */
			MESIStack newStack = new MESIStack(stack.id, target, stack.addr, this, MESIEventType.READ_REQUEST_ACTION, stack);
			newStack.isBlocking = (target.next == ccache);
			newStack.isRead = true;
			newStack.isRetry = false;
			this.schedule(MESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void READ_REQUEST_ACTION(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request action", stack.id, stack.tag, target.name);

			/* Check block locking error. */
			if(stack.isErr) {
				ret.isErr = true;
				this.schedule(MESIEventType.READ_REQUEST_REPLY, stack, 0);
				return;
			}

			this.schedule(ccache.next == target ? MESIEventType.READ_REQUEST_UPDOWN : MESIEventType.READ_REQUEST_DOWNUP, stack, 0);
		}

		void READ_REQUEST_UPDOWN(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_UPDOWN(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown", stack.id, stack.tag, target.name);

			stack.pending = 1;

			/* Status = M/E/S */
			if(stack.state != MESIState.INVALID) {
				DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				
				/* Check: block requested by ccache is not already owned by ccache */
				assert(dirEntry.owner != ccache, format("ccache: %s, target: %s, dirEntry.owner: %s (set=%d, way=%d)", 
								ccache.name, target.name, dirEntry.owner.name, stack.set % target.getDir().xSize, stack.way));
				
				/* Send read request to owners other than ccache for the block. */
				if(dirEntry.owner !is null && dirEntry.owner != ccache) {
					/* Send read request */
					stack.pending++;
					MESIStack newStack = new MESIStack(stack.id, target, stack.tag, this, MESIEventType.READ_REQUEST_UPDOWN_FINISH, stack);
					newStack.target = dirEntry.owner;
					this.schedule(MESIEventType.READ_REQUEST, newStack, 0);
				}
				this.schedule(MESIEventType.READ_REQUEST_UPDOWN_FINISH, stack, 0);
			}
			/* Status = I */
			else {
				assert(!target.getDir().isSharedOrOwned(stack.set, stack.way));
				MESIStack newStack = new MESIStack(stack.id, target, stack.tag, this, MESIEventType.READ_REQUEST_UPDOWN_MISS, stack);
				newStack.target = target.next;
				this.schedule(MESIEventType.READ_REQUEST, newStack, 0);
			}
		}

		void READ_REQUEST_UPDOWN_MISS(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_UPDOWN_MISS(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown miss", stack.id, stack.tag, target.name);

			/* Check error */
			if(stack.isErr) {
				stack.dirLock.unlock();
				ret.isErr = true;
				this.schedule(MESIEventType.READ_REQUEST_REPLY, stack, 0);
				return;
			}

			/* Set block state to excl/shared depending on the return value 'shared'
			 * that comes from a read request into the next cache level.
			 * Also set the tag of the block. */
			target.cache.setBlock(stack.set, stack.way, stack.tag, stack.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
			this.schedule(MESIEventType.READ_REQUEST_UPDOWN_FINISH, stack, 0);
		}

		void READ_REQUEST_UPDOWN_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_UPDOWN_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;

			/* Ignore while pending requests */
			assert(stack.pending > 0);
			stack.pending--;
			if(stack.pending > 0) {
				return;
			}
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown finish", stack.id, stack.tag, target.name);
			
			if(!target.isMem) {
				/* Set owner to null for the directory entry if not owned by ccache. */
				DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				if(dirEntry.owner !is null && dirEntry.owner != ccache) {
					dirEntry.owner = null;
				}

				/* Set ccache as sharer, and check whether there is other cache sharing it. */
				bool isShared = false;
				dirEntry.setSharer(ccache);
				if(dirEntry.sharers.length > 1) {
					isShared = true;
				}
				
				/* if the block is not shared by other caches, set ccache as owner.
				 * Otherwise, notify requester that the block is shared by setting the 'shared' return value to true. */
				ret.isShared = isShared;
				if(!isShared) {
					dirEntry.owner = ccache;
				}
			}

			/* Respond with data, update LRU, unlock */
			if(!target.isMem) {
				target.cache.accessBlock(stack.set, stack.way);
			}
			stack.dirLock.unlock();
			this.schedule(MESIEventType.READ_REQUEST_REPLY, stack, 0);
		}

		void READ_REQUEST_DOWNUP(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_DOWNUP(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request downup", stack.id, stack.tag, target.name);

			/* Check: status must not be invalid.
			 * By default, only one pending request. */
			assert(stack.state != MESIState.INVALID);
			stack.pending = 1;

			/* Send a read request to the owner of the block. */
			DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			if(dirEntry.owner !is null) {
				stack.pending++;
				MESIStack newStack = new MESIStack(stack.id, target, stack.tag, this, MESIEventType.READ_REQUEST_DOWNUP_FINISH, stack);
				newStack.target = dirEntry.owner;
				this.schedule(MESIEventType.READ_REQUEST, newStack, 0);
			}

			this.schedule(MESIEventType.READ_REQUEST_DOWNUP_FINISH, stack, 0);
		}

		void READ_REQUEST_DOWNUP_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_DOWNUP_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;

			/* Ignore while pending requests */
			assert(stack.pending > 0);
			stack.pending--;
			if(stack.pending > 0) {
				return;
			}
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request downup finish", stack.id, stack.tag, target.name);

			/* Set owner of the block to null. */
			DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			dirEntry.owner = null;

			/* Set status to S, update LRU, unlock */
			target.cache.setBlock(stack.set, stack.way, stack.tag, MESIState.SHARED);
			target.cache.accessBlock(stack.set, stack.way);
			stack.dirLock.unlock();
			this.schedule(MESIEventType.READ_REQUEST_REPLY, stack, 0);
		}

		void READ_REQUEST_REPLY(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request reply", stack.id, stack.tag, target.name);

			assert(ccache.next == target || target.next == ccache);
			this.schedule(MESIEventType.READ_REQUEST_FINISH, stack, 2);
		}

		void READ_REQUEST_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.READ_REQUEST_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void WRITE_REQUEST(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request", stack.id, stack.addr, ccache.name);

			/* Default return values */
			ret.isErr = false;

			/* Send request to target */
			assert(ccache.next == target || target.next == ccache);
			this.schedule(MESIEventType.WRITE_REQUEST_RECEIVE, stack, 2);
		}

		void WRITE_REQUEST_RECEIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request receive", stack.id, stack.addr, target.name);

			/* Find and lock */
			MESIStack newStack = new MESIStack(stack.id, target, stack.addr, this, MESIEventType.WRITE_REQUEST_ACTION, stack);
			newStack.isBlocking = target.next == ccache;
			newStack.isRead = false;
			newStack.isRetry = false;
			this.schedule(MESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void WRITE_REQUEST_ACTION(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request action", stack.id, stack.tag, target.name);

			/* Check lock error. */
			if(stack.isErr) {
				ret.isErr = true;
				this.schedule(MESIEventType.WRITE_REQUEST_REPLY, stack, 0);
				return;
			}

			/* Invalidate the rest of upper level sharers */
			MESIStack newStack = new MESIStack(stack.id, target, 0, this, MESIEventType.WRITE_REQUEST_EXCLUSIVE, stack);
			newStack.except = ccache;
			newStack.set = stack.set;
			newStack.way = stack.way;
			this.schedule(MESIEventType.INVALIDATE, newStack, 0);
		}

		void WRITE_REQUEST_EXCLUSIVE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_EXCLUSIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%s %s write request exclusive", stack.id, stack.tag, target.name);

			this.schedule(ccache.next == target ? MESIEventType.WRITE_REQUEST_UPDOWN : MESIEventType.WRITE_REQUEST_DOWNUP, stack, 0);
		}

		void WRITE_REQUEST_UPDOWN(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_UPDOWN(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request updown", stack.id, stack.tag, target.name);

			/* status = M/E */
			if(stack.state == MESIState.MODIFIED || stack.state == MESIState.EXCLUSIVE) {
				this.schedule(MESIEventType.WRITE_REQUEST_UPDOWN_FINISH, stack, 0);
			} 
			/* status = S/I */
			else {
				MESIStack newStack = new MESIStack(stack.id, target, stack.tag, this, MESIEventType.WRITE_REQUEST_UPDOWN_FINISH, stack);
				newStack.target = target.next;
				this.schedule(MESIEventType.WRITE_REQUEST, newStack, 0);
			}
		}

		void WRITE_REQUEST_UPDOWN_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_UPDOWN_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request updown finish", stack.id, stack.tag, target.name);

			/* Error in write request to next cache level */
			if(stack.isErr) {
				ret.isErr = true;
				stack.dirLock.unlock();
				this.schedule(MESIEventType.WRITE_REQUEST_REPLY, stack, 0);
				return;
			}
			
			if(!target.isMem) {
				/* Set ccache as sharer and owner. */
				DirEntry!(MESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				dirEntry.setSharer(ccache);
				dirEntry.owner = ccache;
			}

			/* Update LRU, set status: M->M, E/S/I->E */
			if(!target.isMem) {
				target.cache.accessBlock(stack.set, stack.way);
				if(stack.state != MESIState.MODIFIED) {
					target.cache.setBlock(stack.set, stack.way, stack.tag, MESIState.EXCLUSIVE);
				}
			}
			
			/* Unlock. */
			stack.dirLock.unlock();
			this.schedule(MESIEventType.WRITE_REQUEST_REPLY, stack, 0);
		}

		void WRITE_REQUEST_DOWNUP(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_DOWNUP(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request downup", stack.id, stack.tag, target.name);
			
			/* Set status to I, unlock */
			assert(stack.state != MESIState.INVALID);
			assert(!target.getDir().isSharedOrOwned(stack.set, stack.way));
			target.cache.setBlock(stack.set, stack.way, 0, MESIState.INVALID);
			stack.dirLock.unlock();
			this.schedule(MESIEventType.WRITE_REQUEST_REPLY, stack, 0);
		}

		void WRITE_REQUEST_REPLY(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request reply", stack.id, stack.tag, target.name);

			assert(ccache.next == target || target.next == ccache);
			this.schedule(MESIEventType.WRITE_REQUEST_FINISH, stack, 2);
		}

		void WRITE_REQUEST_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.WRITE_REQUEST_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void INVALIDATE(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.INVALIDATE(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;

			/* Get block info */
			ccache.getBlock(stack.set, stack.way, stack.tag, stack.state);
			logging[LogCategory.DEBUG].infof("%d 0x%x %s invalidate (set=%d, way=%d, state=%s)",
					stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);
			stack.pending = 1;

			/* Send write request to all upper level sharers but ccache */
			DirEntry!(MESIState) dirEntry = ccache.getDirEntry(stack.set, stack.way);
			
			MESICache[] sharersToRemove;
			
			foreach(sharer; dirEntry.sharers) {
				/* Skip 'except' */
				if(sharer != stack.except) {
					sharersToRemove ~= sharer;
				}
			}
			
			foreach(sharer; sharersToRemove) {				
				/* Clear sharer and owner */
				dirEntry.unsetSharer(sharer);
				if(dirEntry.owner == sharer) {
					dirEntry.owner = null;
				}

				/* Send write request upwards */
				MESIStack newStack = new MESIStack(stack.id, ccache, stack.tag, this, MESIEventType.INVALIDATE_FINISH, stack);
				newStack.target = sharer;
				this.schedule(MESIEventType.WRITE_REQUEST, newStack, 0);
				stack.pending++;
			}

			this.schedule(MESIEventType.INVALIDATE_FINISH, stack, 0);
		}

		void INVALIDATE_FINISH(MESIEventType eventType, MESIStack stack, ulong when) {
			logging[LogCategory.MESI].infof("%s.INVALIDATE_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MESIStack ret = stack.retStack;
			MESICache ccache = stack.ccache;
			MESICache target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s invalidate finish", stack.id, stack.tag, ccache.name);

			/* Ignore while pending */
			assert(stack.pending > 0);
			stack.pending--;
			if(stack.pending > 0) {
				return;
			}

			stack.ret();
		}
}