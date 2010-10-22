/*
 * flexim/ise/specifications.d
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

module flexim.ise.specifications;

import flexim.all;

abstract class ArchitecturalSpecification {
	this() {
		this.drawableObjectId = "";
	}
	
	abstract string label();
	abstract string backColor();
	abstract bool isCycleAccurate();
	abstract void realize();
	
	abstract XMLConfig save();
	
	string id;
	string drawableObjectId;
	Canvas canvas;
	
	static this() {
		currentId = 0;
	}
	
	static int currentId;
}

class ProcessorCoreSpecification: ArchitecturalSpecification {
	this() {
	}
}

class SimpleProcessorCoreSpecification: ProcessorCoreSpecification {
	this() {
		this.id = format("simpleProcessorCore%d", currentId++);
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
	
	override XMLConfig save() {
		return SimpleProcessorCoreSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class SimpleProcessorCoreSpecificationXMLSerializer: XMLSerializer!(SimpleProcessorCoreSpecification) {
	this() {
	}
	
	override XMLConfig save(SimpleProcessorCoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("SimpleProcessorCoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override SimpleProcessorCoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		SimpleProcessorCoreSpecification specification = new SimpleProcessorCoreSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new SimpleProcessorCoreSpecificationXMLSerializer();
	}
	
	static SimpleProcessorCoreSpecificationXMLSerializer singleInstance;	
}

class OoOProcessorCoreSpecification : ProcessorCoreSpecification {
	this() {
		this.id = format("ooOProcessorCore%d", currentId++);
		
		this.iCacheId = "";
		this.dCacheId = "";
	}
	
	this(string id) {
		this.id = id;
		
		this.iCacheId = "";
		this.dCacheId = "";
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
		assert(this.iCache !is null);
		assert(this.dCache !is null);
	}
	
	override XMLConfig save() {
		return OoOProcessorCoreSpecificationXMLSerializer.singleInstance.save(this);
	}
	
	ICacheSpecification iCache() {
		if(this.canvas !is null && this.iCacheId != "") {
			return cast(ICacheSpecification)(this.canvas.getSpecification(this.iCacheId));
		}
		
		return null;
	}
	
	DCacheSpecification dCache() {
		if(this.canvas !is null && this.dCacheId != "") {
			return cast(DCacheSpecification)(this.canvas.getSpecification(this.dCacheId));
		}
		
		return null;
	}
	
	string iCacheId;
	string dCacheId;
}

class OoOProcessorCoreSpecificationXMLSerializer: XMLSerializer!(OoOProcessorCoreSpecification) {
	this() {
	}
	
	override XMLConfig save(OoOProcessorCoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("OoOProcessorCoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		xmlConfig["iCacheId"] = specification.iCacheId;
		xmlConfig["dCacheId"] = specification.dCacheId;
		
		return xmlConfig;
	}
	
	override OoOProcessorCoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		string iCacheId = xmlConfig["iCacheId"];
		string dCacheId = xmlConfig["dCacheId"];
		
		OoOProcessorCoreSpecification specification = new OoOProcessorCoreSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		specification.iCacheId = iCacheId;
		specification.dCacheId = dCacheId;
		
		return specification;
	}
	
	static this() {
		singleInstance = new OoOProcessorCoreSpecificationXMLSerializer();
	}
	
	static OoOProcessorCoreSpecificationXMLSerializer singleInstance;
}

abstract class CacheSpecification : ArchitecturalSpecification {
	this() {
	}
}

class ICacheSpecification : CacheSpecification {
	this() {
		this.id = format("iCache%d", currentId++);
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
	
	override XMLConfig save() {
		return ICacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class ICacheSpecificationXMLSerializer: XMLSerializer!(ICacheSpecification) {
	this() {
	}
	
	override XMLConfig save(ICacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("ICacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override ICacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		ICacheSpecification specification = new ICacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new ICacheSpecificationXMLSerializer();
	}
	
	static ICacheSpecificationXMLSerializer singleInstance;
}

class DCacheSpecification : CacheSpecification {
	this() {
		this.id = format("dCache%d", currentId++);
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
	
	override XMLConfig save() {
		return DCacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class DCacheSpecificationXMLSerializer: XMLSerializer!(DCacheSpecification) {
	this() {
	}
	
	override XMLConfig save(DCacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("DCacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override DCacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		DCacheSpecification specification = new DCacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new DCacheSpecificationXMLSerializer();
	}
	
	static DCacheSpecificationXMLSerializer singleInstance;
}

class L2CacheSpecification : CacheSpecification {
	this() {
		this.id = format("l2Cache%d", currentId++);
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
	
	override XMLConfig save() {
		return L2CacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class L2CacheSpecificationXMLSerializer: XMLSerializer!(L2CacheSpecification) {
	this() {
	}
	
	override XMLConfig save(L2CacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("L2CacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override L2CacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		L2CacheSpecification specification = new L2CacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new L2CacheSpecificationXMLSerializer();
	}
	
	static L2CacheSpecificationXMLSerializer singleInstance;
}

abstract class InterconnectSpecification : ArchitecturalSpecification {
	this() {
	}
}

abstract class P2PInterconnectSpecification : InterconnectSpecification {
	this() {
	}
}

class FixedLatencyP2PInterconnectSpecification : P2PInterconnectSpecification {
	this() {
		this.id = format("fixedLatencyP2PInterconnect%d", currentId++);
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
	
	override XMLConfig save() {
		return FixedLatencyP2PInterconnectSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class FixedLatencyP2PInterconnectSpecificationXMLSerializer: XMLSerializer!(FixedLatencyP2PInterconnectSpecification) {
	this() {
	}
	
	override XMLConfig save(FixedLatencyP2PInterconnectSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyP2PInterconnectSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override FixedLatencyP2PInterconnectSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		FixedLatencyP2PInterconnectSpecification specification = new FixedLatencyP2PInterconnectSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new FixedLatencyP2PInterconnectSpecificationXMLSerializer();
	}
	
	static FixedLatencyP2PInterconnectSpecificationXMLSerializer singleInstance;
}

abstract class MainMemorySpecification : ArchitecturalSpecification {
	this() {
	}
}

class FixedLatencyDRAMSpecification : MainMemorySpecification {
	this() {
		this.id = format("fixedLatencyDRAM%d", currentId++);
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
	
	override XMLConfig save() {
		return FixedLatencyDRAMSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class FixedLatencyDRAMSpecificationXMLSerializer: XMLSerializer!(FixedLatencyDRAMSpecification) {
	this() {		
	}
	
	override XMLConfig save(FixedLatencyDRAMSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyDRAMSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override FixedLatencyDRAMSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		FixedLatencyDRAMSpecification specification = new FixedLatencyDRAMSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new FixedLatencyDRAMSpecificationXMLSerializer();
	}
	
	static FixedLatencyDRAMSpecificationXMLSerializer singleInstance;
}

abstract class ArchitectureArchitecturalSpecification : ArchitecturalSpecification {
	this() {
	}
}

class SharedCacheMulticoreSpecification: ArchitectureArchitecturalSpecification {
	this() {
		this.id = format("sharedCacheMulticore%d", currentId++);
		
		this.coreIds[0] = "";
		this.coreIds[1] = "";
		
		this.l2CacheId = "";
		this.interconnectId = "";
		this.mainMemoryId = "";
	}
	
	this(string id) {
		this.id = id;
		
		this.coreIds[0] = "";
		this.coreIds[1] = "";
		
		this.l2CacheId = "";
		this.interconnectId = "";
		this.mainMemoryId = "";
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
		assert(this.coreIds.length == 2);
		assert(this.l2Cache !is null);
		assert(this.interconnect !is null);
		assert(this.mainMemory !is null);
	}
	
	override XMLConfig save() {
		return SharedCacheMulticoreSpecificationXMLFileSerializer.singleInstance.save(this);
	}
	
	OoOProcessorCoreSpecification getCore(string coreId) {
		if(this.canvas !is null && coreId != "") {
			return cast(OoOProcessorCoreSpecification)(this.canvas.getSpecification(coreId));
		}
		
		return null;
	}
	
	OoOProcessorCoreSpecification getCore(int coreNum) {
		assert(coreNum >= 0 && coreNum < this.coreIds.length);
		
		return this.getCore(this.coreIds[coreNum]);
	}
	
	string[int] coreIds;
	
	L2CacheSpecification l2Cache() {
		if(this.canvas !is null && this.l2CacheId != "") {
			return cast(L2CacheSpecification)(this.canvas.getSpecification(this.l2CacheId));
		}
		
		return null;
	}
	
	FixedLatencyP2PInterconnectSpecification interconnect() {
		if(this.canvas !is null && this.interconnectId != "") {
			return cast(FixedLatencyP2PInterconnectSpecification)(this.canvas.getSpecification(this.interconnectId));
		}
		
		return null;
	}
	
	FixedLatencyDRAMSpecification mainMemory() {
		if(this.canvas !is null && this.mainMemoryId != "") {
			return cast(FixedLatencyDRAMSpecification)(this.canvas.getSpecification(this.mainMemoryId));
		}
		
		return null;
	}
	
	string l2CacheId;
	string interconnectId;
	string mainMemoryId;
}

class SharedCacheMulticoreSpecificationXMLFileSerializer: XMLSerializer!(SharedCacheMulticoreSpecification) {
	this() {		
	}
	
	override XMLConfig save(SharedCacheMulticoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("SharedCacheMulticoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["numCores"] = to!(string)(specification.coreIds.length);
				
		foreach(i, coreId; specification.coreIds) {
			xmlConfig[format("coreId%d", i)] = coreId;
		}
		
		xmlConfig["l2CacheId"] = specification.l2CacheId;
		xmlConfig["interconnectId"] = specification.interconnectId;
		xmlConfig["mainMemoryId"] = specification.mainMemoryId;
		
		return xmlConfig;
	}
	
	override SharedCacheMulticoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string l2CacheId = xmlConfig["l2CacheId"];
		string interconnectId = xmlConfig["interconnectId"];
		string mainMemoryId = xmlConfig["mainMemoryId"];
		int numCores = to!(int)(xmlConfig["numCores"]);
		
		SharedCacheMulticoreSpecification specification = new SharedCacheMulticoreSpecification(id);
			
		for(int i = 0; i < numCores; i++) {
			specification.coreIds[i] = xmlConfig[format("coreId%d", i)];
		}
		
		specification.l2CacheId = l2CacheId;
		specification.interconnectId = interconnectId;
		specification.mainMemoryId = mainMemoryId;
		
		return specification;
	}
	
	static this() {
		singleInstance = new SharedCacheMulticoreSpecificationXMLFileSerializer();
	}
	
	static SharedCacheMulticoreSpecificationXMLFileSerializer singleInstance;
}