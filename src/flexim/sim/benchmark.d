/*
 * flexim/sim/benchmark.d
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

module flexim.sim.benchmark;

import flexim.all;

import std.path;
import std.regexp;

interface PropertiesProvider {
	string[string] properties();
}

class Benchmark : PropertiesProvider {
	this(string title, string cwd, string exe, string argsLiteral, string stdin = null, string stdout = null, uint numThreads = 1) {
		this.title = title;
		this.cwd = cwd;
		this.exe = exe;
		this.argsLiteral = argsLiteral;
		this.stdin = stdin;
		this.stdout = stdout;
		this.numThreads = numThreads;
	}
	
	override string toString() {
		return format("Benchmark[title=%s, cwd=%s, exe=%s, argsLiteral=%s, stdin=%s, stdout=%s, numThreads=%d]",
			this.title, this.cwd, this.exe, this.argsLiteral, this.stdin, this.stdout, this.numThreads);
	}
	
	override string[string] properties() {
		string[string] props;
		
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		props["exe"] = this.exe;
		props["argsLiteral"] = this.argsLiteral;
		props["stdin"] = this.stdin;
		props["stdout"] = this.stdout;
		props["numThreads"] = to!(string)(this.numThreads);
		
		return props;
	}
	
	string title;
	string cwd;
	string exe;
	string argsLiteral;
	string stdin;
	string stdout;
	
	string args() {
		return sub(this.argsLiteral, r"\$\{nthreads\}", format("%d", this.numThreads), "g");
	}
	
	uint numThreads;
	
	BenchmarkSuite suite;
}

class BenchmarkSuite : PropertiesProvider {	
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	void register(Benchmark benchmark) {
		assert(!(benchmark.title in this.benchmarks), format("%s.%s", this.title, benchmark.title));
		benchmark.suite = this;
		this.benchmarks[benchmark.title] = benchmark;
	}
	
	Benchmark opIndex(string index) {
		return this.benchmarks[index];
	}
	
	override string toString() {
		return format("BenchmarkSuite[title=%s, cwd=%s, benchmarks.length=%d]", this.title, this.cwd, this.benchmarks.length);
	}
	
	static BenchmarkSuite loadXML(string cwd, string fileName) {
		return BenchmarkSuiteXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite) {
		saveXML(benchmarkSuite, "../configs/benchmarks", benchmarkSuite.title ~ ".xml");
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite, string cwd, string fileName) {
		BenchmarkSuiteXMLFileSerializer.singleInstance.saveXML(benchmarkSuite, join(cwd, fileName));
	}
	
	override string[string] properties() {
		string[string] props;
		
		props["title"] = this.title;
		props["cwd"] = this.cwd;
		
		return props;
	}
	
	string title;
	string cwd;
	
	Benchmark[string] benchmarks;
}

class BenchmarkSuiteXMLFileSerializer: XMLFileSerializer!(BenchmarkSuite) {
	this() {
	}
	
	override XMLConfigFile save(BenchmarkSuite benchmarkSuite) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("BenchmarkSuite");
		
		xmlConfigFile["title"] = benchmarkSuite.title;
		xmlConfigFile["cwd"] = benchmarkSuite.cwd;
		
		foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
			XMLConfig xmlConfig = new XMLConfig("Benchmark");
			xmlConfig["title"] = benchmark.title;
			xmlConfig["cwd"] = benchmark.cwd;
			xmlConfig["exe"] = benchmark.exe;
			xmlConfig["argsLiteral"] = benchmark.argsLiteral;
			xmlConfig["stdin"] = benchmark.stdin;
			xmlConfig["stdout"] = benchmark.stdout;
			
			xmlConfigFile.entries ~= xmlConfig;
		}
			
		return xmlConfigFile;
	}
	
	override BenchmarkSuite load(XMLConfigFile xmlConfigFile) {
		string bs_title = xmlConfigFile["title"];
		string bs_cwd = xmlConfigFile["cwd"];
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(bs_title, bs_cwd);
		
		foreach(entry; xmlConfigFile.entries) {
			string title = entry["title"];
			string cwd = entry["cwd"];
			string exe = entry["exe"];
			string argsLiteral = entry["argsLiteral"];
			string stdin = entry["stdin"];
			string stdout = entry["stdout"];
			
			Benchmark benchmark = new Benchmark(title, cwd, exe, argsLiteral, stdin, stdout);
			benchmarkSuite.register(benchmark);
		}
		
		return benchmarkSuite;
	}
	
	static this() {
		singleInstance = new BenchmarkSuiteXMLFileSerializer();
	}
	
	static BenchmarkSuiteXMLFileSerializer singleInstance;
}