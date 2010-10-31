/*
 * flexim/isa.d
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

module flexim.isa;

import flexim.all;

union MachInst {
	uint data;

	uint opIndex(BitField field) {
		return bits(this.data, field.hi, field.lo);
	}

	bool isRMt() {
		uint func = this[FUNC];
		return (func == 0x10 || func == 0x11);
	}

	bool isRMf() {
		uint func = this[FUNC];
		return (func == 0x12 || func == 0x13);
	}

	bool isROneOp() {
		uint func = this[FUNC];
		return (func == 0x08 || func == 0x09);
	}

	bool isRTwoOp() {
		uint func = this[FUNC];
		return (func >= 0x18 && func <= 0x1b);
	}

	bool isLoadStore() {
		uint opcode = this[OPCODE];
		return (((opcode >= 0x20) && (opcode <= 0x2e)) || (opcode == 0x30) || (opcode == 0x38));
	}

	bool isFPLoadStore() {
		uint opcode = this[OPCODE];
		return (opcode == 0x31 || opcode == 0x39);
	}

	bool isOneOpBranch() {
		uint opcode = this[OPCODE];
		return ((opcode == 0x00) || (opcode == 0x01) || (opcode == 0x06) || (opcode == 0x07));
	}

	bool isShift() {
		uint func = this[FUNC];
		return (func == 0x00 || func == 0x01 || func == 0x03);
	}

	bool isCVT() {
		uint func = this[FUNC];
		return (func == 32 || func == 33 || func == 36);
	}

	bool isCompare() {
		uint func = this[FUNC];
		return (func >= 48);
	}

	bool isGPR_FP_Move() {
		uint rs = this[RS];
		return (rs == 0 || rs == 4);
	}

	bool isGPR_FCR_Move() {
		uint rs = this[RS];
		return (rs == 2 || rs == 6);
	}

	bool isFPBranch() {
		uint rs = this[RS];
		return (rs == 8);
	}

	bool isSyscall() {
		return (this[OPCODE_LO] == 0x0 && this[FUNC_HI] == 0x1 && this[FUNC_LO] == 0x4);
	}

	MachInstType getType() {
		uint opcode = this[OPCODE];

		if(opcode == 0)
			return MachInstType.R;
		else if((opcode == 0x02) || (opcode == 0x03))
			return MachInstType.J;
		else if(opcode == 0x11)
			return MachInstType.F;
		else
			return MachInstType.I;
	}
}

enum MachInstType {
	R,
	I,
	J,
	F
}

struct BitField {
	string name;
	uint hi;
	uint lo;
}

const BitField OPCODE = {"OPCODE", 31, 26};
const BitField OPCODE_HI = {"OPCODE_HI", 31, 29};
const BitField OPCODE_LO = {"OPCODE_LO", 28, 26};

const BitField REGIMM = {"REGIMM", 20, 16};
const BitField REGIMM_HI = {"REGIMM_HI", 20, 19};
const BitField REGIMM_LO = {"REGIMM_LO", 18, 16};

const BitField FUNC = {"FUNC", 5, 0};
const BitField FUNC_HI = {"FUNC_HI", 5, 3};
const BitField FUNC_LO = {"FUNC_LO", 2, 0};

const BitField RS = {"RS", 25, 21};
const BitField RS_MSB = {"RS_MSB", 25, 25};
const BitField RS_HI = {"RS_HI", 25, 24};
const BitField RS_LO = {"RS_LO", 23, 21};
const BitField RS_SRL = {"RS_SRL", 25, 22};
const BitField RS_RT = {"RS_RT", 25, 16};
const BitField RT = {"RT", 20, 16};
const BitField RT_HI = {"RT_HI", 20, 19};
const BitField RT_LO = {"RT_LO", 18, 16};
const BitField RT_RD = {"RT_RD", 20, 11};
const BitField RD = {"RD", 15, 11};

const BitField INTIMM = {"INTIMM", 15, 0};
const BitField RS_RT_INTIMM = {"RS_RT_INTIMM", 25, 0};

//Floating-point operate format
const BitField FMT = {"FMT", 25, 21};
const BitField FR = {"FR", 25, 21};
const BitField FT = {"FT", 20, 16};
const BitField FS = {"FS", 15, 11};
const BitField FD = {"FD", 10, 6};

const BitField ND = {"ND", 17, 17};
const BitField TF = {"TF", 16, 16};
const BitField MOVCI = {"MOVCI", 16, 16};
const BitField MOVCF = {"MOVCF", 16, 16};
const BitField SRL = {"SRL", 21, 21};
const BitField SRLV = {"SRLV", 6, 6};
const BitField SA = {"SA", 10, 6};

// Floating Point Condition Codes
const BitField COND = {"COND", 3, 0};
const BitField CC = {"CC", 10, 8};
const BitField BRANCH_CC = {"BRANCH_CC", 20, 18};

// CP0 Register Select
const BitField SEL = {"SEL", 2, 0};

// INTERRUPTS
const BitField SC = {"SC", 5, 5};

// Branch format
const BitField OFFSET = {"OFFSET", 15, 0};

// Jmp format
const BitField JMPTARG = {"JMPTARG", 25, 0};
const BitField HINT = {"HINT", 10, 6};

const BitField SYSCALLCODE = {"SYSCALLCODE", 25, 6};
const BitField TRAPCODE = {"TRAPCODE", 15, 13};

// EXT/INS instructions
const BitField MSB = {"MSB", 15, 11};
const BitField LSB = {"LSB", 10, 6};

// DSP instructions
const BitField OP = {"OP", 10, 6};
const BitField OP_HI = {"OP_HI", 10, 9};
const BitField OP_LO = {"OP_LO", 8, 6};
const BitField DSPSA = {"DSPSA", 23, 21};
const BitField HILOSA = {"HILOSA", 25, 20};
const BitField RDDSPMASK = {"RDDSPMASK", 21, 16};
const BitField WRDSPMASK = {"WRDSPMASK", 16, 11};
const BitField ACSRC = {"ACSRC", 22, 21};
const BitField ACDST = {"ACDST", 12, 11};
const BitField BP = {"BP", 12, 11};

// MT Instructions
const BitField POS = {"POS", 10, 6};
const BitField MT_U = {"MT_U", 5, 5};
const BitField MT_H = {"MT_H", 4, 4};

//Cache Ops
const BitField CACHE_OP = {"CACHE_OP", 20, 16};

string disassemble(MachInst machInst, uint pc, Thread thread) {
	string buf;

	buf ~= format("0x%08x : 0x%08x %s ", pc, machInst.data, thread.core.isa.decodeMachInst(machInst).mnemonic);

	if(machInst.data == 0x00000000) {
		return buf;
	}

	switch(machInst.getType()) {
		case MachInstType.J:
			buf ~= format("%x", machInst[JMPTARG]);
		break;
		case MachInstType.I:
			if(machInst.isOneOpBranch()) {
				buf ~= format("$%s, %d", mips_gpr_names[machInst[RS]], cast(short) machInst[INTIMM]);
			} else if(machInst.isLoadStore()) {
				buf ~= format("$%s, %d($%s)", mips_gpr_names[machInst[RT]], cast(short) machInst[INTIMM], mips_gpr_names[machInst[RS]]);
			} else if(machInst.isFPLoadStore()) {
				buf ~= format("$f%d, %d($%s)", machInst[FT], cast(short) machInst[INTIMM], mips_gpr_names[machInst[RS]]);
			} else {
				buf ~= format("$%s, $%s, %d", mips_gpr_names[machInst[RT]], mips_gpr_names[machInst[RS]], cast(short) machInst[INTIMM]);
			}
		break;
		case MachInstType.F:
			if(machInst.isCVT()) {
				buf ~= format("$f%d, $f%d", machInst[FD], machInst[FS]);
			} else if(machInst.isCompare()) {
				buf ~= format("%d, $f%d, $f%d", machInst[FD] >> 2, machInst[FS], machInst[FT]);
			} else if(machInst.isFPBranch()) {
				buf ~= format("%d, %d", machInst[FD] >> 2, cast(short) machInst[INTIMM]);
			} else if(machInst.isGPR_FP_Move()) {
				buf ~= format("$%s, $f%d", mips_gpr_names[machInst[RT]], machInst[FS]);
			} else if(machInst.isGPR_FCR_Move()) {
				buf ~= format("$%s, $%d", mips_gpr_names[machInst[RT]], machInst[FS]);
			} else {
				buf ~= format("$f%d, $f%d, $f%d", machInst[FD], machInst[FS], machInst[FT]);
			}
		break;
		case MachInstType.R:
			if(machInst.isSyscall()) {
			} else if(machInst.isShift()) {
				buf ~= format("$%s, $%s, %d", mips_gpr_names[machInst[RD]], mips_gpr_names[machInst[RT]], machInst[SA]);
			} else if(machInst.isROneOp()) {
				buf ~= format("$%s", mips_gpr_names[machInst[RS]]);
			} else if(machInst.isRTwoOp()) {
				buf ~= format("$%s, $%s", mips_gpr_names[machInst[RS]], mips_gpr_names[machInst[RT]]);
			} else if(machInst.isRMt()) {
				buf ~= format("$%s", mips_gpr_names[machInst[RS]]);
			} else if(machInst.isRMf()) {
				buf ~= format("$%s", mips_gpr_names[machInst[RD]]);
			} else {
				buf ~= format("$%s, $%s, $%s", mips_gpr_names[machInst[RD]], mips_gpr_names[machInst[RS]], mips_gpr_names[machInst[RT]]);
			}
		break;
		default:
			logging.fatal(LogCategory.INSTRUCTION, "you can not reach here");
	}

	return buf;
}

/* instruction flags */
enum StaticInstFlag: uint {
	NONE = 0x00000000,
	ICOMP = 0x00000001, /* integer computation */
	FCOMP = 0x00000002, /* floating-point computation */
	CTRL = 0x00000004, /* control inst */
	UNCOND = 0x00000008, /*   unconditional change */
	COND = 0x00000010, /*   conditional change */
	MEM = 0x00000020, /* memory access inst */
	LOAD = 0x00000040, /*   load inst */
	STORE = 0x00000080, /*   store inst */
	DISP = 0x00000100, /*   displaced (R+C) addr mode */
	RR = 0x00000200, /*   R+R addr mode */
	DIRECT = 0x00000400, /*   direct addressing mode */
	TRAP = 0x00000800, /* traping inst */
	LONGLAT = 0x00001000, /* long latency inst (for sched) */	
	DIRJMP = 0x00002000, /* direct jump */
	INDIRJMP = 0x00004000,	/* indirect jump */
	CALL = 0x00008000, /* function call */
	FPCOND = 0x00010000, /* floating point conditional branch */
	IMM = 0x00020000, /* instruction has immediate operand */
	RET = 0x00040000 /* function return */
}

/* possible functional units */
enum FunctionalUnitType: uint {
	NONE = 0,
	IntALU,
	IntMULT,
	IntDIV,
	FloatADD,
	FloatCMP, /* fp comparer */
	FloatCVT, /* fp-int conversion */
	FloatMULT,
	FloatDIV,
	FloatSQRT,
	RdPort,
	WrPort
};

static const string mips_gpr_names[32] = ["zero", "at", "v0", "v1", "a0", "a1", "a2", "a3", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "t8", "t9",
		"k0", "k1", "gp", "sp", "s8", "ra"];

const uint NumIntRegs = 32;
const uint NumFloatRegs = 32;
const uint NumMiscRegs = 4;

enum MiscRegNums: int {
	LO = 0,
	HI,
	EA,
	FCSR
};

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

abstract class ISA {
	StaticInst decode(uint pc, Memory mem) {
		if(pc in this.decodedInsts) {
			return this.decodedInsts[pc];
		}
		else {
			MachInst machInst;
	
			mem.readWord(pc, &machInst.data);
	
			StaticInst staticInst = this.decodeMachInst(machInst);
	
			assert(staticInst !is null, format("failed to decode machine instructon 0x%08x", machInst.data));
				
			this.decodedInsts[pc] = staticInst;
				
			return staticInst;
		}
	}
	
	abstract StaticInst decodeMachInst(MachInst machInst);
	
	StaticInst[uint] decodedInsts;
}

enum RegisterDependencyType: string {
	INT = "INT",
	FP = "FP",
	MISC = "MISC"
}

class RegisterDependency {
	this(RegisterDependencyType type, uint num) {
		this.type = type;
		this.num = num;
	}
	
	override string toString() {
		return format("RegisterDependency[type=%s, num=%d]", this.type, this.num);
	}
	
	RegisterDependencyType type;
	uint num;
}

abstract class StaticInst {
	public:		
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			this.mnemonic = mnemonic;
			this.machInst = machInst;
			this.flags = flags;
			this.fuType = fuType;
			
			this.setupDeps();
		}
		
		uint targetPc(Thread thread) {
			return 0;
		}
		
		abstract void setupDeps();
		
		abstract void execute(Thread thread);

		uint opIndex(BitField field) {
			return this.machInst[field];
		}
		
		bool isLongLat() {
			return (this.flags & StaticInstFlag.LONGLAT) == StaticInstFlag.LONGLAT;
		}
		
		bool isTrap() {
			return (this.flags & StaticInstFlag.TRAP) == StaticInstFlag.TRAP;
		}
		
		bool isMem() {
			return (this.flags & StaticInstFlag.MEM) == StaticInstFlag.MEM;
		}
		
		bool isLoad() {
			return this.isMem && (this.flags & StaticInstFlag.LOAD) == StaticInstFlag.LOAD;
		}
		
		bool isStore() {
			return this.isMem && (this.flags & StaticInstFlag.STORE) == StaticInstFlag.STORE;
		}

		bool isConditional() {
			return (this.flags & StaticInstFlag.COND) == StaticInstFlag.COND;
		}

		bool isUnconditional() {
			return (this.flags & StaticInstFlag.UNCOND) == StaticInstFlag.UNCOND;
		}
		
		bool isDirectJump() {
			return (this.flags & StaticInstFlag.DIRJMP) != StaticInstFlag.DIRJMP;
		}

		bool isControl() {
			return (this.flags & StaticInstFlag.CTRL) == StaticInstFlag.CTRL;
		}

		bool isCall() {
			return (this.flags & StaticInstFlag.CALL) == StaticInstFlag.CALL;
		}

		bool isReturn() {
			return (this.flags & StaticInstFlag.RET) == StaticInstFlag.RET;
		}
		
		bool isNop() {
			return (cast(Nop)this) !is null;
		}
		
		RegisterDependency[] iDeps;
		RegisterDependency[] oDeps;
		
		MachInst machInst;
		string mnemonic;
		StaticInstFlag flags;
		FunctionalUnitType fuType;
}

class DynamicInst {
	public:		
		this(Thread thread, uint pc, StaticInst staticInst) {
			this.thread = thread;
			this.pc = pc;
			this.staticInst = staticInst;
		}
		
		void execute() {
			this.thread.intRegs[ZeroReg] = 0;
			
			this.staticInst.execute(this.thread);
		}
		
		override string toString() {
			return disassemble(this.staticInst.machInst, this.pc, this.thread);
		}
		
		uint pc;
		
		StaticInst staticInst;
		
		Thread thread;
}

class MipsISA : ISA {
	this() {
		
	}
	
	override StaticInst decodeMachInst(MachInst machInst) {
		switch(machInst[OPCODE_HI]) {
			case 0x0:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x1:
										switch(machInst[MOVCI]) {
											case 0x0:
												return new FailUnimplemented("Movf", machInst);
											case 0x1:
												return new FailUnimplemented("Movt", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x0:
										switch(machInst[RS]) {
											case 0x0:
												switch(machInst[RT_RD]) {
													case 0x0:
														switch(machInst[SA]) {
															case 0x1:
																return new FailUnimplemented("Ssnop", machInst);
															case 0x3:
																return new FailUnimplemented("Ehb", machInst);
															default:
																return new Nop(machInst);
														}
													default:
														return new Sll(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x2:
										switch(machInst[RS_SRL]) {
											case 0x0:
												switch(machInst[SRL]) {
													case 0x0:
														return new Srl(machInst);
													case 0x1:
														return new FailUnimplemented("Rotr", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[RS]) {
											case 0x0:
												return new Sra(machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x4:
										return new Sllv(machInst);
									case 0x6:
										switch(machInst[SRLV]) {
											case 0x0:
												return new Srlv(machInst);
											case 0x1:
												return new FailUnimplemented("Rotrv", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x7:
										return new Srav(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[HINT]) {
											case 0x1:
												return new FailUnimplemented("Jr_hb", machInst);
											default:
												return new Jr(machInst);
										}
									case 0x1:
										switch(machInst[HINT]) {
											case 0x1:
												return new FailUnimplemented("Jalr_hb", machInst);
											default:
												return new Jalr(machInst);
										}
									case 0x2:
										return new FailUnimplemented("Movz", machInst);
									case 0x3:
										return new FailUnimplemented("Movn", machInst);
									case 0x4:
										return new Syscall(machInst);
									case 0x7:
										return new FailUnimplemented("Sync", machInst);
									case 0x5:
										return new FailUnimplemented("Break", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new Mfhi(machInst);
									case 0x1:
										return new Mthi(machInst);
									case 0x2:
										return new Mflo(machInst);
									case 0x3:
										return new Mtlo(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new Mult(machInst);
									case 0x1:
										return new Multu(machInst);
									case 0x2:
										return new Div(machInst);
									case 0x3:
										return new Divu(machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[HINT]) {
									case 0x0:
										switch(machInst[FUNC_LO]) {
											case 0x0:
												return new Add(machInst);
											case 0x1:
												return new Addu(machInst);
											case 0x2:
												return new Sub(machInst);
											case 0x3:
												return new Subu(machInst);
											case 0x4:
												return new And(machInst);
											case 0x5:
												return new Or(machInst);
											case 0x6:
												return new Xor(machInst);
											case 0x7:
												return new Nor(machInst);
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x5:
								switch(machInst[HINT]) {
									case 0x0:
										switch(machInst[FUNC_LO]) {
											case 0x2:
												return new Slt(machInst);
											case 0x3:
												return new Sltu(machInst);
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Tge", machInst);
									case 0x1:
										return new FailUnimplemented("Tgeu", machInst);
									case 0x2:
										return new FailUnimplemented("Tlt", machInst);
									case 0x3:
										return new FailUnimplemented("Tltu", machInst);
									case 0x4:
										return new FailUnimplemented("Teq", machInst);
									case 0x6:
										return new FailUnimplemented("Tne", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x1:
						switch(machInst[REGIMM_HI]) {
							case 0x0:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new Bltz(machInst);
									case 0x1:
										return new Bgez(machInst);
									case 0x2:
										return new FailUnimplemented("Bltzl", machInst);
									case 0x3:
										return new FailUnimplemented("Bgezl", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new FailUnimplemented("Tgei", machInst);
									case 0x1:
										return new FailUnimplemented("Tgeiu", machInst);
									case 0x2:
										return new FailUnimplemented("Tlti", machInst);
									case 0x3:
										return new FailUnimplemented("Tltiu", machInst);
									case 0x4:
										return new FailUnimplemented("Teqi", machInst);
									case 0x6:
										return new FailUnimplemented("Tnei", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[REGIMM_LO]) {
									case 0x0:
										return new Bltzal(machInst);
									case 0x1:
										switch(machInst[RS]) {
											case 0x0:
												return new Bal(machInst);
											default:
												return new Bgezal(machInst);
										}
									case 0x2:
										return new FailUnimplemented("Bltzall", machInst);
									case 0x3:
										return new FailUnimplemented("Bgezall", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[REGIMM_LO]) {
									case 0x4:
										return new FailUnimplemented("Bposge32", machInst);
									case 0x7:
										return new FailUnimplemented("WarnUnimplemented.synci", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x2:
						return new J(machInst);
					case 0x3:
						return new Jal(machInst);
					case 0x4:
						switch(machInst[RS_RT]) {
							case 0x0:
								return new B(machInst);
							default:
								return new Beq(machInst);
						}
					case 0x5:
						return new Bne(machInst);
					case 0x6:
						return new Blez(machInst);
					case 0x7:
						return new Bgtz(machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x1:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Addi(machInst);
					case 0x1:
						return new Addiu(machInst);
					case 0x2:
						return new Slti(machInst);
					case 0x3:
						switch(machInst[RS_RT_INTIMM]) {
							case 0xabc1:
								return new FailUnimplemented("Fail", machInst);
							case 0xabc2:
								return new FailUnimplemented("Pass", machInst);
							default:
								return new Sltiu(machInst);
						}
					case 0x4:
						return new Andi(machInst);
					case 0x5:
						return new Ori(machInst);
					case 0x6:
						return new Xori(machInst);
					case 0x7:
						switch(machInst[RS]) {
							case 0x0:
								return new Lui(machInst);
							default:
								return new Unknown(machInst);
						}
					default:
						return new Unknown(machInst);
				}
			case 0x2:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS]) {
									case 0x0:
										return new FailUnimplemented("Mfc0", machInst);
									case 0x4:
										return new FailUnimplemented("Mtc0", machInst);
									case 0x1:
										return new CP0Unimplemented("dmfc0", machInst);
									case 0x5:
										return new CP0Unimplemented("dmtc0", machInst);
									default:
										return new CP0Unimplemented("unknown", machInst);
									case 0x8:
										switch(machInst[MT_U]) {
											case 0x0:
												return new FailUnimplemented("Mftc0", machInst);
											case 0x1:
												switch(machInst[SEL]) {
													case 0x0:
														return new FailUnimplemented("Mftgpr", machInst);
													case 0x1:
														switch(machInst[RT]) {
															case 0x0:
																return new FailUnimplemented("Mftlo_dsp0", machInst);
															case 0x1:
																return new FailUnimplemented("Mfthi_dsp0", machInst);
															case 0x2:
																return new FailUnimplemented("Mftacx_dsp0", machInst);
															case 0x4:
																return new FailUnimplemented("Mftlo_dsp1", machInst);
															case 0x5:
																return new FailUnimplemented("Mfthi_dsp1", machInst);
															case 0x6:
																return new FailUnimplemented("Mftacx_dsp1", machInst);
															case 0x8:
																return new FailUnimplemented("Mftlo_dsp2", machInst);
															case 0x9:
																return new FailUnimplemented("Mfthi_dsp2", machInst);
															case 0x10:
																return new FailUnimplemented("Mftacx_dsp2", machInst);
															case 0x12:
																return new FailUnimplemented("Mftlo_dsp3", machInst);
															case 0x13:
																return new FailUnimplemented("Mfthi_dsp3", machInst);
															case 0x14:
																return new FailUnimplemented("Mftacx_dsp3", machInst);
															case 0x16:
																return new FailUnimplemented("Mftdsp", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													case 0x2:
														switch(machInst[MT_H]) {
															case 0x0:
																return new FailUnimplemented("Mftc1", machInst);
															case 0x1:
																return new FailUnimplemented("Mfthc1", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x3:
														return new FailUnimplemented("Cftc1", machInst);
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0xc:
										switch(machInst[MT_U]) {
											case 0x0:
												return new FailUnimplemented("Mttc0", machInst);
											case 0x1:
												switch(machInst[SEL]) {
													case 0x0:
														return new FailUnimplemented("Mttgpr", machInst);
													case 0x1:
														switch(machInst[RT]) {
															case 0x0:
																return new FailUnimplemented("Mttlo_dsp0", machInst);
															case 0x1:
																return new FailUnimplemented("Mtthi_dsp0", machInst);
															case 0x2:
																return new FailUnimplemented("Mttacx_dsp0", machInst);
															case 0x4:
																return new FailUnimplemented("Mttlo_dsp1", machInst);
															case 0x5:
																return new FailUnimplemented("Mtthi_dsp1", machInst);
															case 0x6:
																return new FailUnimplemented("Mttacx_dsp1", machInst);
															case 0x8:
																return new FailUnimplemented("Mttlo_dsp2", machInst);
															case 0x9:
																return new FailUnimplemented("Mtthi_dsp2", machInst);
															case 0x10:
																return new FailUnimplemented("Mttacx_dsp2", machInst);
															case 0x12:
																return new FailUnimplemented("Mttlo_dsp3", machInst);
															case 0x13:
																return new FailUnimplemented("Mtthi_dsp3", machInst);
															case 0x14:
																return new FailUnimplemented("Mttacx_dsp3", machInst);
															case 0x16:
																return new FailUnimplemented("Mttdsp", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													case 0x2:
														return new FailUnimplemented("Mttc1", machInst);
													case 0x3:
														return new FailUnimplemented("Cttc1", machInst);
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0xb:
										switch(machInst[RD]) {
											case 0x0:
												switch(machInst[POS]) {
													case 0x0:
														switch(machInst[SEL]) {
															case 0x1:
																switch(machInst[SC]) {
																	case 0x0:
																		return new FailUnimplemented("Dvpe", machInst);
																	case 0x1:
																		return new FailUnimplemented("Evpe", machInst);
																	default:
																		return new CP0Unimplemented("unknown", machInst);
																}
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											case 0x1:
												switch(machInst[POS]) {
													case 0xf:
														switch(machInst[SEL]) {
															case 0x1:
																switch(machInst[SC]) {
																	case 0x0:
																		return new FailUnimplemented("Dmt", machInst);
																	case 0x1:
																		return new FailUnimplemented("Emt", machInst);
																	default:
																		return new CP0Unimplemented("unknown", machInst);
																}
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new CP0Unimplemented("unknown", machInst);
												}
											case 0xc:
												switch(machInst[POS]) {
													case 0x0:
														switch(machInst[SC]) {
															case 0x0:
																return new FailUnimplemented("Di", machInst);
															case 0x1:
																return new FailUnimplemented("Ei", machInst);
															default:
																return new CP0Unimplemented("unknown", machInst);
														}
													default:
														return new Unknown(machInst);
												}
											default:
												return new CP0Unimplemented("unknown", machInst);
										}
									case 0xa:
										return new FailUnimplemented("Rdpgpr", machInst);
									case 0xe:
										return new FailUnimplemented("Wrpgpr", machInst);
								}
							case 0x1:
								switch(machInst[FUNC]) {
									case 0x18:
										return new FailUnimplemented("Eret", machInst);
									case 0x1f:
										return new FailUnimplemented("Deret", machInst);
									case 0x1:
										return new FailUnimplemented("Tlbr", machInst);
									case 0x2:
										return new FailUnimplemented("Tlbwi", machInst);
									case 0x6:
										return new FailUnimplemented("Tlbwr", machInst);
									case 0x8:
										return new FailUnimplemented("Tlbp", machInst);
									case 0x20:
										return new CP0Unimplemented("wait", machInst);
									default:
										return new CP0Unimplemented("unknown", machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x1:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS_HI]) {
									case 0x0:
										switch(machInst[RS_LO]) {
											case 0x0:
												return new Mfc1(machInst);
											case 0x2:
												return new Cfc1(machInst);
											case 0x3:
												return new FailUnimplemented("Mfhc1", machInst);
											case 0x4:
												return new Mtc1(machInst);
											case 0x6:
												return new Ctc1(machInst);
											case 0x7:
												return new FailUnimplemented("Mthc1", machInst);
											case 0x1:
												return new CP1Unimplemented("dmfc1", machInst);
											case 0x5:
												return new CP1Unimplemented("dmtc1", machInst);
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[RS_LO]) {
											case 0x0:
												switch(machInst[ND]) {
													case 0x0:
														switch(machInst[TF]) {
															case 0x0:
																return new Bc1f(machInst);
															case 0x1:
																return new Bc1t(machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[TF]) {
															case 0x0:
																return new Bc1fl(machInst);
															case 0x1:
																return new Bc1tl(machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												return new CP1Unimplemented("bc1any2", machInst);
											case 0x2:
												return new CP1Unimplemented("bc1any4", machInst);
											default:
												return new CP1Unimplemented("unknown", machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[RS_HI]) {
									case 0x2:
										switch(machInst[RS_LO]) {
											case 0x0:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new Add_s(machInst);
															case 0x1:
																return new Sub_s(machInst);
															case 0x2:
																return new Mul_s(machInst);
															case 0x3:
																return new Div_s(machInst);
															case 0x4:
																return new Sqrt_s(machInst);
															case 0x5:
																return new Abs_s(machInst);
															case 0x7:
																return new Neg_s(machInst);
															case 0x6:
																return new Mov_s(machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Round_l_s", machInst);
															case 0x1:
																return new FailUnimplemented("Trunc_l_s", machInst);
															case 0x2:
																return new FailUnimplemented("Ceil_l_s", machInst);
															case 0x3:
																return new FailUnimplemented("Floor_l_s", machInst);
															case 0x4:
																return new FailUnimplemented("Round_w_s", machInst);
															case 0x5:
																return new FailUnimplemented("Trunc_w_s", machInst);
															case 0x6:
																return new FailUnimplemented("Ceil_w_s", machInst);
															case 0x7:
																return new FailUnimplemented("Floor_w_s", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_s", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_s", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_s", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_s", machInst);
															case 0x5:
																return new FailUnimplemented("Recip_s", machInst);
															case 0x6:
																return new FailUnimplemented("Rsqrt_s", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x3:
														return new CP1Unimplemented("unknown", machInst);
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																return new Cvt_d_s(machInst);
															case 0x4:
																return new Cvt_w_s(machInst);
															case 0x5:
																return new Cvt_l_s(machInst);
															case 0x6:
																return new FailUnimplemented("Cvt_ps_s", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x5:
														return new CP1Unimplemented("unknown", machInst);
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new C_f_s(machInst);
															case 0x1:
																return new C_un_s(machInst);
															case 0x2:
																return new C_eq_s(machInst);
															case 0x3:
																return new C_ueq_s(machInst);
															case 0x4:
																return new C_olt_s(machInst);
															case 0x5:
																return new C_ult_s(machInst);
															case 0x6:
																return new C_ole_s(machInst);
															case 0x7:
																return new C_ule_s(machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new C_sf_s(machInst);
															case 0x1:
																return new C_ngle_s(machInst);
															case 0x2:
																return new C_seq_s(machInst);
															case 0x3:
																return new C_ngl_s(machInst);
															case 0x4:
																return new C_lt_s(machInst);
															case 0x5:
																return new C_nge_s(machInst);
															case 0x6:
																return new C_le_s(machInst);
															case 0x7:
																return new C_ngt_s(machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new Add_d(machInst);
															case 0x1:
																return new Sub_d(machInst);
															case 0x2:
																return new Mul_d(machInst);
															case 0x3:
																return new Div_d(machInst);
															case 0x4:
																return new Sqrt_d(machInst);
															case 0x5:
																return new Abs_d(machInst);
															case 0x7:
																return new Neg_d(machInst);
															case 0x6:
																return new Mov_d(machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x1:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Round_l_d", machInst);
															case 0x1:
																return new FailUnimplemented("Trunc_l_d", machInst);
															case 0x2:
																return new FailUnimplemented("Ceil_l_d", machInst);
															case 0x3:
																return new FailUnimplemented("Floor_l_d", machInst);
															case 0x4:
																return new FailUnimplemented("Round_w_d", machInst);
															case 0x5:
																return new FailUnimplemented("Trunc_w_d", machInst);
															case 0x6:
																return new FailUnimplemented("Ceil_w_d", machInst);
															case 0x7:
																return new FailUnimplemented("Floor_w_d", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_d", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_d", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_d", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_d", machInst);
															case 0x5:
																return new FailUnimplemented("Recip_d", machInst);
															case 0x6:
																return new FailUnimplemented("Rsqrt_d", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new Cvt_s_d(machInst);
															case 0x4:
																return new Cvt_w_d(machInst);
															case 0x5:
																return new Cvt_l_d(machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new C_f_d(machInst);
															case 0x1:
																return new C_un_d(machInst);
															case 0x2:
																return new C_eq_d(machInst);
															case 0x3:
																return new C_ueq_d(machInst);
															case 0x4:
																return new C_olt_d(machInst);
															case 0x5:
																return new C_ult_d(machInst);
															case 0x6:
																return new C_ole_d(machInst);
															case 0x7:
																return new C_ule_d(machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new C_sf_d(machInst);
															case 0x1:
																return new C_ngle_d(machInst);
															case 0x2:
																return new C_seq_d(machInst);
															case 0x3:
																return new C_ngl_d(machInst);
															case 0x4:
																return new C_lt_d(machInst);
															case 0x5:
																return new C_nge_d(machInst);
															case 0x6:
																return new C_le_d(machInst);
															case 0x7:
																return new C_ngt_d(machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x2:
												return new CP1Unimplemented("unknown", machInst);
											case 0x3:
												return new CP1Unimplemented("unknown", machInst);
											case 0x7:
												return new CP1Unimplemented("unknown", machInst);
											case 0x4:
												switch(machInst[FUNC]) {
													case 0x20:
														return new Cvt_s_w(machInst);
													case 0x21:
														return new Cvt_d_w(machInst);
													case 0x26:
														return new CP1Unimplemented("cvt_ps_w", machInst);
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x5:
												switch(machInst[FUNC_HI]) {
													case 0x20:
														return new Cvt_s_l(machInst);
													case 0x21:
														return new Cvt_d_l(machInst);
													case 0x26:
														return new CP1Unimplemented("cvt_ps_l", machInst);
													default:
														return new CP1Unimplemented("unknown", machInst);
												}
											case 0x6:
												switch(machInst[FUNC_HI]) {
													case 0x0:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Add_ps", machInst);
															case 0x1:
																return new FailUnimplemented("Sub_ps", machInst);
															case 0x2:
																return new FailUnimplemented("Mul_ps", machInst);
															case 0x5:
																return new FailUnimplemented("Abs_ps", machInst);
															case 0x6:
																return new FailUnimplemented("Mov_ps", machInst);
															case 0x7:
																return new FailUnimplemented("Neg_ps", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x1:
														return new CP1Unimplemented("unknown", machInst);
													case 0x2:
														switch(machInst[FUNC_LO]) {
															case 0x1:
																switch(machInst[MOVCF]) {
																	case 0x0:
																		return new FailUnimplemented("Movf_ps", machInst);
																	case 0x1:
																		return new FailUnimplemented("Movt_ps", machInst);
																	default:
																		return new Unknown(machInst);
																}
															case 0x2:
																return new FailUnimplemented("Movz_ps", machInst);
															case 0x3:
																return new FailUnimplemented("Movn_ps", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x3:
														return new CP1Unimplemented("unknown", machInst);
													case 0x4:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Cvt_s_pu", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x5:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("Cvt_s_pl", machInst);
															case 0x4:
																return new FailUnimplemented("Pll", machInst);
															case 0x5:
																return new FailUnimplemented("Plu", machInst);
															case 0x6:
																return new FailUnimplemented("Pul", machInst);
															case 0x7:
																return new FailUnimplemented("Puu", machInst);
															default:
																return new CP1Unimplemented("unknown", machInst);
														}
													case 0x6:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_f_ps", machInst);
															case 0x1:
																return new FailUnimplemented("C_un_ps", machInst);
															case 0x2:
																return new FailUnimplemented("C_eq_ps", machInst);
															case 0x3:
																return new FailUnimplemented("C_ueq_ps", machInst);
															case 0x4:
																return new FailUnimplemented("C_olt_ps", machInst);
															case 0x5:
																return new FailUnimplemented("C_ult_ps", machInst);
															case 0x6:
																return new FailUnimplemented("C_ole_ps", machInst);
															case 0x7:
																return new FailUnimplemented("C_ule_ps", machInst);
															default:
																return new Unknown(machInst);
														}
													case 0x7:
														switch(machInst[FUNC_LO]) {
															case 0x0:
																return new FailUnimplemented("C_sf_ps", machInst);
															case 0x1:
																return new FailUnimplemented("C_ngle_ps", machInst);
															case 0x2:
																return new FailUnimplemented("C_seq_ps", machInst);
															case 0x3:
																return new FailUnimplemented("C_ngl_ps", machInst);
															case 0x4:
																return new FailUnimplemented("C_lt_ps", machInst);
															case 0x5:
																return new FailUnimplemented("C_nge_ps", machInst);
															case 0x6:
																return new FailUnimplemented("C_le_ps", machInst);
															case 0x7:
																return new FailUnimplemented("C_ngt_ps", machInst);
															default:
																return new Unknown(machInst);
														}
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new CP1Unimplemented("unknown", machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x2:
						switch(machInst[RS_MSB]) {
							case 0x0:
								switch(machInst[RS_HI]) {
									case 0x0:
										switch(machInst[RS_LO]) {
											case 0x0:
												return new CP2Unimplemented("mfc2", machInst);
											case 0x2:
												return new CP2Unimplemented("cfc2", machInst);
											case 0x3:
												return new CP2Unimplemented("mfhc2", machInst);
											case 0x4:
												return new CP2Unimplemented("mtc2", machInst);
											case 0x6:
												return new CP2Unimplemented("ctc2", machInst);
											case 0x7:
												return new CP2Unimplemented("mftc2", machInst);
											default:
												return new CP2Unimplemented("unknown", machInst);
										}
									case 0x1:
										switch(machInst[ND]) {
											case 0x0:
												switch(machInst[TF]) {
													case 0x0:
														return new CP2Unimplemented("bc2f", machInst);
													case 0x1:
														return new CP2Unimplemented("bc2t", machInst);
													default:
														return new CP2Unimplemented("unknown", machInst);
												}
											case 0x1:
												switch(machInst[TF]) {
													case 0x0:
														return new CP2Unimplemented("bc2fl", machInst);
													case 0x1:
														return new CP2Unimplemented("bc2tl", machInst);
													default:
														return new CP2Unimplemented("unknown", machInst);
												}
											default:
												return new CP2Unimplemented("unknown", machInst);
										}
									default:
										return new CP2Unimplemented("unknown", machInst);
								}
							default:
								return new CP2Unimplemented("unknown", machInst);
						}
					case 0x3:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x0: {
										return new FailUnimplemented("Lwxc1", machInst);
									}
									case 0x1: {
										return new FailUnimplemented("Ldxc1", machInst);
									}
									case 0x5: {
										return new FailUnimplemented("Luxc1", machInst);
									}
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Swxc1", machInst);
									case 0x1:
										return new FailUnimplemented("Sdxc1", machInst);
									case 0x5:
										return new FailUnimplemented("Suxc1", machInst);
									case 0x7:
										return new FailUnimplemented("Prefx", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x6:
										return new FailUnimplemented("Alnv_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Madd_s", machInst);
									case 0x1:
										return new FailUnimplemented("Madd_d", machInst);
									case 0x6:
										return new FailUnimplemented("Madd_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x5:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Msub_s", machInst);
									case 0x1:
										return new FailUnimplemented("Msub_d", machInst);
									case 0x6:
										return new FailUnimplemented("Msub_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Nmadd_s", machInst);
									case 0x1:
										return new FailUnimplemented("Nmadd_d", machInst);
									case 0x6:
										return new FailUnimplemented("Nmadd_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Nmsub_s", machInst);
									case 0x1:
										return new FailUnimplemented("Nmsub_d", machInst);
									case 0x6:
										return new FailUnimplemented("Nmsub_ps", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x4:
						return new FailUnimplemented("Beql", machInst);
					case 0x5:
						return new FailUnimplemented("Bnel", machInst);
					case 0x6:
						return new FailUnimplemented("Blezl", machInst);
					case 0x7:
						return new FailUnimplemented("Bgtzl", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x3:
				switch(machInst[OPCODE_LO]) {
					case 0x4:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x2:
										return new FailUnimplemented("Mul", machInst);
									case 0x0:
										return new FailUnimplemented("Madd", machInst);
									case 0x1:
										return new FailUnimplemented("Maddu", machInst);
									case 0x4:
										return new FailUnimplemented("Msub", machInst);
									case 0x5:
										return new FailUnimplemented("Msubu", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Clz", machInst);
									case 0x1:
										return new FailUnimplemented("Clo", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x7:
										return new FailUnimplemented("sdbbp", machInst);
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					case 0x7:
						switch(machInst[FUNC_HI]) {
							case 0x0:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Ext", machInst);
									case 0x4:
										return new FailUnimplemented("Ins", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x1:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										return new FailUnimplemented("Fork", machInst);
									case 0x1:
										return new FailUnimplemented("Yield", machInst);
									case 0x2:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0: {
														return new FailUnimplemented("Lwx", machInst);
													}
													case 0x4: {
														return new FailUnimplemented("Lhx", machInst);
													}
													case 0x6: {
														return new FailUnimplemented("Lbux", machInst);
													}
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x4:
										return new FailUnimplemented("Insv", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x2:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addu_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Subu_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Addu_s_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Subu_s_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Muleu_s_ph_qbl", machInst);
													case 0x7:
														return new FailUnimplemented("Muleu_s_ph_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addu_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Subu_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Addq_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Subq_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Addu_s_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Subu_s_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Addq_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Subq_s_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addsc", machInst);
													case 0x1:
														return new FailUnimplemented("Addwc", machInst);
													case 0x2:
														return new FailUnimplemented("Modsub", machInst);
													case 0x4:
														return new FailUnimplemented("Raddu_w_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Addq_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Subq_s_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Muleq_s_w_phl", machInst);
													case 0x5:
														return new FailUnimplemented("Muleq_s_w_phr", machInst);
													case 0x6:
														return new FailUnimplemented("Mulq_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Mulq_rs_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmpu_eq_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Cmpu_lt_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Cmpu_le_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Pick_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Cmpgu_eq_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Cmpgu_lt_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Cmpgu_le_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmp_eq_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Cmp_lt_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Cmp_le_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Pick_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Precrq_qb_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Precr_qb_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Packrl_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Precrqu_s_qb_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Precrq_ph_w", machInst);
													case 0x5:
														return new FailUnimplemented("Precrq_rs_ph_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Cmpgdu_eq_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Cmpgdu_lt_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Cmpgdu_le_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Precr_sra_ph_w", machInst);
													case 0x7:
														return new FailUnimplemented("Precr_sra_r_ph_w", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x2:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Repl_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Replv_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Precequ_ph_qbl", machInst);
													case 0x5:
														return new FailUnimplemented("Precequ_ph_qbr", machInst);
													case 0x6:
														return new FailUnimplemented("Precequ_ph_qbla", machInst);
													case 0x7:
														return new FailUnimplemented("Precequ_ph_qbra", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Repl_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Replv_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Preceq_w_phl", machInst);
													case 0x5:
														return new FailUnimplemented("Preceq_w_phr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Absq_s_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x3:
														return new FailUnimplemented("Bitrev", machInst);
													case 0x4:
														return new FailUnimplemented("Preceu_ph_qbl", machInst);
													case 0x5:
														return new FailUnimplemented("Preceu_ph_qbr", machInst);
													case 0x6:
														return new FailUnimplemented("Preceu_ph_qbla", machInst);
													case 0x7:
														return new FailUnimplemented("Preceu_ph_qbra", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Shll_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Shrl_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Shllv_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Shrlv_qb", machInst);
													case 0x4:
														return new FailUnimplemented("Shra_qb", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_qb", machInst);
													case 0x6:
														return new FailUnimplemented("Shrav_qb", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Shll_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Shra_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Shllv_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Shrav_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Shll_s_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Shllv_s_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x4:
														return new FailUnimplemented("Shll_s_w", machInst);
													case 0x5:
														return new FailUnimplemented("Shra_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Shllv_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Shrav_r_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x1:
														return new FailUnimplemented("Shrl_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Shrlv_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x3:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Adduh_qb", machInst);
													case 0x1:
														return new FailUnimplemented("Subuh_qb", machInst);
													case 0x2:
														return new FailUnimplemented("Adduh_r_qb", machInst);
													case 0x3:
														return new FailUnimplemented("Subuh_r_qb", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addqh_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Subqh_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Addqh_r_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Subqh_r_ph", machInst);
													case 0x4:
														return new FailUnimplemented("Mul_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Mul_s_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Addqh_w", machInst);
													case 0x1:
														return new FailUnimplemented("Subqh_w", machInst);
													case 0x2:
														return new FailUnimplemented("Addqh_r_w", machInst);
													case 0x3:
														return new FailUnimplemented("Subqh_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Mulq_s_w", machInst);
													case 0x7:
														return new FailUnimplemented("Mulq_rs_w", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x4:
								switch(machInst[SA]) {
									case 0x2:
										return new FailUnimplemented("Wsbh", machInst);
									case 0x10:
										return new FailUnimplemented("Seb", machInst);
									case 0x18:
										return new FailUnimplemented("Seh", machInst);
									default:
										return new Unknown(machInst);
								}
							case 0x6:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpa_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dps_w_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Mulsa_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpau_h_qbl", machInst);
													case 0x4:
														return new FailUnimplemented("Dpaq_s_w_ph", machInst);
													case 0x5:
														return new FailUnimplemented("Dpsq_s_w_ph", machInst);
													case 0x6:
														return new FailUnimplemented("Mulsaq_s_w_ph", machInst);
													case 0x7:
														return new FailUnimplemented("Dpau_h_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpax_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dpsx_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpsu_h_qbl", machInst);
													case 0x4:
														return new FailUnimplemented("Dpaq_sa_l_w", machInst);
													case 0x5:
														return new FailUnimplemented("Dpsq_sa_l_w", machInst);
													case 0x7:
														return new FailUnimplemented("Dpsu_h_qbr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Maq_sa_w_phl", machInst);
													case 0x2:
														return new FailUnimplemented("Maq_sa_w_phr", machInst);
													case 0x4:
														return new FailUnimplemented("Maq_s_w_phl", machInst);
													case 0x6:
														return new FailUnimplemented("Maq_s_w_phr", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Dpaqx_s_w_ph", machInst);
													case 0x1:
														return new FailUnimplemented("Dpsqx_s_w_ph", machInst);
													case 0x2:
														return new FailUnimplemented("Dpaqx_sa_w_ph", machInst);
													case 0x3:
														return new FailUnimplemented("Dpsqx_sa_w_ph", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x1:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Append", machInst);
													case 0x1:
														return new FailUnimplemented("Prepend", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Balign", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							case 0x7:
								switch(machInst[FUNC_LO]) {
									case 0x0:
										switch(machInst[OP_HI]) {
											case 0x0:
												switch(machInst[OP_LO]) {
													case 0x0:
														return new FailUnimplemented("Extr_w", machInst);
													case 0x1:
														return new FailUnimplemented("Extrv_w", machInst);
													case 0x2:
														return new FailUnimplemented("Extp", machInst);
													case 0x3:
														return new FailUnimplemented("Extpv", machInst);
													case 0x4:
														return new FailUnimplemented("Extr_r_w", machInst);
													case 0x5:
														return new FailUnimplemented("Extrv_r_w", machInst);
													case 0x6:
														return new FailUnimplemented("Extr_rs_w", machInst);
													case 0x7:
														return new FailUnimplemented("Extrv_rs_w", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x1:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Extpdp", machInst);
													case 0x3:
														return new FailUnimplemented("Extpdpv", machInst);
													case 0x6:
														return new FailUnimplemented("Extr_s_h", machInst);
													case 0x7:
														return new FailUnimplemented("Extrv_s_h", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x2:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Rddsp", machInst);
													case 0x3:
														return new FailUnimplemented("Wrdsp", machInst);
													default:
														return new Unknown(machInst);
												}
											case 0x3:
												switch(machInst[OP_LO]) {
													case 0x2:
														return new FailUnimplemented("Shilo", machInst);
													case 0x3:
														return new FailUnimplemented("Shilov", machInst);
													case 0x7:
														return new FailUnimplemented("Mthlip", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									case 0x3:
										switch(machInst[OP]) {
											case 0x0:
												switch(machInst[RD]) {
													case 0x1d:
														return new FailUnimplemented("Rdhwr", machInst);
													default:
														return new Unknown(machInst);
												}
											default:
												return new Unknown(machInst);
										}
									default:
										return new Unknown(machInst);
								}
							default:
								return new Unknown(machInst);
						}
					default:
						return new Unknown(machInst);
				}
			case 0x4:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Lb(machInst);
					case 0x1:
						return new Lh(machInst);
					case 0x3:
						return new Lw(machInst);
					case 0x4:
						return new Lbu(machInst);
					case 0x5:
						return new Lhu(machInst);
					case 0x2:
						return new Lwl(machInst);
					case 0x6:
						return new Lwr(machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x5:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Sb(machInst);
					case 0x1:
						return new Sh(machInst);
					case 0x3:
						return new Sw(machInst);
					case 0x2:
						return new Swl(machInst);
					case 0x6:
						return new Swr(machInst);
					case 0x7:
						return new FailUnimplemented("Cache", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x6:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Ll(machInst);
					case 0x1:
						return new Lwc1(machInst);
					case 0x5:
						return new Ldc1(machInst);
					case 0x2:
						return new CP2Unimplemented("lwc2", machInst);
					case 0x6:
						return new CP2Unimplemented("ldc2", machInst);
					case 0x3:
						return new FailUnimplemented("Pref", machInst);
					default:
						return new Unknown(machInst);
				}
			case 0x7:
				switch(machInst[OPCODE_LO]) {
					case 0x0:
						return new Sc(machInst);
					case 0x1:
						return new Swc1(machInst);
					case 0x5:
						return new Sdc1(machInst);
					case 0x2:
						return new CP2Unimplemented("swc2", machInst);
					case 0x6:
						return new CP2Unimplemented("sdc2", machInst);
					default:
						return new Unknown(machInst);
				}
			default:
				return new Unknown(machInst);
		}
	}
}

class Syscall: StaticInst {
	public:
		this(MachInst machInst) {
			super("syscall", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, 2);
		}

		override void execute(Thread thread) {
			thread.syscall(thread.intRegs[2]);
		}
}

class Sll: StaticInst {
	public:
		this(MachInst machInst) {
			super("sll", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RT]] << this[SA];
		}
}

class Sllv: StaticInst {
	public:
		this(MachInst machInst) {
			super("sllv", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RT]] << bits(thread.intRegs[this[RS]], 4, 0);
		}
}

class Sra: StaticInst {
	public:
		this(MachInst machInst) {
			super("sra", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RT]] >> this[SA];
		}
}

class Srav: StaticInst {
	public:
		this(MachInst machInst) {
			super("srav", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RT]] >> bits(thread.intRegs[this[RS]], 4, 0);
		}
}

class Srl: StaticInst {
	public:
		this(MachInst machInst) {
			super("srl", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RT]] >> this[SA];
		}
}

class Srlv: StaticInst {
	public:
		this(MachInst machInst) {
			super("srlv", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RT]] >> bits(thread.intRegs[this[RS]], 4, 0);
		}
}

abstract class Branch: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
			this.displacement = sext(this[OFFSET] << 2, 16);
		}
		
		override uint targetPc(Thread thread) {
			return thread.npc + this.displacement;
		}
		
		void branch(Thread thread) {
			thread.nnpc = this.targetPc(thread);
		}

	private:
		int displacement;
}

class B: Branch {
	public:
		this(MachInst machInst) {
			super("b", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			
		}

		override void execute(Thread thread) {
			this.branch(thread);
		}
}

class Bal: Branch {
	public:
		this(MachInst machInst) {
			super("bal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, ReturnAddressReg);
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			this.branch(thread);
		}
}

class Beq: Branch {
	public:
		this(MachInst machInst) {
			super("beq", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] == cast(int) thread.intRegs[this[RT]]) {
				this.branch(thread);
			}
		}
}

class Beqz: Branch {
	public:
		this(MachInst machInst) {
			super("beqz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] == 0) {
				this.branch(thread);
			}
		}
}

class Bgez: Branch {
	public:
		this(MachInst machInst) {
			super("bgez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] >= 0) {
				this.branch(thread);
			}
		}
}

class Bgezal: Branch {
	public:
		this(MachInst machInst) {
			super("bgezal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, ReturnAddressReg);
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			if(cast(int) thread.intRegs[this[RS]] >= 0) {
				this.branch(thread);
			}
		}
}

class Bgtz: Branch {
	public:
		this(MachInst machInst) {
			super("bgtz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] > 0) {
				this.branch(thread);
			}
		}
}

class Blez: Branch {
	public:
		this(MachInst machInst) {
			super("blez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] <= 0) {
				this.branch(thread);
			}
		}
}

class Bltz: Branch {
	public:
		this(MachInst machInst) {
			super("bltz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] < 0) {
				this.branch(thread);
			}
		}
}

class Bltzal: Branch {
	public:
		this(MachInst machInst) {
			super("bltzal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {			
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, ReturnAddressReg);
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			if(cast(int) thread.intRegs[this[RS]] < 0) {
				this.branch(thread);
			}
		}
}

class Bne: Branch {
	public:
		this(MachInst machInst) {
			super("bne", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}
		
		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] != cast(int) thread.intRegs[this[RT]]) {
				this.branch(thread);
			}
		}
}

class Bnez: Branch {
	public:
		this(MachInst machInst) {
			super("bnez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] != 0) {
				this.branch(thread);
			}
		}
}

class Bc1f: Branch {
	public:
		this(MachInst machInst) {
			super("bc1f", machInst, StaticInstFlag.CTRL | StaticInstFlag.COND, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}

		override void execute(Thread thread) {
			uint fcsr = thread.miscRegs.fcsr;
			bool cond = getFCC(fcsr, this[BRANCH_CC]) == 0;
			
			if(cond) {
				this.branch(thread);
			}
		}
}

class Bc1t: Branch {
	public:
		this(MachInst machInst) {
			super("bc1t", machInst, StaticInstFlag.CTRL | StaticInstFlag.COND, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}

		override void execute(Thread thread) {
			uint fcsr = thread.miscRegs.fcsr;
			bool cond = getFCC(fcsr, this[BRANCH_CC]) == 1;
			
			if(cond) {
				this.branch(thread);
			}
		}
}

class Bc1fl: Branch {
	public:
		this(MachInst machInst) {
			super("bc1fl", machInst, StaticInstFlag.CTRL | StaticInstFlag.COND, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}

		override void execute(Thread thread) {
			uint fcsr = thread.miscRegs.fcsr;
			bool cond = getFCC(fcsr, this[BRANCH_CC]) == 0;
			
			if(cond) {
				this.branch(thread);
			}
			else {
				thread.npc = thread.nnpc;
				thread.nnpc = thread.nnpc + uint.sizeof;
			}
		}
}

class Bc1tl: Branch {
	public:
		this(MachInst machInst) {
			super("bc1tl", machInst, StaticInstFlag.CTRL | StaticInstFlag.COND, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}

		override void execute(Thread thread) {
			uint fcsr = thread.miscRegs.fcsr;
			bool cond = getFCC(fcsr, this[BRANCH_CC]) == 1;
			
			if(cond) {
				this.branch(thread);
			}
			else {
				thread.npc = thread.nnpc;
				thread.nnpc = thread.nnpc + uint.sizeof;
			}
		}
}

abstract class Jump: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
			this.target = this[JMPTARG] << 2;
		}

		void jump(Thread thread) {
			thread.nnpc = this.targetPc(thread);
		}

	private:
		uint target;
}

class J: Jump {
	public:
		this(MachInst machInst) {
			super("j", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
		}
		
		override uint targetPc(Thread thread) {
			return mbits(thread.npc, 32, 28) | this.target;
		}

		override void execute(Thread thread) {
			this.jump(thread);
		}
}

class Jal: Jump {
	public:
		this(MachInst machInst) {
			super("jal", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, ReturnAddressReg);
		}

		override uint targetPc(Thread thread) {
			return mbits(thread.npc, 32, 28) | this.target;
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			this.jump(thread);
		}
}

class Jalr: Jump {
	public:
		this(MachInst machInst) {
			super("jalr", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.CALL | StaticInstFlag.INDIRJMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}
		
		override uint targetPc(Thread thread) {
			return thread.intRegs[this[RS]];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.nnpc;
			this.jump(thread);
		}
}

class Jr: Jump {
	public:
		this(MachInst machInst) {
			super("jr", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.RET | StaticInstFlag.INDIRJMP, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
		}

		override uint targetPc(Thread thread) {
			return thread.intRegs[this[RS]];
		}

		override void execute(Thread thread) {
			this.jump(thread);
		}
}

abstract class IntOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

abstract class IntImmOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
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
			super("add", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] + cast(int) thread.intRegs[this[RT]];
			logging.warn(LogCategory.INSTRUCTION, "Add: overflow trap not implemented.");
		}
}

class Addi: IntImmOp {
	public:
		this(MachInst machInst) {
			super("addi", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] + this.sextImm;
			logging.warn(LogCategory.INSTRUCTION, "Addi: overflow trap not implemented.");
		}
}

class Addiu: IntImmOp {
	public:
		this(MachInst machInst) {
			super("addiu", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] + this.sextImm;
		}
}

class Addu: IntOp {
	public:
		this(MachInst machInst) {
			super("addu", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] + cast(int) thread.intRegs[this[RT]];
		}
}

class Sub: IntOp {
	public:
		this(MachInst machInst) {
			super("sub", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] - cast(int) thread.intRegs[this[RT]];
			logging.warn(LogCategory.INSTRUCTION, "Sub: overflow trap not implemented.");
		}
}

class Subu: IntOp {
	public:
		this(MachInst machInst) {
			super("subu", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] - cast(int) thread.intRegs[this[RT]];
		}
}

class And: IntOp {
	public:
		this(MachInst machInst) {
			super("and", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] & thread.intRegs[this[RT]];
		}
}

class Andi: IntImmOp {
	public:
		this(MachInst machInst) {
			super("andi", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] & this.zextImm;
		}
}

class Nor: IntOp {
	public:
		this(MachInst machInst) {
			super("nor", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = ~(thread.intRegs[this[RS]] | thread.intRegs[this[RT]]);
		}
}

class Or: IntOp {
	public:
		this(MachInst machInst) {
			super("or", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] | thread.intRegs[this[RT]];
		}
}

class Ori: IntImmOp {
	public:
		this(MachInst machInst) {
			super("ori", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] | this.zextImm;
		}
}

class Xor: IntOp {
	public:
		this(MachInst machInst) {
			super("xor", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.intRegs[this[RS]] ^ thread.intRegs[this[RT]];
		}
}

class Xori: IntImmOp {
	public:
		this(MachInst machInst) {
			super("xori", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = thread.intRegs[this[RS]] ^ this.zextImm;
		}
}

class Slt: IntOp {
	public:
		this(MachInst machInst) {
			super("slt", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(int) thread.intRegs[this[RS]] < cast(int) thread.intRegs[this[RT]] ? 1 : 0;
		}
}

class Slti: IntImmOp {
	public:
		this(MachInst machInst) {
			super("slti", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(int) thread.intRegs[this[RS]] < this.sextImm ? 1 : 0;
		}
}

class Sltiu: IntImmOp {
	public:
		this(MachInst machInst) {
			super("sltiu", machInst, StaticInstFlag.ICOMP | StaticInstFlag.IMM, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = cast(uint) thread.intRegs[this[RS]] < this.zextImm ? 1 : 0;
		}
}

class Sltu: IntOp {
	public:
		this(MachInst machInst) {
			super("sltu", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = cast(uint) thread.intRegs[this[RS]] < cast(uint) thread.intRegs[this[RT]] ? 1 : 0;
		}
}

class Lui: IntImmOp {
	public:
		this(MachInst machInst) {
			super("lui", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RT]] = this.imm << 16;
		}
}

class Divu: StaticInst {
	public:
		this(MachInst machInst) {
			super("divu", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntDIV);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
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

			thread.miscRegs.lo = lo;
			thread.miscRegs.hi = hi;
		}
}

class Div: StaticInst {
	public:
		this(MachInst machInst) {
			super("div", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntDIV);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
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

			thread.miscRegs.lo = lo;
			thread.miscRegs.hi = hi;
		}
}

class Mflo: StaticInst {
	public:
		this(MachInst machInst) {
			super("mflo", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.miscRegs.lo;
		}
}

class Mfhi: StaticInst {
	public:
		this(MachInst machInst) {
			super("mfhi", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.miscRegs.hi;
		}
}

class Mtlo: StaticInst {
	public:
		this(MachInst machInst) {
			super("mtlo", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
		}

		override void execute(Thread thread) {
			thread.miscRegs.lo = thread.intRegs[this[RD]];
		}
}

class Mthi: StaticInst {
	public:
		this(MachInst machInst) {
			super("mthi", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RD]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
		}

		override void execute(Thread thread) {
			thread.miscRegs.hi = thread.intRegs[this[RD]];
		}
}

class Mult: StaticInst {
	public:
		this(MachInst machInst) {
			super("mult", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
		}

		override void execute(Thread thread) {
			long rs = 0;
			long rt = 0;
			
			rs = sext(thread.intRegs[this[RS]], 32);
			rt = sext(thread.intRegs[this[RT]], 32);

			long val = rs * rt;

			uint lo = cast(uint) bits64(val, 31, 0);
			uint hi = cast(uint) bits64(val, 63, 32);

			thread.miscRegs.lo = lo;
			thread.miscRegs.hi = hi;
		}
}

class Multu: StaticInst {
	public:
		this(MachInst machInst) {
			super("multu", machInst, StaticInstFlag.ICOMP, FunctionalUnitType.IntALU);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.LO);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.HI);
		}

		override void execute(Thread thread) {
			ulong rs = 0;
			ulong rt = 0;
			
			rs = thread.intRegs[this[RS]];
			rt = thread.intRegs[this[RT]];

			ulong val = rs * rt;

			uint lo = cast(uint) bits64(val, 31, 0);
			uint hi = cast(uint) bits64(val, 63, 32);

			thread.miscRegs.lo = lo;
			thread.miscRegs.hi = hi;
		}
}

abstract class FloatOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

abstract class FloatBinaryOp: FloatOp {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FD]);
		}
}

abstract class FloatUnaryOp: FloatOp {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FD]);
		}
}

class Add_d: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("add_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatADD);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs + ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Sub_d: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("sub_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatADD);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs - ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Mul_d: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("mul_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatMULT);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs * ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Div_d: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("div_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatDIV);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs / ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Sqrt_d: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("sqrt_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatSQRT);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = sqrt(fs);
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Abs_d: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("abs_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = fabs(fs);
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Neg_d: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("neg_d", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = -1 * fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Mov_d: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("mov_d", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double fd = fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Add_s: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("add_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatADD);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs + ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Sub_s: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("sub_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatADD);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs - ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Mul_s: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("mul_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatMULT);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs * ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Div_s: FloatBinaryOp {
	public:
		this(MachInst machInst) {
			super("div_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatDIV);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs / ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Sqrt_s: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("sqrt_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatSQRT);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = sqrt(fs);
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Abs_s: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("abs_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = fabs(fs);
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Neg_s: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("neg_s", machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = -fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Mov_s: FloatUnaryOp {
	public:
		this(MachInst machInst) {
			super("mov_s", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float fd = fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

abstract class FloatConvertOp: FloatOp {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCVT);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FD]);
		}
}

class Cvt_d_s: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_s", machInst);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			double fd = cast(double) fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Cvt_w_s: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_w_s", machInst);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			uint fd = cast(uint) fs;
			
			thread.floatRegs.setUint(fd, this[FD]);
		}
}

class Cvt_l_s: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_l_s", machInst);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			ulong fd = cast(ulong) fs;
			
			thread.floatRegs.setUlong(fd, this[FD]);
		}
}

class Cvt_s_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_s_d", machInst);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			float fd = cast(float) fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Cvt_w_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_w_d", machInst);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			uint fd = cast(uint) fs;
			
			thread.floatRegs.setUint(fd, this[FD]);
		}
}

class Cvt_l_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_l_d", machInst);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			ulong fd = cast(ulong) fs;
			
			thread.floatRegs.setUlong(fd, this[FD]);
		}
}

class Cvt_s_w: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_s_w", machInst);
		}

		override void execute(Thread thread) {
			uint fs = thread.floatRegs.getUint(this[FS]);
			float fd = cast(float) fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Cvt_d_w: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_w", machInst);
		}

		override void execute(Thread thread) {
			uint fs = thread.floatRegs.getUint(this[FS]);
			double fd = cast(double) fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Cvt_s_l: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_s_l", machInst);
		}

		override void execute(Thread thread) {
			ulong fs = thread.floatRegs.getUlong(this[FS]);
			float fd = cast(float) fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Cvt_d_l: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_l", machInst);
		}

		override void execute(Thread thread) {
			ulong fs = thread.floatRegs.getUlong(this[FS]);
			double fd = cast(double) fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);		
		}
}

abstract class FloatCompareOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FT]);
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}
}

class C_cond_d(alias mnemonic): FloatCompareOp {
	public:
		this(MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.miscRegs.fcsr;
		
			bool less;
			bool equal;
			
			bool unordered = isnan(fs) || isnan(ft);
			if(unordered) {
				equal = false;
				less = false;
			}
			else {
				equal = fs == ft;
				less = fs < ft;
			}

			uint cond = this[COND];
			
			if(((cond&0x4) && less)||((cond&0x2) && equal)||((cond&0x1) && unordered)) {
				setFCC(fcsr, this[CC]);
			}
			else {
				clearFCC(fcsr, this[CC]);
			}
			
			thread.miscRegs.fcsr = fcsr;			
		}
}

class C_cond_s(alias mnemonic): FloatCompareOp {
	public:
		this(MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.FCOMP, FunctionalUnitType.FloatCMP);
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			uint fcsr = thread.miscRegs.fcsr;
		
			bool less;
			bool equal;
			
			bool unordered = isnan(fs) || isnan(ft);
			if(unordered) {
				equal = false;
				less = false;
			}
			else {
				equal = fs == ft;
				less = fs < ft;
			}

			uint cond = this[COND];
			
			if(((cond&0x4) && less)||((cond&0x2) && equal)||((cond&0x1) && unordered)) {
				setFCC(fcsr, this[CC]);
			}
			else {
				clearFCC(fcsr, this[CC]);
			}
			
			thread.miscRegs.fcsr = fcsr;
		}
}

alias C_cond_d!("c_f_d") C_f_d;
alias C_cond_d!("c_un_d") C_un_d;
alias C_cond_d!("c_eq_d") C_eq_d;
alias C_cond_d!("c_ueq_d") C_ueq_d;
alias C_cond_d!("c_olt_d") C_olt_d;
alias C_cond_d!("c_ult_d") C_ult_d;
alias C_cond_d!("c_ole_d") C_ole_d;
alias C_cond_d!("c_ule_d") C_ule_d;
alias C_cond_d!("c_sf_d") C_sf_d;
alias C_cond_d!("c_ngle_d") C_ngle_d;
alias C_cond_d!("c_seq_d") C_seq_d;
alias C_cond_d!("c_ngl_d") C_ngl_d;
alias C_cond_d!("c_lt_d") C_lt_d;
alias C_cond_d!("c_nge_d") C_nge_d;
alias C_cond_d!("c_le_d") C_le_d;
alias C_cond_d!("c_ngt_d") C_ngt_d;

alias C_cond_s!("c_f_s") C_f_s;
alias C_cond_s!("c_un_s") C_un_s;
alias C_cond_s!("c_eq_s") C_eq_s;
alias C_cond_s!("c_ueq_s") C_ueq_s;
alias C_cond_s!("c_olt_s") C_olt_s;
alias C_cond_s!("c_ult_s") C_ult_s;
alias C_cond_s!("c_ole_s") C_ole_s;
alias C_cond_s!("c_ule_s") C_ule_s;
alias C_cond_s!("c_sf_s") C_sf_s;
alias C_cond_s!("c_ngle_s") C_ngle_s;
alias C_cond_s!("c_seq_s") C_seq_s;
alias C_cond_s!("c_ngl_s") C_ngl_s;
alias C_cond_s!("c_lt_s") C_lt_s;
alias C_cond_s!("c_nge_s") C_nge_s;
alias C_cond_s!("c_le_s") C_le_s;
alias C_cond_s!("c_ngt_s") C_ngt_s;

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

class CP1Control: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FunctionalUnitType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

class Mfc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("mfc1", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {			
			uint fs = thread.floatRegs.getUint(this[FS]);
			thread.intRegs[this[RT]] = fs;
		}
}

class Cfc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("cfc1", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
		}

		override void execute(Thread thread) {			
			uint fcsr = thread.miscRegs.fcsr;
			
			uint rt = 0;
			
			if(this[FS] == 31) {
				rt = fcsr;
				thread.intRegs[this[RT]] = rt;
			}
		}
}

class Mtc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("mtc1", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.FP, this[FS]);
		}

		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			thread.floatRegs.setUint(rt, this[FS]);
		}
}

class Ctc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("ctc1", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}

		override void setupDeps() {
			this.iDeps ~= new RegisterDependency(RegisterDependencyType.INT, this[RT]);
			this.oDeps ~= new RegisterDependency(RegisterDependencyType.MISC, MiscRegNums.FCSR);
		}

		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			
			if(this[FS]) {
				thread.miscRegs.fcsr = rt;
			}
		}
}

class Nop: StaticInst {
	public:
		this(MachInst machInst) {
			super("nop", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
		}
}

class FailUnimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
			Fault fault = new UnimplFault(format("[%s] machInst: 0x%08x, mnemonic: \"%s\"", typeof(this).stringof, this.machInst.data, this.mnemonic));
			fault.invoke(thread);
		}
}

class CP0Unimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

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
			super("unknown", machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
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
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);
		}
		
		override void setupDeps() {
		}
}

class TrapImm: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FunctionalUnitType.NONE);

			this.imm = cast(short) machInst[INTIMM];
		}
		
		override void setupDeps() {
		}

	protected:
		short imm;
}

class Fault {
	public:
		abstract string getName();

		void invoke(Thread thread) {
			logging.panicf(LogCategory.INSTRUCTION, "fault (%s) detected @ PC %p", this.getName(), thread.pc);
		}
}

class UnimplFault: Fault {
	public:
		this(string panicStr) {
			this.panicStr = panicStr;
		}

		override string getName() {
			return "Unimplemented simulator feature";
		}

		override void invoke(Thread thread) {
			logging.panicf(LogCategory.INSTRUCTION, "UnimplFault (%s)\n", this.panicStr);
		}

	private:
		string panicStr;
}

class ReservedInstructionFault: Fault {
	public:
		override string getName() {
			return "Reserved Instruction Fault";
		}

		override void invoke(Thread thread) {
			logging.panicf(LogCategory.INSTRUCTION, "ReservedInstructionFault (%s)\n", this.getName());
		}
}