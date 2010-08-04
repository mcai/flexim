module flexim.cpu.ooo.common;

import flexim.all;

const uint STORE_ADDR_INDEX = 0;
const uint STORE_OP_INDEX = 1;

ulong inst_seq = 0;

class Link(LinkT, EntryT) {
	this(string name, EntryT entry) {
		this.name = name;
		this.entry = entry;
		this.next = null;
	}

	string name;

	EntryT entry;
	LinkT next;
}

class FetchRecord {
	this(Addr pc, DynamicInst uop) {
		this.pc = pc;
		this.uop = uop;
	}

	override string toString() {
		return format("FetchRecord [uop = %s]", uop);
	}

	Addr pc;
	DynamicInst uop;
}

enum RUUStationStatus : string {
	FETCHED = "FETCHED",
	READY = "READY",
	ISSUED = "ISSUED",
	COMPLETED = "COMPLETED"
}

class RUUStation {
	this(Addr pc, DynamicInst uop) {
		this.pc = pc;
		this.uop = uop;

		this.inLsq = false;
		this.eaComp = false;
		this.ea = 0;

		this.seq = ++inst_seq;

		this.status = RUUStationStatus.FETCHED;
	}

	bool storeAddrReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.uop.staticInst));		
		assert(memOp !is null);		
		return !(memOp.memSrcRegIdx[STORE_ADDR_INDEX] in this.ideps);
	}

	bool storeOpReady() {
		MemoryOp memOp = (cast(MemoryOp)(this.uop.staticInst));		
		assert(memOp !is null);		
		return !(memOp.memSrcRegIdx[STORE_OP_INDEX] in this.ideps);
	}

	bool operandsReady() {
		return this.ideps.length == 0;
	}

	override string toString() {
		string str;
		
		str ~= format("RUUStation [uop = %s, inLsq: %s, eaComp: %s, ea: %d, seq: %d, status: %s, operandsReady: %s]",
				this.uop, this.inLsq, this.eaComp, this.ea, this.seq, this.status, this.operandsReady);
		
		if(this.uop.isStore) {
			str ~= format("\n     storeOpReady: %s, operandsReady: %s", this.storeOpReady, this.operandsReady);
		}
		
		foreach(i, idep; this.ideps) {
			str ~= format("\n     ideps[%d]: %s\n", i, to!(string)(idep));
		}
		
		return str;
	}

	Addr pc;
	DynamicInst uop;
	bool inLsq;
	bool eaComp;
	Addr ea;

	ulong seq;

	RUUStationStatus status;

	RUUStation[uint] ideps;
	uint[MAX_ODEPS] onames;
}

class RegisterDependency {
	this(uint regName, RUUStation creator) {
		this.regName = regName;
		this.creator = creator;
	}

	bool ready() {
		return this.creator is null;
	}

	uint regName;
	RUUStation creator;
	RUUStation[] dependents;
}

class IFQ: Queue!(FetchRecord) {
	this(string name) {
		super(name, 4);
	}
}

class ReadyQ: Queue!(RUUStation) {
	this(string name) {
		super(name, 80);
	}
}

class RUU: Queue!(RUUStation) {
	this(string name) {
		super(name, 16);
	}
}

class LSQ: Queue!(RUUStation) {
	this(string name) {
		super(name, 8);
	}
}

enum EventQEventType: string {
	DEFAULT = "default"
}

class EventQ: EventQueue!(EventQEventType, RUUStation) {
	public:
		this(string name) {
			super(name);

			this.registerHandler(EventQEventType.DEFAULT, &this.haltHandler);
		}

		void haltHandler(EventQEventType eventType, RUUStation context, ulong when) {
			this.buffer ~= context;
		}

		void enqueue(RUUStation rs, ulong delay) {
			this.schedule(EventQEventType.DEFAULT, rs, delay);
		}

		bool empty() {
			return this.buffer.empty;
		}

		uint size() {
			return this.buffer.length;
		}

		int opApply(int delegate(ref uint, ref RUUStation) dg) {
			int result;

			foreach(ref uint i, ref RUUStation p; this.buffer) {
				result = dg(i, p);
				if(result)
					break;
			}
			return result;
		}

		int opApply(int delegate(ref RUUStation) dg) {
			int result;

			foreach(ref RUUStation p; this.buffer) {
				result = dg(p);
				if(result)
					break;
			}
			return result;
		}

		void popFront() {			
			this.buffer.popFront;
		}

		RUUStation front() {
			return this.buffer.front;
		}

		override string toString() {
			string str;

			str ~= format("%s [size: %d]\n", this.name, this.size);

			foreach(i, entry; this) {
				str ~= format("  %2d: %s\n", i, to!(string)(entry));
			}

			return str;
		}

		RUUStation[] buffer;
}