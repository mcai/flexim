/*
 * flexim/isa/basic.d
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

module flexim.isa.basic;

import flexim.all;

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
