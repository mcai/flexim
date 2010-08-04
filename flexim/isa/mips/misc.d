module flexim.isa.mips.misc;

import flexim.all;

class Nop: StaticInst {
	public:
		this(MachInst machInst) {
			super("nop", machInst, StaticInstFlag.NONE, FUType.NONE);
		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
		}
}

class FailUnimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("type: %s, machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class CP0Unimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("[%s] machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class CP1Unimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("[%s] machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class CP2Unimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("[%s] machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class WarnUnimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("[%s] machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class Unknown: StaticInst {
	public:
		this(MachInst machInst) {
			super("unknown", machInst, StaticInstFlag.NONE, FUType.NONE);
		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			new ReservedInstructionFault();
		}
}

class Trap: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);
		}
		
		override void setupDeps() {
		}
}

class TrapImm: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

			this.imm = cast(short) machInst[INTIMM];
		}
		
		override void setupDeps() {
		}

	protected:
		short imm;
}