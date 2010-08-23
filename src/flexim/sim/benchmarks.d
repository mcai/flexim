/*
 * flexim/sim/benchmarks.d
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

module flexim.sim.benchmarks;

import flexim.all;

import std.path;
import std.regexp;

class Benchmark {
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

class BenchmarkSuiteXMLSerializer: XMLSerializer!(BenchmarkSuite) {
	this() {
	}
	
	override XMLConfigFile save(BenchmarkSuite benchmarkSuite) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("BenchmarkSuite");
		
		xmlConfigFile.attributes["title"] = benchmarkSuite.title;
		xmlConfigFile.attributes["cwd"] = benchmarkSuite.cwd;
		
		foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
			XMLConfig xmlConfig = new XMLConfig("Benchmark");
			xmlConfig.attributes["title"] = benchmark.title;
			xmlConfig.attributes["cwd"] = benchmark.cwd;
			xmlConfig.attributes["exe"] = benchmark.exe;
			xmlConfig.attributes["argsLiteral"] = benchmark.argsLiteral;
			xmlConfig.attributes["stdin"] = benchmark.stdin;
			xmlConfig.attributes["stdout"] = benchmark.stdout;
			
			xmlConfigFile.entries ~= xmlConfig;
		}
			
		return xmlConfigFile;
	}
	
	override BenchmarkSuite load(XMLConfigFile xmlConfigFile) {
		string bs_title = xmlConfigFile.attributes["title"];
		string bs_cwd = xmlConfigFile.attributes["cwd"];
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(bs_title, bs_cwd);
		
		foreach(entry; xmlConfigFile.entries) {
			string title = entry.attributes["title"];
			string cwd = entry.attributes["cwd"];
			string exe = entry.attributes["exe"];
			string argsLiteral = entry.attributes["argsLiteral"];
			string stdin = entry.attributes["stdin"];
			string stdout = entry.attributes["stdout"];
			
			Benchmark benchmark = new Benchmark(title, cwd, exe, argsLiteral, stdin, stdout);
			benchmarkSuite.register(benchmark);
		}
		
		return benchmarkSuite;
	}
	
	static this() {
		singleInstance = new BenchmarkSuiteXMLSerializer();
	}
	
	static BenchmarkSuiteXMLSerializer singleInstance;
}

class BenchmarkSuite {	
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	void register(Benchmark benchmark) {
		assert(!(benchmark.title in this.benchmarks));
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
		return BenchmarkSuiteXMLSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite) {
		saveXML(benchmarkSuite, "../configs/benchmarks", benchmarkSuite.title ~ ".xml");
	}
	
	static void saveXML(BenchmarkSuite benchmarkSuite, string cwd, string fileName) {
		BenchmarkSuiteXMLSerializer.singleInstance.saveXML(benchmarkSuite, join(cwd, fileName));
	}
	
	string title;
	string cwd;
	
	Benchmark[string] benchmarks;
}