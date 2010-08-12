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
			uint fs = thread.floatRegs.getUint(this[FS]);
			thread.intRegs[this[RT]] = fs;
		}
}

class Cfc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("cfc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= Misc_Base_DepTag + MiscRegNums.FCSR;
			this.destRegIdx ~= this[RT];
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
			super("mtc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= FP_Base_DepTag + this[FS];
		}

		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			thread.floatRegs.setUint(rt, this[FS]);
		}
}

class Ctc1: CP1Control {
	public:
		this(MachInst machInst) {
			super("ctc1", machInst, StaticInstFlag.NONE, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RT];
			this.destRegIdx ~= Misc_Base_DepTag + MiscRegNums.FCSR;
		}

		override void execute(Thread thread) {
			uint rt = thread.intRegs[this[RT]];
			
			if(this[FS]) {
				thread.miscRegs.fcsr = rt;
			}
		}
}