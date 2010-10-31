/*
 * flexim/misc.d
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

module flexim.misc;

import flexim.all;

import dcollections.model.List;
import dcollections.LinkList;

const string PUBLIC = "public";
const string PROTECTED = "protected";
const string PRIVATE = "private";

template declareProperty(T, string _name, string setter_modifier = PUBLIC, string getter_modifier = PUBLIC, string field_modifier = PRIVATE) {
	mixin(setter_modifier ~ ": " ~ "void " ~ _name ~ "(" ~ T.stringof ~ " v) { m_" ~ _name ~ " = v; }");
	mixin(getter_modifier ~ ": " ~ T.stringof ~ " " ~ _name ~ "() { return m_" ~ _name ~ ";}");
	mixin(field_modifier ~ ": " ~ T.stringof ~ " m_" ~ _name ~ ";");
}

/// Generate a 32-bit mask of 'nbits' 1s, right justified.
uint mask(int nbits) {
	return (nbits == 32) ? cast(uint) -1 : (1U << nbits) - 1;
}

/// Generate a 64-bit mask of 'nbits' 1s, right justified.
ulong mask64(int nbits) {
	return (nbits == 64) ? cast(ulong) -1 : (1UL << nbits) - 1;
}

/// Extract the bitfield from position 'first' to 'last' (inclusive)
/// from 'val' and right justify it.  MSB is numbered 31, LSB is 0.
uint bits(uint val, int first, int last) {
	int nbits = first - last + 1;
	return (val >> last) & mask(nbits);
}

/// Extract the bitfield from position 'first' to 'last' (inclusive)
/// from 'val' and right justify it.  MSB is numbered 63, LSB is 0.
ulong bits64(ulong val, int first, int last) {
	int nbits = first - last + 1;
	return (val >> last) & mask(nbits);
}

/// Extract the bit from this position from 'val' and right justify it.
uint bits(uint val, int bit) {
	return bits(val, bit, bit);
}

/// Extract the bit from this position from 'val' and right justify it.
ulong bits64(ulong val, int bit) {
	return bits64(val, bit, bit);
}

/// Mask off the given bits in place like bits() but without shifting.
/// MSB is numbered 31, LSB is 0.
uint mbits(uint val, int first, int last) {
	return val & (mask(first + 1) & ~mask(last));
}

/// Mask off the given bits in place like bits() but without shifting.
/// MSB is numbered 63, LSB is 0.
ulong mbits64(ulong val, int first, int last) {
	return val & (mask64(first + 1) & ~mask(last));
}

uint mask(int first, int last) {
	return mbits(cast(uint) -1, first, last);
}

ulong mask64(int first, int last) {
	return mbits64(cast(ulong) -1, first, last);
}

/// Sign-extend an N-bit value to 32 bits.
int sext(uint val, int n) {
	int sign_bit = bits(val, n - 1, n - 1);
	return sign_bit ? (val | ~mask(n)) : val;
}

/// Sign-extend an N-bit value to 32 bits.
long sext64(ulong val, int n) {
	long sign_bit = bits64(val, n - 1, n - 1);
	return sign_bit ? (val | ~mask64(n)) : val;
}

template Rounding(T) {
	T roundUp(T n, uint alignment) {
		return (n + cast(T) (alignment - 1)) & ~cast(T) (alignment - 1);
	}

	T roundDown(T n, uint alignment) {
		return n & ~(alignment - 1);
	}
}

/// 32 bit is assumed.
uint aligned(uint n, uint i) {
	alias Rounding!(uint) util;
	return util.roundDown(n, i);
}

/// 32 bit is assumed.
uint aligned(uint n) {
	alias Rounding!(uint) util;
	return util.roundDown(n, 4);
}

/// 32 bit is assumed.
uint getBit(uint x, uint b) {
	return x & (1U << b);
}

/// 32 bit is assumed.
uint setBit(uint x, uint b) {
	return x | (1U << b);
}

/// 32 bit is assumed.
uint clearBit(uint x, uint b) {
	return x & ~(1U << b);
}

/// 32 bit is assumed.
uint setBitValue(uint x, uint b, bool v) {
	return v ? setBit(x, b) : clearBit(x, b);
}

uint mod(uint x, uint y) {
	return (x + y) % y;
}

bool getFCC1(uint fcsr, int cc)
{
	if(cc == 0)
		return cast(bool) (fcsr & 0x800000);
	else
		return cast(bool) (fcsr & (0x1000000 << cc));
}

bool getFCC(uint fcsr, int cc_idx)
{
    int shift = (cc_idx == 0) ? 23 : cc_idx + 24;
    bool cc_val = (fcsr >> shift) & 0x00000001;
    return cc_val;
}

void setFCC(ref uint fcsr, int cc) {
	if(cc == 0)
		fcsr=(fcsr | 0x800000);
	else 
		fcsr=(fcsr | (0x1000000 << cc));
}

void clearFCC(ref uint fcsr, int cc) {
	if(cc == 0)
		fcsr=(fcsr & 0xFF7FFFFF); 
	else
		fcsr=(fcsr & (0xFEFFFFFF << cc));
}

uint
genCCVector(uint fcsr, int cc_num, uint cc_val)
{
    int cc_idx = (cc_num == 0) ? 23 : cc_num + 24;

    fcsr = bits(fcsr, 31, cc_idx + 1) << (cc_idx + 1) |
           cc_val << cc_idx |
           bits(fcsr, cc_idx - 1, 0);

    return fcsr;
}

class List(EntryT) {
	this(string name) {
		this.name = name;
		this.entries = new LinkList!(EntryT)();
	}
	
	bool empty() {
		return this.entries.length == 0;
	}
	
	uint size() {
		return this.entries.length;
	}
	
	int opApply(int delegate(ref EntryT) dg) {
		int result;

		foreach(ref EntryT p; this.entries) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}
	
	void popFront() {
		this.entries.takeFront();
	}
	
	void popBack() {
		this.entries.takeBack();
	}
	
	EntryT front() {
		if(!this.empty) {
			return this.entries.front;
		}
		return null;
	}
	
	EntryT back() {
		if(!this.empty) {
			return this.entries.back;
		}
		return null;
	}
	
	void remove(EntryT value) {
		auto c = find(this.entries[], value).begin;
		this.entries.remove(c);
	}
	
	void opOpAssign(string op, EntryT)(EntryT entry)
		if(op == "~") {
		this.entries ~= entry;
	}
	
	void clear() {
		this.entries.clear();
	}
	
	override string toString() {
		return format("%s[size=%d]", this.name, this.size);
	}
	
	string name;
	LinkList!(EntryT) entries;
}

class Queue(EntryT): List!(EntryT) {
	this(string name, uint capacity) {
		super(name);
		this.capacity = capacity;
	}

	bool full() {
		return this.size >= this.capacity;
	}

	void opOpAssign(string op, EntryT)(EntryT entry)
		if(op == "~") {
		if(this.size >= this.capacity) {
			logging.fatalf(LogCategory.MISC, "%s", this);
		}
		this.entries ~= entry;
	}
	
	override string toString() {
		return format("%s[capacity=%d, size=%d]", this.name, this.capacity, this.size);
	}

	uint capacity;
}

class DelayedQueue(EntryT): Queue!(EntryT), EventProcessor {
	this(string name, uint capacity) {
		super(name, capacity);
		this.eventQueue = new DelegateEventQueue();
		Simulator.singleInstance.addEventProcessor(this);
	} 
	
	void enqueue(EntryT entry, ulong delay = 0) {
		this.eventQueue.schedule({this ~= entry;}, delay);
	}
	
	override void processEvents() {
		this.eventQueue.processEvents();
	}
	
	DelegateEventQueue eventQueue;
}

interface Invokable {
	void invoke();
}

class Callback: Invokable {	
	class Invoker: Invokable {
		alias void delegate() CallbackT;
	
		this(CallbackT callback) {
			this.callback = callback;
		}
	
		override void invoke() {
			if(this.callback !is null) {
				this.callback();
			}
		}
	
		CallbackT callback;
	}
	
	this(Invoker callback) {
		this.callback = callback;
	}

	override void invoke() {
		if(this.callback !is null) {
			this.callback.invoke();
		}
	}

	Invoker callback;
}

class Callback0 : Callback {
	this(void delegate() del) {
		super(new Invoker({del();}));
	}
}

class Callback1(Param1T) : Callback {
	this(Param1T m1, void delegate(Param1T) del) {
		super(new Invoker({del(m1);}));
	}	
}

class Callback2(Param1T, Param2T) : Callback {
	this(Param1T m1, Param2T m2, void delegate(Param1T, Param2T) del) {
		super(new Invoker({del(m1, m2);}));
	}	
}

class Callback3(Param1T, Param2T, Param3T) : Callback {
	this(Param1T m1, Param2T m2, Param3T m3, void delegate(Param1T, Param2T, Param3T) del) {		
		super(new Invoker({del(m1, m2, m3);}));
	}
}

class Callback4(Param1T, Param2T, Param3T, Param4T) : Callback {
	this(Param1T m1, Param2T m2, Param3T m3, Param4T m4, void delegate(Param1T, Param2T, Param3T, Param4T) del) {		
		super(new Invoker({del(m1, m2, m3, m4);}));
	}
}

class Callback5(Param1T, Param2T, Param3T, Param4T, Param5T) : Callback {
	this(Param1T m1, Param2T m2, Param3T m3, Param4T m4, Param5T m5, void delegate(Param1T, Param2T, Param3T, Param4T, Param5T) del) {		
		super(new Invoker({del(m1, m2, m3, m4, m5);}));
	}
}

class ContextCallback1(Param1T) {
	alias void delegate(Param1T m1) CallbackT;
	
	this(CallbackT callback) {
		this.callback = callback;
	}
	
	void invoke(Param1T m1) {
		if(this.callback !is null) {
			this.callback(m1);
		}
	}
	
	CallbackT callback;
}

class ContextCallback2(Param1T, Param2T) {
	alias void delegate(Param1T m1, Param2T m2) CallbackT;

	this(CallbackT callback) {
		this.callback = callback;
	}

	void invoke(Param1T m1, Param2T m2) {
		if(this.callback !is null) {
			this.callback(m1, m2);
		}
	}

	CallbackT callback;
}

class ContextCallback3(Param1T, Param2T, Param3T) {
	alias void delegate(Param1T m1, Param2T m2, Param3T m3) CallbackT;

	this(CallbackT callback) {
		this.callback = callback;
	}

	void invoke(Param1T m1, Param2T m2, Param3T m3) {
		if(this.callback !is null) {
			this.callback(m1, m2, m3);
		}
	}

	CallbackT callback;
}

class ContextCallback4(Param1T, Param2T, Param3T, Param4T) {
	alias void delegate(Param1T m1, Param2T m2, Param3T m3, Param4T m4) CallbackT;

	this(CallbackT callback) {
		this.callback = callback;
	}

	void invoke(Param1T m1, Param2T m2, Param3T m3, Param4T m4) {
		if(this.callback !is null) {
			this.callback(m1, m2, m3, m4);
		}
	}

	CallbackT callback;
}

class Event(EventTypeT, EventContextT) {
	this(EventTypeT eventType, EventContextT context, ulong scheduled, ulong when) {
		this.eventType = eventType;
		this.context = context;
		this.scheduled = scheduled;
		this.when = when;
	}
	
	override string toString() {
		string str;
		
		str ~= format("Event[type=%s, context=%s, scheduled=%d, when=%d]", this.eventType, this.context, this.scheduled, this.when);
		
		return str;
	}

	EventTypeT eventType;
	EventContextT context;
	ulong scheduled;
	ulong when;
}

interface EventProcessor {
	void processEvents();
}

class EventQueue(EventTypeT: string, EventContextT): EventProcessor {
	alias void delegate(EventTypeT, EventContextT, ulong) EventHandler;

	public:
		this(string name) {
			this.name = name;
		}

		void registerHandler(EventTypeT eventType, EventHandler eventHandler) {
			this.eventHandlers[eventType] ~= eventHandler;
		}

		void schedule(EventTypeT eventType, EventContextT context, ulong delay = 0) {
			assert(delay >= 0);
			this.schedule(new Event!(EventTypeT, EventContextT)(eventType, context, currentCycle, currentCycle + delay));
		}

		void schedule(Event!(EventTypeT, EventContextT) event) {
			this.events[event.when] ~= event;
		}

		void execute(EventTypeT eventType, EventContextT context) {
			this.execute(new Event!(EventTypeT, EventContextT)(eventType, context, currentCycle, currentCycle));
		}

		void execute(Event!(EventTypeT, EventContextT) event) {
			assert(event.eventType in this.eventHandlers);
			foreach(eventHandler; this.eventHandlers[event.eventType]) {
				eventHandler(event.eventType, event.context, event.when);
			}
		}

		void processEvents() {
			if(currentCycle in this.events) {
				foreach(event; this.events[currentCycle]) {
					this.execute(event);
				}
				this.events.remove(currentCycle);
			}
		}
		
		override string toString() {
			return format("%s[events.length=%d]", this.name, this.events.length);
		}
		
		string name;

	private:
		EventHandler[][EventTypeT] eventHandlers;		
		Event!(EventTypeT, EventContextT)[][ulong] events;
}

class DelegateEventQueue: EventProcessor {
	alias void delegate() DelegateT;
	alias LinkList!(EventT) LinkListT; 
	
	class EventT {
		this(DelegateT del, ulong when) {
			this.del = del;
			this.when = when;
		}
		
		DelegateT del;
		ulong when;
	}
	
	this() {
		this.events = new LinkListT();
	}
			
	void processEvents() {
		foreach(ref bool doRemove, EventT event; &this.events.purge) {
			if(event.when == currentCycle) {
				event.del();
				doRemove = true;
			}
			else {
				doRemove = false;
			}
		}
	}
	
	void schedule(void delegate() del, ulong delay = 0) {
		ulong when = currentCycle + delay;
		this.events ~= new EventT(del, when);
	}
	
	dcollections.model.List.List!(EventT) events;
}