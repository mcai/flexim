/*
 * flexim/isa/mem.d
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

module flexim.isa.mem;

import flexim.all;

class MemoryOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);

			this.displacement = sext(machInst[OFFSET], 16);
		}

		int displacement() {
			return this.m_displacement;
		}

		uint ea(Thread thread) {
			uint ea = thread.intRegs[this[RS]] + this.displacement;
			return ea;
		}

		override void setupDeps() {
			this.setupEaDeps();
			
			this.eaOdeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.EA);
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.EA);
			
			this.setupMemDeps();
		}
		
		abstract void setupEaDeps();
		abstract void setupMemDeps();
		
		alias iDeps eaIdeps;
		alias oDeps eaOdeps;
		
		RegisterDependency[] memIDeps;
		RegisterDependency[] memODeps;

	private:
		void displacement(int value) {
			this.m_displacement = value;
		}

		int m_displacement;
}

class Lb: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lb", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {			
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			byte mem = 0;
			thread.mem.readByte(this.ea(thread), cast(ubyte*) &mem);
			thread.intRegs[this[RT]] = mem;
		}
}

class Lbu: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lbu", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {			
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			ubyte mem = 0;
			thread.mem.readByte(this.ea(thread), &mem);
			thread.intRegs[this[RT]] = mem;
		}
}

class Lh: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lh", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			short mem = 0;
			thread.mem.readHalfWord(this.ea(thread), cast(ushort*) &mem);
			thread.intRegs[this[RT]] = mem;
		}
}

class Lhu: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lhu", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			ushort mem = 0;
			thread.mem.readHalfWord(this.ea(thread), &mem);
			thread.intRegs[this[RT]] = mem;
		}
}

class Lw: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lw", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			int mem = 0;
			thread.mem.readWord(this.ea(thread), cast(uint*) &mem);
			thread.intRegs[this[RT]] = mem;
		}
}

class Lwl: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lwl", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
		
		override uint ea(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;
			uint ea = addr & ~3;			
			return ea;
		}

		override void execute(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;

			uint ea = addr & ~3;
			uint byte_offset = addr & 3;

			uint mem = 0;

			thread.mem.readWord(ea, &mem);

			uint mem_shift = 24 - 8 * byte_offset;

			uint rt = (mem << mem_shift) | (thread.intRegs[this[RT]] & mask(mem_shift));

			thread.intRegs[this[RT]] = rt;
		}
}

class Lwr: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lwr", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
		
		override uint ea(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;
			uint ea = addr & ~3;
			return ea;
		}

		override void execute(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;

			uint ea = addr & ~3;
			uint byte_offset = addr & 3;

			uint mem = 0;

			thread.mem.readWord(ea, &mem);

			uint mem_shift = 8 * byte_offset;

			uint rt = (thread.intRegs[this[RT]] & (mask(mem_shift) << (32 - mem_shift))) | (mem >> mem_shift);

			thread.intRegs[this[RT]] = rt;
		}
}

class Ll: MemoryOp {
	public:
	this(MachInst machInst) {
		super("ll", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
	}

	override void setupEaDeps() {
		this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
	}

	override void setupMemDeps() {
		this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
	}

	override void execute(Thread thread) {		
		uint mem = 0;		
		thread.mem.readWord(this.ea(thread), &mem);		
		thread.intRegs[this[RT]] = mem;
	}
}

class Lwc1: MemoryOp {
	public:
		this(MachInst machInst) {
			super("lwc1", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}
	
		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}
	
		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
		}
	
		override void execute(Thread thread) {			
			uint mem = 0;
			thread.mem.readWord(this.ea(thread), &mem);			
			thread.floatRegs.setUint(mem, this[FT]);
		}
}

class Ldc1: MemoryOp {
	public:
		this(MachInst machInst) {
			super("ldc1", machInst, StaticInstFlag.MEM | StaticInstFlag.LOAD | StaticInstFlag.DISP, FunctionalUnitType.RdPort);
		}
	
		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}
	
		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
		}
	
		override void execute(Thread thread) {			
			ulong mem = 0;
			thread.mem.readDoubleWord(this.ea(thread), &mem);			
			thread.floatRegs.setUlong(mem, this[FT]);
		}
}

class Sb: MemoryOp {
	public:
		this(MachInst machInst) {
			super("sb", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			ubyte mem = cast(ubyte) bits(thread.intRegs[this[RT]], 7, 0);
			thread.mem.writeByte(this.ea(thread), mem);
		}
}

class Sh: MemoryOp {
	public:
		this(MachInst machInst) {
			super("sh", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			ushort mem = cast(ushort) bits(thread.intRegs[this[RT]], 15, 0);
			thread.mem.writeHalfWord(this.ea(thread), mem);
		}
}

class Sw: MemoryOp {
	public:
		this(MachInst machInst) {
			super("sw", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			uint mem = thread.intRegs[this[RT]];
			thread.mem.writeWord(this.ea(thread), mem);
		}
}

class Swl: MemoryOp {
	public:
		this(MachInst machInst) {
			super("swl", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
		
		override uint ea(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;
			uint ea = addr & ~3;
			return ea;
		}

		override void execute(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;

			uint ea = addr & ~3;
			uint byte_offset = addr & 3;

			uint mem = 0;

			thread.mem.readWord(ea, &mem);

			uint reg_shift = 24 - 8 * byte_offset;
			uint mem_shift = 32 - reg_shift;

			mem = (mem & (mask(reg_shift) << mem_shift)) | (thread.intRegs[this[RT]] >> reg_shift);

			thread.mem.writeWord(ea, mem);
		}
}

class Swr: MemoryOp {
	public:
		this(MachInst machInst) {
			super("swr", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}

		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
		
		override uint ea(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;
			uint ea = addr & ~3;
			return ea;
		}

		override void execute(Thread thread) {
			uint addr = thread.intRegs[this[RS]] + this.displacement;

			uint ea = addr & ~3;
			uint byte_offset = addr & 3;

			uint mem = 0;

			thread.mem.readWord(ea, &mem);

			uint reg_shift = 8 * byte_offset;

			mem = thread.intRegs[this[RT]] << reg_shift | (mem & (mask(reg_shift)));

			thread.mem.writeWord(ea, mem);
		}
}

class Sc: MemoryOp {
	public:
		this(MachInst machInst) {
			super("sc", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}
	
		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
	
		override void setupMemDeps() {
			this.memODeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}
	
		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			thread.mem.writeWord(this.ea(thread), rt);
			thread.intRegs[this[RT]] = 1;
		}
}

class Swc1: MemoryOp {
	public:
		this(MachInst machInst) {
			super("swc1", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}
	
		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}
	
		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
		}
	
		override void execute(Thread thread) {			
			uint ft = thread.floatRegs.getUint(this[FT]);			
			thread.mem.writeWord(this.ea(thread), ft);
		}
}

class Sdc1: MemoryOp {
	public:
		this(MachInst machInst) {
			super("sdc1", machInst, StaticInstFlag.MEM | StaticInstFlag.STORE | StaticInstFlag.DISP, FunctionalUnitType.WrPort);
		}
	
		override void setupEaDeps() {
			this.eaIdeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}
	
		override void setupMemDeps() {
			this.memIDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
		}
	
		override void execute(Thread thread) {		
			ulong ft = thread.floatRegs.getUlong(this[FT]);			
			thread.mem.writeDoubleWord(this.ea(thread), ft);
		}
}