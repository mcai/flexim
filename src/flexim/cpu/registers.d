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
const int NumIntRegs = 32;
const int NumFloatRegs = 32;

enum MiscRegNums: int {
	LO = 0,
	HI,
	EA,
	FCSR
};

// These help enumerate all the registers for dependence tracking.
const int FP_Base_DepTag = NumIntRegs;
const int Misc_Base_DepTag = FP_Base_DepTag + NumFloatRegs;

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

interface RegisterFile(RegT) {	
	void clear();
	void checkpoint();
	void restore();
}

class IntRegisterFile : RegisterFile!(uint) {
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
	
	uint opIndex(uint index) {
		assert(index < NumIntRegs);
		uint value = this.regs[index];
		//logging.infof(LogCategory.THREAD, "    Reading int reg %d as %#x.", index, value);
		return value;
	}
	
	void opIndexAssign(uint value, uint index) {
		assert(index < NumIntRegs);
		this.regs[index] = value;
		//logging.infof(LogCategory.THREAD, "    Setting int reg %d to %#x.", index, value);
	}

	override string toString() {
		string buf;

		foreach(i, reg; this.regs[0 .. NumIntRegs]) {
			if(i % 4 == 0) {
				buf ~= "    ";
			}

			if(i > 0) {
				buf ~= "  ";
			}

			buf ~= format("%s  = 0x%08x ", mips_gpr_names[i], reg);

			if(i % 4 == 3 && i != (NumIntRegs - 1)) {
				buf ~= '\n';
			}
		}

		return buf;
	}

	uint[NumIntRegs] regs;
}

class MiscRegisterFile: RegisterFile!(uint) {
	this() {
		this.clear();
	}
	
	override void clear() {
		this.lo = 0;
		this.hi = 0;
		this.ea = 0;
		this.fcsr = 0;
	}
	
	override void checkpoint() {
		assert(0);
		//TODO
	}
	
	override void restore() {
		assert(0);
		//TODO
	}
	
	uint lo;
	uint hi;
	uint ea;
	uint fcsr;
}

class FloatRegisterFile : RegisterFile!(float) {
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
	
	float getFloat(uint index) {
		assert(index < NumFloatRegs);
		float value = this.regs.f[index];
		//logging.infof(LogCategory.REGISTER, "    Reading float reg %d as %f.", index, value);
		return value;
	}
	
	void setFloat(float value, uint index) {
		assert(index < NumFloatRegs);
		this.regs.f[index] = value;
		//logging.infof(LogCategory.REGISTER, "    Setting float reg %d to %f.", index, value);
	}
	
	double getDouble(uint index) {
		assert(index < NumFloatRegs);
		double value = this.regs.d[index/2];
		//logging.infof(LogCategory.REGISTER, "    Reading double reg %d as %f.", index, value);
		return value;
	}
	
	void setDouble(double value, uint index) {
		assert(index < NumFloatRegs);
		this.regs.d[index/2] = value;
		//logging.infof(LogCategory.REGISTER, "    Setting double reg %d to %f.", index, value);
	}
	
	uint getUint(uint index) {
		assert(index < NumFloatRegs);
		uint value = this.regs.i[index];
		//logging.infof(LogCategory.REGISTER, "    Reading float reg %d bits as %#x.", index, value);
		return value;
	}
	
	void setUint(uint value, uint index) {
		assert(index < NumFloatRegs, format("%d", index));
		this.regs.i[index] = value;
		//logging.infof(LogCategory.REGISTER, "    Setting float reg %d bits to %#x.", index, value);
	}
	
	ulong getUlong(uint index) {
		assert(index < NumFloatRegs);
		ulong value = this.regs.l[index/2];
		//logging.infof(LogCategory.REGISTER, "    Reading double reg %d bits as %#x.", index, value);
		return value;
	}
	
	void setUlong(ulong value, uint index) {
		assert(index < NumFloatRegs);
		this.regs.l[index/2] = value;
		//logging.infof(LogCategory.REGISTER, "    Setting double reg %d bits to %#x.", index, value);
	}

	override string toString() {
		string buf;

		foreach(i, reg; this.regs.f[0 .. NumFloatRegs]) {
			if(i % 4 == 0) {
				buf ~= "    ";
			}

			if(i > 0) {
				buf ~= "  ";
			}

			buf ~= format("f%d  = 0x%08x ", i, reg);

			if(i % 4 == 3 && i != (NumFloatRegs - 1)) {
				buf ~= '\n';
			}
		}

		return buf;
	}
	
	union cop1_reg {
		float f[NumFloatRegs];
		int i[NumFloatRegs];
		double d[NumFloatRegs / 2];
		long l[NumFloatRegs / 2];
	};
	
	cop1_reg regs;
}