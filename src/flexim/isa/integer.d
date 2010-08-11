/*
 * flexim/isa/integer.d
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

module flexim.isa.integer;

import flexim.all;

abstract class IntOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

abstract class IntImmOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);

			this.imm = cast(short) machInst[INTIMM];

			this.zextImm = 0x0000FFFF & machInst[INTIMM];

			this.sextImm = sext(machInst[INTIMM], 16);
		}

	private:
		short imm;
		int sextImm;
		uint zextImm;
}

class Add: IntOp {
	public:
		this(MachInst machInst) {
			super("add", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] + cast(int) thread.intRegs[this[RT]];
			logging.warn(LogCategory.INSTRUCTION, "Add: overflow trap not implemented.");
		}
}

class Addi: IntImmOp {
	public:
		this(MachInst machInst) {
			super("addi", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] + this.sextImm;
			logging.warn(LogCategory.INSTRUCTION, "Addi: overflow trap not implemented.");
		}
}

class Addiu: IntImmOp {
	public:
		this(MachInst machInst) {
			super("addiu", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] + this.sextImm;
		}
}

class Addu: IntOp {
	public:
		this(MachInst machInst) {
			super("addu", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] + cast(int) thread.intRegs[this[RT]];
		}
}

class Sub: IntOp {
	public:
		this(MachInst machInst) {
			super("sub", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] - cast(int) thread.intRegs[this[RT]];
			logging.warn(LogCategory.INSTRUCTION, "Sub: overflow trap not implemented.");
		}
}

class Subu: IntOp {
	public:
		this(MachInst machInst) {
			super("subu", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] - cast(int) thread.intRegs[this[RT]];
		}
}

class And: IntOp {
	public:
		this(MachInst machInst) {
			super("and", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] & thread.intRegs[this[RT]];
		}
}

class Andi: IntImmOp {
	public:
		this(MachInst machInst) {
			super("andi", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] & this.zextImm;
		}
}

class Nor: IntOp {
	public:
		this(MachInst machInst) {
			super("nor", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = ~(thread.intRegs[this[RS]] | thread.intRegs[this[RT]]);
		}
}

class Or: IntOp {
	public:
		this(MachInst machInst) {
			super("or", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] | thread.intRegs[this[RT]];
		}
}

class Ori: IntImmOp {
	public:
		this(MachInst machInst) {
			super("ori", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] | this.zextImm;
		}
}

class Xor: IntOp {
	public:
		this(MachInst machInst) {
			super("xor", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] ^ thread.intRegs[this[RT]];
		}
}

class Xori: IntImmOp {
	public:
		this(MachInst machInst) {
			super("xori", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] ^ this.zextImm;
		}
}

class Slt: IntOp {
	public:
		this(MachInst machInst) {
			super("slt", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] < cast(int) thread.intRegs[this[RT]] ? 1 : 0;
		}
}

class Slti: IntImmOp {
	public:
		this(MachInst machInst) {
			super("slti", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] < this.sextImm ? 1 : 0;
		}
}

class Sltiu: IntImmOp {
	public:
		this(MachInst machInst) {
			super("sltiu", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(uint) thread.intRegs[this[RS]] < this.zextImm ? 1 : 0;
		}
}

class Sltu: IntOp {
	public:
		this(MachInst machInst) {
			super("sltu", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RS]] < cast(uint) thread.intRegs[this[RT]] ? 1 : 0;
		}
}

class Lui: IntImmOp {
	public:
		this(MachInst machInst) {
			super("lui", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = this.imm << 16;
		}
}

class Divu: StaticInst {
	public:
		this(MachInst machInst) {
			super("divu", machInst, StaticInstFlag.ICOMP, FUType.IntDIV);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= MiscIntRegNums.LO;
			this.destRegIdx ~= MiscIntRegNums.HI;
		}

		override void execute(Thread thread) {
			ulong rs = 0;
			ulong rt = 0;

			uint lo = 0;
			uint hi = 0;

			rs = thread.intRegs[this[RS]];
			rt = thread.intRegs[this[RT]];

			if(rt != 0) {
				lo = cast(uint) (rs / rt);
				hi = cast(uint) (rs % rt);
			}

			thread.intRegs[MiscIntRegNums.LO] = lo;
			thread.intRegs[MiscIntRegNums.HI] = hi;
		}
}

class Div: StaticInst {
	public:
		this(MachInst machInst) {
			super("div", machInst, StaticInstFlag.ICOMP, FUType.IntDIV);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= MiscIntRegNums.LO;
			this.destRegIdx ~= MiscIntRegNums.HI;
		}

		override void execute(Thread thread) {
			long rs = 0;
			long rt = 0;

			uint lo = 0;
			uint hi = 0;

			rs = sext(thread.intRegs[this[RS]], 32);
			rt = sext(thread.intRegs[this[RT]], 32);

			if(rt != 0) {
				lo = cast(uint) (rs / rt);
				hi = cast(uint) (rs % rt);
			}

			thread.intRegs[MiscIntRegNums.LO] = lo;
			thread.intRegs[MiscIntRegNums.HI] = hi;
		}
}

class Mflo: StaticInst {
	public:
		this(MachInst machInst) {
			super("mflo", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= MiscIntRegNums.LO;
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[MiscIntRegNums.LO];
		}
}

class Mfhi: StaticInst {
	public:
		this(MachInst machInst) {
			super("mfhi", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= MiscIntRegNums.HI;
			this.destRegIdx ~= this[RD];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[MiscIntRegNums.HI];
		}
}

class Mtlo: StaticInst {
	public:
		this(MachInst machInst) {
			super("mtlo", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RD];
			this.destRegIdx ~= MiscIntRegNums.LO;
		}

		override void execute(Thread thread) {
			thread.intRegs[MiscIntRegNums.LO] = thread.intRegs[this[RD]];
		}
}

class Mthi: StaticInst {
	public:
		this(MachInst machInst) {
			super("mthi", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RD];
			this.destRegIdx ~= MiscIntRegNums.HI;
		}

		override void execute(Thread thread) {
			thread.intRegs[MiscIntRegNums.HI] = thread.intRegs[this[RD]];
		}
}

class Mult: StaticInst {
	public:
		this(MachInst machInst) {
			super("mult", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= MiscIntRegNums.LO;
			this.destRegIdx ~= MiscIntRegNums.HI;
		}

		override void execute(Thread thread) {
			long rs = 0;
			long rt = 0;
			
			rs = sext(thread.intRegs[this[RS]], 32);
			rt = sext(thread.intRegs[this[RT]], 32);

			long val = rs * rt;

			uint lo = cast(uint) bits64(val, 31, 0);
			uint hi = cast(uint) bits64(val, 63, 32);

			thread.intRegs[MiscIntRegNums.LO] = lo;
			thread.intRegs[MiscIntRegNums.HI] = hi;
		}
}

class Multu: StaticInst {
	public:
		this(MachInst machInst) {
			super("multu", machInst, StaticInstFlag.ICOMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= MiscIntRegNums.LO;
			this.destRegIdx ~= MiscIntRegNums.HI;
		}

		override void execute(Thread thread) {
			ulong rs = 0;
			ulong rt = 0;
			
			rs = thread.intRegs[this[RS]];
			rt = thread.intRegs[this[RT]];

			ulong val = rs * rt;

			uint lo = cast(uint) bits64(val, 31, 0);
			uint hi = cast(uint) bits64(val, 63, 32);

			thread.intRegs[MiscIntRegNums.LO] = lo;
			thread.intRegs[MiscIntRegNums.HI] = hi;
		}
}
