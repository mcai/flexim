/*
 * flexim/mem/sequencer.d
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

module flexim.mem.sequencer;

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

enum CPURequestType: string {
	READ = "READ",
	WRITE = "WRITE"
}

class CPURequest {
	this(CPURequestType type, DynamicInst uop, uint pc, uint vtaddr, RUUStation rs, uint phaddr, Callback onCompletedCallback) {
		this.id = currentId++;
		
		this.type = type;
		this.uop = uop;
		this.pc = pc;
		this.vtaddr = vtaddr;
		this.rs = rs;
		this.phaddr = phaddr;
		this.onCompletedCallback = onCompletedCallback;
	}

	override string toString() {
		return format("%s[ID=%d, pc=0x%x, vtaddr=0x%x, phaddr=0x%x]", to!(string)(this.type), this.id, this.pc, this.vtaddr, this.phaddr);
	}

	ulong id;
	
	CPURequestType type;
	DynamicInst uop;
	uint pc;
	uint vtaddr;
	RUUStation rs;
	uint phaddr;
	Callback onCompletedCallback;
	
	static this() {
		currentId = 0;
	}
	
	static ulong currentId;
}

class ReadCPURequest: CPURequest {
	this(DynamicInst uop, uint pc, uint vtaddr, RUUStation rs, uint phaddr, void delegate(CPURequest) del) {
		super(CPURequestType.READ, uop, pc, vtaddr, rs, phaddr, new Callback1!(CPURequest)(this, del));
	}
}

class WriteCPURequest: CPURequest {
	this(DynamicInst uop, uint pc, uint vtaddr, RUUStation rs, uint phaddr, void delegate(CPURequest) del) {
		super(CPURequestType.WRITE, uop, pc, vtaddr, rs, phaddr, new Callback1!(CPURequest)(this, del));
	}
}

class Sequencer: MemorySystemNode {
	this(string name, CoherentCache l1Cache) {
		super(name, l1Cache.memorySystem);

		this.l1Cache = l1Cache;

		this.maxReadCapacity = 32;
	}

	void read(ReadCPURequest req) {
		//logging.infof(LogCategory.REQUEST, "%s.read", this.name);

		assert(req !is null);
		assert(req.type == CPURequestType.READ);

		uint blockPhaddr = this.blockAddress(req.phaddr);

		if(blockPhaddr in this.pendingReads) {
			this.pendingReads[blockPhaddr] ~= req;
		} else if(this.canAcceptRead(blockPhaddr)) {
			this.pendingReads[blockPhaddr] ~= req;
			this.sendLoad(req, this.l1Cache);
		} else {
			assert(0);
			//TODO: schedule retry request
		}
	}
	
	void sendLoad(ReadCPURequest req, CoherentCache target) {
		target.receiveLoad(req, this);
	}

	void write(WriteCPURequest req) {
		//logging.infof(LogCategory.REQUEST, "%s.write", this.name);

		assert(req !is null);
		assert(req.type == CPURequestType.WRITE);

		this.sendStore(req, this.l1Cache);
	}
	
	void sendStore(WriteCPURequest req, CoherentCache target) {
		target.receiveStore(req, this);
	}

	bool canAcceptRead(uint addr) {
		return (this.pendingReads.length < this.maxReadCapacity);
	}

	void completeRequest(ReadCPURequest req) {
		//logging.infof(LogCategory.REQUEST, "%s.completeRequest", this.name);

		if(req.onCompletedCallback !is null) {
			req.onCompletedCallback.invoke();
		}
	}

	void receiveLoadResponse(ReadCPURequest req, CoherentCache source) {
		//logging.infof(LogCategory.REQUEST, "%s.handleMessage(%s, %s)", this.name, req, source);

		uint blockPhaddr = this.blockAddress(req.phaddr);
		
		assert(blockPhaddr in this.pendingReads, format("pendingReads.length=%d", this.pendingReads.length));

		if(blockPhaddr in this.pendingReads) {
			foreach(pendingRead; this.pendingReads[blockPhaddr]) {
				this.completeRequest(pendingRead);
			}

			this.pendingReads.remove(blockPhaddr);
		}
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

	ReadCPURequest[][uint] pendingReads;

	CoherentCache l1Cache;
}