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