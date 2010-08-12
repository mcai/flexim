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
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs + ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs - ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs * ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			
			double fd = fs / ft;
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = sqrt(fs);
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = fabs(fs);
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			
			double fd = -1 * fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
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
			double fs = thread.floatRegs.getDouble(this[FS]);
			double fd = fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);
		}
}

class Add_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("add_s", machInst, StaticInstFlag.FCOMP, FUType.FloatADD);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs + ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Sub_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("sub_s", machInst, StaticInstFlag.FCOMP, FUType.FloatADD);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs - ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Mul_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("mul_s", machInst, StaticInstFlag.FCOMP, FUType.FloatMULT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs * ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Div_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("div_s", machInst, StaticInstFlag.FCOMP, FUType.FloatDIV);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float ft = thread.floatRegs.getFloat(this[FT]);
			
			float fd = fs / ft;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Sqrt_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("sqrt_s", machInst, StaticInstFlag.FCOMP, FUType.FloatSQRT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = sqrt(fs);
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Abs_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("abs_s", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = fabs(fs);
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Neg_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("neg_s", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			
			float fd = -fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Mov_s: FloatOp {
	public:
		this(MachInst machInst) {
			super("mov_s", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			float fs = thread.floatRegs.getFloat(this[FS]);
			float fd = fs;
			
			thread.floatRegs.setFloat(fd, this[FD]);
		}
}

class Cvt_d_s: FloatConvertOp {
	public:
		this(MachInst machInst) {
			super("cvt_d_s", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_w_s", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_l_s", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_s_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_w_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_l_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_s_w", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_d_w", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_s_l", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
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
			super("cvt_d_l", machInst, StaticInstFlag.FCOMP, FUType.FloatCVT);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= FP_Base_DepTag + this[FD];
		}

		override void execute(Thread thread) {
			ulong fs = thread.floatRegs.getUlong(this[FS]);
			double fd = cast(double) fs;
			
			thread.floatRegs.setDouble(fd, this[FD]);		
		}
}

abstract class FloatCompareOp: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.srcRegIdx ~= FP_Base_DepTag + this[FT];
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
		
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
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);			
		}
}

class C_f_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_f_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = false;
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);			
		}
}

class C_un_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_un_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = isnan(fs) || isnan(ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_eq_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_eq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {		
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ueq_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ueq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_olt_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_olt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ult_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ult_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ole_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ole_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ule_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ule_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_sf_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_sf_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = false;
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngle_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ngle_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = isnan(fs) || isnan(ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_seq_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_seq_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngl_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ngl_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs == ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_lt_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_lt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_nge_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_nge_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs < ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_le_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_le_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {	
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? false : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}

class C_ngt_d: FloatCompareOp {
	public:
		this(MachInst machInst) {
			super("C_ngt_d", machInst, StaticInstFlag.FCOMP, FUType.FloatCMP);
		}

		override void execute(Thread thread) {
			double fs = thread.floatRegs.getDouble(this[FS]);
			double ft = thread.floatRegs.getDouble(this[FT]);
			uint fcsr = thread.floatRegs.getUint(FPControlRegNums.FCSR);
			
			bool cond = (isnan(fs) || isnan(ft)) ? true : (fs <= ft);
			
			fcsr = genCCVector(fcsr, this[CC], cond);
			
			thread.floatRegs.setUint(fcsr, FPControlRegNums.FCSR);
		}
}