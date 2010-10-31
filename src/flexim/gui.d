/*
 * flexim/gui.d
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

module flexim.gui;

import flexim.all;

import std.path;

import core.thread;

import cairo.Context;
import cairo.ImageSurface;
import cairo.PdfSurface;
import cairo.Surface;

import gdk.Color;
import gdk.Cursor;
import gdk.Display;
import gdk.Drawable;
import gdk.Event;
import gdk.Keymap;
import gdk.Keysyms;
import gdk.Pixbuf;
import gdk.Rectangle;
import gdk.Screen;
import gdk.Threads;

import glade.Glade;

import glib.RandG;
import glib.Str;

import gobject.ObjectG;
import gobject.Value;

import gthread.Thread;

import gtk.AboutDialog;
import gtk.Builder;
import gtk.Button;
import gtk.CellRenderer;
import gtk.CellRendererCombo;
import gtk.CellRendererPixbuf;
import gtk.CellRendererText;
import gtk.CheckButton;
import gtk.ComboBox;
import gtk.Dialog;
import gtk.DragAndDrop;
import gtk.DrawingArea;
import gtk.EditableIF;
import gtk.Entry;
import gtk.Expander;
import gtk.FileChooserDialog;
import gtk.FileFilter;
import gtk.Fixed;
import gtk.Frame;
import gtk.HBox;
import gtk.HRuler;
import gtk.HSeparator;
import gtk.IconFactory;
import gtk.IconSet;
import gtk.Image;
import gtk.ImageMenuItem;
import gtk.Label;
import gtk.Layout;
import gtk.ListStore;
import gtk.Main;
import gtk.MainWindow;
import gtk.MenuItem;
import gtk.MessageDialog;
import gtk.Notebook;
import gtk.ObjectGtk;
import gtk.ScrolledWindow;
import gtk.SpinButton;
import gtk.StockItem;
import gtk.Table;
import gtk.Timeout;
import gtk.ToggleButton;
import gtk.ToolButton;
import gtk.Toolbar;
import gtk.ToolItem;
import gtk.ToolItemGroup;
import gtk.ToolPalette;
import gtk.TreeIter;
import gtk.TreeModel;
import gtk.TreePath;
import gtk.TreeStore;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.VBox;
import gtk.VRuler;
import gtk.VSeparator;
import gtk.Widget;
import gtk.Window;

import gtkc.gobject;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;

class GladeFile {
	this(string fileName, string dirName = "../res/glade/", string fileExt = ".glade") {
		this.builder = new Builder();
		this.builder.addFromFile(join(dirName, fileName ~ fileExt));
	}
	
	Builder builder;
}

T getBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

T getBuilderObject(T, K)(Builder builder, string name) {
	return getBuilderObject!(T, K)(builder.getObject(name));
}

T getBuilderObject(T, K)(GladeFile gladeFile, string name) {
	return getBuilderObject!(T, K)(gladeFile.builder, name);
}

void guiActionNotImplemented(Window parent, string text) {
	MessageDialog d = new MessageDialog(parent, GtkDialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, text);
	d.run();
	d.destroy();
}

HBox hpack(T...)(T widgets) {
	HBox hbox = new HBox(false, 6);
	
	foreach(widget; widgets) {
		if(is(typeof(widget) == Label) || is(typeof(widget) == VSeparator)) {
			hbox.packStart(widget, false, false, 0);
		}
		else if(is(typeof(widget) == Entry)) {
			hbox.packStart(widget, true, true, 0);
		}
		else {
			hbox.packStart(widget, true, true, 0);
		}
	}
	
	return hbox;
}

VBox vpack(T...)(T widgets) {
	VBox vbox = new VBox(false, 6);
	
	foreach(widget; widgets) {
		vbox.packStart(widget, false, true, 0);
	}
	
	return vbox;
}

VBox vpack2(T)(T[] widgets) {
	VBox vbox = new VBox(false, 6);
	
	foreach(widget; widgets) {
		vbox.packStart(widget, false, true, 0);
	}
	
	return vbox;
}

HBox newHBoxWithLabelAndWidget(string labelText, Widget widget) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);

	return hpack(label, widget);
}

HBox newHBoxWithLabelAndComboBox(string labelText, void delegate(ComboBox) comboBoxInitAction = null, void delegate() comboBoxChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);

	GType[] types;
	types ~= GType.STRING;
	
	ListStore listStore = new ListStore(types);
	
	ComboBox comboBox = new ComboBox(listStore);
	
	if(comboBoxInitAction !is null) {
		comboBoxInitAction(comboBox);
	}
	
	comboBox.addOnChanged(delegate void(ComboBox)
		{
			if(comboBoxChangedAction !is null) {
				comboBoxChangedAction();
			}
		});
	comboBox.setActive(0);
	
	comboBox.setSensitive(comboBoxChangedAction !is null);

	return hpack(label, comboBox);
}

HBox newHBoxWithLabelAndEntry2(T)(string labelText, Property!(T) property, void delegate(string) entryChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);
	Entry entry = new Entry(to!(string)(property));
	entry.addOnChanged(delegate void(EditableIF)
		{
			if(entryChangedAction !is null) {
				entryChangedAction(entry.getText());
			}
		});

	entry.setEditable(entryChangedAction !is null);

	property.addListener(delegate void(T newValue)
		{
			entry.setText(to!(string)(newValue));
			entry.showAll();
		});
	
	return hpack(label, entry);
}

HBox newHBoxWithLabelAndEntry(string labelText, string entryText, void delegate(string) entryChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);
	Entry entry = new Entry(entryText);
	entry.addOnChanged(delegate void(EditableIF)
		{
			if(entryChangedAction !is null) {
				entryChangedAction(entry.getText());
			}
		});

	entry.setEditable(entryChangedAction !is null);
	
	return hpack(label, entry);
}

HBox newHBoxWithLabelAndSpinButton(T)(string labelText, T minEntryValue, T maxEntryValue, T entryStep, T initialEntryValue, void delegate(T newText) spinButtonValueChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);
	SpinButton spinButton = new SpinButton(cast(double) minEntryValue, cast(double) maxEntryValue, entryStep);
	spinButton.setValue(cast(double) initialEntryValue);
	spinButton.setDigits(0);
	spinButton.addOnValueChanged(delegate void(SpinButton)
		{
			if(spinButtonValueChangedAction !is null) {
				spinButtonValueChangedAction(cast(T) (spinButton.getValue()));
			}
		});

	spinButton.setEditable(spinButtonValueChangedAction !is null);
	
	return hpack(label, spinButton);
}

void setupTextComboBox(ComboBox comboBox) {
	GType[] types;
	types ~= GType.STRING;
	
	ListStore listStore = new ListStore(types);
	
	comboBox.setModel(listStore);
	
	CellRenderer renderer = new CellRendererText();
	comboBox.packStart(renderer, true);
	comboBox.addAttribute(renderer, "text", 0);
}

string registerStockId(string name, string label, string key, string fileName = null) {
	if(fileName is null) {
		fileName = format("../res/stock/%s.svg", name);
	}
	string domain = "slow";
	string id = format("%s-%s", domain, name);
	Pixbuf pixbuf = new Pixbuf(fileName);
	IconSet iconSet = new IconSet(pixbuf);
	IconFactory factory = new IconFactory();
	factory.add(id, iconSet);
	factory.addDefault();
	int keyval = Keymap.gdkKeyvalFromName(key);
	GdkModifierType modifier = GdkModifierType.MOD1_MASK;
	
	GtkStockItem gtkStockItem;

	gtkStockItem.stockId = cast(char*) toStringz(id);
	gtkStockItem.label = cast(char*) toStringz(label);
	gtkStockItem.modifier = modifier;
	gtkStockItem.keyval = keyval;
	gtkStockItem.translationDomain = cast(char*) toStringz(domain);
	
	StockItem stockItem = new StockItem(&gtkStockItem);
	stockItem.add(1);
	
	return id;
}

ToolItemGroup addItemGroup(ToolPalette palette, string name) {
	ToolItemGroup group = new ToolItemGroup(name);
	palette.add(group);
	return group;
}

ToolItem addItem(ToolItemGroup group, string stockId, string actionName, string tooltipText) {
	ToolButton item = new ToolButton(stockId);
	item.setActionName(actionName);
	item.setTooltipText(tooltipText);
	item.setIsImportant(true);
	group.insert(item, -1);
	return item;
}

ToolButton bindToolButton(ToolButton toolButton, void delegate() action) {
	toolButton.addOnClicked(delegate void(ToolButton toolButton)
		{
			action();
		});
	return toolButton;
}

ToolButton bindToolButton(Builder builder, string toolButtonName, void delegate() action) {
	ToolButton toolButton = getBuilderObject!(ToolButton, GtkToolButton)(builder, toolButtonName);
	return bindToolButton(toolButton, action);
}

MenuItem bindMenuItem(MenuItem menuItem, void delegate() action) {
	menuItem.addOnActivate(delegate void(MenuItem)
		{
			action();
		});
	return menuItem;
}

MenuItem bindMenuItem(Builder builder, string menuItemName, void delegate() action) {
	MenuItem menuItem = getBuilderObject!(MenuItem, GtkMenuItem)(builder, menuItemName);
	return bindMenuItem(menuItem, action);
}

void hideOnDelete(Dialog dialog) {
	dialog.addOnDelete(delegate bool(gdk.Event.Event, Widget)
		{
			dialog.hide();
			return true;
		});
}

class FrameEditSet {
	this(
		Frame frameEditSet, 
		ComboBox comboBoxSet, 
		Button buttonSetAdd, 
		Button buttonSetRemove, 
		VBox vboxContent) {
		this.frameEditSet = frameEditSet;
		this.comboBoxSet = comboBoxSet;
		this.buttonSetAdd = buttonSetAdd;
		this.buttonSetRemove = buttonSetRemove;
		this.vboxContent = vboxContent;

		setupTextComboBox(this.comboBoxSet);
		this.comboBoxSet.addOnChanged(delegate void(ComboBox)
			{
				this.onComboBoxSetChanged();
			});
		this.comboBoxSet.setActive(0);
		
		if(this.buttonSetAdd !is null) {
			this.buttonSetAdd.addOnClicked(delegate void(Button)
				{
					this.onButtonSetAddClicked();
				});
		}
		
		if(this.buttonSetRemove !is null) {	
			this.buttonSetRemove.addOnClicked(delegate void(Button)
				{
					this.onButtonSetRemoveClicked();
				});
		}
			
		this.notebookSets = new Notebook();
		this.notebookSets.setShowTabs(false);
		this.notebookSets.setBorderWidth(2);
		this.notebookSets.setCurrentPage(0);
		this.vboxContent.packStart(this.notebookSets, true, true, 0);
	}
	
	void showFrame() {
		this.frameEditSet.showAll();
	}
	
	abstract void onComboBoxSetChanged();
	abstract void onButtonSetAddClicked();
	abstract void onButtonSetRemoveClicked();
	
	Frame frameEditSet;
	ComboBox comboBoxSet;
	Button buttonSetAdd, buttonSetRemove;
	VBox vboxContent;
	Notebook notebookSets;
}

class FrameBenchmarkConfigs : FrameEditSet {
	this() {
		GladeFile gladeFile = new GladeFile("frameBenchmarkConfigs");
		Builder builder = gladeFile.builder;
		
		Frame frameBenchmarkConfigs = getBuilderObject!(Frame, GtkFrame)(builder, "frameBenchmarkConfigs");
		ComboBox comboBoxBenchmarkSuites = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxBenchmarkSuites");
		Button buttonAddBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonAddBenchmarkSuite");
		Button buttonRemoveBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveBenchmarkSuite");
		VBox vboxBenchmarks = getBuilderObject!(VBox, GtkVBox)(builder, "vboxBenchmarks");
			
		super(frameBenchmarkConfigs, comboBoxBenchmarkSuites, buttonAddBenchmarkSuite, buttonRemoveBenchmarkSuite, vboxBenchmarks);
		
		foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
			this.newBenchmarkSuite(benchmarkSuite);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string benchmarkSuiteTitle = this.comboBoxSet.getActiveText();
		
		if(benchmarkSuiteTitle != "") {
			assert(benchmarkSuiteTitle in benchmarkSuites, benchmarkSuiteTitle);
			BenchmarkSuite benchmarkSuite = benchmarkSuites[benchmarkSuiteTitle];
			assert(benchmarkSuite !is null);
			
			int indexOfBenchmarkSuite = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfBenchmarkSuite);

			this.buttonSetRemove.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do {
			currentBenchmarkSuiteId++;
		} while(format("benchmarkSuite%d", currentBenchmarkSuiteId) in benchmarkSuites);
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(format("benchmarkSuite%d", currentBenchmarkSuiteId));
		benchmarkSuites[benchmarkSuite.title] = benchmarkSuite;
		this.newBenchmarkSuite(benchmarkSuite);
		
		int indexOfBenchmarkSuite = benchmarkSuites.length - 1;
		
		this.comboBoxSet.setActive(indexOfBenchmarkSuite);
		this.notebookSets.setCurrentPage(indexOfBenchmarkSuite);
	}
	
	override void onButtonSetRemoveClicked() {
		string benchmarkSuiteTitle = this.comboBoxSet.getActiveText();
		
		if(benchmarkSuiteTitle != "") {
			BenchmarkSuite benchmarkSuite = benchmarkSuites[benchmarkSuiteTitle];
			assert(benchmarkSuite !is null);
				
			benchmarkSuites.remove(benchmarkSuite.title);
			
			int indexOfBenchmarkSuite = this.comboBoxSet.getActive();
			this.comboBoxSet.removeText(indexOfBenchmarkSuite);
			
			this.notebookSets.removePage(indexOfBenchmarkSuite);
			
			if(indexOfBenchmarkSuite > 0) {
				this.comboBoxSet.setActive(indexOfBenchmarkSuite - 1);
			}
			else {
				this.comboBoxSet.setActive(benchmarkSuites.length > 0 ? 0 : -1);
			}
		}
	}
	
	void newBenchmarkSuite(BenchmarkSuite benchmarkSuite) {
		this.comboBoxSet.appendText(benchmarkSuite.title);
		
		VBox vboxBenchmarkSuite = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title: ", benchmarkSuite.title, delegate void(string entryText)
				{
					benchmarkSuites.remove(benchmarkSuite.title);
					benchmarkSuite.title = entryText;
					benchmarkSuites[benchmarkSuite.title] = benchmarkSuite;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, benchmarkSuite.title);
					this.comboBoxSet.setActive(index);
				}));
		
		VBox vboxBenchmarks = new VBox(false, 6);
		
		foreach(benchmark; benchmarkSuite.benchmarks) {
			this.newBenchmark(benchmark, vboxBenchmarks);
		}
		
		HBox hboxButtonAdd = new HBox(false, 6);
		
		Button buttonAdd = new Button("Add Benchmark");
		buttonAdd.addOnClicked(delegate void(Button)
			{
				do
				{
					currentBenchmarkId++;
				}
				while(format("benchmark%d", currentBenchmarkId) in benchmarkSuite.benchmarks);
				
				Benchmark benchmark = new Benchmark(format("benchmark%d", currentBenchmarkId), "", "", "", "", "");
				benchmarkSuite.register(benchmark);
				this.newBenchmark(benchmark, vboxBenchmarks);
			});
		hboxButtonAdd.packEnd(buttonAdd, false, false, 0);
		
		vboxBenchmarkSuite.packStart(hbox0, false, true, 6);
		vboxBenchmarkSuite.packStart(vboxBenchmarks, false, true, 0);
		vboxBenchmarkSuite.packStart(hboxButtonAdd, false, true, 6);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxBenchmarkSuite);
		
		this.notebookSets.appendPage(scrolledWindow, benchmarkSuite.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	void newBenchmark(Benchmark benchmark, VBox vboxBenchmarkList) {
		HBox hboxBenchmark = new HBox(false, 6);
		
		HSeparator sep = new HSeparator();
		vboxBenchmarkList.packStart(sep, false, true, 4);
		
		VBox vbox2 = new VBox(false, 6);
		Label labelBenchmarkTitle = new Label(benchmark.title);
		Button buttonRemoveBenchmark = new Button("Remove");
		buttonRemoveBenchmark.addOnClicked(delegate void(Button)
			{
				sep.destroy();
				hboxBenchmark.destroy();
				benchmark.suite.benchmarks.remove(benchmark.title);
			});
		vbox2.packStart(labelBenchmarkTitle, false, false, 0);
		vbox2.packStart(buttonRemoveBenchmark, false, false, 0);
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry("Title: ", benchmark.title, delegate void(string entryText)
				{
					benchmark.suite.benchmarks.remove(benchmark.title);
					benchmark.title = entryText;
					benchmark.suite.register(benchmark);
					labelBenchmarkTitle.setText(benchmark.title);
				}),
			newHBoxWithLabelAndEntry("Cwd: ", benchmark.cwd, delegate void(string entryText)
				{
					benchmark.cwd = entryText;
				}));
				
		HBox hbox2 = hpack(
			newHBoxWithLabelAndEntry("Exe: ", benchmark.exe, delegate void(string entryText)
				{
					benchmark.exe = entryText;
				}),
			newHBoxWithLabelAndEntry("Args in Literal: ", benchmark.argsLiteral, delegate void(string entryText)
				{
					benchmark.argsLiteral = entryText;
				}));
						
		HBox hbox3 = hpack(
			newHBoxWithLabelAndEntry("Stdin: ", benchmark.stdin, delegate void(string entryText)
				{
					benchmark.stdin = entryText;
				}),
			newHBoxWithLabelAndEntry("Stdout: ", benchmark.stdout, delegate void(string entryText)
				{
					benchmark.stdout = entryText;
				}));
		
		VBox vbox = new VBox(false, 6);
		vbox.packStart(hbox1, false, true, 0);
		vbox.packStart(hbox2, false, true, 0);
		vbox.packStart(hbox3, false, true, 0);
		
		hboxBenchmark.packStart(vbox2, false, false, 0);
		hboxBenchmark.packStart(new VSeparator(), false, false, 0);
		hboxBenchmark.packStart(vbox, true, true, 0);
		
		vboxBenchmarkList.packStart(hboxBenchmark, false, true, 0);
		
		vboxBenchmarkList.showAll();
	}

	int currentBenchmarkSuiteId = -1;
	int currentBenchmarkId = -1;
}

class FrameSimulationConfigs : FrameEditSet {
	this() {		
		GladeFile gladeFile = new GladeFile("frameSimulationConfigs");
		Builder builder = gladeFile.builder;
		
		Frame frameSimulationConfigs = getBuilderObject!(Frame, GtkFrame)(builder, "frameSimulationConfigs");
		ComboBox comboBoxSimulations = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulations");
		Button buttonAddSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonAddSimulation");
		Button buttonRemoveSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveSimulation");
		VBox vboxSimulation = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulation");
		this.buttonSimulate = getBuilderObject!(Button, GtkButton)(builder, "buttonSimulate");
			
		super(frameSimulationConfigs, comboBoxSimulations, buttonAddSimulation, buttonRemoveSimulation, vboxSimulation);
		
		HBox hboxAddSimulation = getBuilderObject!(HBox, GtkHBox)(builder, "hboxAddSimulation");
			
		this.numCoresWhenAddSimulation = this.numThreadsPerCoreWhenAddSimulation = 2;
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Number of Cores:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numCoresWhenAddSimulation = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numThreadsPerCoreWhenAddSimulation = newValue;
			}));
		
		hboxAddSimulation.packStart(hbox0, true, true, 0);
		
		foreach(simulationConfigTitle, simulationConfig; simulationConfigs) {
			this.newSimulationConfig(simulationConfig);
		}

		this.buttonSimulate.addOnClicked(delegate void(Button)
			{
				string oldButtonLabel = this.buttonSimulate.getLabel();
				
				string simulationConfigTitle = this.comboBoxSet.getActiveText();
				SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
				
				Simulation simulation = new Simulation(simulationConfig, delegate void(Simulation simulation)
					{
						gdkThreadsEnter();
						simulation.stat.dispatch();
						gdkThreadsLeave();
					});
				
				core.thread.Thread threadRunSimulation = new core.thread.Thread(
					{
						simulation.execute();
		
						gdkThreadsEnter();
						this.buttonSimulate.setSensitive(true);
						this.buttonSimulate.setLabel(oldButtonLabel);
						simulation.stat.dispatch();
						gdkThreadsLeave();
					});
					
				core.thread.Thread threadUpdateGui = new core.thread.Thread(
					{
						while(simulation.isRunning) {
							gdkThreadsEnter();
							simulation.stat.dispatch();
							gdkThreadsLeave();
							
							core.thread.Thread.sleep(30000);
						}
					});
	
				this.buttonSimulate.setSensitive(false);
				this.buttonSimulate.setLabel("Simulating.. Please Wait");

				simulation.stat.reset();
					
				threadRunSimulation.start();
				//threadUpdateGui.start();
			});
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string simulationConfigTitle = this.comboBoxSet.getActiveText();
		
		if(simulationConfigTitle != "") {
			assert(simulationConfigTitle in simulationConfigs, simulationConfigTitle);
			SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
			assert(simulationConfig !is null);
			
			int indexOfSimulationConfig = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfSimulationConfig);
			
			this.buttonSetRemove.setSensitive(true);
			this.buttonSimulate.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
			this.buttonSimulate.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do {
			currentSimulationId++;
		}while(format("simulation%d", currentSimulationId) in simulationConfigs);
		
		ProcessorConfig processor = new ProcessorConfig(2000000, 2000000, 7200, 1);
		
		for(uint i = 0; i < this.numCoresWhenAddSimulation; i++) {
			CoreConfig core = new CoreConfig(CacheConfig.newL1(format("l1I-%d", i)), CacheConfig.newL1(format("l1D-%d", i)));
			processor.cores ~= core;
			
			for(uint j = 0; j < this.numThreadsPerCoreWhenAddSimulation; j++) {
				Benchmark workload = benchmarkSuites["WCETBench"]["fir"];
				ContextConfig context = new ContextConfig(workload);
				processor.contexts ~= context;
			}
		}
		
		CacheConfig l2Cache = CacheConfig.newL2();
		MainMemoryConfig mainMemory = new MainMemoryConfig(400);
		
		SimulationConfig simulationConfig = new SimulationConfig(format("simulation%d", currentSimulationId), "../stats/simulations", processor, l2Cache, mainMemory);
		
		simulationConfigs[simulationConfig.title] = simulationConfig;
		this.newSimulationConfig(simulationConfig);
		
		int indexOfSimulationConfig = simulationConfigs.length - 1;
		
		this.comboBoxSet.setActive(indexOfSimulationConfig);
		this.notebookSets.setCurrentPage(indexOfSimulationConfig);
	}
	
	override void onButtonSetRemoveClicked() {
		string simulationConfigTitle = this.comboBoxSet.getActiveText();
		
		if(simulationConfigTitle != "") {
			SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
			assert(simulationConfig !is null);
			
			simulationConfigs.remove(simulationConfig.title);
			
			int indexOfSimulationConfig = this.comboBoxSet.getActive();
			this.comboBoxSet.removeText(indexOfSimulationConfig);
			
			this.notebookSets.removePage(indexOfSimulationConfig);
			
			if(indexOfSimulationConfig > 0) {
				this.comboBoxSet.setActive(indexOfSimulationConfig - 1);
			}
			else {
				this.comboBoxSet.setActive(simulationConfigs.length > 0 ? 0 : -1);
			}
		}
	}
	
	HBox newCache(CacheConfig cache) {
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Name:", cache.name), 
			newHBoxWithLabelAndEntry("Level:", to!(string)(cache.level)));
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Number of Sets:", 1, 1024, 1, cache.numSets, delegate void(uint newValue)
			{
				cache.numSets = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Associativity:", 1, 1024, 1, cache.assoc, delegate void(uint newValue)
			{
				cache.assoc = newValue;
			}), 
			newHBoxWithLabelAndSpinButton!(uint)("Block Size:", 1, 1024, 1, cache.blockSize, delegate void(uint newValue)
			{
				cache.blockSize = newValue;
			}));
		
		HBox hbox2 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Hit Latency:", 1, 1024, 1, cache.hitLatency, delegate void(uint newValue)
			{
				cache.hitLatency = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Miss Latency:", 1, 1024, 1, cache.missLatency, delegate void(uint newValue)
			{
				cache.missLatency = newValue;
			}),
			newHBoxWithLabelAndEntry("Replacement Policy", to!(string)(cache.policy), delegate void(string entryText)
			{
				cache.policy = cast(CacheReplacementPolicy) entryText;
			}));
				
		return hpack(new Label(cache.name), new VSeparator(), vpack(hbox0, hbox1, hbox2));
	}
	
	ComboBox newContext(ContextConfig context) {
		ComboBox comboBoxBenchmark = new ComboBox();
		
		foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
			foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
				comboBoxBenchmark.appendText(format("%s (%s)", benchmarkTitle, benchmarkSuiteTitle));
			}
		}
		
		comboBoxBenchmark.addOnChanged(delegate void(ComboBox comboBox)
			{
				string benchmarkName = comboBox.getActiveText();
				
				if(benchmarkName != "") {
					int index1 = std.algorithm.indexOf(benchmarkName, '(');
					int index2 = std.algorithm.indexOf(benchmarkName, ')');
					string benchmarkSuiteTitle = benchmarkName[(index1 + 1)..index2];
					string benchmarkTitle = benchmarkName[0..(index1 - 1)];
					
					Benchmark workload = benchmarkSuites[benchmarkSuiteTitle][benchmarkTitle];
					context.workload = workload;
				}
			});
					
		comboBoxBenchmark.setActive(comboBoxBenchmark.getIndex(format("%s (%s)", context.workload.title, context.workload.suite.title)));
			
		return comboBoxBenchmark;
	}
	
	void newSimulationConfig(SimulationConfig simulationConfig) {
		this.comboBoxSet.appendText(simulationConfig.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", simulationConfig.title, delegate void(string entryText)
				{
					simulationConfigs.remove(simulationConfig.title);
					simulationConfig.title = entryText;
					simulationConfigs[simulationConfig.title] = simulationConfig;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, simulationConfig.title);
					this.comboBoxSet.setActive(index);
				}),
			newHBoxWithLabelAndEntry("Cwd:", simulationConfig.cwd, delegate void(string entryText)
				{
					simulationConfig.cwd = entryText;
				}));
		
		vboxSimulation.packStart(hbox0, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndSpinButton!(ulong)("Max Cycle:", 1, 2000000, 1000, simulationConfig.processor.maxCycle, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxCycle = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Insts:", 1, 2000000, 1000, simulationConfig.processor.maxInsts, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxInsts = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Time:", 1, 7200, 100, simulationConfig.processor.maxTime, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxTime = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, simulationConfig.processor.numThreadsPerCore));
			
		vboxProcessor.packStart(hbox1, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		Widget[] vboxesCore;
		
		foreach(i, core; simulationConfig.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(this.newCache(core.iCache), this.newCache(core.dCache)));
		}
		
		VBox vboxCores = vpack2(vboxesCore);
			
		vboxProcessor.packStart(vboxCores, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		Widget[] vboxesContext;
		
		foreach(i, context; simulationConfig.processor.contexts) {			
			vboxesContext ~= hpack(
				new Label(format("context-%d", i)),
				new VSeparator(), 
				newHBoxWithLabelAndWidget("Benchmark:", this.newContext(context)));
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);
		
		vboxSimulation.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		vboxSimulation.packStart(newCache(simulationConfig.l2Cache), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Latency:", 1, 1024, 1, simulationConfig.mainMemory.latency, delegate void(uint newValue)
			{
				simulationConfig.mainMemory.latency = newValue;
			}));
			
		HBox hboxMainMemory = hpack(new Label("Main Memory"), new VSeparator(), vpack(hbox13));
		
		vboxSimulation.packStart(hboxMainMemory, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
			
		//////////////////////
			
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxSimulation);
		
		this.notebookSets.appendPage(scrolledWindow, simulationConfig.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	uint numCoresWhenAddSimulation, numThreadsPerCoreWhenAddSimulation;
	int currentSimulationId = -1;
	
	Button buttonSimulate;
}

class FrameSimulationStats: FrameEditSet {
	this() {
		GladeFile gladeFile = new GladeFile("frameSimulationStats");
		Builder builder = gladeFile.builder;
		
		Frame frameSimulationStats = getBuilderObject!(Frame, GtkFrame)(builder, "frameSimulationStats");
		ComboBox comboBoxSimulationStats = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulationStats");
		VBox vboxSimulationStat = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulationStat");
			
		super(frameSimulationStats, comboBoxSimulationStats, null, null, vboxSimulationStat);
		
		foreach(simulationStatTitle, simulationStat; simulationStats) {
			this.newSimulationStat(simulationStat);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string simulationStatTitle = this.comboBoxSet.getActiveText();
		
		if(simulationStatTitle != "") {
			assert(simulationStatTitle in simulationStats, simulationStatTitle);
			SimulationStat simulationStat = simulationStats[simulationStatTitle];
			assert(simulationStat !is null);
			
			int indexOfSimulationStat = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfSimulationStat);
		}
	}
	
	override void onButtonSetAddClicked() {
		assert(0);
	}
	
	override void onButtonSetRemoveClicked() {
		assert(0);
	}
	
	HBox newCache(CacheStat cache, string cacheName) {
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Name:", cacheName));
			
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("Accesses", cache.accesses),
			newHBoxWithLabelAndEntry2!(ulong)("Hits", cache.hits),
			newHBoxWithLabelAndEntry2!(ulong)("Evictions", cache.evictions));
				
		HBox hbox2 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("Reads", cache.reads),
			newHBoxWithLabelAndEntry2!(ulong)("Blocking Reads", cache.blockingReads),
			newHBoxWithLabelAndEntry2!(ulong)("Nonblocking Reads", cache.nonblockingReads),
			newHBoxWithLabelAndEntry2!(ulong)("Read Hits", cache.readHits));
				
		HBox hbox3 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("Writes", cache.writes),
			newHBoxWithLabelAndEntry2!(ulong)("Blocking Writes", cache.blockingWrites),
			newHBoxWithLabelAndEntry2!(ulong)("Nonblocking Writes", cache.nonblockingWrites),
			newHBoxWithLabelAndEntry2!(ulong)("Write Hits", cache.writeHits));
				
		HBox hbox4 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("Read Retries", cache.readRetries),
			newHBoxWithLabelAndEntry2!(ulong)("Write Retries", cache.writeRetries));
				
		HBox hbox5 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Accesses", cache.noRetryAccesses),
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Hits", cache.noRetryHits));
				
		HBox hbox6 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Reads", cache.noRetryReads),
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Read Hits", cache.noRetryReadHits));
					
		HBox hbox7 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Writes", cache.noRetryWrites),
			newHBoxWithLabelAndEntry2!(ulong)("No-Retry Write Hits", cache.noRetryWriteHits));
	
		return hpack(new Label(cacheName), new VSeparator(), vpack(hbox0, hbox1, hbox2, hbox3, hbox4, hbox5, hbox6, hbox7));
	}
	
	void newSimulationStat(SimulationStat simulationStat) {
		this.comboBoxSet.appendText(simulationStat.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", simulationStat.title),
			newHBoxWithLabelAndEntry("Cwd:", simulationStat.cwd),
			newHBoxWithLabelAndEntry2!(ulong)("Total Cycles:", simulationStat.totalCycles),
			newHBoxWithLabelAndEntry2!(ulong)("Duration:", simulationStat.duration));
		
		vboxSimulation.packStart(hbox0, false, true, 0);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		Widget[] vboxesCore;
		
		foreach(i, core; simulationStat.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(this.newCache(core.iCache, format("l1I-%d", i)), this.newCache(core.dCache, format("l1D-%d", i))));
		}
		
		VBox vboxCores = vpack2(vboxesCore);
		
		vboxProcessor.packStart(vboxCores, false, true, 6);
	
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		Widget[] vboxesContext;
		
		foreach(i, context; simulationStat.processor.contexts) {
			vboxesContext ~= hpack(
				new Label(format("context-%d", i)),
				new VSeparator(),
				newHBoxWithLabelAndEntry2!(ulong)("Total Instructions Committed:", context.totalInsts)); 		
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);
		
		vboxSimulation.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		vboxSimulation.packStart(newCache(simulationStat.l2Cache, "l2"), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndEntry2!(ulong)("Reads:", simulationStat.mainMemory.reads),
			newHBoxWithLabelAndEntry2!(ulong)("Writes:", simulationStat.mainMemory.writes),
			newHBoxWithLabelAndEntry2!(ulong)("Accesses:", simulationStat.mainMemory.accesses));
		
		HBox hboxMainMemory = hpack(new Label("Main Memory"), new VSeparator(), vpack(hbox13));
		
		vboxSimulation.packStart(hboxMainMemory, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
			
		//////////////////////
			
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxSimulation);
		
		this.notebookSets.appendPage(scrolledWindow, simulationStat.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
}

abstract class ArchitecturalSpecification {
	this() {
		this.drawableObjectId = "";
	}
	
	abstract string label();
	abstract string backColor();
	abstract bool isCycleAccurate();
	abstract void realize();
	
	abstract XMLConfig save();
	
	string id;
	string drawableObjectId;
	Canvas canvas;
	
	static this() {
		currentId = 0;
	}
	
	static int currentId;
}

class ProcessorCoreSpecification: ArchitecturalSpecification {
	this() {
	}
}

class SimpleProcessorCoreSpecification: ProcessorCoreSpecification {
	this() {
		this.id = format("simpleProcessorCore%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "Simple (Functional) Processor Core";
	}
	
	override string backColor() {
		return "red";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return SimpleProcessorCoreSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class SimpleProcessorCoreSpecificationXMLSerializer: XMLSerializer!(SimpleProcessorCoreSpecification) {
	this() {
	}
	
	override XMLConfig save(SimpleProcessorCoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("SimpleProcessorCoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override SimpleProcessorCoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		SimpleProcessorCoreSpecification specification = new SimpleProcessorCoreSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new SimpleProcessorCoreSpecificationXMLSerializer();
	}
	
	static SimpleProcessorCoreSpecificationXMLSerializer singleInstance;	
}

class OoOProcessorCoreSpecification : ProcessorCoreSpecification {
	this() {
		this.id = format("ooOProcessorCore%d", currentId++);
		
		this.iCacheId = "";
		this.dCacheId = "";
	}
	
	this(string id) {
		this.id = id;
		
		this.iCacheId = "";
		this.dCacheId = "";
	}
	
	override string label() {
		return "Out-of-Order Processor Core";
	}
	
	override string backColor() {
		return "red";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
		assert(this.iCache !is null);
		assert(this.dCache !is null);
	}
	
	override XMLConfig save() {
		return OoOProcessorCoreSpecificationXMLSerializer.singleInstance.save(this);
	}
	
	ICacheSpecification iCache() {
		if(this.canvas !is null && this.iCacheId != "") {
			return this.canvas.getSpecification!(ICacheSpecification)(this.iCacheId);
		}
		
		return null;
	}
	
	DCacheSpecification dCache() {
		if(this.canvas !is null && this.dCacheId != "") {
			return this.canvas.getSpecification!(DCacheSpecification)(this.dCacheId);
		}
		
		return null;
	}
	
	string iCacheId;
	string dCacheId;
}

class OoOProcessorCoreSpecificationXMLSerializer: XMLSerializer!(OoOProcessorCoreSpecification) {
	this() {
	}
	
	override XMLConfig save(OoOProcessorCoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("OoOProcessorCoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		xmlConfig["iCacheId"] = specification.iCacheId;
		xmlConfig["dCacheId"] = specification.dCacheId;
		
		return xmlConfig;
	}
	
	override OoOProcessorCoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		string iCacheId = xmlConfig["iCacheId"];
		string dCacheId = xmlConfig["dCacheId"];
		
		OoOProcessorCoreSpecification specification = new OoOProcessorCoreSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		specification.iCacheId = iCacheId;
		specification.dCacheId = dCacheId;
		
		return specification;
	}
	
	static this() {
		singleInstance = new OoOProcessorCoreSpecificationXMLSerializer();
	}
	
	static OoOProcessorCoreSpecificationXMLSerializer singleInstance;
}

abstract class CacheSpecification : ArchitecturalSpecification {
	this() {
	}
}

class ICacheSpecification : CacheSpecification {
	this() {
		this.id = format("iCache%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "Inst Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return ICacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class ICacheSpecificationXMLSerializer: XMLSerializer!(ICacheSpecification) {
	this() {
	}
	
	override XMLConfig save(ICacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("ICacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override ICacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		ICacheSpecification specification = new ICacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new ICacheSpecificationXMLSerializer();
	}
	
	static ICacheSpecificationXMLSerializer singleInstance;
}

class DCacheSpecification : CacheSpecification {
	this() {
		this.id = format("dCache%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "Data Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return DCacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class DCacheSpecificationXMLSerializer: XMLSerializer!(DCacheSpecification) {
	this() {
	}
	
	override XMLConfig save(DCacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("DCacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override DCacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		DCacheSpecification specification = new DCacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new DCacheSpecificationXMLSerializer();
	}
	
	static DCacheSpecificationXMLSerializer singleInstance;
}

class L2CacheSpecification : CacheSpecification {
	this() {
		this.id = format("l2Cache%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "L2 Cache";
	}
	
	override string backColor() {
		return "green";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return L2CacheSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class L2CacheSpecificationXMLSerializer: XMLSerializer!(L2CacheSpecification) {
	this() {
	}
	
	override XMLConfig save(L2CacheSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("L2CacheSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override L2CacheSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		L2CacheSpecification specification = new L2CacheSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new L2CacheSpecificationXMLSerializer();
	}
	
	static L2CacheSpecificationXMLSerializer singleInstance;
}

abstract class InterconnectSpecification : ArchitecturalSpecification {
	this() {
	}
}

abstract class P2PInterconnectSpecification : InterconnectSpecification {
	this() {
	}
}

class FixedLatencyP2PInterconnectSpecification : P2PInterconnectSpecification {
	this() {
		this.id = format("fixedLatencyP2PInterconnect%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "Fixed-Latency P2P Interconnect";
	}
	
	override string backColor() {
		return "blue";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return FixedLatencyP2PInterconnectSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class FixedLatencyP2PInterconnectSpecificationXMLSerializer: XMLSerializer!(FixedLatencyP2PInterconnectSpecification) {
	this() {
	}
	
	override XMLConfig save(FixedLatencyP2PInterconnectSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyP2PInterconnectSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override FixedLatencyP2PInterconnectSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		FixedLatencyP2PInterconnectSpecification specification = new FixedLatencyP2PInterconnectSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new FixedLatencyP2PInterconnectSpecificationXMLSerializer();
	}
	
	static FixedLatencyP2PInterconnectSpecificationXMLSerializer singleInstance;
}

abstract class MainMemorySpecification : ArchitecturalSpecification {
	this() {
	}
}

class FixedLatencyDRAMSpecification : MainMemorySpecification {
	this() {
		this.id = format("fixedLatencyDRAM%d", currentId++);
	}
	
	this(string id) {
		this.id = id;
	}
	
	override string label() {
		return "Fixed-Latency DRAM Controller";
	}
	
	override string backColor() {
		return "brown";
	}
	
	override bool isCycleAccurate() {
		return false;
	}
	
	override void realize() {
	}
	
	override XMLConfig save() {
		return FixedLatencyDRAMSpecificationXMLSerializer.singleInstance.save(this);
	}
}

class FixedLatencyDRAMSpecificationXMLSerializer: XMLSerializer!(FixedLatencyDRAMSpecification) {
	this() {		
	}
	
	override XMLConfig save(FixedLatencyDRAMSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("FixedLatencyDRAMSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["drawableObjectId"] = specification.drawableObjectId;
		
		return xmlConfig;
	}
	
	override FixedLatencyDRAMSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string drawableObjectId = xmlConfig["drawableObjectId"];
		
		FixedLatencyDRAMSpecification specification = new FixedLatencyDRAMSpecification(id);
		specification.drawableObjectId = drawableObjectId;
		return specification;
	}
	
	static this() {
		singleInstance = new FixedLatencyDRAMSpecificationXMLSerializer();
	}
	
	static FixedLatencyDRAMSpecificationXMLSerializer singleInstance;
}

abstract class ArchitectureArchitecturalSpecification : ArchitecturalSpecification {
	this() {
	}
}

class SharedCacheMulticoreSpecification: ArchitectureArchitecturalSpecification {
	this() {
		this.id = format("sharedCacheMulticore%d", currentId++);
		
		this.coreIds[0] = "";
		this.coreIds[1] = "";
		
		this.l2CacheId = "";
		this.interconnectId = "";
		this.mainMemoryId = "";
	}
	
	this(string id) {
		this.id = id;
		
		this.coreIds[0] = "";
		this.coreIds[1] = "";
		
		this.l2CacheId = "";
		this.interconnectId = "";
		this.mainMemoryId = "";
	}
	
	override string label() {
		return "Shared Cache Multicore";
	}
	
	override string backColor() {
		return "default";
	}
	
	override bool isCycleAccurate() {
		return true;
	}
	
	override void realize() {
		assert(this.coreIds.length == 2);
		assert(this.l2Cache !is null);
		assert(this.interconnect !is null);
		assert(this.mainMemory !is null);
	}
	
	override XMLConfig save() {
		return SharedCacheMulticoreSpecificationXMLFileSerializer.singleInstance.save(this);
	}
	
	OoOProcessorCoreSpecification getCore(string coreId) {
		if(this.canvas !is null && coreId != "") {
			return this.canvas.getSpecification!(OoOProcessorCoreSpecification)(coreId);
		}
		
		return null;
	}
	
	OoOProcessorCoreSpecification getCore(int coreNum) {
		assert(coreNum >= 0 && coreNum < this.coreIds.length);
		
		return this.getCore(this.coreIds[coreNum]);
	}
	
	string[int] coreIds;
	
	L2CacheSpecification l2Cache() {
		if(this.canvas !is null && this.l2CacheId != "") {
			return this.canvas.getSpecification!(L2CacheSpecification)(this.l2CacheId);
		}
		
		return null;
	}
	
	FixedLatencyP2PInterconnectSpecification interconnect() {
		if(this.canvas !is null && this.interconnectId != "") {
			return this.canvas.getSpecification!(FixedLatencyP2PInterconnectSpecification)(this.interconnectId);
		}
		
		return null;
	}
	
	FixedLatencyDRAMSpecification mainMemory() {
		if(this.canvas !is null && this.mainMemoryId != "") {
			return this.canvas.getSpecification!(FixedLatencyDRAMSpecification)(this.mainMemoryId);
		}
		
		return null;
	}
	
	string l2CacheId;
	string interconnectId;
	string mainMemoryId;
}

class SharedCacheMulticoreSpecificationXMLFileSerializer: XMLSerializer!(SharedCacheMulticoreSpecification) {
	this() {		
	}
	
	override XMLConfig save(SharedCacheMulticoreSpecification specification) {
		XMLConfig xmlConfig = new XMLConfig("SharedCacheMulticoreSpecification");
		xmlConfig["id"] = specification.id;
		xmlConfig["numCores"] = to!(string)(specification.coreIds.length);
				
		foreach(i, coreId; specification.coreIds) {
			xmlConfig[format("coreId%d", i)] = coreId;
		}
		
		xmlConfig["l2CacheId"] = specification.l2CacheId;
		xmlConfig["interconnectId"] = specification.interconnectId;
		xmlConfig["mainMemoryId"] = specification.mainMemoryId;
		
		return xmlConfig;
	}
	
	override SharedCacheMulticoreSpecification load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		string l2CacheId = xmlConfig["l2CacheId"];
		string interconnectId = xmlConfig["interconnectId"];
		string mainMemoryId = xmlConfig["mainMemoryId"];
		int numCores = to!(int)(xmlConfig["numCores"]);
		
		SharedCacheMulticoreSpecification specification = new SharedCacheMulticoreSpecification(id);
			
		for(int i = 0; i < numCores; i++) {
			specification.coreIds[i] = xmlConfig[format("coreId%d", i)];
		}
		
		specification.l2CacheId = l2CacheId;
		specification.interconnectId = interconnectId;
		specification.mainMemoryId = mainMemoryId;
		
		return specification;
	}
	
	static this() {
		singleInstance = new SharedCacheMulticoreSpecificationXMLFileSerializer();
	}
	
	static SharedCacheMulticoreSpecificationXMLFileSerializer singleInstance;
}

alias Tuple!(double, "x", double, "y") Point;
alias Tuple!(double, "width", double, "height") Size;
alias Tuple!(double, "x", double, "y", double, "width", double, "height") Rectangle;

class CanvasColors {
	static this() {
		this.entries["default"] = new gdk.Color.Color();
		this.entries["red"] = new gdk.Color.Color(0xEE799F);
		this.entries["green"] = new gdk.Color.Color(0x43CD80);
		this.entries["blue"] = new gdk.Color.Color(0x00B2EE);
		this.entries["brown"] = new gdk.Color.Color(0xEE7942);
	}
	
	static gdk.Color.Color opIndex(string index) {
		assert(index in this.entries, index);
		return this.entries[index];
	}
	
	static gdk.Color.Color[string] entries;
}

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

class CursorSet {
	this() {
		this(ENTIS);
	}
	
	this(string category) {
		this.category = category;
		
		gtk.Invisible.Invisible invisible = new gtk.Invisible.Invisible();
		gdk.Screen.Screen screen = invisible.getScreen();
		gdk.Display.Display display = screen.getDisplay();
		
		this.normal = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "pointer.png"), 4, 2);
		this.northwest = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-northwest.png"), 6, 6);
		this.north = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-north.png"), 12, 6);
		this.northeast = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-northeast.png"), 18, 6);
		this.west = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-west.png"), 6, 12);
		this.east = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-east.png"), 18, 12);
		this.southwest = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-southwest.png"), 6, 18);
		this.south = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-south.png"), 12, 18);
		this.southeast = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-southeast.png"), 18, 18);
		this.cross = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "stroke.png"), 2, 20);
		this.move = new Cursor(display, new Pixbuf("../res/cursors" ~ "/" ~ this.category ~ "/" ~ "move.png"), 11, 11);
	}
	
	override string toString() {
		return format("Cursor[category=%s]", this.category);
	}
	
	static const string DEFAULT = "default";
	static const string AERO = "aero";
	static const string ENTIS = "entis";
	static const string INCARNERRY_MARK = "incarnerry-mark";
	static const string VOLTA_RINGLETS = "volta-ringlets";
	
	string category;
	Cursor normal, northwest, north, northeast, west, east, southwest, south, southeast, cross, move;
}

enum Direction : uint {
	NONE = -1,
	NORTHWEST = 0,
	NORTH = 1,
	NORTHEAST = 2,
	WEST = 3,
	EAST = 4,
	SOUTHWEST = 5,
	SOUTH = 6,
	SOUTHEAST = 7,
	END = 8,
	END2 = 9
}

class Control {
	this() {
		this.offset.x = this.offset.y = 0;
		this.size = 10.0;
		this.limbus = false;
	}
	
	void draw(Context context) {
		this.rect.width = this.size / 2.0;
		this.rect.height = this.size / 2.0;
		
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		
		context.rectangle(this.rect.x - this.rect.width / 2.0, this.rect.y - this.rect.height / 2.0, this.rect.width, this.rect.height);
		
		if(this.limbus) {
			context.setSourceRgba(0.5, 0.0, 0.0, 0.25);
		}
		else {
			context.setSourceRgba(0.0, 0.5, 0.0, 0.25);
		}
		
		context.fillPreserve();
		
		if(this.limbus) {
			context.setSourceRgba(0.25, 0.0, 0.0, 0.5);
		}
		else {
			context.setSourceRgba(0.0, 0.25, 0.0, 0.5);
		}
		
		context.stroke();
	}
	
	bool atPosition(double x, double y) {
		return x >= (this.rect.x - this.size / 2.0) && x <= (this.rect.x + this.size) &&
			y >= (this.rect.y - this.size / 2.0) && y <= (this.rect.y + this.size);
	}
	
	override string toString() {
		return format("Control[x=%f, y=%f, width=%f, height=%f, offset=%s, size=%f, limbus=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.offset, this.size, this.limbus);
	}
	
	Rectangle rect;
	Point offset;
	double size;
	bool limbus;
}

class Paper {
	this() {
		this.active = true;
		this.top = this.left = this.bottom = this.right = 0;
	}
	
	void draw(Context context) {
		int shadow = 5;
		
		context.setLineWidth(2.5);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		
		context.setSourceRgb(1.0, 1.0, 1.0);
		context.fillPreserve();
		
		context.setSourceRgb(0.0, 0.0, 0.0);
		double[] dash;
		context.setDash(dash, 0);
		context.stroke();
		
		context.setSourceRgba(0.0, 0.0, 0.0, 0.25);
		double[] dash2;
		context.setDash(dash2, 0);
		
		context.setLineWidth(shadow);
		context.moveTo(this.rect.x + this.rect.width + shadow / 2.0, this.rect.y + shadow);
		context.lineTo(this.rect.x + this.rect.width + shadow / 2.0, this.rect.y + this.rect.height + shadow / 2.0);
		context.lineTo(this.rect.x + shadow, this.rect.y + this.rect.height + shadow / 2.0);
		context.stroke();
	}
	
	override string toString() {
		return format("Paper[x=%f, y=%f, width=%f, height=%f, active=%s, top=%f, left=%f, bottom=%f, right=%f]", 
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.top, this.left, this.bottom, this.right);
	}
	
	Rectangle rect;
	bool active;
	double top, left, bottom, right;
}

class Grid {
	this() {
		this.active = true;
		this.size = 15.0;
		this.snap = true;
	}
	
	void draw(Context context) {
		context.setLineWidth(0.15);
		context.setSourceRgb(0.0, 0.0, 0.0);
		double[] dash;
		dash ~= 2.0;
		dash ~= 2.0;
		context.setDash(dash, 0);
		
		double _x = this.rect.x;
		double _y = this.rect.y;
		
		while(_x <= this.rect.x + this.rect.width) {
			context.moveTo(_x, this.rect.y);
			context.lineTo(_x, this.rect.y + this.rect.height);
			_x += this.size;
		}
		
		while(_y <= this.rect.y + this.rect.height) {
			context.moveTo(this.rect.x, _y);
			context.lineTo(this.rect.x + this.rect.width, _y);
			_y += this.size;
		}
		
		context.stroke();
	}
	
	double nearest(double value) {
		if(this.snap) {
			double lower = this.size * cast(int) (value / this.size);
			double upper = this.size * cast(int) (value / this.size) + this.size;
			double middle = (lower + upper) / 2.0;
			if(value > middle) {
				return upper;
			}
			else {
				return lower;
			}
		}
		else {
			return value;
		}
	}
	
	override string toString() {
		return format("Grid[x=%f, y=%f, width=%f, height=%f, active=%s, snap=%s, size=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.snap, this.size);
	}
	
	Rectangle rect;
	bool active, snap;
	double size;
}

class Selection {
	this() {
		this.active = false;
	}
	
	void draw(Context context) {
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		context.setSourceRgba(0.0, 0.0, 0.5, 0.25);
		context.fillPreserve();
		context.setSourceRgba(0.0, 0.0, 0.25, 0.5);
		context.stroke();
	}
	
	override string toString() {
		return format("Selection[x=%f, y=%f, width=%f, height=%f, active=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active);
	}
	
	Rectangle rect;
	bool active;
}

class Handler {
	this() {
		this.controls[Direction.NORTHWEST] = new Control();
		this.controls[Direction.NORTH] = new Control();
		this.controls[Direction.NORTHEAST] = new Control();
		this.controls[Direction.WEST] = new Control();
		this.controls[Direction.EAST] = new Control();
		this.controls[Direction.SOUTHWEST] = new Control();
		this.controls[Direction.SOUTH] = new Control();
		this.controls[Direction.SOUTHEAST] = new Control();
		this.controls[Direction.END] = new Control();
	}
	
	void draw(Context context) {
		context.setLineWidth(0.5);
		context.setSourceRgb(0.0, 0.5, 0.0);
		double[] dash;
		dash ~= 5.0;
		dash ~= 3.0;
		context.setDash(dash, 0);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		context.stroke();
		
		foreach(control; this.controls) {
			control.draw(context);
		}
	}
	
	bool atPosition(double x, double y) {
		foreach(control; this.controls) {
			if(control.atPosition(x, y)) {
				return true;
			}
		}
		
		return false;
	}
	
	Direction getDirection(double x, double y) {
		foreach(direction, control; this.controls) {
			if(control.atPosition(x, y)) {
				return direction;
			}
		}
		
		return Direction.NONE;
	}
	
	override string toString() {
		return format("Handler[x=%f, y=%f, width=%f, height=%f, line=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.line);
	}
	
	Rectangle rect;
	Control[Direction] controls;
	bool line;
}

abstract class DrawableObject {
	this(string id) {
		this.id = id;
		this.handler = new Handler();
		this.selected = false;
		this.resize = false;
		this.direction = Direction.NONE;
		this.isAbstract = false;
	}
	
	void addOnArchitecturalSpecificationChanged(void delegate(ArchitecturalSpecification specification) del) {
		this.specificationChangedListeners ~= del;
	}
	
	void fireArchitecturalSpecificationChanged(ArchitecturalSpecification specification) {
		foreach(listener; this.specificationChangedListeners) {
			listener(specification);
		}
	}
	
	void delegate(ArchitecturalSpecification)[] specificationChangedListeners;
	
	abstract void post();
	
	void draw(Context context) {
		if(this.selected) {
			this.handler.rect.x = this.rect.x;
			this.handler.rect.y = this.rect.y;
			this.handler.rect.width = this.rect.width;
			this.handler.rect.height = this.rect.height;
			this.post();
			this.handler.draw(context);
		}
	}
	
	bool atPosition(double x, double y) {
		return x >= (this.rect.x - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			x <= (this.rect.x + this.rect.width + this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y >= (this.rect.y - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y <= (this.rect.y + this.rect.height + this.handler.controls[Direction.NORTHWEST].size / 2.0);
	}
	
	bool inRegion(double x, double y, double width, double height) {
		if(width < 0) {
			x += width;
			width = -width;
		}
		if(height < 0) {
			y += height;
			height = -height;
		}
		return (x + width) > this.rect.x && (y + height) > this.rect.y &&
			x < (this.rect.x + this.rect.width) && y < (this.rect.y + this.rect.height);
	}
	
	bool inSelection(Selection selection) {
		return this.inRegion(selection.rect.x, selection.rect.y, selection.rect.width, selection.rect.height);
	}
	
	abstract XMLConfig save();
	
	string opIndex(string index) {
		assert(index in this.properties);
		return this.properties[index];
	}
	
	void opIndexAssign(string value, string index) {
		this.firePropertyChanged(index, value);
		this.properties[index] = value;
	}
	
	void addOnPropertyChanged(void delegate(string key, string newValue) del) {
		this.propertyChangedListeners ~= del;
	}
	
	void firePropertyChanged(string key, string newValue) {
		foreach(listener; this.propertyChangedListeners) {
			listener(key, newValue);
		}
	}
	
	void delegate(string, string)[] propertyChangedListeners;
	
	double[] dashToUse() {
		return this.isAbstract ? this.dashDots : this.dashNone;
	}
	
	override string toString() {
		return format("DrawableObject[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction);
	}

	string id;
	string[string] properties;
	
	Rectangle rect;
	Handler handler;
	Rectangle offset;
	Direction direction;
	bool selected, resize;
	
	bool isAbstract;
	
	double[] dashNone;
	double[] dashDots;
	
	ArchitecturalSpecification specification() {
		return this.m_specification;
	}
	
	void specification(ArchitecturalSpecification value) {
		if(this.m_specification != value) {
			this.m_specification = value;
			
			this.fireArchitecturalSpecificationChanged(value);
		}
	}
	
	ArchitecturalSpecification m_specification;
}

abstract class BoxBase: DrawableObject {
	this(string id) {
		super(id);
		this.backColor = "green";
	
		this.dashDots ~= 8.0;
		this.dashDots ~= 4.0;
	}
	
	override void post() {
	    this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.NORTHEAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.NORTHEAST].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.SOUTHWEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.SOUTHWEST].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.NORTH].rect.x = this.rect.x + this.rect.width / 2;
	    this.handler.controls[Direction.NORTH].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.SOUTH].rect.x = this.rect.x + this.rect.width / 2;
	    this.handler.controls[Direction.SOUTH].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.WEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.WEST].rect.y = this.rect.y + this.rect.height / 2;
	    
	    this.handler.controls[Direction.EAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.EAST].rect.y = this.rect.y + this.rect.height / 2;
	}
	
	override void draw(Context context) {
		super.draw(context);
		this.drawBox(context);
	}
	
	abstract void drawBox(Context context);
	
	override string toString() {
		return format("BoxBase[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, backColor=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.backColor);
	}

	gdk.Color.Color color() {
		return CanvasColors[this.backColor];
	}
	
	string backColor;
}

class Text: BoxBase {
	this(string id, string text = "") {
		super(id);
		this.font = "Verdana";
		this.size = 32;
		this.preserve = true;
		this.text = text;
		
		this.addOnArchitecturalSpecificationChanged(delegate void(ArchitecturalSpecification newArchitecturalSpecification) 
			{
				this.text = newArchitecturalSpecification.label;
				this.underline = true;
			});
	}
	
	override void drawBox(Context context) {
		newDrawing(context, 
			{
				PgLayout layout = PgCairo.createLayout(context);
				
				string description = format("%s %d", this.font, this.size);
				
				PgFontDescription font = PgFontDescription.fromString(description);
				layout.setJustify(true);
				layout.setFontDescription(font);
				layout.setMarkup(this.underline ? "<u>" ~ this.text ~ "</u>" : this.text, -1);
				
				context.setSourceRgb(0.0, 0.0, 0.0);
				context.moveTo(this.rect.x, this.rect.y);
				
				if(!this.preserve) {
					int width, height;
					layout.getSize(width, height);
					width /= PANGO_SCALE;
					height /= PANGO_SCALE;
					this.scale(context, width, height);
				}
				else {
					layout.setWidth(cast(int) (this.rect.width) * PANGO_SCALE);
					int width, height;
					layout.getSize(width, height);
					height /= PANGO_SCALE;
					this.rect.height = height;
				}
	
				PgCairo.showLayout(context, layout);
			});
	}
	
	void scale(Context context, double w, double h) {
		if(this.rect.width == 0) {
			this.rect.width = w;
		}
		
		if(this.rect.height == 0) {
			this.rect.height = h;
		}
		
		double scaleX = this.rect.width / w;
		double scaleY = this.rect.height / h;
		
		if(scaleX != 0) {
			context.scale(scaleX, 1.0);
		}
		
		if(scaleY != 0) {
			context.scale(1.0, scaleY);
		}
	}
	
	override XMLConfig save() {
		return TextXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Text[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
	bool underline;
}

class TextXMLSerializer: XMLSerializer!(Text) {
	this() {
	}
	
	override XMLConfig save(Text text) {
		XMLConfig xmlConfig = new XMLConfig("Text");
		xmlConfig["id"] = text.id;
		xmlConfig["x"] = to!(string)(text.rect.x);
		xmlConfig["y"] = to!(string)(text.rect.y);
		xmlConfig["width"] = to!(string)(text.rect.width);
		xmlConfig["height"] = to!(string)(text.rect.height);
		xmlConfig["backColor"] = text.backColor;
		xmlConfig["underline"] = to!(string)(text.underline);
		
		xmlConfig["font"] = text.font;
		xmlConfig["size"] = to!(string)(text.size);
		xmlConfig["preserve"] = to!(string)(text.preserve);
		xmlConfig["text"] = text.text;

		if(text.specification !is null) {
			xmlConfig.entries ~= text.specification.save();
		}
			
		return xmlConfig;
	}
	
	override Text load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		bool underline = to!(bool)(xmlConfig["underline"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string textStr = xmlConfig["text"];
			
		Text text = new Text(id);
		text.rect.x = x;
		text.rect.y = y;
		text.rect.width = width;
		text.rect.height = height;
		text.backColor = backColor;
		text.underline = underline;
		
		text.font = font;
		text.size = size;
		text.preserve = preserve;
		text.text = textStr;
		
		foreach(entry; xmlConfig.entries) {
			string typeName = entry.typeName;
			
			if(typeName == "OoOProcessorCoreSpecification") {
				text.specification = OoOProcessorCoreSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "ICacheSpecification") {
				text.specification = ICacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "DCacheSpecification") {
				text.specification = DCacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "L2CacheSpecification") {
				text.specification = L2CacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyP2PInterconnectSpecification") {
				text.specification = FixedLatencyP2PInterconnectSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyDRAMSpecification") {
				text.specification = FixedLatencyDRAMSpecificationXMLSerializer.singleInstance.load(entry);
			}
			break;
		}
		
		return text;
	}
	
	static this() {
		singleInstance = new TextXMLSerializer();
	}
	
	static TextXMLSerializer singleInstance;
}

class Box: BoxBase {
	this(string id) {
		super(id);
	}
	
	override void drawBox(Context context) {
		context.setDash(this.dashToUse, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		context.setSourceColor(this.color);
		context.fillPreserve();
		context.setSourceColor(gdk.Color.Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return BoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Box[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
}

class BoxXMLSerializer: XMLSerializer!(Box) {
	this() {
	}
	
	override XMLConfig save(Box box) {
		XMLConfig xmlConfig = new XMLConfig("Box");
		xmlConfig["id"] = box.id;
		xmlConfig["x"] = to!(string)(box.rect.x);
		xmlConfig["y"] = to!(string)(box.rect.y);
		xmlConfig["width"] = to!(string)(box.rect.width);
		xmlConfig["height"] = to!(string)(box.rect.height);
		xmlConfig["backColor"] = box.backColor;
		xmlConfig["isAbstract"] = to!(string)(box.isAbstract);
			
		return xmlConfig;
	}
	
	override Box load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
			
		Box box = new Box(id);
		box.rect.x = x;
		box.rect.y = y;
		box.rect.width = width;
		box.rect.height = height;
		box.backColor = backColor;
		box.isAbstract = isAbstract;
		return box;
	}
	
	static this() {
		singleInstance = new BoxXMLSerializer();
	}
	
	static BoxXMLSerializer singleInstance;
}

class RoundedBox: BoxBase {
	this(string id) {
		super(id);
		this.radius = 10;
		this.handler.controls[Direction.END] = new Control();
	}
	
	override void post() {
		super.post();
	    
	    this.handler.controls[Direction.END].rect.x = this.rect.x + this.radius;
	    this.handler.controls[Direction.END].rect.y = this.rect.y + this.radius;
	    this.handler.controls[Direction.END].limbus = true;
	}
	
	override void drawBox(Context context) {
		double _radius = this.radius;
		
		context.setDash(this.dashToUse, 0);
		context.setLineWidth(2.5);
		
		if(_radius > (this.rect.height / 2) || _radius > (this.rect.width / 2)) {
			if((this.rect.height / 2) < (this.rect.width / 2)) {
				_radius = this.rect.height / 2;
			}
			else {
				_radius = this.rect.width / 2;
			}
		}
		
		context.moveTo(this.rect.x, this.rect.y + _radius);
		context.arc(this.rect.x + _radius, this.rect.y + _radius, _radius, PI, -PI / 2);
		context.lineTo(this.rect.x + this.rect.width - _radius, this.rect.y);
		context.arc(this.rect.x + this.rect.width - _radius, this.rect.y + _radius, _radius, -PI / 2, 0);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height - _radius);
		context.arc(this.rect.x + this.rect.width - _radius, this.rect.y + this.rect.height - _radius, _radius, 0, PI / 2);
		context.lineTo(this.rect.x + _radius, this.rect.y + this.rect.height);
		context.arc(this.rect.x + this.radius, this.rect.y + this.rect.height - _radius, _radius, PI / 2, PI);
		context.closePath();
		context.setSourceColor(this.color);
		context.fillPreserve();

		context.setSourceColor(gdk.Color.Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return RoundedBoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("RoundedBox[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s, radius=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
	}
	
	double radius;
}

class RoundedBoxXMLSerializer: XMLSerializer!(RoundedBox) {
	this() {
	}
	
	override XMLConfig save(RoundedBox box) {
		XMLConfig xmlConfig = new XMLConfig("RoundedBox");
		xmlConfig["id"] = box.id;
		xmlConfig["x"] = to!(string)(box.rect.x);
		xmlConfig["y"] = to!(string)(box.rect.y);
		xmlConfig["width"] = to!(string)(box.rect.width);
		xmlConfig["height"] = to!(string)(box.rect.height);
		xmlConfig["backColor"] = box.backColor;
		xmlConfig["radius"] = to!(string)(box.radius);
		xmlConfig["isAbstract"] = to!(string)(box.isAbstract);
			
		return xmlConfig;
	}
	
	override RoundedBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		double radius = to!(double)(xmlConfig["radius"]);
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
			
		RoundedBox roundedBox = new RoundedBox(id);
		roundedBox.rect.x = x;
		roundedBox.rect.y = y;
		roundedBox.rect.width = width;
		roundedBox.rect.height = height;
		roundedBox.backColor = backColor;
		roundedBox.radius = radius;
		roundedBox.isAbstract = isAbstract;
		return roundedBox;
	}
	
	static this() {
		singleInstance = new RoundedBoxXMLSerializer();
	}
	
	static RoundedBoxXMLSerializer singleInstance;
}

class TextBox: Box {
	this(string id, string text = "") {
		super(id);
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
		
		this["hello"] = "world";
		
		this.addOnArchitecturalSpecificationChanged(delegate void(ArchitecturalSpecification newArchitecturalSpecification) 
			{
				this.text = newArchitecturalSpecification.label;
				this.backColor = newArchitecturalSpecification.backColor;
				this.isAbstract = !newArchitecturalSpecification.isCycleAccurate;
			});
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setAlignment(PangoAlignment.CENTER);
		layout.setFontDescription(font);
		layout.setWidth(cast(int) this.rect.width * PANGO_SCALE);
		layout.setHeight(cast(int) this.rect.height * PANGO_SCALE);
		layout.setMarkup(this.underline ? "<u>" ~ this.text ~ "</u>" : this.text, -1);

		context.setSourceColor(gdk.Color.Color.black);
		context.moveTo(this.rect.x, this.rect.y + 10);

		PgCairo.showLayout(context, layout);
	}
	
	override void drawBox(Context context) {
		super.drawBox(context);		
		this.drawText(context);
	}
	
	override XMLConfig save() {
		return TextBoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("TextBox[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
	bool underline;
}

class TextBoxXMLSerializer: XMLSerializer!(TextBox) {
	this() {
	}
	
	override XMLConfig save(TextBox textBox) {
		XMLConfig xmlConfig = new XMLConfig("TextBox");
		xmlConfig["id"] = textBox.id;
		xmlConfig["x"] = to!(string)(textBox.rect.x);
		xmlConfig["y"] = to!(string)(textBox.rect.y);
		xmlConfig["width"] = to!(string)(textBox.rect.width);
		xmlConfig["height"] = to!(string)(textBox.rect.height);
		xmlConfig["backColor"] = textBox.backColor;
		xmlConfig["isAbstract"] = to!(string)(textBox.isAbstract);
		xmlConfig["underline"] = to!(string)(textBox.underline);
		
		xmlConfig["font"] = textBox.font;
		xmlConfig["size"] = to!(string)(textBox.size);
		xmlConfig["preserve"] = to!(string)(textBox.preserve);
		xmlConfig["text"] = textBox.text;

		if(textBox.specification !is null) {
			xmlConfig.entries ~= textBox.specification.save();
		}
			
		return xmlConfig;
	}
	
	override TextBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
		bool underline = to!(bool)(xmlConfig["underline"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		TextBox textBox = new TextBox(id);
		textBox.rect.x = x;
		textBox.rect.y = y;
		textBox.rect.width = width;
		textBox.rect.height = height;
		textBox.backColor = backColor;
		textBox.isAbstract = isAbstract;
		textBox.underline = underline;
		
		textBox.font = font;
		textBox.size = size;
		textBox.preserve = preserve;
		textBox.text = text;
		
		foreach(entry; xmlConfig.entries) {
			string typeName = entry.typeName;
			
			if(typeName == "OoOProcessorCoreSpecification") {
				textBox.specification = OoOProcessorCoreSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "ICacheSpecification") {
				textBox.specification = ICacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "DCacheSpecification") {
				textBox.specification = DCacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "L2CacheSpecification") {
				textBox.specification = L2CacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyP2PInterconnectSpecification") {
				textBox.specification = FixedLatencyP2PInterconnectSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyDRAMSpecification") {
				textBox.specification = FixedLatencyDRAMSpecificationXMLSerializer.singleInstance.load(entry);
			}
			break;
		}
		
		return textBox;
	}
	
	static this() {
		singleInstance = new TextBoxXMLSerializer();
	}
	
	static TextBoxXMLSerializer singleInstance;
}

class RoundedTextBox: RoundedBox {
	this(string id, string text = "") {
		super(id);
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
		
		this.addOnArchitecturalSpecificationChanged(delegate void(ArchitecturalSpecification newArchitecturalSpecification) 
			{
				this.text = newArchitecturalSpecification.label;
				this.backColor = newArchitecturalSpecification.backColor;
				this.isAbstract = !newArchitecturalSpecification.isCycleAccurate;
			});
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setAlignment(PangoAlignment.CENTER);
		layout.setFontDescription(font);
		layout.setWidth(cast(int) this.rect.width * PANGO_SCALE);
		layout.setHeight(cast(int) this.rect.height * PANGO_SCALE);
		layout.setMarkup(this.underline ? "<u>" ~ this.text ~ "</u>" : this.text, -1);

		context.setSourceColor(gdk.Color.Color.black);
		context.moveTo(this.rect.x, this.rect.y + 10);

		PgCairo.showLayout(context, layout);
	}
	
	override void drawBox(Context context) {
		super.drawBox(context);		
		this.drawText(context);
	}
	
	override XMLConfig save() {
		return RoundedTextBoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("RoundedTextBox[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s, radius=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
	bool underline;
}

class RoundedTextBoxXMLSerializer: XMLSerializer!(RoundedTextBox) {
	this() {
	}
	
	override XMLConfig save(RoundedTextBox roundedTextBox) {
		XMLConfig xmlConfig = new XMLConfig("RoundedTextBox");
		xmlConfig["id"] = roundedTextBox.id;
		xmlConfig["x"] = to!(string)(roundedTextBox.rect.x);
		xmlConfig["y"] = to!(string)(roundedTextBox.rect.y);
		xmlConfig["width"] = to!(string)(roundedTextBox.rect.width);
		xmlConfig["height"] = to!(string)(roundedTextBox.rect.height);
		xmlConfig["backColor"] = roundedTextBox.backColor;
		xmlConfig["radius"] = to!(string)(roundedTextBox.radius);
		xmlConfig["isAbstract"] = to!(string)(roundedTextBox.isAbstract);
		xmlConfig["underline"] = to!(string)(roundedTextBox.underline);
		
		xmlConfig["font"] = roundedTextBox.font;
		xmlConfig["size"] = to!(string)(roundedTextBox.size);
		xmlConfig["preserve"] = to!(string)(roundedTextBox.preserve);
		xmlConfig["text"] = roundedTextBox.text;

		if(roundedTextBox.specification !is null) {
			xmlConfig.entries ~= roundedTextBox.specification.save();
		}
			
		return xmlConfig;
	}
	
	override RoundedTextBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		double radius = to!(double)(xmlConfig["radius"]);
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
		bool underline = to!(bool)(xmlConfig["underline"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		RoundedTextBox roundedTextBox = new RoundedTextBox(id);
		roundedTextBox.rect.x = x;
		roundedTextBox.rect.y = y;
		roundedTextBox.rect.width = width;
		roundedTextBox.rect.height = height;
		roundedTextBox.backColor = backColor;
		roundedTextBox.radius = radius;
		roundedTextBox.isAbstract = isAbstract;
		roundedTextBox.underline = underline;
		
		roundedTextBox.font = font;
		roundedTextBox.size = size;
		roundedTextBox.preserve = preserve;
		roundedTextBox.text = text;
		
		foreach(entry; xmlConfig.entries) {
			string typeName = entry.typeName;
			
			if(typeName == "OoOProcessorCoreSpecification") {
				roundedTextBox.specification = OoOProcessorCoreSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "ICacheSpecification") {
				roundedTextBox.specification = ICacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "DCacheSpecification") {
				roundedTextBox.specification = DCacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "L2CacheSpecification") {
				roundedTextBox.specification = L2CacheSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyP2PInterconnectSpecification") {
				roundedTextBox.specification = FixedLatencyP2PInterconnectSpecificationXMLSerializer.singleInstance.load(entry);
			}
			else if(typeName == "FixedLatencyDRAMSpecification") {
				roundedTextBox.specification = FixedLatencyDRAMSpecificationXMLSerializer.singleInstance.load(entry);
			}
			break;
		}
		
		return roundedTextBox;
	}
	
	static this() {
		singleInstance = new RoundedTextBoxXMLSerializer();
	}
	
	static RoundedTextBoxXMLSerializer singleInstance;
}

class Line: DrawableObject {
	this(string id) {
		super(id);
		this.handler.line = true;
		this.thickness = 2.5;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
		this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
		
		this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
		this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y +  this.rect.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dashToUse, 0);
		context.setLineWidth(this.thickness);
		context.moveTo(this.rect.x, this.rect.y);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height);
		context.setSourceColor(gdk.Color.Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return LineXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Line[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, thickness=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.thickness);
	}
	
	double thickness;
}

class LineXMLSerializer: XMLSerializer!(Line) {
	this() {
	}
	
	override XMLConfig save(Line line) {
		XMLConfig xmlConfig = new XMLConfig("Line");
		xmlConfig["id"] = line.id;
		xmlConfig["x"] = to!(string)(line.rect.x);
		xmlConfig["y"] = to!(string)(line.rect.y);
		xmlConfig["width"] = to!(string)(line.rect.width);
		xmlConfig["height"] = to!(string)(line.rect.height);
		xmlConfig["isAbstract"] = to!(string)(line.isAbstract);
			
		return xmlConfig;
	}
	
	override Line load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
			
		Line line = new Line(id);
		line.rect.x = x;
		line.rect.y = y;
		line.rect.width = width;
		line.rect.height = height;
		line.isAbstract = isAbstract;
		return line;
	}
	
	static this() {
		singleInstance = new LineXMLSerializer();
	}
	
	static LineXMLSerializer singleInstance;
}

enum ArrowHeadStyle: string {
	NONE = "NONE",
	SOLID = "SOLID"
}

class ArrowHead {
	this(ArrowHeadStyle style = ArrowHeadStyle.SOLID) {
		this.length = 5;
		this.degrees = 0.5;
		this.style = style;
	}
	
	void draw(Context context, double startX, double startY, double endX, double endY) {	
		if(this.style == ArrowHeadStyle.SOLID) {
			double angle = atan2(endY - startY, endX - startX) + PI;
		
			double x1 = endX + this.length * cos(angle - this.degrees);
			double y1 = endY + this.length * sin(angle - this.degrees);
			double x2 = endX + this.length * cos(angle + this.degrees);
			double y2 = endY + this.length * sin(angle + this.degrees);
			
			context.moveTo(endX, endY);
			context.lineTo(x1, y1);
			context.lineTo(x2, y2);
			context.closePath();
	
			context.setSourceColor(gdk.Color.Color.black);
			context.strokePreserve();
	
			context.fill();
		}
	}
	
	double length, degrees;
	ArrowHeadStyle style;
}

class Arrow: DrawableObject {	
	this(string id) {
		super(id);
		this.handler.line = true;
		this.thickness = 2.5;
		
		this.startHead = new ArrowHead(ArrowHeadStyle.NONE);
		this.endHead = new ArrowHead(ArrowHeadStyle.SOLID);
	}
	
	ArrowHeadStyle startHeadStyle() {
		return this.startHead.style;
	}
	
	void startHeadStyle(ArrowHeadStyle value) {
		this.startHead.style = value;
	}
	
	ArrowHeadStyle endHeadStyle() {
		return this.endHead.style;
	}
	
	void endHeadStyle(ArrowHeadStyle value) {
		this.endHead.style = value;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
		this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
		
		this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
		this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y +  this.rect.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dashToUse, 0);
		context.setLineWidth(this.thickness);
		context.moveTo(this.rect.x, this.rect.y);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height);
		context.setSourceColor(gdk.Color.Color.black);
		context.stroke();
		
		this.startHead.draw(context, this.rect.x + this.rect.width, this.rect.y + this.rect.height, this.rect.x, this.rect.y);
		this.endHead.draw(context, this.rect.x, this.rect.y, this.rect.x + this.rect.width, this.rect.y + this.rect.height);
	}
	
	override XMLConfig save() {
		return ArrowXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Arrow[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, thickness=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.thickness);
	}
	
	double thickness;
	
	ArrowHead startHead, endHead;
}

class ArrowXMLSerializer: XMLSerializer!(Arrow) {
	this() {
	}
	
	override XMLConfig save(Arrow arrow) {
		XMLConfig xmlConfig = new XMLConfig("Arrow");
		xmlConfig["id"] = arrow.id;
		xmlConfig["x"] = to!(string)(arrow.rect.x);
		xmlConfig["y"] = to!(string)(arrow.rect.y);
		xmlConfig["width"] = to!(string)(arrow.rect.width);
		xmlConfig["height"] = to!(string)(arrow.rect.height);
		xmlConfig["isAbstract"] = to!(string)(arrow.isAbstract);
		
		xmlConfig["startHeadStyle"] = to!(string)(arrow.startHeadStyle);
		xmlConfig["endHeadStyle"] = to!(string)(arrow.endHeadStyle);
			
		return xmlConfig;
	}
	
	override Arrow load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		bool isAbstract = to!(bool)(xmlConfig["isAbstract"]);
		
		ArrowHeadStyle startHeadStyle = cast(ArrowHeadStyle) (xmlConfig["startHeadStyle"]);
		ArrowHeadStyle endHeadStyle = cast(ArrowHeadStyle) (xmlConfig["endHeadStyle"]);
			
		Arrow arrow = new Arrow(id);
		arrow.rect.x = x;
		arrow.rect.y = y;
		arrow.rect.width = width;
		arrow.rect.height = height;
		arrow.isAbstract = isAbstract;
		
		arrow.startHeadStyle = startHeadStyle;
		arrow.endHeadStyle = endHeadStyle;
		return arrow;
	}
	
	static this() {
		singleInstance = new ArrowXMLSerializer();
	}
	
	static ArrowXMLSerializer singleInstance;
}

class Canvas: DrawingArea {
	this() {		
		this.setAppPaintable(true);
		
		this.paper = new Paper();
		this.origin.x = this.origin.y = 0;
		this.grid = new Grid();
		this.selection = new Selection();
		this.cursorSet = new CursorSet();
		
		this.total.width = this.total.height = 0;
		
		this.border = 10;
		
		this.pick = false;
		this.selectedChild = null;

		/*this.addEvents(GdkEventMask.BUTTON_PRESS_MASK);
		this.addEvents(GdkEventMask.BUTTON_RELEASE_MASK);
		this.addEvents(GdkEventMask.POINTER_MOTION_MASK);
		this.addEvents(GdkEventMask.BUTTON_MOTION_MASK);
		
		this.addOnExpose(&this.exposed);
		this.addOnButtonPress(&this.buttonPressed);
		this.addOnButtonRelease(&this.buttonReleased);
		this.addOnMotionNotify(&this.motionNotified);
		
		this.addOnDragDataReceived(&this.dragDataReceived);
		
		this.addOnSelected(delegate void(DrawableObject child)
			{
				this.selectedChild = child;
			});*/
		
		this.paper.rect.x = 5;
		this.paper.rect.y = 5;
		this.paper.rect.width = 800;
		this.paper.rect.height = 650;
		
		this.paper.top = 5;
		this.paper.left = 5;
		this.paper.bottom = 5;
		this.paper.right = 5;
		
		this.grid.snap = true;
	}
	
	void dragDataReceived(GdkDragContext* context, gint x, gint y, GtkSelectionData* data, guint info, guint time, Widget widget) {
		Widget toolItem = this.frameDrawingManager.palette.getDragItem(data);
		if(toolItem !is null) {
			ToolButton toolButton = cast(ToolButton) toolItem;
			string actionName = toolButton.getActionName();
			ArchitecturalSpecification specificationToAssign = null;
			
			double _x = x - this.origin.x;
			double _y = y - this.origin.y;
			
			foreach(child; this.children) {
				if(child.atPosition(_x, _y)) {
					if(cast(Text) child !is null) {
						Text text = cast(Text) child;
						if(actionName == "archSharedCacheMulticore") {
							this.specification = new SharedCacheMulticoreSpecification();
							this.specification.drawableObjectId = child.id;
							specificationToAssign = this.specification;
						}
						
						if(specificationToAssign !is null) {
							text.specification = specificationToAssign;
							this.fireArchitecturalSpecificationAssociated(text, text.specification);
						}
						
						break;
					}
					else if(cast(TextBox) child !is null) {
						TextBox textBox = cast(TextBox) child;
						if(actionName == "cpuSimple") {
							specificationToAssign = new SimpleProcessorCoreSpecification();
						}
						else if(actionName == "cpuOoO") {
							specificationToAssign = new OoOProcessorCoreSpecification();
						}
						else if(actionName == "cacheL1I") {
							specificationToAssign = new ICacheSpecification();
						}
						else if(actionName == "cacheL1D") {
							specificationToAssign = new DCacheSpecification();
						}
						else if(actionName == "cacheL2") {
							specificationToAssign = new L2CacheSpecification();
						}
						else if(actionName == "interconnectFixedP2P") {
							specificationToAssign = new FixedLatencyP2PInterconnectSpecification();
						}
						else if(actionName == "dramFixed") {
							specificationToAssign = new FixedLatencyDRAMSpecification();
						}
						
						if(specificationToAssign !is null) {
							specificationToAssign.drawableObjectId = child.id;
							textBox.specification = specificationToAssign;
							this.fireArchitecturalSpecificationAssociated(textBox, textBox.specification);
						}
						
						break;
					}
				}
			}
		}
		
		this.queueDraw();
	}
	
	void addOnArchitecturalSpecificationAssociated(void delegate(DrawableObject child, ArchitecturalSpecification specification) del) {
		this.specificationAssociatedListeners ~= del;
	}
	
	void fireArchitecturalSpecificationAssociated(DrawableObject child, ArchitecturalSpecification specification) {
		foreach(listener; this.specificationAssociatedListeners) {
			listener(child, specification);
		}
	}
	
	void delegate(DrawableObject, ArchitecturalSpecification)[] specificationAssociatedListeners;
	
	void addOnSelected(void delegate(DrawableObject child) del) {
		this.selectedListeners ~= del;
	}
	
	void fireSelected(DrawableObject child) {
		foreach(listener; this.selectedListeners) {
			listener(child);
		}
	}
	
	void delegate(DrawableObject)[] selectedListeners;
	
	void addOnArchitecturalSpecificationChanged(void delegate(SharedCacheMulticoreSpecification specification) del) {
		this.specificationChangedListeners ~= del;
	}
	
	void fireArchitecturalSpecificationChanged(SharedCacheMulticoreSpecification specification) {
		foreach(listener; this.specificationChangedListeners) {
			listener(specification);
		}
	}
	
	void delegate(SharedCacheMulticoreSpecification)[] specificationChangedListeners;
	
	bool exposed(GdkEventExpose* event, Widget widget) {
		this.context = new Context(this.getWindow());
		
		double width = event.area.width;
		double height = event.area.height;
		
		this.total.width = this.paper.rect.width + 2 * this.border;
		this.total.height = this.paper.rect.height + 2 * this.border;
		
		if(width < this.total.width) {
			width = this.total.width;
		}
		
		if(height < this.total.height) {
			height = this.total.height;
		}
		
		this.setSizeRequest(cast(int) width, cast(int) height);
		
		context.setSourceRgb(0.75, 0.75, 0.75);
		context.paint();
		
		this.paper.rect.x = (width - this.paper.rect.width) / 2;
		this.paper.rect.y = (height - this.paper.rect.height) / 2;
		
		if(this.paper.rect.x < this.border) {
			this.paper.rect.x = this.border;
		}
		
		if(this.paper.rect.y < this.border) {
			this.paper.rect.y = this.border;
		}
		
		this.paper.draw(context);
		
		this.origin.x = this.paper.rect.x + this.paper.left;
		this.origin.y = this.paper.rect.y + this.paper.top;
		
		if(this.grid.active) {
			this.grid.rect.x = this.origin.x;
			this.grid.rect.y = this.origin.y;
			this.grid.rect.width = this.paper.rect.width - this.paper.left - this.paper.right;
			this.grid.rect.height = this.paper.rect.height - this.paper.top - this.paper.bottom;
			this.grid.draw(context);
		}
		
		foreach(child; this.children) {
			child.rect.x += this.origin.x;
			child.rect.y += this.origin.y;
			child.draw(context);
			child.rect.x -= this.origin.x;
			child.rect.y -= this.origin.y;
		}
		
		if(this.selection.active) {
			this.selection.rect.x += this.origin.x;
			this.selection.rect.y += this.origin.y;
			this.selection.draw(context);
			this.selection.rect.x -= this.origin.x;
			this.selection.rect.y -= this.origin.y;
		}
		
		Effect[] effectsToRemove;
		
		foreach(effect; this.effects) {
			effect.draw(context);
			if(!effect.active) {
				effectsToRemove ~= effect;
			}
		}
		
		foreach(effectToRemove; effectsToRemove) {
			int indexToRemove = this.effects.indexOf(effectToRemove);
			this.effects = this.effects.remove(indexToRemove);
		}
		
		return true;
	}
	
	bool buttonPressed(GdkEventButton* event, Widget widget) {
		event.x -= this.origin.x;
		event.y -= this.origin.y;
		
		if(this.pick) {
			foreach(child; this.children) {
				child.selected = false;
			}
			
			int x, y;
			this.getPointer(x, y);
			
			DrawableObject child = this.childToAdd;
			child.selected = true;
			this.fireSelected(child);
			child.resize = true;
			child.rect.x = this.grid.nearest(event.x);
			child.rect.y = this.grid.nearest(event.y);
			child.rect.width = 0;
			child.rect.height = 0;
			this.add(child);
			
			child.offset.x = event.x;
			child.offset.y = event.y;
			child.offset.width = child.rect.width;
			child.offset.height = child.rect.height;
			
			child.direction = Direction.SOUTHEAST;
			child.handler.controls[child.direction].offset.x = event.x - child.rect.x;
			child.handler.controls[child.direction].offset.y = event.y - child.rect.y;
			
			return true;
		}
		
		bool selected = false;
		bool move = false;
		bool resize = false;
		
		foreach(child; this.children) {
			if(child.atPosition(event.x, event.y)) {
				if(child.selected) {
					move = true;
				}
				selected = true;
				child.selected = true;
				if(child.handler.atPosition(event.x + this.origin.x, event.y + this.origin.y)) {
					child.offset.x = event.x;
					child.offset.y = event.y;
					child.offset.width = child.rect.width;
					child.offset.height = child.rect.height;
					child.resize = true;
					child.direction = child.handler.getDirection(event.x + this.origin.x, event.y + this.origin.y);
					child.handler.controls[child.direction].offset.x = event.x - child.rect.x;
					child.handler.controls[child.direction].offset.y = event.y - child.rect.y;
					resize = true;
				}
				break;
			}
		}
		
		if(!resize) {
			foreach(child; this.children) {
				child.resize = false;
				if(child.selected) {
					child.offset.x = event.x - child.rect.x;
					child.offset.y = event.y - child.rect.y;
					if(!child.atPosition(event.x, event.y) && !move && !(event.state & ModifierType.CONTROL_MASK) ||
						child.atPosition(event.x, event.y) && move && event.state & ModifierType.CONTROL_MASK) {
						child.selected = false;
					}
					else {
						child.selected = true;
						this.fireSelected(child);
					}
				}
			}
			
			if(!selected && !move) {
				this.selection.rect.x = event.x;
				this.selection.rect.y = event.y;
				this.selection.rect.width = 0;
				this.selection.rect.height = 0;
				this.selection.active = true;
			}
			
			this.queueDraw();
		}
		
		return true;
	}
	
	bool buttonReleased(GdkEventButton* event, Widget widget) {
		if(this.selection.active) {
			foreach(child; this.children) {
				if(child.inSelection(this.selection)) {
					child.selected = true;
					this.fireSelected(child);
				}
			}
			this.selection.active = false;
		}
		
		this.pick = false;
		this.getWindow().setCursor(this.cursorSet.normal);
		
		this.queueDraw();
		
		return true;
	}
	
	bool motionNotified(GdkEventMotion* event, Widget widget) {		
		double x = event.x - this.origin.x;
		double y = event.y - this.origin.y;
		
		this.setTooltipText("");

		foreach(child; this.children) {
			if(child.atPosition(x, y)) {
				this.setTooltipText(child.specification !is null ? child.specification.id : "(" ~ child.id ~ ")");
				break;
			}
		}
		
		Direction direction = Direction.NONE;
		if(!(event.state & ModifierType.BUTTON1_MASK)) {
			foreach(child; this.children) {
				if(child.atPosition(x, y)) {
					if(child.selected) {
						if(child.handler.atPosition(x + this.origin.x, y + this.origin.y)) {
							direction = child.handler.getDirection(x + this.origin.x, y + this.origin.y);
							break;
						}
					}
				}
			}
		}
		
		if(direction != Direction.NONE) {
			if(direction == Direction.NORTHWEST) {
				this.getWindow().setCursor(this.cursorSet.northwest);
			}
			else if(direction == Direction.NORTH) {
				this.getWindow().setCursor(this.cursorSet.north);
			}
			else if(direction == Direction.NORTHEAST) {
				this.getWindow().setCursor(this.cursorSet.northeast);
			}
			else if(direction == Direction.WEST) {
				this.getWindow().setCursor(this.cursorSet.west);
			}
			else if(direction == Direction.EAST) {
				this.getWindow().setCursor(this.cursorSet.east);
			}
			else if(direction == Direction.SOUTHWEST) {
				this.getWindow().setCursor(this.cursorSet.southwest);
			}
			else if(direction == Direction.SOUTH) {
				this.getWindow().setCursor(this.cursorSet.south);
			}
			else if(direction == Direction.SOUTHEAST) {
				this.getWindow().setCursor(this.cursorSet.southeast);
			}
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
			this.getWindow().setCursor(this.cursorSet.move);
		}
		else if(this.pick) {
			this.getWindow().setCursor(this.cursorSet.cross);
		}
		else {
			this.getWindow().setCursor(this.cursorSet.normal);
		}

		if(this.selection.active) {
			this.selection.rect.width = x - this.selection.rect.x;
			this.selection.rect.height = y - this.selection.rect.y;
			
			this.queueDraw();
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
			foreach(child; this.children) {
				if(child.selected) {
					if(child.resize) {
						if(child.direction == Direction.EAST) {
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
						}
						else if(child.direction == Direction.NORTH) {
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTH].offset.y);
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.SOUTH) {
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.WEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.WEST].offset.x);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
						}
						else if(child.direction == Direction.SOUTHEAST) {
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.SOUTHWEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.SOUTHWEST].offset.x);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.NORTHEAST) {
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHEAST].offset.y);
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.NORTHWEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.NORTHWEST].offset.x);
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHWEST].offset.y);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.END) {
							child.handler.controls[Direction.END].rect.x = this.grid.nearest(x - child.handler.controls[Direction.END].offset.x);
							child.handler.controls[Direction.END].rect.y = this.grid.nearest(y - child.handler.controls[Direction.END].offset.y);
						}
					}
					else {
						child.rect.x = this.grid.nearest(x - child.offset.x);
						child.rect.y = this.grid.nearest(y - child.offset.y);
					}
					
					this.queueDraw();
				}
			}
		}
		
		return true;
	}
	
	void add(DrawableObject childToAdd) {
		foreach(child; this.children) {
			assert(child.id != childToAdd.id);
		}
		
		this.children ~= childToAdd;
	}
	
	void create(DrawableObject child) {
		this.pick = true;
		this.childToAdd = child;
		
		this.effects ~= new PuffEffect(this);
	}
	
	void cutSelected() {
		writefln("cutSelected");
	}
	
	void copySelected() {
		writefln("copySelected");
	}
	
	void paste() {
		writefln("paste");
	}
	
	void deleteSelected() {
		DrawableObject[] childrenToDelete;
		
		foreach(child; this.children) {
			if(child.selected) {
				childrenToDelete ~= child;
			}
		}
		
		foreach(childToDelete; childrenToDelete) {
			int index = this.children.indexOf(childToDelete);
			this.children = this.children.remove(index);
		}
		
		if(childrenToDelete.length > 0) {
			this.queueDraw();
		}
	}
	
	void exportToPdf(string fileName) {
		Surface surface = PdfSurface.create(fileName, this.paper.rect.width, this.paper.rect.height);
		Context context = Context.create(surface);
		foreach(child; this.children) {
			bool selected = child.selected;
			child.selected = false;
			child.rect.x += this.paper.left;
			child.rect.y += this.paper.top;
			child.draw(context);
			child.rect.x -= this.paper.left;
			child.rect.y -= this.paper.top;
			child.selected = selected;
		}
		surface.finish();
		context.showPage();
	}
	
	override string toString() {
		return format("Canvas[origin=%s, total=%s, border=%f, pick=%s, childToAdd=%s]",
			this.origin, this.total, this.border, this.pick, this.childToAdd);
	}
	
	static Canvas loadXML(string cwd = "../configs/ise", string fileName = "layout" ~ ".xml") {
		return CanvasXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(Canvas canvas, string cwd = "../configs/ise", string fileName = "layout" ~ ".xml") {
		CanvasXMLFileSerializer.singleInstance.saveXML(canvas, join(cwd, fileName));
	}
	
	DrawableObject getDrawableObject(string id) {
		foreach(child; this.children) {
			if(child.id == id) {
				return child;
			}
		}
		
		assert(0);
	}
	
	DrawableObject getDrawableObjectFromSpecificationId(string specificationId) {
		foreach(child; this.children) {
			if(child.specification !is null && child.specification.id == specificationId) {
				return child;
			}
		}

		return null;
	}
	
	T getSpecification(T)(string specificationId) {
		foreach(child; this.children) {
			if(child.specification !is null && child.specification.id == specificationId) {
				return cast(T) (child.specification);
			}
		}

		return null;
	}
	
	Paper paper;
	Point origin;
	Grid grid;
	Selection selection;
	CursorSet cursorSet;
	DrawableObject[] children;
	Size total;
	double border;
	bool pick;
	DrawableObject childToAdd, selectedChild;
	
	Context context;
	
	Effect[] effects;
	
	FrameDrawingManager frameDrawingManager;
	
	SharedCacheMulticoreSpecification specification() {
		return this.m_specification;
	}
	
	void specification(SharedCacheMulticoreSpecification value) {
		if(this.m_specification != value) {
			this.m_specification = value;
			
			this.fireArchitecturalSpecificationChanged(value);
		}
	}
	
	SharedCacheMulticoreSpecification m_specification;
}

class CanvasXMLFileSerializer: XMLFileSerializer!(Canvas) {
	this() {
	}
	
	override XMLConfigFile save(Canvas canvas) {
		XMLConfigFile xmlConfigFile = new XMLConfigFile("Canvas");
		//xmlConfigFile["x"] = to!(string)(canvas.x);
		
		foreach(child; canvas.children) {
			xmlConfigFile.entries ~= child.save();
		}
		
		if(canvas.specification !is null) {
			xmlConfigFile.entries ~= canvas.specification.save();
		}
			
		return xmlConfigFile;
	}
	
	override Canvas load(XMLConfigFile xmlConfigFile) {
		//double x = to!(double)(xmlConfigFile["x"]);
			
		Canvas canvas = new Canvas();
		//canvas.x = x;
		
		foreach(entry; xmlConfigFile.entries) {
			string typeName = entry.typeName;
			
			if(typeName == "Text") {
				canvas.add(TextXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "Box") {
				canvas.add(BoxXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "RoundedBox") {
				canvas.add(RoundedBoxXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "TextBox") {
				canvas.add(TextBoxXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "RoundedTextBox") {
				canvas.add(RoundedTextBoxXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "Line") {
				canvas.add(LineXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "Arrow") {
				canvas.add(ArrowXMLSerializer.singleInstance.load(entry));
			}
			else if(typeName == "SharedCacheMulticoreSpecification") {
				canvas.specification = SharedCacheMulticoreSpecificationXMLFileSerializer.singleInstance.load(entry);
			}
			else {
				assert(0, typeName);
			}
		}
		
		foreach(child; canvas.children) {
			if(child.specification !is null) {
				child.specification.canvas = canvas;
			}
		}
		
		if(canvas.specification !is null) {
			canvas.specification.canvas = canvas;
		}
		
		return canvas;
	}
	
	static this() {
		singleInstance = new CanvasXMLFileSerializer();
	}
	
	static CanvasXMLFileSerializer singleInstance;
}

class Effect {
	this(Canvas canvas) {
		this.canvas = canvas;
		this.active = true;
	}
	
	abstract void draw(Context context);
	
	Canvas canvas;
	bool active;
}

class PuffEffect: Effect {
	this(Canvas canvas) {
		super(canvas);
		
		this.alpha = 1.0;
		this.size = 1.0;
			
		Timeout timeout = new Timeout(5, delegate  bool()
		{
			if(!this.active) {
				return false;
			}
			
			this.canvas.queueDraw();
			return true;
		}, true);
	}
	
	override void draw(Context context) {
		double w = this.canvas.getAllocation().width;
		double h = this.canvas.getAllocation().height;
		
		context.selectFontFace("Courier", cairo_font_slant_t.NORMAL, cairo_font_weight_t.BOLD);
		
		this.size = this.size + 3.8;
		
		if(this.size > 10) {
			this.alpha = this.alpha - 0.1;
		}
		
		context.setFontSize(this.size);
		context.setSourceRgb(0, 0, 0);
		
		cairo_text_extents_t extents;
		context.textExtents("ZetCode", &extents);
		
		context.moveTo(w/2 - extents.width/2, h/2);
		context.textPath("ZetCode");
		context.clip();
		context.stroke();
		context.paintWithAlpha(this.alpha);
		
		if(this.alpha <= 0) {
			this.active = false;
		}
	}
	
	double alpha, size;
}

class FrameDrawingManager {
	this() {
		GladeFile gladeFile = new GladeFile("mainWindow");
		this.builder = gladeFile.builder;
		
		this.frameDrawing = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameDrawing");
					
		this.canvas = Canvas.loadXML();
		this.canvas.frameDrawingManager = this;
		
		this.buildToolbar();
		this.buildCanvas();
		
		VBox vboxCenter = new VBox(false, 0);
		vboxCenter.packStart(this.toolbarDrawableObjects, false, false, 0);
		vboxCenter.packStart(this.tableCanvas, true, true, 0);
		
		this.frameDrawing.add(vboxCenter);
		
		this.setupPalette();
		this.populatePalette();
		this.buildPropertiesView();
	}
		
	void buildToolbar() {
		this.toolbarDrawableObjects = new Toolbar();
		this.toolbarDrawableObjects.setOrientation(GtkOrientation.HORIZONTAL);
		this.toolbarDrawableObjects.setStyle(GtkToolbarStyle.BOTH_HORIZ);
		
		int position = 0;

		string TEXT = registerStockId("text", "Text", "X");
		string BOX = registerStockId("box", "Box", "X");
		string TEXT_BOX = registerStockId("text_box", "Text Box", "X");
		string LINE = registerStockId("line", "Line", "X");
		
		ToolButton toolButtonText = new ToolButton(TEXT);
		toolButtonText.setTooltipText("Text");
		bindToolButton(toolButtonText, 
			{
				Text child = new Text(format("text%d", this.canvas.children.length), "Insert text here");
				child.size = 12;
				this.canvas.create(child);
			});
		
		ToolButton toolButtonBox = new ToolButton(BOX);
		toolButtonBox.setTooltipText("Box");
		bindToolButton(toolButtonBox, 
			{
				Box child = new Box(format("box%d", this.canvas.children.length));
				this.canvas.create(child);
			});
			
		ToolButton toolButtonTextBox = new ToolButton(TEXT_BOX);
		toolButtonTextBox.setTooltipText("Text Box");
		bindToolButton(toolButtonTextBox, 
			{
				TextBox child = new TextBox(format("textBox%d", this.canvas.children.length), "Insert text here");
				this.canvas.create(child);
			});
		
		ToolButton toolButtonLine = new ToolButton(LINE);
		toolButtonLine.setTooltipText("Line");
		bindToolButton(toolButtonLine, 
			{
				Line child = new Line(format("Line%d", this.canvas.children.length));
				this.canvas.create(child);
			});

		this.toolbarDrawableObjects.insert(toolButtonText, position++);
		this.toolbarDrawableObjects.insert(toolButtonBox, position++);
		this.toolbarDrawableObjects.insert(toolButtonTextBox, position++);
		this.toolbarDrawableObjects.insert(toolButtonLine, position++);
	}
	
	void buildCanvas() {
		this.tableCanvas = new Table(3, 3, false);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		this.tableCanvas.attach(scrolledWindow, 1, 2, 1, 2, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, 4, 4);
		
		scrolledWindow.addWithViewport(this.canvas);
	}
	
	void setupPalette() {
		this.palette = new ToolPalette();
		this.palette.setIconSize(IconSize.DND);
		
		this.palette.addDragDest(this.canvas, GtkDestDefaults.ALL, GtkToolPaletteDragTargets.ITEMS, GdkDragAction.ACTION_COPY);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.NEVER, GtkPolicyType.AUTOMATIC);
		scrolledWindow.setBorderWidth(6);
		
		scrolledWindow.add(this.palette);
		
		VBox vboxLeftTop = getBuilderObject!(VBox, GtkVBox)(builder, "vboxLeftTop");
		vboxLeftTop.packStart(scrolledWindow, true, true, 0);
	}
	
	void populatePalette() {		
		ToolItemGroup groupArchitectures = addItemGroup(this.palette, "Architectures");
		string ARCH_SHARED_CACHE_MULTICORE = registerStockId("archSharedCacheMulticore", "Shared Cache Multicore", "X", "../res/canvas/arch_shared_cache_multicore.svg");
		addItem(groupArchitectures, ARCH_SHARED_CACHE_MULTICORE, "archSharedCacheMulticore", "Shared Cache Multicore Architecture");
			
		ToolItemGroup groupProcessorCores = addItemGroup(this.palette, "Processor Cores");
		string CPU_SIMPLE = registerStockId("cpuSimple", "Simple CPU", "X", "../res/canvas/cpu_simple.svg");
		string CPU_OOO = registerStockId("cpuOOO", "OoO CPU", "X", "../res/canvas/cpu_ooo.svg");
		addItem(groupProcessorCores, CPU_SIMPLE, "cpuSimple", "Simple CPU Core");
		addItem(groupProcessorCores, CPU_OOO, "cpuOoO", "Out-of-Order CPU Core");
		
		ToolItemGroup groupCaches = addItemGroup(this.palette, "Memory Hierarchy Objects");
		string CACHE_L1I = registerStockId("cacheL1I", "L1 Instruction Cache", "X", "../res/canvas/cache_l1i.svg");
		string CACHE_L1D = registerStockId("cacheL1d", "L1 Data Cache", "X", "../res/canvas/cache_l1d.svg");
		string CACHE_L2 = registerStockId("cacheL2", "Shared L2 Cache", "X", "../res/canvas/cache_l2.svg");
		string DRAM_FIXED = registerStockId("dramFixed", "Fixed Latency DRAM", "X", "../res/canvas/dram_fixed.svg");
		addItem(groupCaches, CACHE_L1I, "cacheL1I", "L1 Instruction Cache");
		addItem(groupCaches, CACHE_L1D, "cacheL1D", "L1 Data Cache");
		addItem(groupCaches, CACHE_L2, "cacheL2", "Shared L2 Cache");
		addItem(groupCaches, DRAM_FIXED, "dramFixed", "Fixed Latency DRAM");
		
		ToolItemGroup groupInterconnects = addItemGroup(this.palette, "Interconnects");
		string INTERCONNECT_FIXED_P2P = registerStockId("interconnectFixedP2P", "Fixed Latency P2P Interconnect", "X", "../res/canvas/interconnect_fixed_p2p.svg");			
		addItem(groupInterconnects, INTERCONNECT_FIXED_P2P, "interconnectFixedP2P", "Fixed Latency P2P Interconnect");
	}
	
	void buildPropertiesView() {
		VBox vboxLeftBottom = getBuilderObject!(VBox, GtkVBox)(builder, "vboxLeftBottom");
			
		vboxLeftBottom.packStart(new Label("Simulated Architecture"), false, false, 0);

		TreeViewArchitecturalSpecificationProperties treeViewNodeProperties = new TreeViewArchitecturalSpecificationProperties(this.canvas);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		scrolledWindow.add(treeViewNodeProperties);
		
		vboxLeftBottom.packStart(scrolledWindow, true, true, 0);
		
		canvas.addOnSelected(delegate void(DrawableObject child) {
			//treeViewNodeProperties.data = child.properties;
			//treeViewNodeProperties.refreshList();
		});
	}
	
	Frame frameDrawing;
	Toolbar toolbarDrawableObjects;
	Table tableCanvas;
	Canvas canvas;
	ToolPalette palette;
	
	Builder builder;
}

class TreeViewArchitecturalSpecificationProperties: TreeView {
	bool delegate(string)[string] rowToActionMappings;
	
	this(Canvas canvas) {
		this.canvas = canvas;
		this.canvas.addOnArchitecturalSpecificationChanged(delegate void(SharedCacheMulticoreSpecification specification)
			{
				this.populate();
			});
			
		this.canvas.addOnArchitecturalSpecificationAssociated(delegate void(DrawableObject child, ArchitecturalSpecification specification)
			{
				this.populateComboItems();
			});
		
		GType[] types;
		types ~= GType.STRING;
		types ~= GType.STRING;
				
		this.treeStore = new TreeStore(types);

		GType[] types2;
		types2 ~= GType.STRING;
		types2 ~= GType.STRING;
		types2 ~= GType.STRING;
		this.listStoreCombo = new ListStore(types2);
		this.populateComboItems();

		this.appendColumn(new TreeViewColumn("Component", new CellRendererText(), "text", 0));
		
		CellRendererCombo cellRendererCombo = new CellRendererCombo();
		
		g_object_set(
			cellRendererCombo.getCellRendererComboStruct(), 
			Str.toStringz("model"), this.listStoreCombo.getListStoreStruct(), 
			Str.toStringz("text-column"), 0,
			Str.toStringz("editable"), true,
			Str.toStringz("has-entry"), false,
			null);
		
		cellRendererCombo.addOnEdited(delegate void(string pathString, string newText, CellRendererText cellRendererText)
			{
				TreeIter iter = new TreeIter();
				this.treeStore.getIterFromString(iter, pathString);
				
				assert(pathString in this.rowToActionMappings);
				
				if(newText != "" && this.rowToActionMappings[pathString](newText)) {
					this.treeStore.setValue(iter, 1, newText);
				}
			});
		
		this.appendColumn(new TreeViewColumn("Specification", cellRendererCombo, "text", 1));
		
		this.setRulesHint(true);
		
		this.populate();
	}
	
	void populateComboItems() {
		this.listStoreCombo.clear();
		
		foreach(child; this.canvas.children) {
			if(child.specification !is null) {
				TreeIter iter = this.listStoreCombo.createIter();
				this.listStoreCombo.setValue(iter, 0, child.specification.id);
			}
		}
	}
	
	void populate() {
		this.setModel(null);
		this.treeStore.clear();
		
		int currentRow = -1;
		
		if(this.canvas.specification !is null) {
			foreach(i, ref coreId; this.canvas.specification.coreIds) {
				TreeIter iterCore = this.treeStore.createIter();
				this.treeStore.setValue(iterCore, 0, format("core#%d", i));
				this.treeStore.setValue(iterCore, 1, coreId);
				
				this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
					OoOProcessorCoreSpecification specification = this.canvas.getSpecification!(OoOProcessorCoreSpecification)(text);
					coreId = specification.id;
					return (cast(OoOProcessorCoreSpecification) specification !is null);
				};

				OoOProcessorCoreSpecification specCore = this.canvas.getSpecification!(OoOProcessorCoreSpecification)(coreId);
				string iCacheId = specCore.iCacheId;
				string dCacheId = specCore.dCacheId;
				
				TreeIter iterICache = this.treeStore.append(iterCore);
				this.treeStore.setValue(iterICache, 0, "icache");
				this.treeStore.setValue(iterICache, 1, iCacheId);
				
				this.rowToActionMappings[format("%d:%d", currentRow, 0)] = delegate bool(string text) {
					ICacheSpecification specification = this.canvas.getSpecification!(ICacheSpecification)(text);
					if(specification !is null) {
						specCore.iCacheId = specification.id;
						return true;
					}
					else {
						return false;
					}
				};
				
				TreeIter iterDCache = this.treeStore.append(iterCore);
				this.treeStore.setValue(iterDCache, 0, "dcache");
				this.treeStore.setValue(iterDCache, 1, dCacheId);
				
				this.rowToActionMappings[format("%d:%d", currentRow, 1)] = delegate bool(string text) {
					DCacheSpecification specification = this.canvas.getSpecification!(DCacheSpecification)(text);
					if(specification !is null) {
						specCore.dCacheId = specification.id;
						return true;
					}
					else {
						return false;
					}
				};
			}
			
			TreeIter iterL2 = this.treeStore.createIter();
			this.treeStore.setValue(iterL2, 0, "l2");
			this.treeStore.setValue(iterL2, 1, this.canvas.specification.l2CacheId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				L2CacheSpecification specification = this.canvas.getSpecification!(L2CacheSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.l2CacheId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
			
			TreeIter iterInterconnect = this.treeStore.createIter();
			this.treeStore.setValue(iterInterconnect, 0, "interconnect");
			this.treeStore.setValue(iterInterconnect, 1, this.canvas.specification.interconnectId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				FixedLatencyP2PInterconnectSpecification specification = this.canvas.getSpecification!(FixedLatencyP2PInterconnectSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.interconnectId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
			
			TreeIter iterMainMemory = this.treeStore.createIter();
			this.treeStore.setValue(iterMainMemory, 0, "mainMemory");
			this.treeStore.setValue(iterMainMemory, 1, this.canvas.specification.mainMemoryId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				FixedLatencyDRAMSpecification specification = this.canvas.getSpecification!(FixedLatencyDRAMSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.mainMemoryId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
		}
		
		this.setModel(this.treeStore);
	}
	
	TreeStore treeStore;
	ListStore listStoreCombo;
	
	Canvas canvas;
}

class Startup {	
	this(string[] args) {
		Main.init(args);
		
		GladeFile gladeFile = new GladeFile("mainWindow");
		this.builder = gladeFile.builder;

		this.buildSplashScreen();
		
		Main.run();
	}
	
	/*bool keyPressed(GdkEventKey* event, Widget widget) {
		if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_c) {
			this.canvas.copySelected();
			return  true;
		}
		else if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_x) {
			this.canvas.cutSelected();
			return  true;
			
		}
		else if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_v) {
			this.canvas.paste();
			return  true;
			
		}
		else if(event.keyval == GdkKeysyms.GDK_Delete) {
			this.canvas.deleteSelected();
			return  true;
		}
		else {
			return false;
		}
	}
	
	void exportToPdf() {		
		FileChooserDialog dialog = new FileChooserDialog("PDF file to generate", this.mainWindow, FileChooserAction.SAVE);
		
		FileFilter filter1 = new FileFilter();
		filter1.setName("PDF Files");
		filter1.addMimeType("document/pdf");
		filter1.addPattern("*.pdf");
		dialog.addFilter(filter1);
			
		FileFilter filter2 = new FileFilter();
		filter2.setName("All Files");
		filter2.addPattern("*");
		dialog.addFilter(filter2);
		
		if(dialog.run() == ResponseType.GTK_RESPONSE_OK) {
			string fileName = dialog.getFilename();
			if(fileName !is null) {
				this.canvas.exportToPdf(fileName);
			}
		}
		
		dialog.destroy();
	}*/
	
	void buildMainWindow() {
		this.mainWindow = getBuilderObject!(Window, GtkWindow)(this.builder, "mainWindow");
		this.mainWindow.maximize();
		this.mainWindow.addOnDestroy(delegate void(ObjectGtk)
			{
				saveConfigsAndStats();
				//Canvas.saveXML(this.canvas);
				Main.exit(0);
			});
			
		//this.mainWindow.addOnKeyPress(&this.keyPressed);
	}
	
	void buildFrames() {		
		this.frameBenchmarkConfigs = new FrameBenchmarkConfigs();
		this.frameSimulationConfigs = new FrameSimulationConfigs();
		this.frameSimulationStats = new FrameSimulationStats();
		
		Frame frameBenchmarks = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameBenchmarks");
		Frame frameArchitectures = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameArchitectures");
		Frame frameSimulations = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameSimulations");
		
		frameBenchmarks.add(this.frameBenchmarkConfigs.frameEditSet);
		frameArchitectures.add(this.frameSimulationConfigs.frameEditSet);
		frameSimulations.add(this.frameSimulationStats.frameEditSet);
	}
	
	void buildToolbars() {
		bindToolButton(this.builder, "toolButtonNew", {writeln("toolButtonNew is clicked.");});
	}
	
	void buildMenus() {
		bindMenuItem(this.builder, "menuItemFileQuit", {Main.quit();});
		//bindMenuItem(this.builder, "menuItemFileExportToPDF", {this.exportToPdf();});
		bindMenuItem(this.builder, "menuItemHelpAbout", 
			{
				string[] authors, documenters, artists;
		
				authors ~= "Min Cai (itecgo@163.com)";
				documenters ~= "Min Cai (itecgo@163.com)";
				artists ~= "Min Cai (itecgo@163.com)";
				
				AboutDialog aboutDialog = new AboutDialog();
				aboutDialog.setProgramName("Flexim ISE");
				aboutDialog.setVersion("0.1 Prelease");
				aboutDialog.setCopyright("Copyright (c) 2010 Min Cai <itecgo@163.com>");
				aboutDialog.setLogo(new Pixbuf("../res/flexim.png"));
				aboutDialog.setAuthors(authors);
				aboutDialog.setDocumenters(documenters);
				aboutDialog.setArtists(artists);
				aboutDialog.setLicense("GPL (GNU General Public License)\nsee http://www.gnu.org/licenses/gpl.html");
				aboutDialog.setWebsite("http://github.com/mcai/flexim");
				aboutDialog.setComments("Flexim Integrated Simulation Enviroment (ISE) is a flexible and rich architectural simulator written in D.");

				aboutDialog.run();
				aboutDialog.destroy();
			});
		//bindMenuItem(this.builder, "menuItemToolsBenchmarks", {this.dialogEditSetBenchmarkSuites.showDialog();});
		//bindMenuItem(this.builder, "menuItemToolsSimulations", {this.dialogEditSetSimulations.showDialog();});
		//bindMenuItem(this.builder, "menuItemToolsSimulationStats", {this.dialogEditSetSimulationStats.showDialog();});
	}
	
	/*void buildFrameDrawing() {
		this.frameDrawingManager = new FrameDrawingManager();
	}*/
	
	void buildSplashScreen() {
		GladeFile gladeFile = new GladeFile("splashScreen");
		
		this.splashScreen = getBuilderObject!(Window, GtkWindow)(gladeFile.builder, "splashScreen");
		this.splashScreen.showAll();
		
		Label labelLoading = getBuilderObject!(Label, GtkLabel)(gladeFile.builder, "labelLoading");
			
		void doPendingEvents() {
			while(Main.eventsPending) {
				Main.iterationDo(false);
			}
		}
		
		Timeout timeout = new Timeout(100, delegate bool ()
			{
				loadConfigsAndStats((string text){
					labelLoading.setMarkup(text);
					doPendingEvents();
				}, true);

				labelLoading.setLabel("Initializing Widgets");
				doPendingEvents();
				
				this.buildMainWindow();
				
				this.buildFrames();
				
				this.buildToolbars();
				
				this.buildMenus();

				labelLoading.setLabel("Initializing designer");
				doPendingEvents();
				
				//this.buildFrameDrawing();
				
				this.splashScreen.destroy();
				
				this.mainWindow.showAll();
				
				gthread.Thread.Thread.init(null);
				gdkThreadsInit();
				
				return false;
			}, false);
	}
	
	/*Canvas canvas() {
		return this.frameDrawingManager.canvas;
	}*/
	
	Builder builder;
	Window mainWindow;
	Window splashScreen;
	//FrameDrawingManager frameDrawingManager;
	
	FrameBenchmarkConfigs frameBenchmarkConfigs;
	FrameSimulationConfigs frameSimulationConfigs;
	FrameSimulationStats frameSimulationStats;
}
