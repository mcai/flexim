/*
 * flexim/cpu/registers.d
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

module flexim.cpu.registers;

import flexim.all;

static const string mips_gpr_names[32] = ["zero", "at", "v0", "v1", "a0", "a1", "a2", "a3", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "t8", "t9",
		"k0", "k1", "gp", "sp", "s8", "ra"];

// Constants Related to the number of registers
const int NumIntArchRegs = 32;
const int NumIntSpecialRegs = 9;
const int NumFloatArchRegs = 32;
const int NumFloatSpecialRegs = 5;

const int NumIntRegs = NumIntArchRegs + NumIntSpecialRegs;
const int NumFloatRegs = NumFloatArchRegs + NumFloatSpecialRegs;

enum MiscIntRegNums: int {
	LO = NumIntArchRegs,
	HI,
	EA
};

enum FPControlRegNums: int {
	FIR = NumFloatArchRegs,
	FCCR,
	FEXR,
	FENR,
	FCSR
}

enum FCSRBits: int {
	Inexact = 1,
	Underflow,
	Overflow,
	DivideByZero,
	Invalid,
	Unimplemented
};

enum FCSRFields: int {
	Flag_Field = 1,
	Enable_Field = 6,
	Cause_Field = 11
};

// Semantically meaningful register indices
const int ZeroReg = 0;
const int AssemblerReg = 1;
const int SyscallSuccessReg = 7;
const int FirstArgumentReg = 4;
const int ReturnValueReg = 2;

const int KernelReg0 = 26;
const int KernelReg1 = 27;
const int GlobalPointerReg = 28;
const int StackPointerReg = 29;
const int FramePointerReg = 30;
const int ReturnAddressReg = 31;

const int SyscallPseudoReturnReg = 3;

// These help enumerate all the registers for dependence tracking.
const int FP_Base_DepTag = NumIntRegs;
const int Ctrl_Base_DepTag = FP_Base_DepTag + NumFloatRegs;

alias ushort RegIndex;

alias uint IntReg;

// floating point register file entry type
alias uint FloatRegBits;
alias float FloatReg;

union FloatRegs {
	FloatReg f[NumFloatRegs];
	FloatRegBits i[NumFloatRegs];
}

interface RegisterFile(RegT) {
	RegT opIndex(uint index);
	void opIndexAssign(RegT value, uint index);
	
	void clear();
	void checkpoint();
	void restore();
}

class IntRegisterFile : RegisterFile!(IntReg) {
	this() {
		this.clear();
	}
	
	override void clear() {
		this.regs.clear();
	}
	
	override void checkpoint() {
		assert(0);
		//TODO
	}
	
	override void restore() {
		assert(0);
		//TODO
	}
	
	override IntReg opIndex(uint index) {
		assert(index < NumIntRegs);
		IntReg value = this.regs[index];
		logging.infof(LogCategory.THREAD, "    Reading int reg %d as %#x.", index, value);
		return value;
	}
	
	override void opIndexAssign(IntReg value, uint index) {
		assert(index < NumIntRegs);
		this.regs[index] = value;
		logging.infof(LogCategory.THREAD, "    Setting int reg %d to %#x.", index, value);
	}

	string dump() {
		string buf;

		foreach(i, reg; this.regs[0 .. NumIntArchRegs]) {
			if(i % 4 == 0) {
				buf ~= "    ";
			}

			if(i > 0) {
				buf ~= "  ";
			}

			buf ~= format("%s  = 0x%08x ", mips_gpr_names[i], reg);

			if(i % 4 == 3 && i != (NumIntArchRegs - 1)) {
				buf ~= '\n';
			}
		}

		return buf;
	}

	IntReg[NumIntRegs] regs;
}

class FloatRegisterFile : RegisterFile!(FloatReg) {
	this() {
		this.clear();
	}
	
	override void clear() {
		this.regs.f = 0f;
	}
	
	override void checkpoint() {
		assert(0);
		//TODO
	}
	
	override void restore() {
		assert(0);
		//TODO
	}
	
	override FloatReg opIndex(uint index) {
		assert(index < NumFloatRegs);
		FloatReg value = this.regs.f[index];
		logging.infof(LogCategory.THREAD, "    Reading float reg %d as %f, %#x.", index, value, this.regs.i[index]);
		return value;
	}
	
	override void opIndexAssign(FloatReg value, uint index) {
		assert(index < NumFloatRegs);
		this.regs.f[index] = value;
		logging.infof(LogCategory.THREAD, "    Setting float reg %d to %f, %#x.", index, value, this.regs.i[index]);
	}
	
	FloatRegBits get(uint index) {
		assert(index < NumFloatRegs);
		FloatRegBits value = this.regs.i[index];
		logging.infof(LogCategory.THREAD, "    Reading float reg %d bits as %#x, %f.", index, value, this.regs.f[index]);
		return value;
	}
	
	void set(FloatRegBits value, uint index) {
		assert(index < NumFloatRegs);
		this.regs.i[index] = value;
		logging.infof(LogCategory.THREAD, "    Setting float reg %d bits to %#x, %#f.", index, value, this.regs.f[index]);
	}
	
	FloatRegs regs;
}