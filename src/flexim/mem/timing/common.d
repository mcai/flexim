/*
 * flexim/mem/timing/common.d
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

module flexim.mem.timing.common;

import flexim.all;

abstract class CoherentCacheNode {	
	this(MemorySystem memorySystem, string name) {
		this.id = currentId++;
		this.name = name;
		this.memorySystem = memorySystem;
		
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this.eventQueue);
	}
	
	void schedule(void delegate() event, ulong delay = 0) {
		this.eventQueue.schedule(event, delay);
	}
	
	void load(uint addr, bool isRetry, 
		void delegate() onCompletedCallback) {
		writefln("%s.load(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		assert(0);
	}
	
	void store(uint addr, bool isRetry, 
		void delegate() onCompletedCallback) {
		writefln("%s.store(addr=0x%x, isRetry=%s)", this, addr, isRetry);
		assert(0);
	}
	
	void findAndLock(uint addr, bool isBlocking, bool isRead, bool isRetry, 
		void delegate(bool hasError, uint set, uint way, MESIState state, uint tag, DirLock dirLock) onCompletedCallback) {
		writefln("%s.findAndLock(addr=0x%x, isBlocking=%s, isRead=%s, isRetry=%s)", this, addr, isBlocking, isRead, isRetry);
		assert(0);
	}
	
	void invalidate(CoherentCacheNode except, uint set, uint way, 
		void delegate() onCompletedCallback) {
		writefln("%s.invalidate(except=%s, set=%d, way=%d)", this, except, set, way);
		assert(0);
	}
	
	void evict(uint set, uint way, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.evict(set=%d, way=%d)", this, set, way);
		assert(0);
	}
	
	void evictReceive(CoherentCacheNode source, uint addr, bool isWriteback, 
		void delegate(bool hasError) onReceiveReplyCallback) {
		writefln("%s.evictReceive(source=%s, addr=0x%x, isWriteback=%s)", this, source, addr, isWriteback);
		assert(0);
	}
	
	void readRequest(CoherentCacheNode target, uint addr, 
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequest(target=%s, addr=0x%x)", this, target, addr);
		assert(0);
	}
	
	void readRequestReceive(CoherentCacheNode source, uint addr, 
		void delegate(bool hasError, bool isShared) onCompletedCallback) {
		writefln("%s.readRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		assert(0);
	}
	void writeRequest(CoherentCacheNode target, uint addr, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequest(target=%s, addr=0x%x)", this, target, addr);
		assert(0);
	}
	
	void writeRequestReceive(CoherentCacheNode source, uint addr, 
		void delegate(bool hasError) onCompletedCallback) {
		writefln("%s.writeRequestReceive(source=%s, addr=0x%x)", this, source, addr);
		assert(0);
	}
	
	abstract uint level();
	
	override string toString() {
		return format("%s", this.name);
	}

	string name;
	ulong id;
	
	MemorySystem memorySystem;
	
	CoherentCacheNode next;	
	
	DelegateEventQueue eventQueue;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

/////////////////////////////////////

class MSHRTarget {
	this() {
	}

	uint threadId;
}

class MSHR {
	this(uint numTargetSlots) {
		this.numTargetSlots = numTargetSlots;
		this.targets = new MSHRTarget[this.numTargetSlots];
	}
	
	uint addr;
	bool isValid;	
	MSHRTarget[] targets;
	
	uint numTargetSlots;
}

class MSHRFile {
	this(uint capacity) {
		this.capacity = capacity;
		this.entries = new MSHR[this.capacity];
	}
	
	bool isFull() {
		assert(0);
	}
	
	uint capacity;
	MSHR[] entries;
}

alias MSHRFile WriteBuffer;