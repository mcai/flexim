module flexim.memsys.moesi;

import flexim.all;

uint retry_lat(ICache)(ICache ccache) {
	return ccache.hitLatency + uniform(0, ccache.hitLatency);
}

class MOESIState: CacheBlockState {
	this(string name) {
		super(name);
	}

	override string toString() {
		return format("%s", this.name);
	}

	static this() {
		MODIFIED = new MOESIState("MODIFIED");
		OWNED = new MOESIState("OWNED");
		EXCLUSIVE = new MOESIState("EXCLUSIVE");
		SHARED = new MOESIState("SHARED");
		INVALID = new MOESIState("INVALID");
	}

	static MOESIState MODIFIED;
	static MOESIState OWNED;
	static MOESIState EXCLUSIVE;
	static MOESIState SHARED;
	static MOESIState INVALID;
}

enum MOESIEventType: string {
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

class MOESICache: Node, ICache!(MOESIState) {
	alias MOESIState StateT;

	alias CacheBlock!(StateT) CacheBlockT;
	alias CacheSet!(StateT) CacheSetT;
	alias Cache!(StateT) CacheT;

	alias CacheQueueEntry!(StateT) CacheQueueEntryT;

	alias ICache!(StateT) ICacheT;

	this(CacheHierarchyT cacheHierarchy, string name, bool isPrivate, uint blockSize, uint assoc, uint numSets, uint hitLatency, uint missLatency, bool lowestPrivate, bool llc) {
		super(name, isPrivate);

		this.cacheHierarchy = cacheHierarchy;

		this.cache = new CacheT(blockSize, assoc, numSets, MOESIState.INVALID);
		
		this.cache.dir.monitors ~= new CacheMonitoringCallback(&this.xx);

		this.hitLatency = hitLatency;
		this.missLatency = missLatency;

		this.lowestPrivate = lowestPrivate;
		this.llc = llc;

		this.stats = new Stats();

		this.upperInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleUpperInterconnectMessage);
		this.lowerInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleLowerInterconnectMessage);
	}
	
	void xx(uint set, uint way, CacheMonitoringEventType eventType) {
		logging[LogCategory.DEBUG].infof("%s %s (set=%d, way=%d)", this.name, eventType, set, way);
	}

	void dumpConfigs(string indent) {
		logging[LogCategory.CONFIG].infof(indent ~ "[%s] number of sets: %d, block size: %d, assoc: %d, hit latency: %d, miss latency: %d", this.name, this.cache.numSets, this.cache.blockSize,
				this.cache.assoc, this.hitLatency, this.missLatency);
	}

	void dumpStats(string indent) {
		string str;

		str ~= format(indent ~ "[%s] -----\n", this.name);
		
		void appendStatStr(T)(string key, T value) {
			str ~= format(indent ~ "  " ~ "%s: %s\n", key, to!string(value));
		}
		
		appendStatStr("Accesses", this.stats["accesses"]);
		appendStatStr("Hits", this.stats["hits"]);
		appendStatStr("Misses", this.stats["accesses"] - this.stats["hits"]);
		appendStatStr("HitRatio", this.stats["accesses"] != 0 ? cast(double)(this.stats["hits"]) / cast(double)(this.stats["accesses"]) : 0.0);
		appendStatStr("Evictions", this.stats["evictions"]);
		appendStatStr("Retries", this.stats["readRetries"] + this.stats["writeRetries"]);
		appendStatStr("ReadRetries", this.stats["readRetries"]);
		appendStatStr("WriteRetries", this.stats["writeRetries"]);
		appendStatStr("NoRetryAccesses", this.stats["noRetryAccesses"]);
		appendStatStr("NoRetryHits", this.stats["noRetryHits"]);
		appendStatStr("NoRetryMisses", this.stats["noRetryAccesses"] - this.stats["noRetryHits"]);
		appendStatStr("NoRetryHitRatio", this.stats["noRetryAccesses"] != 0 ? cast(double)(this.stats["noRetryHits"]) / cast(double)(this.stats["noRetryAccesses"]) : 0.0);
		appendStatStr("NoRetryReads", this.stats["noRetryReads"]);
		appendStatStr("NoRetryReadHits", this.stats["noRetryReadHits"]);
		appendStatStr("NoRetyrReadMisses", this.stats["noRetryReads"] - this.stats["noRetryReadHits"]);
		appendStatStr("NoRetryWrites", this.stats["noRetryWrites"]);
		appendStatStr("NoRetryWriteHits", this.stats["noRetryWriteHits"]);
		appendStatStr("NoRetryWriteMisses", this.stats["noRetryWrites"] - this.stats["noRetryWriteHits"]);
		appendStatStr("Reads", this.stats["reads"]);
		appendStatStr("BlockingReads", this.stats["blockingReads"]);
		appendStatStr("NonblockingReads", this.stats["nonblockingReads"]);
		appendStatStr("ReadHits", this.stats["readHits"]);
		appendStatStr("ReadMisses", this.stats["reads"] - this.stats["readHits"]);
		appendStatStr("Writes", this.stats["writes"]);
		appendStatStr("BlockingWrites", this.stats["blockingWrites"]);
		appendStatStr("NonblockingWrites", this.stats["nonblockingWrites"]);
		appendStatStr("WriteHits", this.stats["writeHits"]);
		appendStatStr("WriteMisses", this.stats["writes"] - this.stats["writeHits"]);

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
		logging[LogCategory.MOESI].infof("%s.handleUpperInterconnectMessage(%s, %s)", this.name, interconnect, m);

		if(m.request.type == RequestType.READ) {
			CacheQueueEntryT queueEntry = new CacheQueueEntryT(interconnect, null, sender, m.request);
			this.pendingRequests[m.request.addr] ~= queueEntry;
			
			MOESIStack newStack = new MOESIStack(m.request.id, this, m.request.addr, new Callback1!(Addr)(m.request.addr, &this.endReadAccess));
			this.cacheHierarchy.eventQueue.schedule(MOESIEventType.LOAD, newStack, 0);
		} else if(m.request.type == RequestType.WRITE) {
			MOESIStack newStack = new MOESIStack(m.request.id, this, m.request.addr, new Callback1!(Addr)(m.request.addr, null));
			this.cacheHierarchy.eventQueue.schedule(MOESIEventType.STORE, newStack, 0);
		}
	}

	void handleLowerInterconnectMessage(Interconnect interconnect, Message m, Node sender) {
		logging[LogCategory.MOESI].infof("%s.handleLowerInterconnectMessage(%s, %s)", this.name, interconnect, m);
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
	
	DirT getDir(Addr phaddr) {
		return this.cache.dir;
	}
	
	DirEntryT getDirEntry(uint set, uint way) {
		return this.cache.dir.dirEntries[set][way];
	}
	
	DirLock getDirLock(uint set) {
		return this.cache.dir.dirLocks[set];
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

	override string name() {
		return super.name;
	}

	ICacheT next() {
		return this.m_next;
	}

	void next(ICacheT value) {
		this.m_next = value;
	}

	CacheHierarchyT cacheHierarchy() {
		return this.m_cacheHierarchy;
	}

	void cacheHierarchy(CacheHierarchyT value) {
		this.m_cacheHierarchy = value;
	}
	
	Stats stats() {
		return this.m_stats;
	}
	
	void stats(Stats value) {
		this.m_stats = value;
	}
	
	override CacheT getCache() {
		return this.cache;
	}

	CacheT cache;

	uint m_hitLatency;
	uint m_missLatency;

	bool lowestPrivate;
	bool llc;

	private ICacheT m_next;

	CacheHierarchyT m_cacheHierarchy;

	CacheQueueEntryT[][Addr] pendingRequests;
	
	private Stats m_stats;
}

class MOESIMemory: MOESICache {
	alias MOESIState StateT;

	alias ICache!(StateT) ICacheT;

	this(CacheHierarchyT cacheHierarchy, string name, uint readLatency, uint writeLatency) {
		super(cacheHierarchy, name, false, 64, 4, 1024, 0, 400, false, false);

		this.readLatency = readLatency;
		this.writeLatency = writeLatency;

		this.upperInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleUpperInterconnectMessage);
	}

	void handleUpperInterconnectMessage(Interconnect interconnect, Message m, Node sender) {
		logging[LogCategory.MOESI].infof("%s.handleUpperInterconnectMessage(%s, %s, %s)", this.name, interconnect, m, sender);

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
		assert(!way);
		tag = set << this.logBlockSize;
		state = MOESIState.EXCLUSIVE;
	}
	
//	override DirT getDir(Addr phaddr) { //TODO
//		return this.cacheHierarchy.mmu.getDir(phaddr);
//	}
	
	override DirEntryT getDirEntry(uint set, uint way) {
		DirT dir = this.getDir(set << this.logBlockSize);
		set = set % dir.xSize;
		return dir.dirEntries[set][way];
	}
	
	override DirLock getDirLock(uint set) {
		DirT dir = this.getDir(set << this.logBlockSize);
		
		assert(dir !is null);
		
		set = set % dir.xSize;
		return dir.dirLocks[set];
	}

	override bool isMem() {
		return true;
	}

	override string name() {
		return super.name;
	}

	ICacheT next() {
		return null;
	}
	
	override CacheT getCache() {
		return this.cache;
	}
}

ulong moesi_stack_id = 0;

class MOESIStack {
	this(ulong id, ICache!(MOESIState) ccache, uint addr, Callback callback) {
		this.id = id;
		this.ccache = ccache;
		this.addr = addr;
		this.callback = callback;
	}

	this(ulong id, ICache!(MOESIState) ccache, uint addr, MOESIEventQueue eventQueue, MOESIEventType retEvent, MOESIStack retStack) {
		this.retEvent = retEvent;
		this.retStack = retStack;

		this(id, ccache, addr, new Callback3!(MOESIEventType, MOESIStack, ulong)(retEvent, retStack, 0, &eventQueue.schedule));
	}

	void ret() {
		if(this.callback !is null) {
			this.callback.invoke();
		}
	}

	override string toString() {
		return format(
				"MOESIStack[id: %d, ccache: %s, target: %s, except: %s, addr: 0x%x, set: %d, way: %d, tag: %d, srcSet: %d, srcWay: %d, srcTag: %d, dirLock: %s, state: %s, pending: %d, isErr: %s, isShared: %s, isRead: %s, isBlocking: %s, isWriteback: %s, isEviction: %s, isRetry: %s, retEvent: %s, retStack ID: %s]",
				this.id, this.ccache !is null ? this.ccache.name : "NULL", this.target !is null ? this.target.name : "NULL", this.except !is null ? this.except.name : "NULL", this.addr, this.set,
				this.way, this.tag, this.srcSet, this.srcWay, this.srcTag, this.dirLock !is null ? to!(string)(this.dirLock) : "NULL", this.state !is null ? to!(string)(this.state) : "NULL",
				this.pending, this.isErr, this.isShared, this.isRead, this.isBlocking, this.isWriteback, this.isEviction, this.isRetry, this.retEvent !is null ? to!(string)(this.retEvent) : "NULL",
				this.retStack !is null ? to!(string)(this.retStack.id) : "N/A");
	}

	ulong id;

	ICache!(MOESIState) ccache, target, except;

	uint addr, set, way, tag;
	uint srcSet, srcWay, srcTag;

	DirLock dirLock;

	MOESIState state;

	int pending;

	bool isErr;
	bool isShared;
	bool isRead;
	bool isBlocking;
	bool isWriteback;
	bool isEviction;
	bool isRetry;

	Callback callback;

	MOESIEventType retEvent;
	MOESIStack retStack;
}

class MOESIEventQueue: EventQueue!(MOESIEventType, MOESIStack) {
	public:
		this() {
			super("MOESIEventQueue");

			this.registerHandler(MOESIEventType.FIND_AND_LOCK, &this.FIND_AND_LOCK);
			this.registerHandler(MOESIEventType.FIND_AND_LOCK_FINISH, &this.FIND_AND_LOCK_FINISH);

			this.registerHandler(MOESIEventType.LOAD, &this.LOAD);
			this.registerHandler(MOESIEventType.LOAD_ACTION, &this.LOAD_ACTION);
			this.registerHandler(MOESIEventType.LOAD_MISS, &this.LOAD_MISS);
			this.registerHandler(MOESIEventType.LOAD_FINISH, &this.LOAD_FINISH);

			this.registerHandler(MOESIEventType.STORE, &this.STORE);
			this.registerHandler(MOESIEventType.STORE_ACTION, &this.STORE_ACTION);
			this.registerHandler(MOESIEventType.STORE_FINISH, &this.STORE_FINISH);

			this.registerHandler(MOESIEventType.EVICT, &this.EVICT);
			this.registerHandler(MOESIEventType.EVICT_ACTION, &this.EVICT_ACTION);
			this.registerHandler(MOESIEventType.EVICT_RECEIVE, &this.EVICT_RECEIVE);
			this.registerHandler(MOESIEventType.EVICT_WRITEBACK, &this.EVICT_WRITEBACK);
			this.registerHandler(MOESIEventType.EVICT_WRITEBACK_EXCLUSIVE, &this.EVICT_WRITEBACK_EXCLUSIVE);
			this.registerHandler(MOESIEventType.EVICT_WRITEBACK_FINISH, &this.EVICT_WRITEBACK_FINISH);
			this.registerHandler(MOESIEventType.EVICT_PROCESS, &this.EVICT_PROCESS);
			this.registerHandler(MOESIEventType.EVICT_REPLY, &this.EVICT_REPLY);
			this.registerHandler(MOESIEventType.EVICT_REPLY_RECEIVE, &this.EVICT_REPLY_RECEIVE);
			this.registerHandler(MOESIEventType.EVICT_FINISH, &this.EVICT_FINISH);

			this.registerHandler(MOESIEventType.READ_REQUEST, &this.READ_REQUEST);
			this.registerHandler(MOESIEventType.READ_REQUEST_RECEIVE, &this.READ_REQUEST_RECEIVE);
			this.registerHandler(MOESIEventType.READ_REQUEST_ACTION, &this.READ_REQUEST_ACTION);
			this.registerHandler(MOESIEventType.READ_REQUEST_UPDOWN, &this.READ_REQUEST_UPDOWN);
			this.registerHandler(MOESIEventType.READ_REQUEST_UPDOWN_MISS, &this.READ_REQUEST_UPDOWN_MISS);
			this.registerHandler(MOESIEventType.READ_REQUEST_UPDOWN_FINISH, &this.READ_REQUEST_UPDOWN_FINISH);
			this.registerHandler(MOESIEventType.READ_REQUEST_DOWNUP, &this.READ_REQUEST_DOWNUP);
			this.registerHandler(MOESIEventType.READ_REQUEST_DOWNUP_FINISH, &this.READ_REQUEST_DOWNUP_FINISH);
			this.registerHandler(MOESIEventType.READ_REQUEST_REPLY, &this.READ_REQUEST_REPLY);
			this.registerHandler(MOESIEventType.READ_REQUEST_FINISH, &this.READ_REQUEST_FINISH);

			this.registerHandler(MOESIEventType.WRITE_REQUEST, &this.WRITE_REQUEST);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_RECEIVE, &this.WRITE_REQUEST_RECEIVE);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_ACTION, &this.WRITE_REQUEST_ACTION);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_EXCLUSIVE, &this.WRITE_REQUEST_EXCLUSIVE);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_UPDOWN, &this.WRITE_REQUEST_UPDOWN);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_UPDOWN_FINISH, &this.WRITE_REQUEST_UPDOWN_FINISH);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_DOWNUP, &this.WRITE_REQUEST_DOWNUP);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_REPLY, &this.WRITE_REQUEST_REPLY);
			this.registerHandler(MOESIEventType.WRITE_REQUEST_FINISH, &this.WRITE_REQUEST_FINISH);

			this.registerHandler(MOESIEventType.INVALIDATE, &this.INVALIDATE);
			this.registerHandler(MOESIEventType.INVALIDATE_FINISH, &this.INVALIDATE_FINISH);
		}

		void FIND_AND_LOCK(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.FIND_AND_LOCK(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s find and lock (blocking=%s)",
					stack.id, stack.addr, ccache.name, stack.isBlocking);

			/* Default return values */
			ret.isErr = false;
			ret.set = 0;
			ret.way = 0;
			ret.state = MOESIState.INVALID;
			ret.tag = 0;

			/* Look for block. */
			bool hit = ccache.findBlock(stack.addr, stack.set, stack.way, stack.tag, stack.state);
			if(hit) {
				logging[LogCategory.DEBUG].infof("  %d 0x%x %s hit: set=%d, way=%d, state=%s",
						stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);
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
				stack.way = ccache.getCache().replaceBlock(stack.set);
				ccache.getCache().getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state != MOESIState.INVALID || !ccache.getDir().isSharedOrOwned(stack.set, stack.way), 
						format("stack.state=%s, ccache.getDirEntry(set=%d, way=%d)=%s", 
								stack.state, stack.set, stack.way, ccache.getDirEntry(stack.set, stack.way)));
				logging[LogCategory.DEBUG].infof("  %d 0x%x %s miss -> lru: set=%d, way=%d, state=%s",
						stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);
			}

			/* Lock entry */
			stack.dirLock = ccache.getDirLock(stack.set);
			if(stack.dirLock.locked && !stack.isBlocking) {
				logging[LogCategory.DEBUG].infof("  %d 0x%x %s block already locked: set=%d, way=%d",
						stack.id, stack.tag, ccache.name, stack.set, stack.way);
				ret.isErr = true;
				stack.ret();
				return;
			}
			if(!stack.dirLock.lock(new Callback3!(MOESIEventType, MOESIStack, ulong)(MOESIEventType.FIND_AND_LOCK, stack, 0, &this.schedule))) {
				return;
			}

			/* Entry is locked. Record the transient tag so that a subsequent lookup
			 * detects that the block is being brought. */
			if(!ccache.isMem) {
				ccache.getCache()[stack.set][stack.way].transientTag = stack.tag;
			}

			/* On miss, evict if victim is a valid block. */
			if(!hit && stack.state != MOESIState.INVALID) {
				stack.isEviction = true;

				MOESIStack newStack = new MOESIStack(stack.id, ccache, 0, this, MOESIEventType.FIND_AND_LOCK_FINISH, stack);
				newStack.set = stack.set;
				newStack.way = stack.way;
				this.schedule(MOESIEventType.EVICT, newStack, ccache.hitLatency);
			}
			else {
				/* Access latency */
				this.schedule(MOESIEventType.FIND_AND_LOCK_FINISH, stack, ccache.hitLatency);
			}
		}

		void FIND_AND_LOCK_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.FIND_AND_LOCK_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s find and lock finish (err=%s)",
					stack.id, stack.tag, ccache.name, stack.isErr);

			uint dumbTag = 0;

			/* If evict produced err, return err */
			if(stack.isErr) {
				ccache.getCache().getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state != MOESIState.INVALID);
				assert(stack.isEviction);
				ret.isErr = true;
				stack.dirLock.unlock();
				stack.ret();
				return;
			}

			/* Eviction */
			if(stack.isEviction) {
				ccache.stats["evictions"]++;
				ccache.getCache().getBlock(stack.set, stack.way, dumbTag, stack.state);
				assert(stack.state == MOESIState.INVALID);
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

		void LOAD(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.LOAD(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load", stack.id, stack.addr, ccache.name);

			/* Call find and lock */
			MOESIStack newStack = new MOESIStack(stack.id, ccache, stack.addr, this, MOESIEventType.LOAD_ACTION, stack);
			newStack.isBlocking = false;
			newStack.isRead = true;
			newStack.isRetry = stack.isRetry;
			this.schedule(MOESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void LOAD_ACTION(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.LOAD_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
				
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load action", stack.id, stack.tag, ccache.name);

			/* Error locking */
			if(stack.isErr) {
				ccache.stats["readRetries"]++;
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MOESIEventType.LOAD, stack, retryLat);
				return;
			}

			/* Hit */
			if(stack.state != MOESIState.INVALID) {
				this.schedule(MOESIEventType.LOAD_FINISH, stack, 0);
			}
			/* Miss */
			else {
				MOESIStack newStack = new MOESIStack(stack.id, ccache, stack.tag, this, MOESIEventType.LOAD_MISS, stack);
				newStack.target = ccache.next;
				this.schedule(MOESIEventType.READ_REQUEST, newStack, 0);
			}
		}

		void LOAD_MISS(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.LOAD_MISS(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load miss", stack.id, stack.tag, ccache.name);

			/* Error on read request. Unlock block and retry load. */
			if(stack.isErr) {
				ccache.stats["readRetries"]++;
				stack.dirLock.unlock();
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MOESIEventType.LOAD, stack, retryLat);
				return;
			}

			/* Set block state to excl/shared depending on return var 'shared'. Also set the tag of the block. */
			ccache.getCache().setBlock(stack.set, stack.way, stack.tag, stack.isShared ? MOESIState.SHARED : MOESIState.EXCLUSIVE);

			/* Continue */
			this.schedule(MOESIEventType.LOAD_FINISH, stack, 0);
		}

		void LOAD_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.LOAD_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s load finish", stack.id, stack.tag, ccache.name);

			/* Update LRU, unlock, and return. */
			if(!ccache.isMem) {
				ccache.getCache().accessBlock(stack.set, stack.way);
			}
			stack.dirLock.unlock();
			stack.ret();
		}

		void STORE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.STORE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store", stack.id, stack.addr, ccache.name);

			/* Call find and lock */
			MOESIStack newStack = new MOESIStack(stack.id, ccache, stack.addr, this, MOESIEventType.STORE_ACTION, stack);
			newStack.isBlocking = false;
			newStack.isRead = false;
			newStack.isRetry = stack.isRetry;
			this.schedule(MOESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void STORE_ACTION(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.STORE_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store action", stack.id, stack.tag, ccache.name);

			/* Error locking */
			if(stack.isErr) {
				ccache.stats["writeRetries"]++;
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MOESIEventType.STORE, stack, retryLat);
				return;
			}

			/* Hit - status=M/E */
			if(stack.state == MOESIState.MODIFIED || stack.state == MOESIState.EXCLUSIVE) {
				this.schedule(MOESIEventType.STORE_FINISH, stack, 0);
			}
			/* Miss - status=O/S/I */
			else {
				MOESIStack newStack = new MOESIStack(stack.id, ccache, stack.tag, this, MOESIEventType.STORE_FINISH, stack);
				newStack.target = ccache.next;
				this.schedule(MOESIEventType.WRITE_REQUEST, newStack, 0);
			}
		}

		void STORE_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.STORE_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s store finish", stack.id, stack.tag, ccache.name);

			/* Error in write request, unlock block and retry store. */
			if(stack.isErr) {
				ccache.stats["writeRetries"]++;
				stack.dirLock.unlock();
				uint retryLat = retry_lat(ccache);
				logging[LogCategory.DEBUG].infof("  lock error, retrying in %d cycles", retryLat);
				stack.isRetry = true;
				this.schedule(MOESIEventType.STORE, stack, retryLat);
				return;
			}

			/* Update LRU, tag/status, unlock, and return. */
			if(!ccache.isMem) {
				ccache.getCache().accessBlock(stack.set, stack.way);
				ccache.getCache().setBlock(stack.set, stack.way, stack.tag, MOESIState.MODIFIED);
			}
			stack.dirLock.unlock();
			stack.ret();
		}

		void EVICT(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;

			/* Default ret value */
			ret.isErr = false;

			/* Get block info */
			ccache.getBlock(stack.set, stack.way, stack.tag, stack.state);
			assert(stack.state != MOESIState.INVALID || !ccache.getDir().isSharedOrOwned(stack.set, stack.way));
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict (set=%d, way=%d, state=%s)",
					stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);

			/* Save some data */
			stack.srcSet = stack.set;
			stack.srcWay = stack.way;
			stack.srcTag = stack.tag;
			stack.target = target = ccache.next;

			/* Send write request to all sharers */
			MOESIStack newStack = new MOESIStack(stack.id, ccache, 0, this, MOESIEventType.EVICT_ACTION, stack);
			newStack.except = null;
			newStack.set = stack.set;
			newStack.way = stack.way;
			this.schedule(MOESIEventType.INVALIDATE, newStack, 0);
		}

		void EVICT_ACTION(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict action", stack.id, stack.tag, ccache.name);

			/* status = I */
			if(stack.state == MOESIState.INVALID) {
				this.schedule(MOESIEventType.EVICT_FINISH, stack, 0);
			} 
			/* status = M/O */
			else if(stack.state == MOESIState.MODIFIED || stack.state == MOESIState.OWNED) {
				this.schedule(MOESIEventType.EVICT_RECEIVE, stack, 2);
				stack.isWriteback = true;
			}
			/* status = S/E */
			else {
				this.schedule(MOESIEventType.EVICT_RECEIVE, stack, 2);
			}
		}

		void EVICT_RECEIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict receive", stack.id, stack.tag, target.name);

			/* Find and lock */
			MOESIStack newStack = new MOESIStack(stack.id, target, stack.srcTag, this, MOESIEventType.EVICT_WRITEBACK, stack);
			newStack.isBlocking = false;
			newStack.isRead = false;
			newStack.isRetry = false;
			this.schedule(MOESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void EVICT_WRITEBACK(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_WRITEBACK(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback", stack.id, stack.tag, target.name);

			/* Error locking block */
			if(stack.isErr) {
				ret.isErr = true;
				this.schedule(MOESIEventType.EVICT_REPLY, stack, 0);
				return;
			}

			/* No writeback */
			if(!stack.isWriteback) {
				this.schedule(MOESIEventType.EVICT_PROCESS, stack, 0);
			} 
			/* Writeback */
			else {				
				MOESIStack newStack = new MOESIStack(stack.id, target, 0, this, MOESIEventType.EVICT_WRITEBACK_EXCLUSIVE, stack);
				newStack.except = ccache;
				newStack.set = stack.set;
				newStack.way = stack.way;
				this.schedule(MOESIEventType.INVALIDATE, newStack, 0);
			}
		}

		void EVICT_WRITEBACK_EXCLUSIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_WRITEBACK_EXCLUSIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback exclusive", stack.id, stack.tag, target.name);

			/* Status = O/S/I */
			assert(stack.state != MOESIState.INVALID, to!string(stack));
			if(stack.state == MOESIState.OWNED || stack.state == MOESIState.SHARED) {
				MOESIStack newStack = new MOESIStack(stack.id, target, stack.tag, this, MOESIEventType.EVICT_WRITEBACK_FINISH, stack);
				newStack.target = target.next;
				this.schedule(MOESIEventType.WRITE_REQUEST, newStack, 0);
			} 
			/* Status = M/E */
			else {
				this.schedule(MOESIEventType.EVICT_WRITEBACK_FINISH, stack, 0);
			}
		}

		void EVICT_WRITEBACK_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_WRITEBACK_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict writeback finish", stack.id, stack.tag, target.name);

			/* Error in write request */
			if(stack.isErr) {
				ret.isErr = true;
				stack.dirLock.unlock();
				this.schedule(MOESIEventType.EVICT_REPLY, stack, 0);
				return;
			}

			/* Set tag, status and lru */
			if(!target.isMem) {
				target.getCache().setBlock(stack.set, stack.way, stack.tag, MOESIState.MODIFIED);
				target.getCache().accessBlock(stack.set, stack.way);
			}
			this.schedule(MOESIEventType.EVICT_PROCESS, stack, 0);
		}

		void EVICT_PROCESS(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_PROCESS(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict process", stack.id, stack.tag, target.name);

			/* Remove sharer, owner, and unlock */
			DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			dirEntry.removeSharer(ccache);
			if(dirEntry.owner !is null && dirEntry.owner.name == ccache.name) {
				dirEntry.owner = null;
			}
			stack.dirLock.unlock();

			this.schedule(MOESIEventType.EVICT_REPLY, stack, 0);
		}

		void EVICT_REPLY(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict reply", stack.id, stack.tag, target.name);

			this.schedule(MOESIEventType.EVICT_REPLY_RECEIVE, stack, 2);
		}

		void EVICT_REPLY_RECEIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_REPLY_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict reply receive", stack.id, stack.tag, ccache.name);

			/* Invalidate block if there was no error. */
			if(!stack.isErr) {
				ccache.getCache().setBlock(stack.srcSet, stack.srcWay, 0, MOESIState.INVALID);
			}
			assert(!ccache.getDir().isSharedOrOwned(stack.srcSet, stack.srcWay));
			this.schedule(MOESIEventType.EVICT_FINISH, stack, 0);
		}

		void EVICT_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.EVICT_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s evict finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void READ_REQUEST(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request", stack.id, stack.addr, ccache.name);

			/* Default return values*/
			ret.isShared = false;
			ret.isErr = false;

			/* Send request to target */
			assert((ccache.next !is null && ccache.next.name == target.name) ||
					(target.next !is null && target.next.name == ccache.name));
			this.schedule(MOESIEventType.READ_REQUEST_RECEIVE, stack, 8);
		}

		void READ_REQUEST_RECEIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request receive", stack.id, stack.addr, target.name);

			/* Find and lock */
			MOESIStack newStack = new MOESIStack(stack.id, target, stack.addr, this, MOESIEventType.READ_REQUEST_ACTION, stack);
			newStack.isBlocking = (target.next !is null && target.next.name == ccache.name);
			newStack.isRead = true;
			newStack.isRetry = false;
			this.schedule(MOESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void READ_REQUEST_ACTION(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request action", stack.id, stack.tag, target.name);

			/* Check block locking error. If read request is down-up, there should not
			 * have been any error while locking. */
			if(stack.isErr) {
				assert(ccache.next !is null && ccache.next.name == target.name); 	
				ret.isErr = true;
				this.schedule(MOESIEventType.READ_REQUEST_REPLY, stack, 0);
				return;
			}

			this.schedule(ccache.next !is null && ccache.next.name == target.name ? MOESIEventType.READ_REQUEST_UPDOWN : MOESIEventType.READ_REQUEST_DOWNUP, stack, 0);
		}

		void READ_REQUEST_UPDOWN(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_UPDOWN(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown", stack.id, stack.tag, target.name);

			stack.pending = 1;

			/* Status = M/O/E/S */
			if(stack.state != MOESIState.INVALID) {
				DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				
				/* Check: block requested by ccache is not already owned by ccache */
				assert(!(dirEntry.owner !is null && dirEntry.owner.name == ccache.name), 
						format("ccache: %s, target: %s, dirEntry.owner: %s (set=%d, way=%d)", 
								ccache.name, target.name, dirEntry.owner.name, stack.set % target.getDir().xSize, stack.way));
				
				/* Send read request to owners other than ccache for the block. */
				if(dirEntry.owner !is null && dirEntry.owner.name != ccache.name) {
					/* Send read request */
					stack.pending++;
					MOESIStack newStack = new MOESIStack(stack.id, target, stack.tag, this, MOESIEventType.READ_REQUEST_UPDOWN_FINISH, stack);
					newStack.target = cast(ICache!(MOESIState)) (dirEntry.owner);
					this.schedule(MOESIEventType.READ_REQUEST, newStack, 0);
				}
				this.schedule(MOESIEventType.READ_REQUEST_UPDOWN_FINISH, stack, 0);
			}
			/* Status = I */
			else {
				assert(!target.getDir().isSharedOrOwned(stack.set, stack.way));
				MOESIStack newStack = new MOESIStack(stack.id, target, stack.tag, this, MOESIEventType.READ_REQUEST_UPDOWN_MISS, stack);
				newStack.target = target.next;
				this.schedule(MOESIEventType.READ_REQUEST, newStack, 0);
			}
		}

		void READ_REQUEST_UPDOWN_MISS(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_UPDOWN_MISS(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown miss", stack.id, stack.tag, target.name);

			/* Check error */
			if(stack.isErr) {
				stack.dirLock.unlock();
				ret.isErr = true;
				this.schedule(MOESIEventType.READ_REQUEST_REPLY, stack, 0);
				return;
			}

			/* Set block state to excl/shared depending on the return value 'shared'
			 * that comes from a read request into the next cache level.
			 * Also set the tag of the block. */
			target.getCache().setBlock(stack.set, stack.way, stack.tag, stack.isShared ? MOESIState.SHARED : MOESIState.EXCLUSIVE);
			logging[LogCategory.DEBUG].infof("%d 0x%x %s set block (set=%d, way=%d) to state=%s",
					stack.id, stack.tag, target.name, stack.set, stack.way, stack.isShared ? MOESIState.SHARED : MOESIState.EXCLUSIVE);
			this.schedule(MOESIEventType.READ_REQUEST_UPDOWN_FINISH, stack, 0);
		}

		void READ_REQUEST_UPDOWN_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_UPDOWN_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;

			/* Ignore while pending requests */
			assert(stack.pending > 0);
			stack.pending--;
			if(stack.pending > 0) {
				return;
			}
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request updown finish", stack.id, stack.tag, target.name);
			
			if(!target.isMem) {
				/* Set owner to null for the directory entry if not owned by ccache. */
				DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				if(dirEntry.owner !is null && dirEntry.owner.name != ccache.name) {
					dirEntry.owner = null;
				}

				/* Set ccache as sharer, and check whether there is other cache sharing it. */
				bool isShared = false;
				dirEntry.addSharer(ccache);
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
				target.getCache().accessBlock(stack.set, stack.way);
			}
			stack.dirLock.unlock();
			this.schedule(MOESIEventType.READ_REQUEST_REPLY, stack, 0);
		}

		void READ_REQUEST_DOWNUP(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_DOWNUP(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request downup", stack.id, stack.tag, target.name);

			/* Check: status must not be invalid.
			 * By default, only one pending request. */
			assert(stack.state != MOESIState.INVALID);
			stack.pending = 1;

			/* Send a read request to the owner of the block. */
			DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			if(dirEntry.owner !is null) {
				stack.pending++;
				MOESIStack newStack = new MOESIStack(stack.id, target, stack.tag, this, MOESIEventType.READ_REQUEST_DOWNUP_FINISH, stack);
				newStack.target = cast(ICache!(MOESIState)) (dirEntry.owner);
				this.schedule(MOESIEventType.READ_REQUEST, newStack, 0);
			}

			this.schedule(MOESIEventType.READ_REQUEST_DOWNUP_FINISH, stack, 0);
		}

		void READ_REQUEST_DOWNUP_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_DOWNUP_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;

			/* Ignore while pending requests */
			assert(stack.pending > 0);
			stack.pending--;
			if(stack.pending > 0) {
				return;
			}
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request downup finish", stack.id, stack.tag, target.name);

			/* Set owner of the block to null. */
			DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
			dirEntry.owner = null;

			/* Set status to S, update LRU, unlock */
			target.getCache().setBlock(stack.set, stack.way, stack.tag, MOESIState.SHARED);
			target.getCache().accessBlock(stack.set, stack.way);
			stack.dirLock.unlock();
			this.schedule(MOESIEventType.READ_REQUEST_REPLY, stack, 0);
		}

		void READ_REQUEST_REPLY(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request reply", stack.id, stack.tag, target.name);

			assert((ccache.next !is null && ccache.next.name == target.name) ||
					(target.next !is null && target.next.name == ccache.name));
			this.schedule(MOESIEventType.READ_REQUEST_FINISH, stack, 2);
		}

		void READ_REQUEST_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.READ_REQUEST_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s read request finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void WRITE_REQUEST(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request", stack.id, stack.addr, ccache.name);

			/* Default return values */
			ret.isErr = false;

			/* Send request to target */
			assert((ccache.next !is null && ccache.next.name == target.name) ||
					(target.next !is null && target.next.name == ccache.name));
			this.schedule(MOESIEventType.WRITE_REQUEST_RECEIVE, stack, 2);
		}

		void WRITE_REQUEST_RECEIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_RECEIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request receive", stack.id, stack.addr, target.name);

			/* Find and lock */
			MOESIStack newStack = new MOESIStack(stack.id, target, stack.addr, this, MOESIEventType.WRITE_REQUEST_ACTION, stack);
			newStack.isBlocking = (target.next !is null && target.next.name == ccache.name);
			newStack.isRead = false;
			newStack.isRetry = false;
			this.schedule(MOESIEventType.FIND_AND_LOCK, newStack, 0);
		}

		void WRITE_REQUEST_ACTION(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_ACTION(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request action", stack.id, stack.tag, target.name);

			/* Check lock error. If write request is down-up, there should
			 * have been no error. */
			if(stack.isErr) {
				assert(ccache.next !is null && ccache.next.name == target.name);
				ret.isErr = true;
				this.schedule(MOESIEventType.WRITE_REQUEST_REPLY, stack, 0);
				return;
			}

			/* Invalidate the rest of upper level sharers */
			MOESIStack newStack = new MOESIStack(stack.id, target, 0, this, MOESIEventType.WRITE_REQUEST_EXCLUSIVE, stack);
			newStack.except = ccache;
			newStack.set = stack.set;
			newStack.way = stack.way;
			this.schedule(MOESIEventType.INVALIDATE, newStack, 0);
		}

		void WRITE_REQUEST_EXCLUSIVE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_EXCLUSIVE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%s %s write request exclusive", stack.id, stack.tag, target.name);

			this.schedule(ccache.next !is null && ccache.next.name == target.name ? MOESIEventType.WRITE_REQUEST_UPDOWN : MOESIEventType.WRITE_REQUEST_DOWNUP, stack, 0);
		}

		void WRITE_REQUEST_UPDOWN(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_UPDOWN(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request updown", stack.id, stack.tag, target.name);

			/* status = M/E */
			if(stack.state == MOESIState.MODIFIED || stack.state == MOESIState.EXCLUSIVE) {
				this.schedule(MOESIEventType.WRITE_REQUEST_UPDOWN_FINISH, stack, 0);
			} 
			/* status = O/S/I */
			else {
				MOESIStack newStack = new MOESIStack(stack.id, target, stack.tag, this, MOESIEventType.WRITE_REQUEST_UPDOWN_FINISH, stack);
				newStack.target = target.next;
				this.schedule(MOESIEventType.WRITE_REQUEST, newStack, 0);
			}
		}

		void WRITE_REQUEST_UPDOWN_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_UPDOWN_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request updown finish", stack.id, stack.tag, target.name);

			/* Error in write request to next cache level */
			if(stack.isErr) {
				ret.isErr = true;
				stack.dirLock.unlock();
				this.schedule(MOESIEventType.WRITE_REQUEST_REPLY, stack, 0);
				return;
			}
			
			if(!target.isMem) {
				/* Set ccache as sharer and owner. */
				DirEntry!(MOESIState) dirEntry = target.getDirEntry(stack.set, stack.way);
				dirEntry.addSharer(ccache);
				dirEntry.owner = ccache;
			}

			/* Update LRU, set status: M->M, O/E/S/I->E */
			if(!target.isMem) {
				target.getCache().accessBlock(stack.set, stack.way);
				if(stack.state != MOESIState.MODIFIED) {
					target.getCache().setBlock(stack.set, stack.way, stack.tag, MOESIState.EXCLUSIVE);
				}
			}
			
			/* Unlock. */
			stack.dirLock.unlock();
			this.schedule(MOESIEventType.WRITE_REQUEST_REPLY, stack, 0);
		}

		void WRITE_REQUEST_DOWNUP(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_DOWNUP(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request downup", stack.id, stack.tag, target.name);
			
			/* Set status to I, unlock */
			assert(stack.state != MOESIState.INVALID);
			assert(!target.getDir().isSharedOrOwned(stack.set, stack.way));
			target.getCache().setBlock(stack.set, stack.way, 0, MOESIState.INVALID);
			stack.dirLock.unlock();
			this.schedule(MOESIEventType.WRITE_REQUEST_REPLY, stack, 0);
		}

		void WRITE_REQUEST_REPLY(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_REPLY(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request reply", stack.id, stack.tag, target.name);

			assert((ccache.next !is null && ccache.next.name == target.name) ||
					(target.next !is null && target.next.name == ccache.name));
			this.schedule(MOESIEventType.WRITE_REQUEST_FINISH, stack, 2);
		}

		void WRITE_REQUEST_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.WRITE_REQUEST_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
			logging[LogCategory.DEBUG].infof("%d 0x%x %s write request finish", stack.id, stack.tag, ccache.name);

			stack.ret();
		}

		void INVALIDATE(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.INVALIDATE(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;

			/* Get block info */
			ccache.getBlock(stack.set, stack.way, stack.tag, stack.state);
			logging[LogCategory.DEBUG].infof("%d 0x%x %s invalidate (set=%d, way=%d, state=%s)",
					stack.id, stack.tag, ccache.name, stack.set, stack.way, stack.state);
			stack.pending = 1;

			/* Send write request to all upper level sharers but ccache */
			DirEntry!(MOESIState) dirEntry = ccache.getDirEntry(stack.set, stack.way);
			foreach(sharer; dirEntry.sharers) {
				/* Skip 'except' */
				if(sharer.name == stack.except.name) {
					continue;
				}

				/* Clear sharer and owner */
				dirEntry.removeSharer(sharer);				
				if(dirEntry.owner !is null && dirEntry.owner.name == sharer.name) {
					dirEntry.owner = null;
				}

				/* Send write request upwards */
				MOESIStack newStack = new MOESIStack(stack.id, ccache, stack.tag, this, MOESIEventType.INVALIDATE_FINISH, stack);
				newStack.target = sharer;
				this.schedule(MOESIEventType.WRITE_REQUEST, newStack, 0);
				stack.pending++;
			}

			this.schedule(MOESIEventType.INVALIDATE_FINISH, stack, 0);
		}

		void INVALIDATE_FINISH(MOESIEventType eventType, MOESIStack stack, ulong when) {
			logging[LogCategory.MOESI].infof("%s.INVALIDATE_FINISH(%s, %s, %d)", this.name, eventType, stack, when);

			MOESIStack ret = stack.retStack;
			ICache!(MOESIState) ccache = stack.ccache;
			ICache!(MOESIState) target = stack.target;
			
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