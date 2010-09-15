/*
 * flexim/cpu/instruction.d
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

module flexim.cpu.instruction;

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

	buf ~= format("0x%08x : 0x%08x %s ", pc, machInst.data, thread.isa.decodeMachInst(machInst).getName());

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
		
		MachInst machInst() {
			return this.m_machInst;
		}
		
		string mnemonic() {
			return this.m_mnemonic;
		}
		
		StaticInstFlag flags() {
			return this.m_flags;
		}
		
		FunctionalUnitType fuType() {
			return this.m_fuType;
		}

		string getName() {
			return this.mnemonic;
		}

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

	protected:		
		void machInst(MachInst value) {
			this.m_machInst = value;
		}
		
		void mnemonic(string value) {
			this.m_mnemonic = value;
		}
		
		void flags(StaticInstFlag value) {
			this.m_flags = value;
		}
		
		void fuType(FunctionalUnitType value) {
			this.m_fuType = value;
		}
		
		MachInst m_machInst;
		string m_mnemonic;
		StaticInstFlag m_flags;
		FunctionalUnitType m_fuType;
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