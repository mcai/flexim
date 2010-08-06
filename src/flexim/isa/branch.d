/*
 * flexim/isa/branch.d
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

module flexim.isa.branch;

import flexim.all;

abstract class Branch: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
			this.displacement = sext(this[OFFSET] << 2, 16);
		}

		void branch(Thread thread) {
			thread.nnpc = thread.npc + this.displacement;
		}

	private:
		int displacement;
}

class B: Branch {
	public:
		this(MachInst machInst) {
			super("b", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FUType.IntALU);
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
			super("bal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.destRegIdx ~= ReturnAddressReg;
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			this.branch(thread);
		}
}

class Beq: Branch {
	public:
		this(MachInst machInst) {
			super("beq", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
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
			super("beqz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
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
			super("bgez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
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
			super("bgezal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= ReturnAddressReg;
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
			super("bgtz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
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
			super("blez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
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
			super("bltz", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
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
			super("bltzal", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {			
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= ReturnAddressReg;
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
			super("bne", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}
		
		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.srcRegIdx ~= this[RT];
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
			super("bnez", machInst, StaticInstFlag.ICOMP | StaticInstFlag.CTRL | StaticInstFlag.COND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
		}

		override void execute(Thread thread) {
			if(cast(int) thread.intRegs[this[RS]] != 0) {
				this.branch(thread);
			}
		}
}

abstract class Jump: StaticInst {
	public:
		this(string mnemonic, MachInst machInst, StaticInstFlag flags, FUType fuType) {
			super(mnemonic, machInst, flags, fuType);
			this.target = this[JMPTARG] << 2;
		}

		void jump(Thread thread, Addr addr) {
			thread.nnpc = addr;
		}
		
		abstract Addr targetPc(Thread thread);

	private:
		uint target;
}

class J: Jump {
	public:
		this(MachInst machInst) {
			super("j", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.DIRJMP, FUType.IntALU);
		}

		override void setupDeps() {
		}
		
		override Addr targetPc(Thread thread) {
			return mbits(thread.npc, 32, 28) | this.target;
		}

		override void execute(Thread thread) {
			this.jump(thread, this.targetPc(thread));
		}
}

class Jal: Jump {
	public:
		this(MachInst machInst) {
			super("jal", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.CALL | StaticInstFlag.DIRJMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.destRegIdx ~= ReturnAddressReg;
		}

		override Addr targetPc(Thread thread) {
			return mbits(thread.npc, 32, 28) | this.target;
		}

		override void execute(Thread thread) {
			thread.intRegs[ReturnAddressReg] = thread.nnpc;
			this.jump(thread, this.targetPc(thread));
		}
}

class Jalr: Jump {
	public:
		this(MachInst machInst) {
			super("jalr", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.CALL | StaticInstFlag.INDIRJMP, FUType.IntALU);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
			this.destRegIdx ~= this[RD];
		}
		
		override Addr targetPc(Thread thread) {
			return thread.intRegs[this[RS]];
		}

		override void execute(Thread thread) {
			thread.intRegs[this[RD]] = thread.nnpc;
			this.jump(thread, this.targetPc(thread));
		}
}

class Jr: Jump {
	public:
		this(MachInst machInst) {
			super("jr", machInst, StaticInstFlag.CTRL | StaticInstFlag.UNCOND | StaticInstFlag.RET | StaticInstFlag.INDIRJMP, FUType.NONE);
		}

		override void setupDeps() {
			this.srcRegIdx ~= this[RS];
		}

		override Addr targetPc(Thread thread) {
			return thread.intRegs[this[RS]];
		}

		override void execute(Thread thread) {
			this.jump(thread, this.targetPc(thread));
		}
}
