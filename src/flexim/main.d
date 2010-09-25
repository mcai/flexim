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

import gdk.Event;

import gobject.ObjectG;

void xx(string[] args) {
	Main.init(args);
	
	Glade glade = new Glade("/home/itecgo/Flexim2/tests/testGtkGui/flexim_gui.glade");
	
	Window window = cast(Window) glade.getWidget("window1");
	
	CheckButton checkButton1 = cast(CheckButton) glade.getWidget("checkbutton1");
	checkButton1.setLabel("hello world.");
	checkButton1.addOnClicked((Button button){window.setTitle("hello...haha"); Main.exit(0);});
	
	window.showAll();
	
	Main.run();
}

T castFromGtkBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

void xx2(string[] args) {
	Main.init(args);
	
	Builder builder = new Builder();
	builder.addFromFile("../gtk/flexim_gui.glade");
	builder.connectSignals(null); 
	
	Window window = castFromGtkBuilderObject!(Window, GtkWindow)(builder.getObject("window1"));
	
	CheckButton checkButton1 = castFromGtkBuilderObject!(CheckButton, GtkCheckButton)(builder.getObject("checkbutton1"));
	checkButton1.setLabel("hello world.");
	checkButton1.addOnClicked((Button button){window.setTitle("hello...haha"); Main.exit(0);});
	
	window.showAll();
	
	Main.run();
}
 
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

class SimulatorMainWindow: MainWindow {
	this() {
		super("Flexim Simulator");
		
		this.setDefaultSize(800, 600);
		
		VBox box = new VBox(false, 2);
		this.labelStatus = new Label("Click a Button");
		box.add(this.labelStatus);
		box.add(new Button("Button 1", (Button button)
			{
				this.labelStatus.setText("You Clicked Button 1");
			}));
		box.add(new Button("Exit", (Button button)
			{
				Main.exit(0);
			}));
		box.add(new Button("About",(Button button)
			{
				with (new AboutDialog())
					{
						string[] names;
						names ~= "Min Cai (itecgo@163.com)";
						setAuthors(names);
						setWebsite("http://github.com/mcai/flexim");
						showAll();
					}
			}));
		add(box);

		Button buttonExit = new Button();
		buttonExit.setLabel("Exit");
		buttonExit.addOnClicked((Button button)
		{
			MessageDialog d = new MessageDialog(this, GtkDialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, "This is a popup message!");
			d.run();
			d.destroy();
		});
		this.add(buttonExit);
		
		this.showAll();
	}
	
	Label labelStatus;
}

void mainGui(string[] args) {
	Main.init(args);
	new SimulatorMainWindow();
	Main.run();
}

void main(string[] args) {
	logging.info(LogCategory.SIMULATOR, "Flexim - A modular and highly configurable multicore simulator written in D");
	logging.info(LogCategory.SIMULATOR, "Copyright (C) 2010 Min Cai <itecgo@163.com>.");
	logging.info(LogCategory.SIMULATOR, "");
	
	main11();
	
	bool useGui = true;
	
	if(useGui) {
		xx2(args);
	}
	else {
		mainConsole(args);
	}
}
