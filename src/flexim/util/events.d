/*
 * flexim/util/events.d
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

module flexim.util.events;

import flexim.all;

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

class EventQueue(EventTypeT: string, EventContextT): EventProcessor, CurrentCycleProvider, SchedulerProvider!(EventTypeT, EventContextT) {
	alias void delegate(EventTypeT, EventContextT, ulong) EventHandler;

	public:
		this(string name) {
			this.name = name;
	        this.eventArray = new Event!(EventTypeT, EventContextT)[event_queue_size];
			this.events = BinaryHeap!(Event!(EventTypeT, EventContextT)[])(this.eventArray, 0);
		}
		
		ulong currentCycle() {
			return Simulator.singleInstance.currentCycle;
		}

		void registerHandler(EventTypeT eventType, EventHandler eventHandler) {
			this.eventHandlers[eventType] ~= eventHandler;
		}

		void schedule(EventTypeT eventType, EventContextT context, ulong delay = 0) {
			assert(delay >= 0);
			ulong when = this.currentCycle + delay;
			ulong scheduled = this.currentCycle;

			this.schedule(new Event!(EventTypeT, EventContextT)(eventType, context, scheduled, when));
		}

		void schedule(Event!(EventTypeT, EventContextT) event) {
			assert(this.events.length < event_queue_size, to!(string)(this));
			
			this.events.insert(event);

			logging.infof(LogCategory.EVENT_QUEUE, "  %s.schedule(%s)", this.name, to!(string)(event));
		}

		void execute(EventTypeT eventType, EventContextT context) {
			this.execute(new Event!(EventTypeT, EventContextT)(eventType, context, this.currentCycle, this.currentCycle));
		}

		void execute(Event!(EventTypeT, EventContextT) event) {
			assert(event.eventType in this.eventHandlers);
			
			logging.infof(LogCategory.EVENT_QUEUE, "  %s.execute(%s)", this.name, to!(string)(event));

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
				assert(event.when >= this.currentCycle);
				if(event.when != this.currentCycle) {
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
					writefln("    [%d] event: %s", i, to!(string)(event));
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