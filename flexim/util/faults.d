/*
 * flexim/util/faults.d
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

module flexim.util.faults;

import flexim.all;

class Fault {
	public:
		abstract string getName();

		void invoke(Thread thread) {
			logging[LogCategory.INSTRUCTION].panicf("fault (%s) detected @ PC %p", this.getName(), thread.pc);
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
			logging[LogCategory.INSTRUCTION].panicf("UnimplFault (%s)\n", this.panicStr);
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
			logging[LogCategory.INSTRUCTION].panicf("ReservedInstructionFault (%s)\n", this.getName());
		}
}