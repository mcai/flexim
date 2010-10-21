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
	}
	
	abstract string label();
	abstract string backColor();
	abstract bool isCycleAccurate();
	abstract void realize();
	
	string id;
	
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
		this.id = format("simpleProcessorCoreBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class SimpleProcessorCoreBlueprintXMLSerializer: XMLSerializer!(SimpleProcessorCoreBlueprint) {
	this() {
	}
	
	override XMLConfig save(SimpleProcessorCoreBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("SimpleProcessorCoreBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override SimpleProcessorCoreBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		SimpleProcessorCoreBlueprint blueprint = new SimpleProcessorCoreBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new SimpleProcessorCoreBlueprintXMLSerializer();
	}
	
	static SimpleProcessorCoreBlueprintXMLSerializer singleInstance;	
}

class OoOProcessorCoreBlueprint : ProcessorCoreBlueprint {
	this() {
		this.id = format("ooOProcessorCoreBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class OoOProcessorCoreBlueprintXMLSerializer: XMLSerializer!(OoOProcessorCoreBlueprint) {
	this() {
	}
	
	override XMLConfig save(OoOProcessorCoreBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("OoOProcessorCoreBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		xmlConfig.entries ~= ICacheBlueprintXMLSerializer.singleInstance.save(blueprint.icache);
		xmlConfig.entries ~= DCacheBlueprintXMLSerializer.singleInstance.save(blueprint.dcache);
		
		return xmlConfig;
	}
	
	override OoOProcessorCoreBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		OoOProcessorCoreBlueprint blueprint = new OoOProcessorCoreBlueprint(id);
		
		blueprint.icache = ICacheBlueprintXMLSerializer.singleInstance.load(xmlConfig.entries[0]);
		blueprint.dcache = DCacheBlueprintXMLSerializer.singleInstance.load(xmlConfig.entries[1]);
		
		return blueprint;
	}
	
	static this() {
		singleInstance = new OoOProcessorCoreBlueprintXMLSerializer();
	}
	
	static OoOProcessorCoreBlueprintXMLSerializer singleInstance;
}

abstract class CacheBlueprint : Blueprint {
	this() {
	}
}

class ICacheBlueprint : CacheBlueprint {
	this() {
		this.id = format("iCacheBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class ICacheBlueprintXMLSerializer: XMLSerializer!(ICacheBlueprint) {
	this() {
	}
	
	override XMLConfig save(ICacheBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("ICacheBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override ICacheBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		ICacheBlueprint blueprint = new ICacheBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new ICacheBlueprintXMLSerializer();
	}
	
	static ICacheBlueprintXMLSerializer singleInstance;
}

class DCacheBlueprint : CacheBlueprint {
	this() {
		this.id = format("dCacheBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class DCacheBlueprintXMLSerializer: XMLSerializer!(DCacheBlueprint) {
	this() {
	}
	
	override XMLConfig save(DCacheBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("DCacheBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override DCacheBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		DCacheBlueprint blueprint = new DCacheBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new DCacheBlueprintXMLSerializer();
	}
	
	static DCacheBlueprintXMLSerializer singleInstance;
}

class L2CacheBlueprint : CacheBlueprint {
	this() {
		this.id = format("l2CacheBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class L2CacheBlueprintXMLSerializer: XMLSerializer!(L2CacheBlueprint) {
	this() {
	}
	
	override XMLConfig save(L2CacheBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("L2CacheBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override L2CacheBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		L2CacheBlueprint blueprint = new L2CacheBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new L2CacheBlueprintXMLSerializer();
	}
	
	static L2CacheBlueprintXMLSerializer singleInstance;
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
		this.id = format("fixedLatencyP2PInterconnectBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class FixedLatencyP2PInterconnectBlueprintXMLSerializer: XMLSerializer!(FixedLatencyP2PInterconnectBlueprint) {
	this() {
	}
	
	override XMLConfig save(FixedLatencyP2PInterconnectBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyP2PInterconnectBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override FixedLatencyP2PInterconnectBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		FixedLatencyP2PInterconnectBlueprint blueprint = new FixedLatencyP2PInterconnectBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new FixedLatencyP2PInterconnectBlueprintXMLSerializer();
	}
	
	static FixedLatencyP2PInterconnectBlueprintXMLSerializer singleInstance;
}

abstract class MainMemoryBlueprint : Blueprint {
	this() {
	}
}

class FixedLatencyDRAMBlueprint : MainMemoryBlueprint {
	this() {
		this.id = format("fixedLatencyDRAMBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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

class FixedLatencyDRAMBlueprintXMLSerializer: XMLSerializer!(FixedLatencyDRAMBlueprint) {
	this() {		
	}
	
	override XMLConfig save(FixedLatencyDRAMBlueprint blueprint) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyDRAMBlueprint");
		xmlConfig["id"] = blueprint.id;
		
		return xmlConfig;
	}
	
	override FixedLatencyDRAMBlueprint load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		
		FixedLatencyDRAMBlueprint blueprint = new FixedLatencyDRAMBlueprint(id);
		return blueprint;
	}
	
	static this() {
		singleInstance = new FixedLatencyDRAMBlueprintXMLSerializer();
	}
	
	static FixedLatencyDRAMBlueprintXMLSerializer singleInstance;
}

abstract class ArchitectureBlueprint : Blueprint {
	this() {
		
	}
}

class SharedCacheMulticoreBlueprint: ArchitectureBlueprint {
	this() {
		this.id = format("sharedCacheMulticoreBlueprint%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
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
	FixedLatencyP2PInterconnectBlueprint interconnect;
	FixedLatencyDRAMBlueprint mainMemory;
}

class SharedCacheMulticoreBlueprintXMLFileSerializer: XMLFileSerializer!(SharedCacheMulticoreBlueprint) {
	this() {		
	}
	
	override XMLConfigFile save(SharedCacheMulticoreBlueprint blueprint) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("SharedCacheMulticoreBlueprint");
		
		foreach(core; blueprint.cores) {
			xmlConfigFile.entries ~= OoOProcessorCoreBlueprintXMLSerializer.singleInstance.save(core);
		}

		xmlConfigFile.entries ~= L2CacheBlueprintXMLSerializer.singleInstance.save(blueprint.l2);
		xmlConfigFile.entries ~= FixedLatencyP2PInterconnectBlueprintXMLSerializer.singleInstance.save(blueprint.interconnect);
		xmlConfigFile.entries ~= FixedLatencyDRAMBlueprintXMLSerializer.singleInstance.save(blueprint.mainMemory);
		
		return xmlConfigFile;
	}
	
	override SharedCacheMulticoreBlueprint load(XMLConfigFile xmlConfigFile) {
		string id = xmlConfigFile["id"];
		
		SharedCacheMulticoreBlueprint blueprint = new SharedCacheMulticoreBlueprint(id);
		
		foreach(entry; xmlConfigFile.entries) {
			string typeName = entry.typeName;
			
			if(typeName == "OoOProcessorCoreBlueprint") {
				blueprint.cores ~= OoOProcessorCoreBlueprintXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "L2CacheBlueprint") {
				blueprint.l2 = L2CacheBlueprintXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyP2PInterconnectBlueprint") {
				blueprint.interconnect = FixedLatencyP2PInterconnectBlueprintXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyDRAMBlueprint") {
				blueprint.mainMemory = FixedLatencyDRAMBlueprintXMLSerializer.singleInstance.load(entry);
			}
		}
		
		return blueprint;
	}
	
	static this() {
		singleInstance = new SharedCacheMulticoreBlueprintXMLFileSerializer();
	}
	
	static SharedCacheMulticoreBlueprintXMLFileSerializer singleInstance;
}