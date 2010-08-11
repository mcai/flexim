/*
 * flexim/isa/control.d
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

module flexim.isa.control;

import flexim.all;

class CP1Control: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
		}
}

class Mfc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("mfc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + this[FS];
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {			
			uint fs = thread.floatRegs.get(this[FS]);
			thread.intRegs[this[RT]] = fs;
		}
}

class Cfc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("cfc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FIR;
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.destRegIdx ~= this[RT];
		}

		override void execute(Thread thread) {			
			uint fir = thread.floatRegs.get(FPControlRegNums.FIR);
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			
			uint rt = 0;
			
			switch(this[FS]) {
				case 0:
					rt = fir;
				break;
				case 25:
					rt = (bits(fcsr, 31, 25) << 1) | bits(fcsr, 23, 23);
				break;
				case 26:
					rt = (bits(fcsr, 17, 12) << 12) | (bits(fcsr, 6, 2) << 2);
				break;
				case 28:
					rt = (bits(fcsr, 11, 7) << 7) | (bits(fcsr, 24, 24) << 2) | bits(fcsr, 1, 0);
				break;
				case 31:
					rt = fcsr;
				break;				
			}
			thread.intRegs[this[RT]] = rt;
		}
}

class Mtc1: CP1Control {

	public:
		this(MachInst machInst) {
			super("mtc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= FP_Base_DepTag + this[FS];
		}

		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			thread.floatRegs.set(rt, this[FS]);
		}
}

class Ctc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("ctc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= FP_Base_DepTag + FPControlRegNums.FCSR;
		}

		override void execute(Thread thread) {			
			uint fcsr = thread.floatRegs.get(FPControlRegNums.FCSR);
			uint rt = thread.intRegs[this[RT]];
			
			switch(this[FS]) {
				case 25:
					thread.floatRegs.set(FPControlRegNums.FCSR,
						(bits(rt, 7, 1) << 25) | (bits(fcsr, 24, 24) << 24) | (bits(rt, 0, 0) << 23) | bits(fcsr, 22, 0));
				break;
				case 26:
					thread.floatRegs.set(FPControlRegNums.FCSR,
						(bits(fcsr, 31, 18) << 18) | (bits(rt, 17, 12) << 12) | (bits(fcsr, 11, 7) << 7) | (bits(rt, 6, 2) << 2) | bits(fcsr, 1, 0));					
				break;
				case 28:
					thread.floatRegs.set(FPControlRegNums.FCSR,
						(bits(fcsr, 31, 25) << 25) | (bits(rt, 2, 2) << 24) | (bits(fcsr, 23, 12) << 12) | (bits(rt, 11, 7) << 7) | (bits(fcsr, 6, 2) << 2) | bits(rt, 1, 0));					
				break;
				case 31:
					thread.floatRegs.set(FPControlRegNums.FCSR, rt);
				break;
			}
		}
}