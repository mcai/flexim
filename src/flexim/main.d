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

import std.concurrency, std.stdio, std.typecons;

Simulation runSimulation(string simulationName) {	
	logging.infof(LogCategory.SIMULATOR, "runSimulation(simulationName=%s)", simulationName);
	SimulationConfig simulationConfig = SimulationConfig.loadXML("../configs/simulations", simulationName ~ ".config.xml");
	Simulation simulation = new Simulation(simulationConfig);
	simulation.execute();
	return simulation;
}

void mainConsole(string[] args) {
	string simulationName = "WCETBench-fir-1x1";
	//string simulationName = "WCETBench-fir-2x1";
	//string simulationName = "Olden_Custom1-em3d_original-1x1";
	//string simulationName = "Olden_Custom1-mst_original-1x1";
	//string simulationName = "Olden_Custom1-mst_original-Olden_Custom1_em3d_original-2x1";
	//string simulationName = "Olden_Custom1-mst_original-2x1";
	
	getopt(args, "simulation", &simulationName);
	
	loadConfigsAndStats(delegate void(string text){logging.info(LogCategory.SIMULATOR, text);}, false);

	logging.infof(LogCategory.SIMULATOR, "runSimulation(simulationName=%s)", simulationName);

	SimulationConfig simulationConfig = SimulationConfig.loadXML("../configs/simulations", simulationName ~ ".config.xml");
	Simulation simulation = new Simulation(simulationConfig);
	simulation.execute();
	
	saveConfigsAndStats();
}

void main(string[] args) {
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (C) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");
	
	bool useBuilder = true;
	
	if(useBuilder) {
		mainGui(args);
	}
	else {
		mainConsole(args);
	}
}
