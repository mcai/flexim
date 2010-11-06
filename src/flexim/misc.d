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

import std.file;
import std.xml;

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

class ListenerSupport(SenderT, ContextT) {
	alias void delegate(SenderT, ContextT) ListenerT;
	
	this() {
	}
	
	void addListener(ListenerT listener) {
		this.listeners ~= listener;
	}
    
    void dispatch(SenderT sender, ContextT context) {
		foreach(listener; this.listeners) {
			listener(sender, context);
		}
    }
    
	ListenerT[] listeners;
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

class List(EntryT, ListT) {
	alias EntryT ContextT;
	alias ListenerSupport!(ListT, ContextT) ListenerSupportT;
	alias ListenerSupportT.ListenerT ListenerT;
	
	this(string name) {
		this.name = name;
		this.entries = new LinkList!(EntryT)();
		
		this.listenerSupportTakeFront = new ListenerSupportT();
		this.listenerSupportTakeBack = new ListenerSupportT();
		this.listenerSupportRemove = new ListenerSupportT();
		this.listenerSupportAppend = new ListenerSupportT();
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
	
	int opApplyReverse(int delegate(ref EntryT) dg) {
		int result;

		foreach_reverse(ref EntryT p; this.entries) {
			result = dg(p);
			if(result)
				break;
		}
		return result;
	}
	
	void takeFront() {
		this.listenerSupportTakeFront.dispatch(cast(ListT) this, this.front);
		this.entries.takeFront();
	}
	
	void takeBack() {
		this.listenerSupportTakeBack.dispatch(cast(ListT) this, this.back);
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
		this.listenerSupportRemove.dispatch(cast(ListT) this, value);
		auto c = find(this.entries[], value).begin;
		this.entries.remove(c);
	}
	
	void opOpAssign(string op, EntryT)(EntryT value)
		if(op == "~") {
		this.listenerSupportAppend.dispatch(cast(ListT) this, value);
		this.entries ~= value;
	}
	
	void clear() {
		this.entries.clear();
	}
	
	void addTakeFrontListener(ListenerT listener) {
		this.listenerSupportTakeFront.addListener(listener);
	}
	
	void addTakeBackListener(ListenerT listener) {
		this.listenerSupportTakeBack.addListener(listener);
	}
	
	void addRemoveListener(ListenerT listener) {
		this.listenerSupportRemove.addListener(listener);
	}
	
	void addAppendListener(ListenerT listener) {
		this.listenerSupportAppend.addListener(listener);
	}
	
	override string toString() {
		return format("%s[size=%d]", this.name, this.size);
	}
	
	string name;
	LinkList!(EntryT) entries;
	
	ListenerSupportT listenerSupportTakeFront;
	ListenerSupportT listenerSupportTakeBack;
	ListenerSupportT listenerSupportRemove;
	ListenerSupportT listenerSupportAppend;
}

class Queue(EntryT, QueueT): List!(EntryT, QueueT) {
	this(string name, uint capacity) {
		super(name);
		this.capacity = capacity;
	}

	bool full() {
		return this.size >= this.capacity;
	}

	void opOpAssign(string op, EntryT)(EntryT value)
		if(op == "~") {
		if(this.size >= this.capacity) {
			logging.fatalf(LogCategory.MISC, "%s", this);
		}

		super ~= value;
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

enum LogCategory: string {
	EVENT_QUEUE = "EVENT_QUEUE",
	SIMULATOR = "SIMULATOR",
	PROCESSOR = "PROCESSOR",
	CORE = "CORE",
	THREAD = "THREAD",
	PROCESS = "PROCESS",
	REGISTER = "REGISTER",
	REQUEST = "REQUEST",
	CACHE = "CACHE",
	COHERENCE = "COHERENCE",
	MEMORY = "MEMORY",
	NET = "NET",
	INSTRUCTION = "INSTRUCTION",
	SYSCALL = "SYSCALL",
	ELF = "ELF",
	CONFIG = "CONFIG",
	STAT = "STAT",
	MISC = "MISC",
	OOO = "OOO",
	TEST = "TEST",
	DEBUG = "DEBUG",
	XML = "XML"
}

class Logger {
	static this() {
		singleInstance = new Logger();
	}
	
	this() {		
			this.enable(LogCategory.SIMULATOR);
		
	//		this.enable(LogCategory.EVENT_QUEUE);
	//		this.enable(LogCategory.PROCESSOR);
	//		this.enable(LogCategory.REGISTER);
			this.enable(LogCategory.REQUEST);
	//		this.enable(LogCategory.CACHE);
			this.enable(LogCategory.COHERENCE);
	//		this.enable(LogCategory.MEMORY);
	//		this.enable(LogCategory.NET);
			this.enable(LogCategory.CONFIG);
			this.enable(LogCategory.STAT);
	//		this.enable(LogCategory.MISC);
	//		this.enable(LogCategory.OOO);
	//		this.enable(LogCategory.TEST);
	//		this.enable(LogCategory.XML);
			this.enable(LogCategory.DEBUG);
	}
	
	void enable(LogCategory category) {
		this.logSwitches[category] = true;
	}

	void disable(LogCategory category) {
		this.logSwitches[category] = false;
	}

	bool enabled(LogCategory category) {
		return category in this.logSwitches && this.logSwitches[category];
	}
	
	string message(string caption, string text) {
		return format("[%d] \t%s%s", currentCycle, caption.endsWith("info") ? "" : "[" ~ caption ~ "] ", text);
	}

	void infof(LogCategory, T...)(LogCategory category, T args) {
		debug {
			this.info(category, format(args));
		}
	}

	void info(LogCategory category, string text) {
		debug {
			if(this.enabled(category)) {
				stdout.writeln(this.message(category ~ "|" ~ "info", text));
			}
		}
	}

	void warnf(LogCategory, T...)(LogCategory category, T args) {
		this.warn(category, format(args));
	}

	void warn(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "warn", text));
	}

	void fatalf(LogCategory, T...)(LogCategory category, T args) {
		this.fatal(category, format(args));
	}

	void fatal(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "fatal", text));
		executeEvent(SimulatorEventType.FATAL, new SimulatorEventContext(this.message(category ~ "|" ~ "fatal", text)));
	}

	void panicf(LogCategory, T...)(LogCategory category, T args) {
		this.panic(category, format(args));
	}

	void panic(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "panic", text));
		executeEvent(SimulatorEventType.PANIC, new SimulatorEventContext(this.message(category ~ "|" ~ "panic", text)));
	}

	void haltf(LogCategory, T...)(LogCategory category, T args) {		
		this.halt(category, format(args));
	}

	void halt(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "halt", text));
		executeEvent(SimulatorEventType.HALT, new SimulatorEventContext(this.message(category ~ "|" ~ "halt", text)));
	}

	bool[LogCategory] logSwitches;
	
	static Logger singleInstance;
}

alias Logger.singleInstance logging;

class XMLConfig {
	this(string typeName) {
		this.typeName = typeName;
	}
	
	override string toString() {
		return format("%s[attributes.length=%d, entries=[%s]]", 
			this.typeName !is null ? this.typeName : "NULL",
			this.attributes.length,
			this.entries.length > 0 ? reduce!("a ~ b")(map!(to!(string))(this.entries)) : "N/A");
	}
	
	void opIndexAssign(string value, string index) {
		this.attributeKeys ~= index;
		this.attributes[index] = value;
	}
	
	string opIndex(string index) {
		assert(index in this.attributes, format("typeName=%s, index=%s", this.typeName, index));
		return this.attributes[index];
	}

	int opApply(int delegate(ref string, ref string) dg) {
		int result;
		
		foreach(key; this.attributeKeys) {
			string value = this.attributes[key];
			result = dg(key, value);
			if(result)
				break;
		}
		
		return result;
	}

	string typeName;
	
	private string[] attributeKeys;
	private string[string] attributes;
	
	XMLConfig[] entries;
}

class XMLConfigFile: XMLConfig {
	this(string typeName) {
		super(typeName);
	}
}
	
void serialize(XMLConfig entry, Element rootElement) {
	Element element = new Element(entry.typeName);

	rootElement ~= element;
	
	serialize(entry, rootElement, element);
}
	
void serialize(XMLConfig entry, Element rootElement, Element element) {
	foreach(key, value; entry) {
        element.tag.attr[key] = value;
	}
	
	foreach(child; entry.entries) {
		serialize(child, element);
	}
}
	
void serialize(XMLConfigFile config, string xmlFileName) {
	Document doc = new Document(new Tag(config.typeName));

	serialize(config, null, doc);
    
    string contentToWrite = "<?xml version=\"1.0\"?>\n" ~ join(doc.pretty(3),"\n");
    
    std.file.write(xmlFileName, contentToWrite);
}

void deserialize(XMLConfig rootEntry, ElementParser xml) {
	XMLConfig entry = new XMLConfig(xml.tag.name);
	
	foreach(key, value; xml.tag.attr) {
		entry[key] = value;
	}

    xml.onStartTag[null] = (ElementParser xml) {
    	deserialize(entry, xml);
    };

    xml.parse();
    
    rootEntry.entries ~= entry;
}

XMLConfigFile deserialize(string xmlFileName) {
    string s = cast(string) std.file.read(xmlFileName);

    check(s);

	DocumentParser xml = new DocumentParser(s);
    
	XMLConfigFile xmlConfig = new XMLConfigFile(xml.tag.name);
	
	foreach(key, value; xml.tag.attr) {
		xmlConfig[key] = value;
	}

    xml.onStartTag[null] = (ElementParser xml) {
    	deserialize(xmlConfig, xml);
    };
	
    xml.parse();
    
    return xmlConfig;
}

abstract class XMLFileSerializer(ObjectT) {
	abstract XMLConfigFile save(ObjectT config);
	abstract ObjectT load(XMLConfigFile xmlConfigFile);
	
	void saveXML(ObjectT config, string xmlFileName) {
		//logging.infof(LogCategory.XML, "%s.saveXML(%s, %s)", "XMLFileSerializer", config, xmlFileName);
		XMLConfigFile xmlConfigFile = save(config);
		serialize(xmlConfigFile, xmlFileName);
	}
	
	ObjectT loadXML(string xmlFileName, ObjectT defaultValue = null) {
		//logging.infof(LogCategory.XML, "%s.loadXML(%s)", "XMLFileSerializer", xmlFileName);
		if(exists(xmlFileName)) {
			XMLConfigFile xmlConfigFile = deserialize(xmlFileName);
			return load(xmlConfigFile);
		}
		else {
			return defaultValue;
		}
	}
}

abstract class XMLSerializer(ObjectT) {
	abstract XMLConfig save(ObjectT config);
	abstract ObjectT load(XMLConfig xmlConfig);
}
