module flexim.isa.mips.basic;

import flexim.all;

class Syscall: StaticInst {
	public:
		this(MachInst machInst) {
			super("syscall", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= 2;
		}

		override void execute(Thread thread) {
			thread.syscall(thread.intRegs[2]);
		}
}

class Sll: StaticInst {
	public:
		this(MachInst machInst) {
			super("sll", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RT]] << this[SA];
		}
}

class Sllv: StaticInst {
	public:
		this(MachInst machInst) {
			super("sllv", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RT]] << bits(thread.intRegs[this[RS]], 4, 0);
		}
}

class Sra: StaticInst {
	public:
		this(MachInst machInst) {
			super("sra", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RT]] >> this[SA];
		}
}

class Srav: StaticInst {
	public:
		this(MachInst machInst) {
			super("srav", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RT]] >> bits(thread.intRegs[this[RS]], 4, 0);
		}
}

class Srl: StaticInst {
	public:
		this(MachInst machInst) {
			super("srl", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RT]] >> this[SA];
		}
}

class Srlv: StaticInst {
	public:
		this(MachInst machInst) {
			super("srlv", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RT]] >> bits(thread.intRegs[this[RS]], 4, 0);
		}
}
