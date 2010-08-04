module flexim.cpu.processor;

import flexim.all;

class Processor {
	public:
		this(CPUSimulator simulator) {
			this(simulator, "");
		}

		this(CPUSimulator simulator, string name) {
			this.simulator = simulator;
			this.name = name;
		}

		Core core(string name) {
			if(name in this.cores) {
				return this.cores[name];
			}

			return null;
		}

		void addCore(Core core) {
			this.cores[core.name] = core;
			this.cores[core.name].processor = this;
		}

		void removeCore(Core core) {
			if(core.name in this.cores) {
				this.cores[core.name].processor = null;
				this.cores.remove(core.name);
			}
		}
		
		void dumpConfigs(string indent) {
			logging[LogCategory.CONFIG].info(indent ~ "[Processor]");
			foreach(core; this.cores) {
				core.dumpConfigs(indent ~ "  ");
			}
		}
		
		void dumpStats(string indent) {
			logging[LogCategory.STAT].info(indent ~ "[Processor]");
			foreach(core; this.cores) {
				core.dumpStats(indent ~ "  ");
			}
		}

		void run() {			
			foreach(core; this.cores) {
				core.run();
			}
		}

		CPUSimulator simulator;
		string name;
		Core[string] cores;
}