/*
 * flexim/ise/blueprints.d
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

module flexim.ise.blueprints;

import flexim.all;

abstract class Blueprint {
	this() {
		this.id = currentId++;
	}
	
	abstract string label();
	abstract string backColor();
	abstract bool isCycleAccurate();
	abstract void realize();
	
	int id;
	
	static this() {
		currentId = 0;
	}
	
	static int currentId;
}

class ProcessorCoreBlueprint: Blueprint {
	this() {
	}
}

class SimpleProcessorCoreBlueprint: ProcessorCoreBlueprint {
	this() {
	}
	
	override string label() {
		return "Simple (Functional) Processor Core";
	}
	
	override string backColor() {
		return "red";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
}

class OoOProcessorCoreBlueprint : ProcessorCoreBlueprint {
	this() {
	}
	
	override string label() {
		return "Out-of-Order Processor Core";
	}
	
	override string backColor() {
		return "red";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
		assert(this.icache !is null);
		assert(this.dcache !is null);
	}
	
	ICacheBlueprint icache;
	DCacheBlueprint dcache;
}

abstract class CacheBlueprint : Blueprint {
	this() {
	}
}

class ICacheBlueprint : CacheBlueprint {
	this() {
	}
	
	override string label() {
		return "Inst Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
}

class DCacheBlueprint : CacheBlueprint {
	this() {
	}
	
	override string label() {
		return "Data Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
}

class L2CacheBlueprint : CacheBlueprint {
	this() {
	}
	
	override string label() {
		return "L2 Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
}

abstract class InterconnectBlueprint : Blueprint {
	this() {
	}
}

abstract class P2PInterconnectBlueprint : InterconnectBlueprint {
	this() {
	}
}

class FixedLatencyP2PInterconnectBlueprint : P2PInterconnectBlueprint {
	this() {
	}
	
	override string label() {
		return "Fixed-Latency P2P Interconnect";
	}
	
	override string backColor() {
		return "blue";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
}

abstract class MainMemoryBlueprint : Blueprint {
	this() {
	}
}

class FixedLatencyDRAMBlueprint : MainMemoryBlueprint {
	this() {
	}
	
	override string label() {
		return "Fixed-Latency DRAM Controller";
	}
	
	override string backColor() {
		return "brown";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
}

abstract class ArchitectureBlueprint : Blueprint {
	this() {
		
	}
}

class SharedCacheMulticoreBlueprint: ArchitectureBlueprint {
	this() {
		
	}
	
	override string label() {
		return "Shared Cache Multicore";
	}
	
	override string backColor() {
		return "default";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
		assert(this.cores.length == 2);
		assert(this.l2 !is null);
		assert(this.interconnect !is null);
		assert(this.mainMemory !is null);
	}
	
	OoOProcessorCoreBlueprint[] cores;
	L2CacheBlueprint l2;
	P2PInterconnectBlueprint interconnect;
	MainMemoryBlueprint mainMemory;
}