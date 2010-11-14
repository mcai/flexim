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
import std.regexp;

void main(string[] args) 
{
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (C) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");
	
	string simulationTitle = "WCETBench-fir-1x1";
	//string simulationTitle = "WCETBench-fir-2x1";
	//string simulationTitle = "Olden_Custom1-em3d_original-1x1";
	//string simulationTitle = "Olden_Custom1-mst_original-1x1";
	//string simulationTitle = "Olden_Custom1-mst_original-Olden_Custom1_em3d_original-2x1";
	//string simulationTitle = "Olden_Custom1-mst_original-2x1";
	
	getopt(args, "simulation", &simulationTitle);

	Simulation simulation = Simulation.loadXML("../simulations", simulationTitle ~ ".xml");

	logging.infof(LogCategory.SIMULATOR, "run simulation(title=%s)", simulationTitle);
	
	simulation.execute(delegate void(CPUSimulator simulator) 
		{
			/*foreach(i, core; simulator.processor.cores) 
			{
				foreach(j, thread; core.threads) 
				{
					thread.renameTable.addValueChangedListener(delegate void(RegisterRenameTable sender, RegisterRenameTable.ListenerContext context)
						{
							logging.infof(LogCategory.SIMULATOR, "%s[%s, %d] = %s", sender.name, context.type, context.num, context.physReg);
						});
				}
			}*/
		});

	Simulation.saveXML(simulation);
}
