/*
 * flexim/isa/misc.d
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

module flexim.isa.misc;

import flexim.all;

class Nop: StaticInst {
	public:
		this(MachInst machInst) {
			super("nop", machInst, StaticInstFlag.NONE, FUType.NONE);
		}
		
		override void setupDeps() {
		}

		override void execute(Thread thread) {
		}
}

class FailUnimplemented: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

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
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

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
			super("unknown", machInst, StaticInstFlag.NONE, FUType.NONE);
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
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);
		}
		
		override void setupDeps() {
		}
}

class TrapImm: StaticInst {
	public:
		this(string mnemonic, MachInst machInst) {
			super(mnemonic, machInst, StaticInstFlag.NONE, FUType.NONE);

			this.imm = cast(short) machInst[INTIMM];
		}
		
		override void setupDeps() {
		}

	protected:
		short imm;
}