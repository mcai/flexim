/*
 * flexim/sim/analysis.d
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

module flexim.sim.analysis;

import flexim.all;

abstract class Stats(ValueT) {	
	this() {
		this.init();
	}

	protected abstract void init();

	protected abstract void init(string index);

	ref ValueT opIndex(string index) {
		assert(index in this.entries, index);
		return this.entries[index];
	}

	void opIndexAssign(ValueT value, string index) {
		assert(index in this.entries, index);
		this.entries[index] = value;
	}

	ValueT[string] entries;
}

enum AnalysisType: string {
	GENERAL = "GENERAL",
	PIPELINE = "PIPELINE",
	CACHE = "CACHE"
}

abstract class BenchmarkAnalysis(ResultT) {
	alias ContextCallback1!(ResultT) CallbackT;
	
	this(Benchmark benchmark, CallbackT callback) {
		this.benchmark = benchmark;
		this.callback = callback;
	}
	
	void complete() {
		if(this.callback !is null) {
			this.callback.invoke(this.result);
		}
	}
	
	abstract AnalysisType type();
	
	Benchmark benchmark;
	CallbackT callback;
	ResultT result;
}

class GeneralAnalysisResult {
	
}

class GeneralAnalysis: BenchmarkAnalysis!(GeneralAnalysisResult) {
	this(Benchmark benchmark, CallbackT callback) {
		super(benchmark, callback);
	}
	
	override AnalysisType type() {
		return AnalysisType.GENERAL;
	}
}

class PipelineAnalysisResult {
	
}

class PipelineAnalysis: BenchmarkAnalysis!(PipelineAnalysisResult) {
	this(Benchmark benchmark, CallbackT callback) {
		super(benchmark, callback);
	}
	
	override AnalysisType type() {
		return AnalysisType.PIPELINE;
	}
}

class CacheAnalysisResult {
	
}

class CacheAnalysis: BenchmarkAnalysis!(CacheAnalysisResult) {
	this(Benchmark benchmark, CallbackT callback) {
		super(benchmark, callback);
	}
	
	override AnalysisType type() {
		return AnalysisType.CACHE;
	}
}