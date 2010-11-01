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

class FrameArchitectureConfigs : FrameEditSet {
	this() {		
		GladeFile gladeFile = new GladeFile("frameArchitectureConfigs");
		Builder builder = gladeFile.builder;
		
		Frame frameArchitectureConfigs = getBuilderObject!(Frame, GtkFrame)(builder, "frameArchitectureConfigs");
		ComboBox comboBoxArchitectures = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxArchitectures");
		Button buttonAddArchitecture = getBuilderObject!(Button, GtkButton)(builder, "buttonAddArchitecture");
		Button buttonRemoveArchitecture = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveArchitecture");
		VBox vboxArchitecture = getBuilderObject!(VBox, GtkVBox)(builder, "vboxArchitecture");
			
		super(frameArchitectureConfigs, comboBoxArchitectures, buttonAddArchitecture, buttonRemoveArchitecture, vboxArchitecture);
		
		HBox hboxAddArchitecture = getBuilderObject!(HBox, GtkHBox)(builder, "hboxAddArchitecture");
			
		this.numCoresWhenAddArchitecture = this.numThreadsPerCoreWhenAddArchitecture = 2;
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Number of Cores:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numCoresWhenAddArchitecture = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numThreadsPerCoreWhenAddArchitecture = newValue;
			}));
		
		hboxAddArchitecture.packStart(hbox0, true, true, 0);
		
		foreach(architectureConfigTitle, architectureConfig; architectureConfigs) {
			this.newArchitectureConfig(architectureConfig);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string architectureConfigTitle = this.comboBoxSet.getActiveText();
		
		if(architectureConfigTitle != "") {
			assert(architectureConfigTitle in architectureConfigs, architectureConfigTitle);
			ArchitectureConfig architectureConfig = architectureConfigs[architectureConfigTitle];
			assert(architectureConfig !is null);
			
			int indexOfArchitectureConfig = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfArchitectureConfig);
			
			this.buttonSetRemove.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do {
			currentArchitectureId++;
		}while(format("architecture%d", currentArchitectureId) in architectureConfigs);
		
		ProcessorConfig processor = new ProcessorConfig(2000000, 2000000, 7200, 1);
		
		for(uint i = 0; i < this.numCoresWhenAddArchitecture; i++) {
			CoreConfig core = new CoreConfig(CacheConfig.newL1(format("l1I-%d", i)), CacheConfig.newL1(format("l1D-%d", i)));
			processor.cores ~= core;
			
			for(uint j = 0; j < this.numThreadsPerCoreWhenAddArchitecture; j++) {
				Benchmark workload = benchmarkSuites["WCETBench"]["fir"];
				ContextConfig context = new ContextConfig(workload);
				//processor.contexts ~= context;
			}
		}
		
		CacheConfig l2Cache = CacheConfig.newL2();
		MainMemoryConfig mainMemory = new MainMemoryConfig(400);
		
		ArchitectureConfig architectureConfig = new ArchitectureConfig(format("architecture%d", currentArchitectureId), processor, l2Cache, mainMemory);
		
		architectureConfigs[architectureConfig.title] = architectureConfig;
		this.newArchitectureConfig(architectureConfig);
		
		int indexOfArchitectureConfig = architectureConfigs.length - 1;
		
		this.comboBoxSet.setActive(indexOfArchitectureConfig);
		this.notebookSets.setCurrentPage(indexOfArchitectureConfig);
	}
	
	override void onButtonSetRemoveClicked() {
		string architectureConfigTitle = this.comboBoxSet.getActiveText();
		
		if(architectureConfigTitle != "") {
			ArchitectureConfig architectureConfig = architectureConfigs[architectureConfigTitle];
			assert(architectureConfig !is null);
			
			architectureConfigs.remove(architectureConfig.title);
			
			int indexOfArchitectureConfig = this.comboBoxSet.getActive();
			this.comboBoxSet.removeText(indexOfArchitectureConfig);
			
			this.notebookSets.removePage(indexOfArchitectureConfig);
			
			if(indexOfArchitectureConfig > 0) {
				this.comboBoxSet.setActive(indexOfArchitectureConfig - 1);
			}
			else {
				this.comboBoxSet.setActive(architectureConfigs.length > 0 ? 0 : -1);
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
	
	void newArchitectureConfig(ArchitectureConfig architectureConfig) {
		this.comboBoxSet.appendText(architectureConfig.title);
		
		VBox vboxArchitecture = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", architectureConfig.title, delegate void(string entryText)
				{
					architectureConfigs.remove(architectureConfig.title);
					architectureConfig.title = entryText;
					architectureConfigs[architectureConfig.title] = architectureConfig;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, architectureConfig.title);
					this.comboBoxSet.setActive(index);
				})/*,
			newHBoxWithLabelAndEntry("Cwd:", architectureConfig.cwd, delegate void(string entryText)
				{
					architectureConfig.cwd = entryText;
				})*/);
		
		vboxArchitecture.packStart(hbox0, false, true, 6);
		
		vboxArchitecture.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndSpinButton!(ulong)("Max Cycle:", 1, 2000000, 1000, architectureConfig.processor.maxCycle, delegate void(ulong newValue)
			{
				architectureConfig.processor.maxCycle = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Insts:", 1, 2000000, 1000, architectureConfig.processor.maxInsts, delegate void(ulong newValue)
			{
				architectureConfig.processor.maxInsts = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Time:", 1, 7200, 100, architectureConfig.processor.maxTime, delegate void(ulong newValue)
			{
				architectureConfig.processor.maxTime = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, architectureConfig.processor.numThreadsPerCore));
			
		vboxProcessor.packStart(hbox1, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		Widget[] vboxesCore;
		
		foreach(i, core; architectureConfig.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(this.newCache(core.iCache), this.newCache(core.dCache)));
		}
		
		VBox vboxCores = vpack2(vboxesCore);
			
		vboxProcessor.packStart(vboxCores, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		/*Widget[] vboxesContext;
		
		foreach(i, context; architectureConfig.processor.contexts) {			
			vboxesContext ~= hpack(
				new Label(format("context-%d", i)),
				new VSeparator(), 
				newHBoxWithLabelAndWidget("Benchmark:", this.newContext(context)));
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);*/
		
		vboxArchitecture.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxArchitecture.packStart(new HSeparator(), false, true, 4);
		
		vboxArchitecture.packStart(newCache(architectureConfig.l2Cache), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Latency:", 1, 1024, 1, architectureConfig.mainMemory.latency, delegate void(uint newValue)
			{
				architectureConfig.mainMemory.latency = newValue;
			}));
			
		HBox hboxMainMemory = hpack(new Label("Main Memory"), new VSeparator(), vpack(hbox13));
		
		vboxArchitecture.packStart(hboxMainMemory, false, true, 6);
		
		vboxArchitecture.packStart(new HSeparator(), false, true, 4);
			
		//////////////////////
			
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxArchitecture);
		
		this.notebookSets.appendPage(scrolledWindow, architectureConfig.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	uint numCoresWhenAddArchitecture, numThreadsPerCoreWhenAddArchitecture;
	int currentArchitectureId = -1;
}

class FrameSimulations: FrameEditSet {
	this() {
		GladeFile gladeFile = new GladeFile("frameSimulations");
		Builder builder = gladeFile.builder;
		
		Frame frameSimulations = getBuilderObject!(Frame, GtkFrame)(builder, "frameSimulations");
		ComboBox comboBoxSimulations = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulations");
		VBox vboxSimulation = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulation");
		this.buttonSimulate = getBuilderObject!(Button, GtkButton)(builder, "buttonSimulate");
			
		super(frameSimulations, comboBoxSimulations, null, null, vboxSimulation);
		
		foreach(simulationTitle, simulation; simulations) {
			this.newSimulation(simulation);
		}
		
		this.buttonSimulate.addOnClicked(delegate void(Button)
			{
				string oldButtonLabel = this.buttonSimulate.getLabel();
				
				string simulationTitle = this.comboBoxSet.getActiveText();
				Simulation simulation = simulations[simulationTitle];
				
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
				threadUpdateGui.start();
			});
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string simulationTitle = this.comboBoxSet.getActiveText();
		
		if(simulationTitle != "") {
			assert(simulationTitle in simulations, simulationTitle);
			Simulation simulation = simulations[simulationTitle];
			assert(simulation !is null);
			
			int indexOfSimulation = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfSimulation);
			
			//this.buttonSetRemove.setSensitive(true);
			this.buttonSimulate.setSensitive(true);
		}
		else {
			//this.buttonSetRemove.setSensitive(false);
			this.buttonSimulate.setSensitive(false);
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
	
	void newSimulation(Simulation simulation) {
		SimulationStat simulationStat = simulation.stat;
		
		this.comboBoxSet.appendText(simulation.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", simulation.title),
			newHBoxWithLabelAndEntry("Cwd:", simulation.cwd),
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
		
		this.notebookSets.appendPage(scrolledWindow, simulation.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	Button buttonSimulate;
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
		this.frameArchitectureConfigs = new FrameArchitectureConfigs();
		this.frameSimulations = new FrameSimulations();
		
		this.notebookCenter = getBuilderObject!(Notebook, GtkNotebook)(this.builder, "notebookCenter");
		
		Frame frameBenchmarks = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameBenchmarks");
		Frame frameArchitectures = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameArchitectures");
		Frame frameSimulations = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameSimulations");
		
		frameBenchmarks.add(this.frameBenchmarkConfigs.frameEditSet);
		frameArchitectures.add(this.frameArchitectureConfigs.frameEditSet);
		frameSimulations.add(this.frameSimulations.frameEditSet);
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
		bindMenuItem(this.builder, "menuItemToolsBenchmarks", 
			{
				this.notebookCenter.setCurrentPage(0);
			});
		bindMenuItem(this.builder, "menuItemToolsSimulations", 
			{
				this.notebookCenter.setCurrentPage(1);
			});
		bindMenuItem(this.builder, "menuItemToolsSimulationStats", 
			{
				this.notebookCenter.setCurrentPage(2);
			});
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

	Notebook notebookCenter;
	
	FrameBenchmarkConfigs frameBenchmarkConfigs;
	FrameArchitectureConfigs frameArchitectureConfigs;
	FrameSimulations frameSimulations;
}
