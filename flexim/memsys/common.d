/*
 * flexim/memsys/common.d
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

module flexim.memsys.common;

import flexim.all;

uint currentMessageID = 1;

class Message {	
	this(Request request) {
		this.request = request;

		this.id = currentMessageID++;
	}

	override string toString() {
		return format("Message[ID: %d, request: %s, isShared: %s, hasData: %s]", this.id, this.request, this.isShared, this.hasData);
	}

	uint id;
	
	Request request;

	bool isShared;
	bool hasData;

	CacheBlockState arg;
}

uint currentDeviceID = 1;

abstract class Interconnect {
	this(string name) {
		this.name = name;
	}

	override string toString() {
		return format("%s", this.name);
	}

	abstract void send(Message msg, Node sender, Node receiver, uint latency = 1);

	string name;
	Node[] nodes;
}

class P2PInterconnect : Interconnect {
	this(string name) {
		super(name);
	}

	override void send(Message msg, Node sender, Node receiver, uint latency = 1) {		
		logging[LogCategory.NET].infof("%s.send(msg = %s, sender = %s, receiver = %s, latency = %d)", this.name, to!(string)(msg), to!(string)(sender), to!(string)(receiver), latency);
		
		Simulator.singleInstance.eventQueue.schedule(SimulatorEventType.GENERAL,
				new SimulatorEventContext("Interconnect", new Callback3!(Interconnect, Message, Node)(this, msg, sender, &receiver.receive)), latency);
	}
}

abstract class Node {
	alias ContextCallback3!(Interconnect, Message, Node) MessageReceivedHandler;
	
	this(string name, bool isPrivate) {
		this(name, currentDeviceID++, isPrivate);
	}

	this(string name, uint id, bool isPrivate) {
		this.name = name;
		this.id = id;
		this.isPrivate = isPrivate;
	}

	override string toString() {
		return format("%s", this.name);
	}

	void receive(Interconnect interconnect, Message msg, Node sender) {
		logging[LogCategory.NET].infof("%s.receive(%s, %s, %s)", this.name, interconnect, msg, sender);

		if(interconnect == this.upperInterconnect) {
			foreach(handler; this.upperInterconnectMessageReceived) {
				handler.invoke(interconnect, msg, sender);
			}
		} else if(interconnect == this.lowerInterconnect) {
			foreach(handler; this.lowerInterconnectMessageReceived) {
				handler.invoke(interconnect, msg, sender);
			}
		}
	}

	string name;
	uint id;

	bool isPrivate;

	MessageReceivedHandler[] upperInterconnectMessageReceived;
	MessageReceivedHandler[] lowerInterconnectMessageReceived;

	Interconnect upperInterconnect;
	Interconnect lowerInterconnect;
}

interface CacheHierarchy(CacheT, StateT) {
	MMU!(StateT) mmu();
	MOESIEventQueue eventQueue(); //TODO: you'd better not bind MOESI here
}

uint currentRequestID = 1;

enum RequestType: string {
	READ = "READ",
	WRITE = "WRITE"
}

class Request {
	this(RequestType type, Addr pc, Addr addr, Callback1!(Request) onCompletedCallback) {
		this.id = currentRequestID++;
		this.type = type;
		this.pc = pc;
		this.addr = addr;
		this.onCompletedCallback = onCompletedCallback;
	}

	override string toString() {
		return format("%s[ID: %d, pc: 0x%x, addr: 0x%x]", to!(string)(this.type), this.id, this.pc, this.addr);
	}

	uint id;
	RequestType type;
	Addr pc;
	Addr addr;
	Callback1!(Request) onCompletedCallback;
}

class Sequencer(RequestT, CacheT): Node {
	this(string name, CacheT l1Cache) {
		super(name, true);

		this.l1Cache = l1Cache;

		this.maxReadCapacity = 32;

		this.lowerInterconnectMessageReceived ~= new MessageReceivedHandler(&this.handleLowerInterconnectMessage);
	}
	
	uint blockSize() {
		return this.l1Cache.blockSize;
	}

	Addr blockAddress(Addr addr) {
		return this.l1Cache.cache.tag(addr);
	}

	void read(RequestT req) {
		logging[LogCategory.REQUEST].infof("%s.read(%s)", this.name, req);

		assert(req !is null);
		assert(req.type == RequestType.READ);

		Addr blockPhaddr = this.blockAddress(req.addr);

		if(blockPhaddr in this.pendingReads) {
			this.pendingReads[blockPhaddr] ~= req;
		} else if(this.canAcceptRead(blockPhaddr)) {
			Message r = new Message(req);

			this.lowerInterconnect.send(r, this, this.l1Cache);

			this.pendingReads[blockPhaddr] ~= req;
		} else {
			assert(0);
			//TODO: schedule retry request
		}
	}

	void write(RequestT req) {
		logging[LogCategory.REQUEST].infof("%s.write(%s)", this.name, req);

		assert(req !is null);
		assert(req.type == RequestType.WRITE);

		Addr blockPhaddr = this.blockAddress(req.addr);

		Message w = new Message(req);

		this.lowerInterconnect.send(w, this, this.l1Cache);
	}

	bool canAcceptRead(Addr addr) {
		return (this.pendingReads.length < this.maxReadCapacity);
	}

	void completeRequest(RequestT req) {
		logging[LogCategory.REQUEST].infof("%s.completeRequest(%s)", this.name, req);

		if(req.onCompletedCallback !is null) {
			req.onCompletedCallback.invoke();
		}
	}

	void handleLowerInterconnectMessage(Interconnect interconnect, Message msg, Node sender) {
		logging[LogCategory.REQUEST].infof("%s.handleLowerInterconnectMessage(%s, %s, %s)", this.name, interconnect, msg, sender);

		Addr blockPhaddr = this.blockAddress(msg.request.addr);

		if(blockPhaddr in this.pendingReads) {
			foreach(req; this.pendingReads[blockPhaddr]) {
				this.completeRequest(req);
			}

			this.pendingReads.remove(blockPhaddr);
		}
	}

	override string toString() {
		return format("%s[pendingReads.length: %d]", this.name, this.pendingReads.length);
	}

	uint maxReadCapacity;

	RequestT[][Addr] pendingReads;

	CacheT l1Cache;
}