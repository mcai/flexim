/*
 * flexim/io/xml.d
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

module flexim.io.xml;

import flexim.all;

import std.xml;

class XMLConfig {
	this(string typeName) {
		this.typeName = typeName;
	}
		
	static void serialize(XMLConfig entry, Element rootElement) {
		Element element = new Element(entry.typeName);

		rootElement ~= element;
		
		serialize(entry, rootElement, element);
	}
		
	static void serialize(XMLConfig entry, Element rootElement, Element element) {				
		foreach(key, value; entry.attributes) {
	        element.tag.attr[key] = value;
		}
		
		foreach(child; entry.entries) {
			serialize(child, element);
		}
	}
		
	static void serialize(XMLConfig config, string xmlFileName) {
		Document doc = new Document(new Tag(config.typeName));

		serialize(config, null, doc);
	    
	    string contentToWrite = "<?xml version=\"1.0\"?>\n" ~ join(doc.pretty(3),"\n");
	    
	    std.file.write(xmlFileName, contentToWrite);
	}
	
	static void deserialize(XMLConfig rootEntry, ElementParser xml) {
		XMLConfig entry = new XMLConfig(xml.tag.name);
		
		foreach(key, value; xml.tag.attr) {
			entry.attributes[key] = value;
		}

	    xml.onStartTag[null] = (ElementParser xml) {
	    	deserialize(entry, xml);
	    };

        xml.parse();
        
        rootEntry.entries ~= entry;
	}
	
	static XMLConfig deserialize(string xmlFileName) {
	    string s = cast(string) std.file.read(xmlFileName);
	
	    check(s);
	
		DocumentParser xml = new DocumentParser(s);
	    
		XMLConfig xmlConfig = new XMLConfig(xml.tag.name);
		
		foreach(key, value; xml.tag.attr) {
			xmlConfig.attributes[key] = value;
		}

	    xml.onStartTag[null] = (ElementParser xml) {
	    	deserialize(xmlConfig, xml);
	    };

	    xml.onEndTag[null] = (in Element xml) {
	    	//deserialize(xmlConfig, xml);
	    };
		
	    xml.parse();
	    
	    return xmlConfig;
	}
	
	override string toString() {
		return format("%s[attributes.length=%d, entries=[%s]]", 
			this.typeName !is null ? this.typeName : "NULL",
			this.attributes.length,
			this.entries.length > 0 ? reduce!("a ~ b")(map!(to!(string))(this.entries)) : "N/A");
	}

	string typeName;
	string[string] attributes;	
	XMLConfig[] entries;
}

void testXMLConfig() {
	XMLConfig config = new XMLConfig("configs");
	config.attributes["configs_attr1_key"] = "configs_attr1_value";
	
	XMLConfig configEntry = new XMLConfig("config1");
	configEntry.attributes["config1_attr1_key"] = "config1_attr1_value";
	config.entries ~= configEntry;
	
	XMLConfig configEntry2 = new XMLConfig("config1_subconfig1");
	configEntry2.attributes["config1_subconfig1_attr1_key"] = "config1_subconfig1_attr1_value";
	configEntry.entries ~= configEntry2;
	
	string xmlFileName = "config.xml";
	
	writeln("config1: " ~ to!(string)(config));
	
	XMLConfig.serialize(config, xmlFileName);
	
	XMLConfig config2 = XMLConfig.deserialize(xmlFileName);
	
	writeln("config2: " ~ to!(string)(config2));
	
	XMLConfig.serialize(config2, "config2.xml");
}