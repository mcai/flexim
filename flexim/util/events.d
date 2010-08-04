module flexim.util.events;

import flexim.all;

interface Callback {
	void invoke();
}

class Callback0: Callback {
	alias void delegate() CallbackT;

	this(CallbackT callback) {
		this.callback = callback;
	}

	override void invoke() {
		if(this.callback !is null) {
			this.callback();
		}
	}
	
	override string toString() {
		string str;
		
		str ~= "Callback0";
		
		return str;
	}

	CallbackT callback;
}

class Callback1(Param1T): Callback {
	alias void delegate(Param1T m1) CallbackT;

	this(Param1T m1, CallbackT callback) {
		this.m1 = m1;
		this.callback = callback;
	}

	override void invoke() {
		if(this.callback !is null) {
			this.callback(this.m1);
		}
	}
	
	override string toString() {
		string str;
		
//		str ~= format("Callback1[m1: %s]", to!string(this.m1));
		
		return str;
	}

	Param1T m1;
	CallbackT callback;
}

class ContextCallback1(Param1T) {
	alias void delegate(Param1T m1) CallbackT;
	
	this(CallbackT callback) {
		this.callback = callback;
	}
	
	void invoke(Param11T m1) {
		if(this.callback !is null) {
			this.callback(m1);
		}
	}
	
	override string toString() {
		string str;
		
		str ~= "ContextCallback1";
		
		return str;
	}
	
	CallbackT callback;
}

class Callback2(Param1T, Param2T): Callback {
	alias void delegate(Param1T m1, Param2T m2) CallbackT;

	this(Param1T m1, Param2T m2, CallbackT callback) {
		this.m1 = m1;
		this.m2 = m2;
		this.callback = callback;
	}

	override void invoke() {
		if(this.callback !is null) {
			this.callback(this.m1, this.m2);
		}
	}
	
	override string toString() {
		string str;
		
//		str ~= format("Callback2[m1: %s, m2: %s]", to!string(this.m1), to!string(this.m2));
		
		return str;
	}

	Param1T m1;
	Param2T m2;

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
	
	override string toString() {
		string str;
		
		str ~= "ContextCallback2";
		
		return str;
	}

	CallbackT callback;
}

class Callback3(Param1T, Param2T, Param3T): Callback {
	alias void delegate(Param1T m1, Param2T m2, Param3T m3) CallbackT;

	this(Param1T m1, Param2T m2, Param3T m3, CallbackT callback) {
		this.m1 = m1;
		this.m2 = m2;
		this.m3 = m3;
		this.callback = callback;
	}

	override void invoke() {
		if(this.callback !is null) {
			this.callback(this.m1, this.m2, this.m3);
		}
	}
	
	override string toString() {
		string str;
		
//		str ~= format("Callback3[m1: %s, m2: %s, m3: %s]", to!string(this.m1), to!string(this.m2), to!string(this.m3));
		
		return str;
	}

	Param1T m1;
	Param2T m2;
	Param3T m3;

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
	
	override string toString() {
		string str;
		
		str ~= "ContextCallback3";
		
		return str;
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
	
	long opCmp(Event otherEvent) {
		return otherEvent.when - this.when;
	}
	
	override string toString() {
		string str;
		
		str ~= format("Event[type: %s, context: %s, scheduled: %d, when: %d]", this.eventType, this.context, this.scheduled, this.when);
		
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

const uint event_queue_size = 10000; 

class EventQueue(EventTypeT: string, EventContextT): EventProcessor {
	alias void delegate(EventTypeT, EventContextT, ulong) EventHandler;

	public:
		this(string name) {
			this.name = name;
	        this.eventArray = new Event!(EventTypeT, EventContextT)[event_queue_size];
			this.events = BinaryHeap!(Event!(EventTypeT, EventContextT)[])(this.eventArray, 0);
		}

		void registerHandler(EventTypeT eventType, EventHandler eventHandler) {
			this.eventHandlers[eventType] ~= eventHandler;
		}

		void schedule(EventTypeT eventType, EventContextT context, ulong delay) {
			assert(delay >= 0);
			ulong when = Simulator.singleInstance.currentCycle + delay;
			ulong scheduled = Simulator.singleInstance.currentCycle;

			this.schedule(new Event!(EventTypeT, EventContextT)(eventType, context, scheduled, when));
		}

		void schedule(Event!(EventTypeT, EventContextT) event) {
			assert(this.events.length < event_queue_size, to!string(this));
			
			this.events.insert(event);

			logging[LogCategory.EVENT_QUEUE].infof("  %s.schedule(%s)", this.name, to!(string)(event));
		}

		void execute(EventTypeT eventType, EventContextT context) {
			this.execute(new Event!(EventTypeT, EventContextT)(eventType, context, Simulator.singleInstance.currentCycle, Simulator.singleInstance.currentCycle));
		}

		void execute(Event!(EventTypeT, EventContextT) event) {
			assert(event.eventType in this.eventHandlers);
			
			logging[LogCategory.EVENT_QUEUE].infof("  %s.execute(%s)", this.name, to!(string)(event));

			foreach(eventHandler; this.eventHandlers[event.eventType]) {
				eventHandler(event.eventType, event.context, event.when);
			}
		}

		void processEvents() {
			while(true) {
				if(this.events.empty) {
					break;
				}

				/* extract event from heap */
				Event!(EventTypeT, EventContextT) event = this.events.front;

				/* must we process it? */
				assert(event.when >= Simulator.singleInstance.currentCycle);
				if(event.when != Simulator.singleInstance.currentCycle) {
					break;
				}

				/* ok, process it */
				this.pop();

				this.execute(event);
			}
		}

		void clear() {
			while(true) {
				if(this.events.empty) {
					break;
				}

				/* extract event from heap */
				Event!(EventTypeT, EventContextT) event = this.pop();
				this.execute(event);
			}
		}

		Event!(EventTypeT, EventContextT) pop() {
			assert(!this.events.empty);
			Event!(EventTypeT, EventContextT) event = this.events.front;
			this.events.removeFront();
			return event;
		}

		int size() {
			return this.events.length;
		}
		
		override string toString() {
			string str;
			
			writeln("eventQueue: ");
			
			foreach(i, event; this.eventArray) {
				if(event !is null) {
					writefln("    [%d] event: %s", i, to!string(event));
				}
			}
			
			return str;
		}
		
		string name;

	private:
		EventHandler[][EventTypeT] eventHandlers;

		Event!(EventTypeT, EventContextT)[] eventArray;
		BinaryHeap!(Event!(EventTypeT, EventContextT)[]) events;
}

interface Invokable {
	void invoke();
}

class EventCallbackInvoker(EventTypeT, ContextT, alias EventQueueT = EventQueue!(EventTypeT, ContextT)) : Invokable {
	this(EventTypeT retEvent, ContextT retStack, EventQueueT eventQueue) {
		this.retEvent = retEvent;
		this.retStack = retStack;
		this.eventQueue = eventQueue;
	}
	
	void invoke() {
		this.eventQueue.schedule(this.retEvent, this.retStack, 0);
	}
	
	EventTypeT retEvent;
	ContextT retStack;
	EventQueueT eventQueue;	
}

alias void delegate() EventCallback;