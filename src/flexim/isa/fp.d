/*
 * flexim/isa/fp.d
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

module flexim.isa.fp;

import flexim.all;

abstract class FloatOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

alias FloatOp FloatConvertOp;
alias FloatOp FloatCompareOp;

class Add_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("add_d", machInst, StaticInstFlag.FCOMP, FUType.FloatADD);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			
			double fd = fs + ft;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Sub_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("sub_d", machInst, StaticInstFlag.FCOMP, FUType.FloatADD);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			
			double fd = fs - ft;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Mul_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("mul_d", machInst, StaticInstFlag.FCOMP, FUType.FloatMULT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			
			double fd = fs * ft;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Div_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("div_d", machInst, StaticInstFlag.FCOMP, FUType.FloatDIV);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			
			double fd = fs / ft;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Sqrt_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("sqrt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatSQRT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			
			double fd = sqrt(fs);
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Abs_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("abs_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			
			double fd = fabs(fs);
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Neg_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("neg_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			
			double fd = -1 * fs;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Mov_d: FloatOp {
	public:
		this(MachInst machInst) {
			super("mov_d", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double fd = fs;
			
			thread.floatRegs[this[FD]] = fd;
		}
}

class Cvt_s_w: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_s_w", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			uint fs = thread.floatRegs.get(this[FS]);
			uint fd = wordToSingle(fs);
			
			thread.floatRegs.set(fd, this[FD]);
		}
}

class Cvt_d_w: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_w", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			uint fs = thread.floatRegs.get(this[FS]);
			ulong fd = wordToDouble(fs);
			
			thread.floatRegs.set(cast(uint) fd, this[FD]);
		}
}

class Cvt_s_l: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_s_l", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			ulong fs = bits64(thread.floatRegs.get(this[FS]), 63, 0);
			uint fd = longToSingle(fs);
			
			thread.floatRegs.set(fd, this[FD]);
		}
}

class Cvt_d_l: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_l", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			ulong fs = bits64(thread.floatRegs.get(this[FS]), 63, 0);
			ulong fd = longToDouble(fs);
			
			thread.floatRegs.set(cast(uint) fd, this[FD]);			
		}
}

class C_f_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_f_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = false;
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);			
		}
}

class C_un_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_un_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = isNan(&fs, 64) || isNan(&ft, 64);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_eq_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_eq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {		
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ueq_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ueq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_olt_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_olt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ult_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ult_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ole_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ole_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ule_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ule_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_sf_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_sf_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = false;
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngle_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ngle_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = isNan(&fs, 64) || isNan(&ft, 64);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_seq_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_seq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngl_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ngl_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_lt_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_lt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_nge_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_nge_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_le_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_le_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? false : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngt_d: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("C_ngt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs[this[FS]];
			double ft = thread.floatRegs[this[FT]];
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			if(isQnan(&fs, 64) || isQnan(&ft, 64)) {
				fcsr = genInvalidVector(fcsr);
				return;
			}
			
			bool cond = (isNan(&fs, 64) || isNan(&ft, 64)) ? true : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.set(fcsr, FPControlRegNums.FCSR);
		}
}