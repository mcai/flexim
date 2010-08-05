/*
 * flexim/cpu/thread.d
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

module flexim.cpu.thread;

import flexim.all;

uint current_thread_id = 0;

enum ThreadStatus {
	Active,
	Suspended,
	Halted
}

class Thread {
	this(string name, Process process) {
		this.id = current_thread_id++;
		
		this.name = name;
		this.process = process;

		this.mem = new Memory();
		
		this.isa = new MipsISA();
		
		this.syscallEmul = new SyscallEmul();

		this.bpred = new CombinedBpred();

		this.clearArchRegs();

		this.process.load(this);
	}

	IntReg getSyscallArg(ref int i) {
		assert(i < 6);
		return this.intRegs[FirstArgumentReg + i++];
	}

	void setSyscallArg(int i, IntReg val) {
		assert(i < 6);
		this.intRegs[FirstArgumentReg + i] = val;
	}

	void setSyscallReturn(SyscallReturn return_value) {
		this.intRegs[ReturnValueReg] = return_value;
		this.intRegs[SyscallSuccessReg] = return_value == cast(IntReg) -EINVAL ? 1 : 0;
	}

	void syscall(uint callnum) {
		this.syscallEmul.syscall(callnum, this);
	}

	void clearArchRegs() {
		this.pc = 0;
		this.npc = 0;
		this.nnpc = 0;
		
		this.intRegs = new IntRegisterFile();
		this.floatRegs = new FloatRegisterFile();
	}

	void dumpConfigs(string indent) {
		logging[LogCategory.CONFIG].infof(indent ~ "[Thread %s]", this.name);

		this.l1I.dumpConfigs(indent ~ "  ");
		this.l1D.dumpConfigs(indent ~ "  ");
	}

	void dumpStats(string indent) {
		logging[LogCategory.STAT].infof(indent ~ "[Thread %s] total instructions: %d", this.name, this.totalInsts);

		this.l1I.dumpStats(indent ~ "  ");
		this.l1D.dumpStats(indent ~ "  ");
	}

	void run() {
		this.pc = this.npc;
		this.npc = this.nnpc;
		this.nnpc += Addr.sizeof;

		MachInst machInst;

		this.mem.readWord(this.pc, &machInst.data);

		StaticInst staticInst = this.isa.decode(machInst);

		assert(staticInst !is null, format("failed to decode machine instructon 0x%08x", machInst.data));

		DynamicInst uop = new DynamicInst(this, this.pc, staticInst);
		uop.execute();

		if(uop.isControl) {
			BpredUpdate dirUpdate = new BpredUpdate();

			Addr predPc = this.bpred.lookup(this.pc, 0, uop, dirUpdate, this.stackRecoverIdx);

			if(predPc < 2) {
				predPc = this.pc + Addr.sizeof;
			}

			this.bpred.update(this.pc, this.npc, this.npc != (this.pc + Addr.sizeof), predPc != (this.pc + Addr.sizeof), predPc == this.npc, uop, dirUpdate);
		}
	}
	
	uint id;

	Sequencer!(CPURequest, MOESICache) seqI() {
		return this.core.processor.simulator.memorySystem.seqIs[this.id];
	}
	
	MOESICache l1I() {
		return this.core.processor.simulator.memorySystem.l1Is[this.id];
	}

	Sequencer!(CPURequest, MOESICache) seqD() {
		return this.core.processor.simulator.memorySystem.seqDs[this.id];
	}
	
	MOESICache l1D() {
		return this.core.processor.simulator.memorySystem.l1Ds[this.id];
	}

	string name;

	Process process;
	Memory mem;
	SyscallEmul syscallEmul;

	ThreadStatus status;

	Addr pc;
	Addr npc;
	Addr nnpc;

	Core core;
	
	ISA isa;
	
	IntRegisterFile intRegs;
	FloatRegisterFile floatRegs;

	ulong totalInsts;

	Bpred bpred;

	uint stackRecoverIdx;
}
