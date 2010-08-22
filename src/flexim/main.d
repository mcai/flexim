/*
 * flexim/main.d
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
 
module flexim.main;

import flexim.all;

import std.file;
import std.getopt;
import std.path;

void performAnalysis(string title, string cwd, string binariesDir, string benchmarkSuiteName, string benchmarkTitle, uint numCores, uint numThreads, AnalysisType analysisType) {
	Benchmark benchmark = BenchmarkSuite.presets[benchmarkSuiteName][benchmarkTitle];
	performAnalysis(title, cwd, binariesDir, benchmark, numCores, numThreads, analysisType);
}

void performAnalysis(string title, string cwd, string binariesDir, Benchmark benchmark, uint numCores, uint numThreads, AnalysisType analysisType) {
	logging.infof(LogCategory.SIMULATOR, "peformAnalysis(title=%s, cwd=%s, binariesDir=%s, benchmark=%s, numCores=%d, numThreads=%d, analysisType=%s)",
		title, cwd, binariesDir, benchmark, numCores, numThreads, analysisType);
	Experiment experiment = Experiment.createDefault(title, cwd, binariesDir, benchmark, numCores, numThreads);
	experiment.execute();
}

void main(string[] args) {
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (c) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");

	string title = "testExp";
	string cwd = "./";
	
	string binariesDir = "../tests/benchmarks";
	
	string benchmarkSuiteName = BenchmarkSuite.OldenCustom1.TITLE;
	
	uint numCores = 1;
	uint numThreads = 2;
	
	getopt(args, "title", &title, "cwd", &cwd, "binariesDir", &binariesDir, "benchmarkSuiteName", &benchmarkSuiteName,
		"numCores", &numCores, "numThreads", &numThreads);
		
	foreach(benchmarkSuiteName, benchmarkSuite; BenchmarkSuite.presets) {
		BenchmarkSuite.saveXML(benchmarkSuite, "../configs/benchmarks", benchmarkSuite.title ~ ".xml");
	}
	
	BenchmarkSuite benchmarkSuite = BenchmarkSuite.presets[benchmarkSuiteName];
	
	foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
		performAnalysis(title, cwd, binariesDir, benchmark, numCores, numThreads, AnalysisType.GENERAL);
	}
}
