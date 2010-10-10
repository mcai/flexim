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
 
int main11() {
    auto tid = spawn(&foo); // create an actor object
 
    foreach(i; 0 .. 10)
        tid.send(i);    // send some integers
    tid.send(1.0f);     // send a float
    tid.send("hello");  // send a string
    tid.send(thisTid);  // send an object (Tid)
 
    receive( (int x) {  writeln("Main thread receives message: ", x);  });
 
    return 0;
}
 
void foo() {
    bool cont = true;
 
    while (cont) {
        receive(  // pattern matching
            (int msg) 	{ writeln("int receive: ", msg); },  // int type
            (Tid sender){ cont = false; sender.send(-1); },  // object type
            (Variant v)	{ writeln("huh?"); }  // any type
        );
    }
}

void runExperiment(string experimentName) {	
	logging.infof(LogCategory.SIMULATOR, "runExperiment(experimentName=%s)", experimentName);
	
	ExperimentConfig experimentConfig = ExperimentConfig.loadXML("../configs/experiments", experimentName ~ ".config.xml");
	Experiment experiment = new Experiment(experimentConfig);
	experiment.execute();
}

void mainConsole(string[] args) {
	//string experimentName = "WCETBench-fir-1x1";
	//string experimentName = "WCETBench-fir-2x1";
	//string experimentName = "Olden_Custom1-em3d_original-1x1";
	//string experimentName = "Olden_Custom1-mst_original-1x1";
	string experimentName = "Olden_Custom1-mst_original-Olden_Custom1_em3d_original-2x1";
	//string experimentName = "Olden_Custom1-mst_original-2x1";
	
	getopt(args, "experiment", &experimentName);
	
	runExperiment(experimentName);
}

void main(string[] args) {
	Main.init(args);
	new Application();
	Main.run();
}

void main1(string[] args) {
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (C) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");
	
	//main11();
	
	bool useBuilder = true;
	
	if(useBuilder) {
		mainGui(args);
	}
	else {
		mainConsole(args);
	}
}
