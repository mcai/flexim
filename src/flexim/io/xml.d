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

import std.file;
import std.xml;

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

	string typeName;
	string[string] attributes;	
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
	foreach(key, value; entry.attributes) {
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
		entry.attributes[key] = value;
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
		xmlConfig.attributes[key] = value;
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
		logging.infof(LogCategory.XML, "%s.saveXML(%s, %s)", "XMLFileSerializer", config, xmlFileName);
		XMLConfigFile xmlConfigFile = save(config);
		serialize(xmlConfigFile, xmlFileName);
	}
	
	ObjectT loadXML(string xmlFileName, ObjectT defaultValue = null) {
		logging.infof(LogCategory.XML, "%s.loadXML(%s)", "XMLFileSerializer", xmlFileName);
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