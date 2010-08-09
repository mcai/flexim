/*
 * flexim/cpu/processor.d
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
			logging.info(LogCategory.CONFIG, indent ~ "[Processor]");
			foreach(core; this.cores) {
				core.dumpConfigs(indent ~ "  ");
			}
		}
		
		void dumpStats(string indent) {
			logging.info(LogCategory.STAT, indent ~ "[Processor]");
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