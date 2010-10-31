/*
 * flexim/io.d
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

module flexim.io;

import flexim.all;

import std.file;
import std.xml;

enum LogCategory: string {
	EVENT_QUEUE = "EVENT_QUEUE",
	SIMULATOR = "SIMULATOR",
	PROCESSOR = "PROCESSOR",
	CORE = "CORE",
	THREAD = "THREAD",
	PROCESS = "PROCESS",
	REGISTER = "REGISTER",
	REQUEST = "REQUEST",
	CACHE = "CACHE",
	COHERENCE = "COHERENCE",
	MEMORY = "MEMORY",
	NET = "NET",
	INSTRUCTION = "INSTRUCTION",
	SYSCALL = "SYSCALL",
	ELF = "ELF",
	CONFIG = "CONFIG",
	STAT = "STAT",
	MISC = "MISC",
	OOO = "OOO",
	TEST = "TEST",
	DEBUG = "DEBUG",
	XML = "XML"
}

class Logger {
	static this() {
		singleInstance = new Logger();
	}
	
	this() {		
			this.enable(LogCategory.SIMULATOR);
		
	//		this.enable(LogCategory.EVENT_QUEUE);
	//		this.enable(LogCategory.PROCESSOR);
	//		this.enable(LogCategory.REGISTER);
			this.enable(LogCategory.REQUEST);
	//		this.enable(LogCategory.CACHE);
			this.enable(LogCategory.COHERENCE);
	//		this.enable(LogCategory.MEMORY);
	//		this.enable(LogCategory.NET);
			this.enable(LogCategory.CONFIG);
			this.enable(LogCategory.STAT);
	//		this.enable(LogCategory.MISC);
	//		this.enable(LogCategory.OOO);
	//		this.enable(LogCategory.TEST);
	//		this.enable(LogCategory.XML);
			this.enable(LogCategory.DEBUG);
	}
	
	void enable(LogCategory category) {
		this.logSwitches[category] = true;
	}

	void disable(LogCategory category) {
		this.logSwitches[category] = false;
	}

	bool enabled(LogCategory category) {
		return category in this.logSwitches && this.logSwitches[category];
	}
	
	string message(string caption, string text) {
		return format("[%d] \t%s%s", currentCycle, caption.endsWith("info") ? "" : "[" ~ caption ~ "] ", text);
	}

	void infof(LogCategory, T...)(LogCategory category, T args) {
		debug {
			this.info(category, format(args));
		}
	}

	void info(LogCategory category, string text) {
		debug {
			if(this.enabled(category)) {
				stdout.writeln(this.message(category ~ "|" ~ "info", text));
			}
		}
	}

	void warnf(LogCategory, T...)(LogCategory category, T args) {
		this.warn(category, format(args));
	}

	void warn(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "warn", text));
	}

	void fatalf(LogCategory, T...)(LogCategory category, T args) {
		this.fatal(category, format(args));
	}

	void fatal(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "fatal", text));
		executeEvent(SimulatorEventType.FATAL, new SimulatorEventContext(this.message(category ~ "|" ~ "fatal", text)));
	}

	void panicf(LogCategory, T...)(LogCategory category, T args) {
		this.panic(category, format(args));
	}

	void panic(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "panic", text));
		executeEvent(SimulatorEventType.PANIC, new SimulatorEventContext(this.message(category ~ "|" ~ "panic", text)));
	}

	void haltf(LogCategory, T...)(LogCategory category, T args) {		
		this.halt(category, format(args));
	}

	void halt(LogCategory category, string text) {
		stderr.writeln(this.message(category ~ "|" ~ "halt", text));
		executeEvent(SimulatorEventType.HALT, new SimulatorEventContext(this.message(category ~ "|" ~ "halt", text)));
	}

	bool[LogCategory] logSwitches;
	
	static Logger singleInstance;
}

alias Logger.singleInstance logging;

class XMLConfig {
	this(string typeName) {
		this.typeName = typeName;
	}
	
	override string toString() {
		return format("%s[attributes.length=%d, entries=[%s]]", 
			this.typeName !is null ? this.typeName : "NULL",
			this.attributes.length,
			this.entries.length > 0 ? reduce!("a ~ b")(map!(to!(string))(this.entries)) : "N/A");
	}
	
	void opIndexAssign(string value, string index) {
		this.attributeKeys ~= index;
		this.attributes[index] = value;
	}
	
	string opIndex(string index) {
		assert(index in this.attributes, format("typeName=%s, index=%s", this.typeName, index));
		return this.attributes[index];
	}

	int opApply(int delegate(ref string, ref string) dg) {
		int result;
		
		foreach(key; this.attributeKeys) {
			string value = this.attributes[key];
			result = dg(key, value);
			if(result)
				break;
		}
		
		return result;
	}

	string typeName;
	
	private string[] attributeKeys;
	private string[string] attributes;
	
	XMLConfig[] entries;
}

class XMLConfigFile: XMLConfig {
	this(string typeName) {
		super(typeName);
	}
}
	
void serialize(XMLConfig entry, Element rootElement) {
	Element element = new Element(entry.typeName);

	rootElement ~= element;
	
	serialize(entry, rootElement, element);
}
	
void serialize(XMLConfig entry, Element rootElement, Element element) {
	foreach(key, value; entry) {
        element.tag.attr[key] = value;
	}
	
	foreach(child; entry.entries) {
		serialize(child, element);
	}
}
	
void serialize(XMLConfigFile config, string xmlFileName) {
	Document doc = new Document(new Tag(config.typeName));

	serialize(config, null, doc);
    
    string contentToWrite = "<?xml version=\"1.0\"?>\n" ~ join(doc.pretty(3),"\n");
    
    std.file.write(xmlFileName, contentToWrite);
}

void deserialize(XMLConfig rootEntry, ElementParser xml) {
	XMLConfig entry = new XMLConfig(xml.tag.name);
	
	foreach(key, value; xml.tag.attr) {
		entry[key] = value;
	}

    xml.onStartTag[null] = (ElementParser xml) {
    	deserialize(entry, xml);
    };

    xml.parse();
    
    rootEntry.entries ~= entry;
}

XMLConfigFile deserialize(string xmlFileName) {
    string s = cast(string) std.file.read(xmlFileName);

    check(s);

	DocumentParser xml = new DocumentParser(s);
    
	XMLConfigFile xmlConfig = new XMLConfigFile(xml.tag.name);
	
	foreach(key, value; xml.tag.attr) {
		xmlConfig[key] = value;
	}

    xml.onStartTag[null] = (ElementParser xml) {
    	deserialize(xmlConfig, xml);
    };
	
    xml.parse();
    
    return xmlConfig;
}

abstract class XMLFileSerializer(ObjectT) {
	abstract XMLConfigFile save(ObjectT config);
	abstract ObjectT load(XMLConfigFile xmlConfigFile);
	
	void saveXML(ObjectT config, string xmlFileName) {
		//logging.infof(LogCategory.XML, "%s.saveXML(%s, %s)", "XMLFileSerializer", config, xmlFileName);
		XMLConfigFile xmlConfigFile = save(config);
		serialize(xmlConfigFile, xmlFileName);
	}
	
	ObjectT loadXML(string xmlFileName, ObjectT defaultValue = null) {
		//logging.infof(LogCategory.XML, "%s.loadXML(%s)", "XMLFileSerializer", xmlFileName);
		if(exists(xmlFileName)) {
			XMLConfigFile xmlConfigFile = deserialize(xmlFileName);
			return load(xmlConfigFile);
		}
		else {
			return defaultValue;
		}
	}
}

abstract class XMLSerializer(ObjectT) {
	abstract XMLConfig save(ObjectT config);
	abstract ObjectT load(XMLConfig xmlConfig);
}