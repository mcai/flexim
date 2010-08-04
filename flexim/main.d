module flexim.main;

import flexim.all;

import std.file;

void main(string[] args) {
	logging[LogCategory.SIMULATOR].infof("Flexim 5 Multicore Simulator for MIPS32 LE (build: %s)", buildnumber);
	logging[LogCategory.SIMULATOR].info("Copyright (C) 2008 - 2010 Min Cai. All Rights Reserved.\n");

	string[] programArgs = args[1 .. args.length];

//	Simulator simulator = new FastCPUSimulator(getcwd(), programArgs);
	Simulator simulator = new OoOCPUSimulator(getcwd(), programArgs);
//	Simulator simulator = new MOESIMemorySystemSimulator();
	
	simulator.run();
}
