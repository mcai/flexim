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

uint currentMessageID = 0;

class Message {	
	this(Request request) {
		this.id = currentMessageID++;
		this.request = request;
	}

	uint id;	
	Request request;
}

uint currentNodeID = 0;

abstract class Node {
	this(string name, MemorySystem memorySystem) {
		this.id = currentNodeID++;
		this.name = name;
		this.memorySystem = memorySystem;
	}

	override string toString() {
		return format("%s", this.name);
	}

	string name;
	uint id;
	
	MemorySystem memorySystem;
}

uint currentRequestID = 0;

enum RequestType: string {
	READ = "READ",
	WRITE = "WRITE"
}

class Request {
	this(RequestType type, Addr pc, Addr addr, Callback onCompletedCallback) {
		this.id = currentRequestID++;
		this.type = type;
		this.pc = pc;
		this.addr = addr;
		this.onCompletedCallback = onCompletedCallback;
	}

	override string toString() {
		return format("%s[ID=%d, pc=0x%x, addr=0x%x]", to!(string)(this.type), this.id, this.pc, this.addr);
	}

	uint id;
	RequestType type;
	Addr pc;
	Addr addr;
	Callback onCompletedCallback;
}

class CPURequest: Request {	
	alias addr phaddr;
	
	this(RequestType type, DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, Callback onCompletedCallback) {
		super(type, pc, phaddr, onCompletedCallback);

		this.uop = uop;
		this.vtaddr = vtaddr;
		this.rs = rs;
	}

	override string toString() {
		return format("%s[ID=%d, pc=0x%x, vtaddr=0x%x, phaddr=0x%x]", to!(string)(this.type), this.id, this.pc, this.vtaddr, this.phaddr);
	}

	DynamicInst uop;
	Addr vtaddr;
	RUUStation rs;
}

class ReadCPURequest: CPURequest {
	this(DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, void delegate(Request) del) {
		super(RequestType.READ, uop, pc, vtaddr, rs, phaddr, new Callback1!(Request)(this, del));
	}
}

class WriteCPURequest: CPURequest {
	this(DynamicInst uop, Addr pc, Addr vtaddr, RUUStation rs, Addr phaddr, void delegate(Request) del) {
		super(RequestType.WRITE, uop, pc, vtaddr, rs, phaddr, new Callback1!(Request)(this, del));
	}
}

class Sequencer: Node {
	this(string name, CoherentCache l1Cache) {
		super(name, l1Cache.memorySystem);

		this.l1Cache = l1Cache;

		this.maxReadCapacity = 32;
	}

	void read(Request req) {
		logging.infof(LogCategory.REQUEST, "%s.read", this.name);

		assert(req !is null);
		assert(req.type == RequestType.READ);

		Addr blockPhaddr = this.blockAddress(req.addr);

		if(blockPhaddr in this.pendingReads) {
			this.pendingReads[blockPhaddr] ~= req;
		} else if(this.canAcceptRead(blockPhaddr)) {
			Message r = new Message(req);
			this.sendLoad(r, this.l1Cache);
			
			this.pendingReads[blockPhaddr] ~= req;
		} else {
			assert(0);
			//TODO: schedule retry request
		}
	}
	
	void sendLoad(Message m, CoherentCache target) {
		target.receiveLoad(m, this);
	}

	void write(Request req) {
		logging.infof(LogCategory.REQUEST, "%s.write", this.name);

		assert(req !is null);
		assert(req.type == RequestType.WRITE);

		Addr blockPhaddr = this.blockAddress(req.addr);

		Message w = new Message(req);
		this.sendStore(w, this.l1Cache);
	}
	
	void sendStore(Message m, CoherentCache target) {
		target.receiveStore(m, this);
	}

	bool canAcceptRead(Addr addr) {
		return (this.pendingReads.length < this.maxReadCapacity);
	}

	void completeRequest(Request req) {
		logging.infof(LogCategory.REQUEST, "%s.completeRequest", this.name);

		if(req.onCompletedCallback !is null) {
			req.onCompletedCallback.invoke();
		}
	}

	void receiveLoadResponse(Message msg, CoherentCache source) {
		logging.infof(LogCategory.REQUEST, "%s.handleMessage(%s, %s)", this.name, msg, source);

		Addr blockPhaddr = this.blockAddress(msg.request.addr);

		if(blockPhaddr in this.pendingReads) {
			foreach(req; this.pendingReads[blockPhaddr]) {
				this.completeRequest(req);
			}

			this.pendingReads.remove(blockPhaddr);
		}
	}
	
	uint blockSize() {
		return this.l1Cache.blockSize;
	}

	Addr blockAddress(Addr addr) {
		return this.l1Cache.cache.tag(addr);
	}

	override string toString() {
		return format("%s[pendingReads.length=%d]", this.name, this.pendingReads.length);
	}

	uint maxReadCapacity;

	Request[][Addr] pendingReads;

	CoherentCache l1Cache;
}

enum MESIState: string {
	MODIFIED = "MODIFIED",
	EXCLUSIVE = "EXCLUSIVE",
	SHARED = "SHARED",
	INVALID = "INVALID"
}

enum CacheReplacementPolicy: string {
	LRU = "LRU",
	FIFO = "FIFO",
	Random = "Random"
}

class DirEntry {
	this(uint x, uint y) {
		this.x = x;
		this.y = y;
	}

	void setSharer(CoherentCache node) {
		assert(node !is null);		
        if(!canFind(this.sharers, node)) {			
			this.sharers ~= node;
        }
	}

	void unsetSharer(CoherentCache node) {
		assert(node !is null);
		if(canFind(this.sharers, node)) {	
			uint indexFound;	
			foreach(i, sharer; this.sharers) {
				if(sharer == node) {
					indexFound = i;
					break;
				}
			}
			this.sharers = this.sharers.remove(indexFound);
		}
	}

	bool isSharer(CoherentCache node) {
		return canFind(this.sharers, node);
	}
	
	bool isShared() {
		return this.sharers.length > 0;
	}
	
	bool isOwned() {
		return this.owner !is null;
	}

	bool isSharedOrOwned() {
		return this.isShared || this.isOwned;
	}

	override string toString() {
		string str;

		str ~= format("DirEntry[owner=%s, sharers.length=%d]", this.owner !is null ? this.owner.name : "NULL", this.sharers.length);

		return str;
	}

	CoherentCache owner() {
		return this.m_owner;
	}

	void owner(CoherentCache value) {
		this.m_owner = value;
	}

	private CoherentCache m_owner;
	CoherentCache[] sharers;

	uint x;
	uint y;
}

class DirLock {
	this(uint x) {
		this.x = x;
	}

	bool lock(ulong lockerRequestId) {
		if(this.locked) {
			return false;
		} else {			
			this.lockerRequestId = lockerRequestId;
			this.locked = true;
			return true;
		}
	}

	void unlock() {
		this.locked = false;
	}

	override string toString() {
		string str;

		str ~= format("DirLock[locked=%s]", this.locked);

		return str;
	}

	uint x;

	bool locked;
	
	ulong lockerRequestId;
}

class Dir {
	this(uint xSize, uint ySize) {
		this.xSize = xSize;
		this.ySize = ySize;

		this.dirEntries = new DirEntry[][this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirEntries[i] = new DirEntry[this.ySize];

			for(uint j = 0; j < this.ySize; j++) {
				this.dirEntries[i][j] = new DirEntry(i, j);
			}
		}

		this.dirLocks = new DirLock[this.xSize];
		for(uint i = 0; i < this.xSize; i++) {
			this.dirLocks[i] = new DirLock(i);
		}
	}

	bool isSharedOrOwned(uint x, uint y) {
		return this.dirEntries[x][y].isSharedOrOwned;
	}

	uint xSize;
	uint ySize;

	DirEntry[][] dirEntries;
	DirLock[] dirLocks;
}

class CacheBlock {
	this(CacheSet set, MESIState initialState) {
		this.set = set;
		this.state = this.initialState = initialState;
		this.tag = 0;
		this.lastAccess = 0;
	}

	override string toString() {
		return format("CacheBlock[set=%s, tag=%d, state=%s]", to!(string)(this.set), this.tag, to!(string)(this.state));
	}

	CacheSet set;
	uint tag;
	uint transientTag;
	MESIState state;
	MESIState initialState;

	ulong lastAccess;
}

class CacheSet {
	this(Cache cache, uint assoc, MESIState initialState) {
		this.cache = cache;
		this.assoc = assoc;

		this.blks = new CacheBlock[this.assoc];
		for(uint i = 0; i < this.assoc; i++) {
			this.blks[i] = new CacheBlock(this, initialState);
		}
	}

	uint length() {
		return this.blks.length;
	}

	CacheBlock opIndex(uint i) {
		return this.blks[i];
	}

	int opApply(int delegate(ref uint, ref CacheBlock) dg) {
		int result;

		foreach(ref uint i, ref CacheBlock p; this.blks) {
			result = dg(i, p);
			if(result)
				break;
		}
		return result;
	}

	int opApply(int delegate(ref CacheBlock) dg) {
		int result;

		foreach(ref CacheBlock p; this.blks) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}

	string toString() {
		return format("CacheSet[assoc=%d]", this.assoc);
	}

	uint assoc;
	CacheBlock[] blks;

	Cache cache;
}

class Cache {
	this(uint blockSize, uint assoc, uint numSets, MESIState initialState) {
		this.blockSize = blockSize;
		this.assoc = assoc;
		this.numSets = numSets;

		this.initialState = initialState;

		this.sets = new CacheSet[this.numSets];
		for(uint i = 0; i < this.numSets; i++) {
			this[i] = new CacheSet(this, this.assoc, initialState);
		}

		this.dir = new Dir(this.numSets, this.assoc);
	}

	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref MESIState state) {
		tag = this.tag(addr);
		set = this.set(addr);

		uint wayFound = this.assoc;

		foreach(way, blk; this[set]) {
			if(blk.tag == tag && blk.state != this.initialState) {
				wayFound = way;
				break;
			}
		}

		if(wayFound == this.assoc) {
			return false;
		} else {
			way = wayFound;
			state = this[set][wayFound].state;

			return true;
		}
	}

	void setBlock(uint set, uint way, uint tag, MESIState state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		this.accessBlock(set, way);
		this[set][way].tag = tag;
		this[set][way].state = state;
	}

	void getBlock(uint set, uint way, ref uint tag, ref MESIState state) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		tag = this[set][way].tag;
		state = this[set][way].state;
	}

	void accessBlock(uint set, uint way) {
		assert(set >= 0 && set < this.numSets);
		assert(way >= 0 && way < this.assoc);
		CacheBlock blk = this[set][way];
		blk.lastAccess = Simulator.singleInstance.currentCycle;
	}

	uint replaceBlock(uint set) {
		assert(set >= 0 && set < this.numSets);

		ulong smallestTime = this[set][0].lastAccess;
		uint smallestIndex = 0;

		foreach(way, blk; this[set]) {
			ulong time = blk.lastAccess;
			if(time < smallestTime) {
				smallestIndex = way;
				smallestTime = time;
			}
		}

		return smallestIndex;
	}

	CacheSet opIndex(uint index) {
		return this.sets[index];
	}

	void opIndexAssign(CacheSet value, uint index) {
		this.sets[index] = value;
	}

	uint logBlockSize() {
		return cast(uint) std.math.log2(this.blockSize);
	}

	uint blockMask() {
		return this.blockSize - 1;
	}

	uint set(Addr addr) {
		return (addr >> this.logBlockSize) % this.numSets;
	}

	uint tag(Addr addr) {
		return addr & ~this.blockMask;
	}

	uint offset(Addr addr) {
		return addr & this.blockMask;
	}

	int assoc;
	int numSets;
	Addr blockSize;

	MESIState initialState;

	CacheSet[] sets;

	Dir dir;
}

class CacheQueueEntry: Invokable {
	this(Node sender, Request request, Invokable onCompletedCallback = null) {
		this.sender = sender;
		this.request = request;
		this.onCompletedCallback = onCompletedCallback;
		this.id = currentId++;
		
		this.set = this.way = this.tag = 0;
		
		this.state = MESIState.INVALID;
		
		this.isShared = false;
	}
	
	override void invoke() {
		if(this.onCompletedCallback !is null) {
			this.onCompletedCallback.invoke();
		}
	}
	
	Addr key() {
		return this.request.addr;
	}
	
	CacheQueueEntry value() {
		return this;
	}

	Node sender;
	Request request;
	Invokable onCompletedCallback;
	
	uint set, way, tag;
	uint srcSet, srcWay, srcTag;
	
	MESIState state;
	
	bool hasError;
	bool isShared;
	bool isEviction;
	bool isWriteback;
	
	DirLock dirLock;
	
	uint pending;
	
	Node except;
	
	ulong id;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class PendingQueue(KeyT, EntryT) {
	this() {
	}
	
	void begin(EntryT entry) {
		this.pendings[entry.key] ~= entry.value;
	}
	
	void end(KeyT key) {
		assert(key in this.pendings);
		
		foreach(entry; this.pendings[key]) {
			entry.invoke();
		}
		
		this.pendings.remove(key);
	}
	
	void end(EntryT entryToRemove) {
		int indexToRemove = -1;
		
		uint key = entryToRemove.key;
		
		foreach(index, entry; this.pendings[key]) {
			if(entry == entryToRemove) {
				indexToRemove = index;
			}
		}
		
		assert(indexToRemove != -1);

		this.pendings[key] = this.pendings[key].remove(indexToRemove);
		
		entryToRemove.invoke();
	}

	EntryT[][KeyT] pendings;
}

class MSHR: PendingQueue!(Addr, CacheQueueEntry) {
	this() {
	}
	
	alias end endAccess;
}

class MSHR2: PendingQueue!(Addr, CacheQueueEntry) {
	this() {
	}
	
	alias end endAccess;
}

class CoherentCache: Node {
	this(string name, MemorySystem memorySystem, uint blockSize, uint assoc, uint numSets, uint hitLatency, uint missLatency, uint level) {
		super(name, memorySystem);

		this.cache = new Cache(blockSize, assoc, numSets, MESIState.INVALID);
		
		this.readMshr = new MSHR();
		this.writeMshr = new MSHR();
		
		this.requestMshr = new MSHR2();

		this.hitLatency = hitLatency;
		this.missLatency = missLatency;
		
		this.level = level;

		this.stat = new CacheStat(this.name);
	}

	bool findBlock(uint addr, ref uint set, ref uint way, ref uint tag, ref MESIState state) {
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

	void getBlock(uint set, uint way, ref uint tag, ref MESIState state) {
		this.cache.getBlock(set, way, tag, state);
	}

	uint blockSize() {
		return this.cache.blockSize;
	}
	
	Dir getDir() {
		return this.cache.dir;
	}
	
	DirEntry getDirEntry(uint set, uint way) {
		return this.getDir().dirEntries[set][way];
	}
	
	DirLock getDirLock(uint set) {
		return this.getDir().dirLocks[set];
	}

	bool isMem() {
		return false;
	}
	
	uint retryLat() {
		return this.hitLatency + uniform(0, this.hitLatency + 2);
	}
	
	void schedule(Invokable callback, uint lat) {
		Simulator.singleInstance.eventQueue.schedule(SimulatorEventType.GENERAL, new SimulatorEventContext(this.name, callback), lat);
	}
	
	void receiveLoad(Message m, Sequencer source) {
		CacheQueueEntry queueEntry = new CacheQueueEntry(source, m.request, new Callback2!(Message, Sequencer)(
			new Message(m.request), source, &this.sendLoadResponse));
		this.readMshr.begin(queueEntry);
		this.load(queueEntry);
	}
	
	void receiveStore(Message m, Sequencer source) {
		CacheQueueEntry queueEntry = new CacheQueueEntry(source, m.request);
		this.writeMshr.begin(queueEntry);
		this.store(queueEntry);
	}
	
	void sendLoadResponse(Message m, Sequencer target) {
		target.receiveLoadResponse(m, this);
	}
	
	void findAndLock(CacheQueueEntry queueEntry, Invokable callback = null) {
		writefln("%s.findAndLock", this.name);
		bool hit = this.findBlock(queueEntry.request.addr, queueEntry.set, queueEntry.way, queueEntry.tag, queueEntry.state);
		
		uint dumbTag = 0;
		if(!hit) {
			queueEntry.way = this.cache.replaceBlock(queueEntry.set);
			this.cache.getBlock(queueEntry.set, queueEntry.way, dumbTag, queueEntry.state);
		}
		
		queueEntry.dirLock = this.getDirLock(queueEntry.set);
		if(!queueEntry.dirLock.lock(queueEntry.id)) {
			queueEntry.hasError = true;
			callback.invoke();
			return;
		}
		
		this.cache[queueEntry.set][queueEntry.way].transientTag = queueEntry.tag;
		
		if(!hit && queueEntry.state != MESIState.INVALID) {
			queueEntry.isEviction = true;
			this.schedule(new Callback2!(CacheQueueEntry, Invokable)(
				queueEntry, new Callback2!(CacheQueueEntry, Invokable)(queueEntry, callback, &this.findAndLockFinish), &this.evict), this.hitLatency);
		}
		else {
			this.schedule(new Callback2!(CacheQueueEntry, Invokable)(queueEntry, callback, &this.findAndLockFinish), this.hitLatency);
		}
	}
	
	void findAndLockFinish(CacheQueueEntry queueEntry, Invokable callback) {
		writefln("%s.findAndLockFinish", this.name);
		uint dumbTag = 0;
		
		if(!queueEntry.hasError) {
			if(queueEntry.isEviction) {
				this.cache.getBlock(queueEntry.set, queueEntry.way, dumbTag, queueEntry.state);
			}
			
			callback.invoke();
		}
		else {
			this.cache.getBlock(queueEntry.set, queueEntry.way, dumbTag, queueEntry.state);
			queueEntry.dirLock.unlock();
			callback.invoke();
		}
	}
	
	void load(CacheQueueEntry queueEntry) {
		writefln("%s.load", this.name);
		this.findAndLock(queueEntry, new Callback1!(CacheQueueEntry)(queueEntry, &this.loadAction));
	}
	
	void loadAction(CacheQueueEntry queueEntry) {
		writefln("%s.loadAction", this.name);
		if(!queueEntry.hasError) {			
			bool hit = (queueEntry.state != MESIState.INVALID);
			if(hit) {
				this.loadFinish(queueEntry);
			}
			else {
				this.sendReadRequest(queueEntry, this.next, new Callback1!(CacheQueueEntry)(queueEntry, &this.loadMiss));
			}
		}
		else {
			queueEntry.hasError = false;
			this.schedule(new Callback1!(CacheQueueEntry)(queueEntry, &this.load), retryLat);
		}
	}
	
	void loadMiss(CacheQueueEntry queueEntry) {
		writefln("%s.loadMiss", this.name);
		this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, queueEntry.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
		this.loadFinish(queueEntry);
	}
	
	void loadFinish(CacheQueueEntry queueEntry) {
		writefln("%s.loadFinish", this.name);
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		queueEntry.dirLock.unlock();
		this.readMshr.endAccess(queueEntry.request.addr);
	}
	
	void store(CacheQueueEntry queueEntry) {
		writefln("%s.store", this.name);
		this.findAndLock(queueEntry, new Callback1!(CacheQueueEntry)(queueEntry, &this.storeAction));
	}
	
	void storeAction(CacheQueueEntry queueEntry) {	
		writefln("%s.storeAction", this.name);
		if(!queueEntry.hasError) {
			bool hit = (queueEntry.state == MESIState.MODIFIED || queueEntry.state == MESIState.EXCLUSIVE);
			if(hit) {
				this.storeFinish(queueEntry);
			}
			else {
				this.sendWriteRequest(queueEntry, this.next, new Callback1!(CacheQueueEntry)(queueEntry, &this.storeFinish));
			}
		}
		else {
			this.schedule(new Callback1!(CacheQueueEntry)(queueEntry, &this.store), retryLat);
		}
	}
	
	void storeFinish(CacheQueueEntry queueEntry) {
		writefln("%s.storeFinish", this.name);
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, MESIState.MODIFIED);
		queueEntry.dirLock.unlock();
		this.writeMshr.endAccess(queueEntry.request.addr);
	}
	
	void evict(CacheQueueEntry queueEntry, Invokable callback) {
		writefln("%s.evict", this.name);
		this.getBlock(queueEntry.set, queueEntry.way, queueEntry.tag, queueEntry.state);
		
		queueEntry.srcSet = queueEntry.set;
		queueEntry.srcWay = queueEntry.way;
		queueEntry.srcTag = queueEntry.tag;
		
		this.sendInvalidates(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, this.next, &this.sendEvict));
	}
	
	void sendEvict(CacheQueueEntry queueEntry, CoherentCache target) {
		writefln("%s.sendEvict", this.name);
		target.receiveEvictAction(queueEntry, this);
	}
	
	void receiveEvictAction(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveEvictAction", this.name);
		if(queueEntry.state == MESIState.INVALID) {
			this.receiveEvictFinish(queueEntry);
			return;
		}
		else if(queueEntry.state == MESIState.MODIFIED) {
			this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveEvict), 2);
			queueEntry.isWriteback = true;
		}
		else {
			this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveEvict), 2);
		}
	}
		
	void receiveEvict(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveEvict", this.name);	
		this.findAndLock(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.evictWriteback));
	}
	
	void evictWriteback(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.evictWriteback", this.name);
		if(!queueEntry.hasError) {
			if(!queueEntry.isWriteback) {
				this.receiveEvictProcess(queueEntry, source);
			}
			else {
				this.sendInvalidates(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.evictWritebackExclusive));
			}
		}
		else {
			this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveEvict), retryLat);
		}		
	}
	
	void evictWritebackExclusive(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.evictWritebackExclusive", this.name);
		if(queueEntry.state == MESIState.SHARED) {
			this.sendWriteRequest(queueEntry, this.next, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.evictWritebackFinish));
		}
		else {
			this.evictWritebackFinish(queueEntry, source);
		}
	}
	
	void evictWritebackFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.evictWritebackFinish", this.name);
		this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, MESIState.MODIFIED);
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		this.receiveEvictProcess(queueEntry, source);
	}
	
	void receiveEvictProcess(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveEvictProcess", this.name);
		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		dirEntry.unsetSharer(source);
		if(dirEntry.owner == source) {
			dirEntry.owner = null;
		}
		queueEntry.dirLock.unlock();
		this.sendEvictReply(queueEntry, source);
	}
	
	void sendEvictReply(CacheQueueEntry queueEntry, CoherentCache target) {
		writefln("%s.sendEvictReply", this.name);
		target.receiveEvictReply(queueEntry, this);
	}
	
	void receiveEvictReply(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveEvictReply", this.name);
		this.cache.setBlock(queueEntry.srcSet, queueEntry.srcWay, 0, MESIState.INVALID);
		this.receiveEvictFinish(queueEntry);
	}
	
	void receiveEvictFinish(CacheQueueEntry queueEntry) {
		writefln("%s.receiveEvictFinish", this.name);
		queueEntry.invoke();
	}
	
	void sendReadRequest(CacheQueueEntry queueEntry, CoherentCache target, Invokable callback) {
		writefln("%s.sendReadRequest", this.name);
		if(this.level == 1) {
			this.memorySystem.mem.receiveReadRequest(queueEntry, this);
		}
		else {
			if(isUpdownRequest(this, target)) {
				target.receiveReadRequestUpdown(queueEntry, this);
			}
			else {
				target.receiveReadRequestDownup(queueEntry, this);
			}
		}
	}
	
	void receiveReadRequestUpdown(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveReadRequestUpdown", this.name);
		this.findAndLock(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.readRequestUpdownAction));
	}
	
	void readRequestUpdownAction(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.readRequestUpdownAction", this.name);
		if(!queueEntry.hasError) {
			bool hit = (queueEntry.state != MESIState.INVALID);
			if(hit) {
				DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
				
				if(dirEntry.owner !is null && dirEntry.owner != source) {
					queueEntry.pending++;
					this.sendReadRequest(queueEntry, dirEntry.owner, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.readRequestUpdownFinish));
				}
				this.readRequestUpdownFinish(queueEntry, source); 
			}
			else {
				this.sendReadRequest(queueEntry, this.next, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.readRequestUpdownMiss));
			}
		}
		else {
			this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveReadRequestUpdown), retryLat);
		}
	}
	
	void readRequestUpdownMiss(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.readRequestUpdownMiss", this.name);
		this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, queueEntry.isShared ? MESIState.SHARED : MESIState.EXCLUSIVE);
		this.readRequestUpdownFinish(queueEntry, source);
	}
	
	void readRequestUpdownFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.readRequestUpdownFinish", this.name);
		queueEntry.pending--;
		if(queueEntry.pending > 0) {
			return;
		}
		
		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		if(dirEntry.owner !is null && dirEntry.owner != source) {
			dirEntry.owner = null;
		}
		
		dirEntry.setSharer(source);
		if(!dirEntry.isShared) {
			dirEntry.owner = source;
		}
		
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		queueEntry.dirLock.unlock();
		
		this.readRequestReply(queueEntry, source);
	}
	
	void receiveReadRequestDownup(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveReadRequestDownup", this.name);
		queueEntry.pending = 1;
		
		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		if(dirEntry.owner !is null) {
			queueEntry.pending++;
			this.sendReadRequest(queueEntry, dirEntry.owner, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveReadRequestDownupFinish));
		}
		
		this.receiveReadRequestDownupFinish(queueEntry, source);
	}
	
	void receiveReadRequestDownupFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveReadRequestDownupFinish", this.name);
		queueEntry.pending--;
		if(queueEntry.pending > 0) {
			return;
		}
		
		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		dirEntry.owner = null;
		
		this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, MESIState.SHARED);
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		queueEntry.dirLock.unlock();		
		this.readRequestReply(queueEntry, source);
	}
	
	void readRequestReply(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.readRequestReply", this.name);
		this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.readRequestFinish), 2);
	}
	
	void readRequestFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.readRequestFinish", this.name);
		sendReadRequestResponse(queueEntry, source);
	}
	
	void sendReadRequestResponse(CacheQueueEntry queueEntry, CoherentCache target) {
		writefln("%s.sendReadRequestResponse", this.name);
		target.receiveReadRequestResponse(queueEntry, this);
	}
	
	void receiveReadRequestResponse(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveReadRequestResponse", this.name);
		queueEntry.invoke();
	}
	
	void sendWriteRequest(CacheQueueEntry queueEntry, CoherentCache target, Invokable callback) {
		writefln("%s.sendWriteRequest", this.name);
		if(this.level == 1) {
			this.memorySystem.mem.receiveWriteRequest(queueEntry, this);
		}
		else {
			target.receiveWriteRequest(queueEntry, this);
		}
	}
	
	void receiveWriteRequest(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequest", this.name);
		this.findAndLock(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.writeRequestAction));
	}
	
	void writeRequestAction(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.writeRequestAction", this.name);
		if(queueEntry.hasError) {
			this.sendInvalidates(queueEntry, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveWriteRequestExclusive));
		}
		else {
			this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveWriteRequest), retryLat);
		}
	}
	
	void receiveWriteRequestExclusive(CacheQueueEntry cacheQueueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequestExclusive", this.name);
		if(isUpdownRequest(source, this)) {
			this.receiveWriteRequestUpdown(cacheQueueEntry, source);
		}
		else {
			this.receiveWriteRequestDownup(cacheQueueEntry, source);
		}
	}
	
	void receiveWriteRequestUpdown(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequestUpdown", this.name);
		bool hit = (queueEntry.state == MESIState.MODIFIED || queueEntry.state == MESIState.EXCLUSIVE);
		if(hit) {
			this.receiveWriteRequestUpdownFinish(queueEntry, source);
		}
		else {
			this.sendWriteRequest(queueEntry, this.next, new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.receiveWriteRequestUpdownFinish));
		}
	}
	
	void receiveWriteRequestUpdownFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequestUpdownFinish", this.name);
		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		dirEntry.setSharer(source);
		dirEntry.owner = source;
		
		this.cache.accessBlock(queueEntry.set, queueEntry.way);
		if(queueEntry.state != MESIState.MODIFIED) {
			this.cache.setBlock(queueEntry.set, queueEntry.way, queueEntry.tag, MESIState.EXCLUSIVE);
		}
		
		queueEntry.dirLock.unlock();
		this.writeRequestReply(queueEntry, source);
	}
	
	void receiveWriteRequestDownup(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequestDownup", this.name);
		this.cache.setBlock(queueEntry.set, queueEntry.way, 0, MESIState.INVALID);
		queueEntry.dirLock.unlock();		
		this.writeRequestReply(queueEntry, source);
	}
	
	void writeRequestReply(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.writeRequestReply", this.name);
		this.schedule(new Callback2!(CacheQueueEntry, CoherentCache)(queueEntry, source, &this.writeRequestFinish), 2);
	}
	
	void writeRequestFinish(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.writeRequestFinish", this.name);
		this.sendWriteRequestResponse(queueEntry, source);
	}
	
	void sendWriteRequestResponse(CacheQueueEntry queueEntry, CoherentCache target) {
		writefln("%s.sendWriteRequestResponse", this.name);
		target.receiveWriteRequestResponse(queueEntry, this);
	}
	
	void receiveWriteRequestResponse(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequestResponse", this.name);
		queueEntry.invoke();
	}
	
	void sendInvalidates(CacheQueueEntry queueEntry, Invokable callback) {
		writefln("%s.sendInvalidates", this.name);
		this.getBlock(queueEntry.set, queueEntry.way, queueEntry.tag, queueEntry.state);
		queueEntry.pending = 1;

		DirEntry dirEntry = this.getDirEntry(queueEntry.set, queueEntry.way);
		CoherentCache[] sharersToRemove;
		
		foreach(sharer; dirEntry.sharers) {
			if(sharer != queueEntry.except) {
				sharersToRemove ~= sharer;
			}
		}
		
		foreach(sharer; sharersToRemove) {	
			dirEntry.unsetSharer(sharer);
			if(dirEntry.owner == sharer) {
				dirEntry.owner = null;
			}
			
			this.sendWriteRequest(queueEntry, sharer, new Callback1!(CacheQueueEntry)(queueEntry, &this.sendInvalidatesFinish));
			queueEntry.pending++;
		}
		
		this.sendInvalidatesFinish(queueEntry);
	}
	
	void sendInvalidatesFinish(CacheQueueEntry queueEntry) {
		writefln("%s.sendInvalidatesFinish", this.name);
		queueEntry.pending--;
		if(queueEntry.pending > 0) {
			return;
		}

		queueEntry.invoke();
	}
	
	static bool isUpdownRequest(CoherentCache source, CoherentCache target) {
		return source.level < target.level;
	}

	Cache cache;
	
	MSHR readMshr;
	MSHR writeMshr;
	
	MSHR2 requestMshr;
	
	CacheStat stat;

	CoherentCache next;

	uint hitLatency;
	uint missLatency;
	
	uint level;
}

class PhysicalMemory: Node {
	this(MemorySystem memorySystem) {
		super("mem", memorySystem);
	}
	
	void receiveReadRequest(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveReadRequest", this.name);
		this.sendReadRequestResponse(queueEntry, source);
	}
	
	void sendReadRequestResponse(CacheQueueEntry queueEntry, CoherentCache target) {
		writefln("%s.sendReadRequestResponse", this.name);
		target.receiveReadRequestResponse(queueEntry, null); //TODO
	}
	
	void receiveWriteRequest(CacheQueueEntry queueEntry, CoherentCache source) {
		writefln("%s.receiveWriteRequest", this.name);
		queueEntry.invoke();
	}
}