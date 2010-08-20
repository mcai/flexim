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

enum AnalysisType: string {
	GENERAL = "GENERAL",
	PIPELINE = "PIPELINE",
	CACHE = "CACHE"
}

interface Analysis(ResultT) {
	alias ContextCallback1!(ResultT) CallbackT;
	
	void execute(CallbackT callback);
	
	AnalysisType type();
}

class GeneralAnalysisResult {
	
}

class GeneralAnalysis: Analysis!(GeneralAnalysisResult) {
	this(Benchmark benchmark) {
		this.benchmark = benchmark;
	}
	
	override void execute(CallbackT callback) {
		callback.invoke(new GeneralAnalysisResult());
	}
	
	override AnalysisType type() {
		return AnalysisType.GENERAL;
	}
	
	Benchmark benchmark;
}

class PipelineAnalysisResult {
	
}

class PipelineAnalysis: Analysis!(PipelineAnalysisResult) {
	override void execute(CallbackT callback) {
		callback.invoke(new PipelineAnalysisResult());
	}
	
	override AnalysisType type() {
		return AnalysisType.PIPELINE;
	}
}

class CacheAnalysisResult {
	
}

class CacheAnalysis: Analysis!(CacheAnalysisResult) {
	override void execute(CallbackT callback) {
		callback.invoke(new CacheAnalysisResult());
	}
	
	override AnalysisType type() {
		return AnalysisType.CACHE;
	}
}














