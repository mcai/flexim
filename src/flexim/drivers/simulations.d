/*
 * flexim/drivers/simulations.d
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

module flexim.drivers.simulations;

import flexim.all;

interface Reproducible {
	void beforeRun();
	void run();
	void afterRun();
}

class Simulation: Reproducible {
	this(string title, string cwd, CPUConfig cpuConfig, CacheConfig cacheConfig, ContextConfig contextConfig) {
		this.title = title;
		this.cwd = cwd;
		this.cpuConfig = cpuConfig;
		this.cacheConfig = cacheConfig;
		this.contextConfig = contextConfig;
	}
	
	override void beforeRun() {
		//TODO
	}
	
	override void run() {
		//TODO
	}
	
	override void afterRun() {
		//TODO
	}
	
	string title;
	string cwd;
	CPUConfig cpuConfig;
	CacheConfig cacheConfig;
	ContextConfig contextConfig;
}

class Experiment: Reproducible {
	this(string title, string cwd) {
		this.title = title;
		this.cwd = cwd;
	}
	
	this(string title, string cwd, Simulation[] simulations) {
		this.title = title;
		this.cwd = cwd;
		this.simulations = simulations;
	}
	
	override void beforeRun() {
		foreach(simulation; this.simulations) {
			simulation.beforeRun();
		}
	}
	
	override void run() {
		foreach(simulation; this.simulations) {
			simulation.run();
		}
	}
	
	override void afterRun() {
		foreach(simulation; this.simulations) {
			simulation.afterRun();
		}
	}
	
	string title;
	string cwd;
	Simulation[] simulations;
}