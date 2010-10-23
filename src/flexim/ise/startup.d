/*
 * flexim/ise/startup.d
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

module flexim.ise.startup;

import flexim.all;

import core.thread;

import std.file;
import std.getopt;
import std.path;

import cairo.Context;

T getBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

T getBuilderObject(T, K)(Builder builder, string name) {
	return getBuilderObject!(T, K)(builder.getObject(name));
}

void guiActionNotImplemented(Window parent, string text) {
	MessageDialog d = new MessageDialog(parent, GtkDialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, text);
	d.run();
	d.destroy();
}

class VBoxViewButtonsList : VBox {
	this(Startup startup) {
		super(false, 5);
		
		this.startup = startup;
		
		with(this.buttonBenchmarkConfigView = new Button("View Config")) {
			addOnClicked(&this.buttonBenchmarkConfigViewClicked);
		}
		
		with(this.buttonExperimentConfigView = new Button("View Config")) {
			addOnClicked(&this.buttonExperimentConfigViewClicked);
		}
		
		with(this.buttonExperimentStatView = new Button("View Stat")) {
			addOnClicked(&this.buttonExperimentStatViewClicked);
		}
		
		with(this.buttonExperimentRun = new Button("Simulate!")) {
			addOnClicked(&this.buttonExperimentRunClicked);
		}
		
		with(this.comboBoxBenchmarkSuites = new ComboBox()) {
		}
		
		with(this.boxBenchmarkSuites = new VBox(false, 5)) {
			packStart(this.comboBoxBenchmarkSuites, true, true, 0);
			packStart(this.buttonBenchmarkConfigView, true, true, 0);
		}
		
		Frame frameBenchmarkSuites = new Frame("Benchmark Suites");
		frameBenchmarkSuites.add(this.boxBenchmarkSuites);
		
		with(this.comboBoxExperiments = new ComboBox()) {
		}
		
		with(this.boxExperiments = new VBox(false, 5)) {
			packStart(this.comboBoxExperiments, true, true, 0);
			packStart(this.buttonExperimentConfigView, true, true, 0);
			packStart(this.buttonExperimentStatView, true, true, 0);
			packStart(this.buttonExperimentRun, true, true, 0);
		}
		
		Frame frameExperiments = new Frame("Experiments");
		frameExperiments.add(this.boxExperiments);
		
		this.packStart(frameBenchmarkSuites, false, false, 0);
		this.packStart(new Label(""), false, false, 0);
		this.packStart(frameExperiments, false, false, 0);
	}
	
	void refillComboBoxItems() {
		with(this.comboBoxBenchmarkSuites) {
			foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
				appendText(benchmarkSuiteTitle);
			}
			setActive(0);
		}
		
		with(this.comboBoxExperiments) {
			foreach(experimentTitle, experimentConfig; experimentConfigs) {
				appendText(experimentTitle);
			}
			setActive(0);
		}
	}

	void buttonBenchmarkConfigViewClicked(Button button) {
		if(this.selectedBenchmarkSuiteName in benchmarkSuites) {
			BenchmarkSuite benchmarkSuite = benchmarkSuites[this.selectedBenchmarkSuiteName];
			//this.graphView.graph = new BenchmarkSuiteConfigTree(benchmarkSuite);
			//this.graphView.redraw();
		}
	}

	void buttonExperimentConfigViewClicked(Button button) {
		if(this.selectedExperimentName in experimentConfigs) {
			ExperimentConfig experimentConfig = experimentConfigs[this.selectedExperimentName];
			//this.graphView.graph = new ExperimentConfigTree(experimentConfig);
			//this.graphView.redraw();
		}
	}

	void buttonExperimentStatViewClicked(Button button) {
		if(this.selectedExperimentName in experimentStats) {
			ExperimentStat experimentStat = experimentStats[this.selectedExperimentName];
			//this.graphView.graph = new ExperimentStatTree(experimentStat);
			//this.graphView.redraw();
		}
	}

	void buttonExperimentRunClicked(Button button) {
		string oldButtonLabel = button.getLabel();
		
		core.thread.Thread threadRunExperiment = new core.thread.Thread(
			{
				runExperiment(this.selectedExperimentName, delegate void(string text)
					{
						this.startup.mainWindow.setTitle(text);
					}); //TODO
				
				this.buttonExperimentStatView.setSensitive(true);
				this.buttonExperimentRun.setSensitive(true);
				this.buttonExperimentRun.setLabel(oldButtonLabel);
			});

		this.buttonExperimentStatView.setSensitive(false);
		this.buttonExperimentRun.setSensitive(false);
		this.buttonExperimentRun.setLabel("Simulating.. Please Wait");
		threadRunExperiment.start();
	}
	
	string selectedBenchmarkSuiteName() {
		return this.comboBoxBenchmarkSuites.getActiveText;
	}
	
	string selectedExperimentName() {
		return this.comboBoxExperiments.getActiveText;
	}
	
	VBox boxBenchmarkSuites, boxExperiments;
	ComboBox comboBoxBenchmarkSuites, comboBoxExperiments;
	
	Button buttonBenchmarkConfigView;
	Button buttonExperimentConfigView, buttonExperimentStatView;
	Button buttonExperimentRun;
	
	Startup startup;
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

class TreeViewNodeProperties: TreeView {
	class ListStoreBenchmark: ListStore {
		this() {
			GType[] types;
			types ~= Pixbuf.getType();
			types ~= GType.STRING;
			types ~= GType.STRING;
			
			super(types);
		}
	}
	
	this() {		
		this.listStore = new ListStoreBenchmark();
		
		this.appendColumn(new TreeViewColumn("Image", new CellRendererPixbuf(), "pixbuf", 0));
		this.appendColumn(new TreeViewColumn("Key", new CellRendererText(), "text", 1));
		this.appendColumn(new TreeViewColumn("Value", new CellRendererText(), "text", 2));
		
		this.refreshList();
	}
	
	void refreshList() {
		this.setModel(null);
		this.listStore.clear();
		
		foreach(key, value; this.data) {
			TreeIter iter = this.listStore.createIter();
	
			this.listStore.setValue(iter, 0, new Value(new Pixbuf("../gtk/canvas/cpu_ooo.svg")));
			this.listStore.setValue(iter, 1, "<br>" ~ key ~ "</br>");
			this.listStore.setValue(iter, 2, value);
		}
		
		this.setModel(this.listStore);
	}
	
	string[string] data;
	ListStoreBenchmark listStore;
}

import glib.Str;
import gtkc.gobject;

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

class BenchmarkSpecification {
	
}

class Startup {
	this(string[] args) {
		Main.init(null);
		Main.init(args);
		
		this.builder = new Builder();
		this.builder.addFromFile("../gtk/flexim_gui.glade");
		this.builder.connectSignals(null); 

		this.buildSplashScreen();
		this.run();
	}
	
	bool keyPressed(GdkEventKey* event, Widget widget) {
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
	}
	
	void buildMainWindow() {
		this.mainWindow = getBuilderObject!(Window, GtkWindow)(this.builder, "mainWindow");
		this.mainWindow.maximize();
		this.mainWindow.addOnDestroy(delegate void(ObjectGtk)
			{
				Canvas.saveXML(this.canvas);
				Main.exit(0);
			});
			
		this.mainWindow.addOnKeyPress(&this.keyPressed);
	}
	
	void buildDialogs() {
		this.dialogEditBenchmarks = getBuilderObject!(Dialog, GtkDialog)(this.builder, "dialogEditBenchmarks");
		this.dialogEditBenchmarks.addOnDelete(delegate bool(gdk.Event.Event, Widget)
			{
				this.dialogEditBenchmarks.hide();
				return true;
			});
		
		this.comboBoxBenchmarkSuites = getBuilderObject!(ComboBox, GtkComboBox)(this.builder, "comboBoxBenchmarkSuites");
		this.vboxBenchmarks = getBuilderObject!(VBox, GtkVBox)(this.builder, "vboxBenchmarks");
		
		setupTextComboBox(this.comboBoxBenchmarkSuites);
		
		Notebook notebookBenchmarks = new Notebook();
		notebookBenchmarks.setShowTabs(false);
		notebookBenchmarks.setBorderWidth(10);
		
		this.vboxBenchmarks.packStart(notebookBenchmarks, true, true, 0);
			
		foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
			comboBoxBenchmarkSuites.appendText(benchmarkSuiteTitle);
			
			VBox vboxBenchmarksList = new VBox(false, 6);
			
			foreach(benchmark; benchmarkSuite.benchmarks) {
				vboxBenchmarksList.packStart(new HSeparator(), false, true, 4);
				
				HBox hbox1 = new HBox(false, 6);
				
				Label labelTitle = new Label("Title: ");
				Entry entryTitle = new Entry(benchmark.title);
				
				Label labelCwd = new Label("Cwd: ");
				Entry entryCwd = new Entry(benchmark.cwd);
				
				hbox1.packStart(labelTitle, false, false, 0);
				hbox1.packStart(entryTitle, true, true, 0);
				hbox1.packStart(labelCwd, false, false, 0);
				hbox1.packStart(entryCwd, true, true, 0);
				
				HBox hbox2 = new HBox(false, 6);
				
				Label labelExe = new Label("Exe: ");
				Entry entryExe = new Entry(benchmark.exe);
				
				Label labelArgsLiteral = new Label("Args in Literal: ");
				Entry entryArgsLiteral = new Entry(benchmark.argsLiteral);
				
				hbox2.packStart(labelExe, false, false, 0);
				hbox2.packStart(entryExe, true, true, 0);
				hbox2.packStart(labelArgsLiteral, false, false, 0);
				hbox2.packStart(entryArgsLiteral, true, true, 0);
				
				HBox hbox3 = new HBox(false, 6);
				
				Label labelStdin = new Label("Stdin: ");
				Entry entryStdin = new Entry(benchmark.stdin);
				
				Label labelStdout = new Label("Stdout: ");
				Entry entryStdout = new Entry(benchmark.stdout);
				
				hbox3.packStart(labelStdin, false, false, 0);
				hbox3.packStart(entryStdin, true, true, 0);
				hbox3.packStart(labelStdout, false, false, 0);
				hbox3.packStart(entryStdout, true, true, 0);
				
				HBox hbox4 = new HBox(false, 6);
				Label labelNumThreads = new Label("Number of Threads: ");
				Entry entryNumThreads = new Entry(benchmark.numThreads);
				
				hbox4.packStart(labelNumThreads, false, false, 0);
				hbox4.packStart(entryNumThreads, true, true, 0);
				
				VBox vbox = new VBox(false, 6);
				vbox.packStart(hbox1, false, true, 0);
				vbox.packStart(hbox2, false, true, 0);
				vbox.packStart(hbox3, false, true, 0);
				vbox.packStart(hbox4, false, true, 0);
				
				Label labelBenchmarkTitle = new Label(benchmark.title);
				Button buttonRemoveBenchmark = new Button("Remove");
				
				HBox hboxBenchmark = new HBox(false, 6);
				hboxBenchmark.packStart(labelBenchmarkTitle, false, false, 0);
				hboxBenchmark.packStart(new VSeparator(), false, false, 0);
				hboxBenchmark.packStart(vbox, true, true, 0);
				hboxBenchmark.packStart(new VSeparator(), false, false, 0);
				hboxBenchmark.packStart(buttonRemoveBenchmark, false, false, 0);
				
				vboxBenchmarksList.packStart(hboxBenchmark, false, true, 0);
			}
			
			ScrolledWindow scrolledWindow = new ScrolledWindow();
			scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
			
			scrolledWindow.addWithViewport(vboxBenchmarksList);
			
			notebookBenchmarks.appendPage(scrolledWindow, benchmarkSuiteTitle);
		}
		notebookBenchmarks.setCurrentPage(0);
		comboBoxBenchmarkSuites.setActive(0);
		
		HBox hboxButtonAdd = new HBox(false, 6);
		
		Button buttonAdd = new Button("Add Benchmark");
		hboxButtonAdd.packEnd(buttonAdd, false, false, 0);
		
		this.vboxBenchmarks.packStart(hboxButtonAdd, false, true, 6);
		
		this.comboBoxBenchmarkSuites.addOnChanged(delegate void(ComboBox)
			{
				string benchmarkSuiteTitle = this.comboBoxBenchmarkSuites.getActiveText();
				
				BenchmarkSuite benchmarkSuite = benchmarkSuites[benchmarkSuiteTitle];
				assert(benchmarkSuite !is null);
				
				int indexOfBenchmarkSuite = this.comboBoxBenchmarkSuites.getActive();
				
				notebookBenchmarks.setCurrentPage(indexOfBenchmarkSuite);
			});
		
		void addBenchmark() {
			
		}
		
		Button buttonCloseDialogEditBenchmarks = getBuilderObject!(Button, GtkButton)(this.builder, "buttonCloseDialogEditBenchmarks");
		buttonCloseDialogEditBenchmarks.addOnClicked(delegate void(Button)
			{
				this.dialogEditBenchmarks.hideAll();
			});
	}
	
	void buildToolbars() {
		this.toolButtonNew = getBuilderObject!(ToolButton, GtkToolButton)(this.builder, "toolButtonNew");
		this.toolButtonNew.addOnClicked(delegate void(ToolButton toolButton)
			{
				writeln(this.toolButtonNew.getTooltipText());
			});
	}
	
	void buildMenus() {
		MenuItem menuItemFileQuit = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(this.builder, "menuItemFileQuit");
		menuItemFileQuit.addOnActivate(delegate void(MenuItem)
			{
				Main.quit();
			});
		
		ImageMenuItem menuItemFileExportToPDF = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(this.builder, "menuItemFileExportToPDF");
		menuItemFileExportToPDF.addOnActivate(delegate void(MenuItem)
			{
				this.exportToPdf();
			});
		
		ImageMenuItem menuItemHelpAbout = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(this.builder, "menuItemHelpAbout");
		menuItemHelpAbout.addOnActivate(delegate void(MenuItem)
			{
				string[] authors, documenters, artists;
		
				authors ~= "Min Cai (itecgo@163.com)";
				documenters ~= "Min Cai (itecgo@163.com)";
				artists ~= "Min Cai (itecgo@163.com)";
				
				AboutDialog aboutDialog = new AboutDialog();
				aboutDialog.setProgramName("Flexim ISE");
				aboutDialog.setVersion("0.1 Prelease");
				aboutDialog.setCopyright("Copyright (c) 2010 Min Cai <itecgo@163.com>");
				aboutDialog.setLogo(new Pixbuf("../gtk/flexim.png"));
				aboutDialog.setAuthors(authors);
				aboutDialog.setDocumenters(documenters);
				aboutDialog.setArtists(artists);
				aboutDialog.setLicense("GPL (GNU General Public License)\nsee http://www.gnu.org/licenses/gpl.html");
				aboutDialog.setWebsite("http://github.com/mcai/flexim");
				aboutDialog.setComments("Flexim Integrated Simulation Enviroment (ISE) is a flexible and rich architectural simulator written in D.");
				
				if (aboutDialog.run() == GtkResponseType.GTK_RESPONSE_CANCEL) {
					aboutDialog.destroy();
				}
			});
		
		MenuItem menuItemToolsBenchmarks = getBuilderObject!(MenuItem, GtkMenuItem)(this.builder, "menuItemToolsBenchmarks");
		menuItemToolsBenchmarks.addOnActivate(delegate void(MenuItem)
			{
				dialogEditBenchmarks.showAll();
			});
	}
	
	void buildFrameDrawing() {
		this.frameDrawing = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameDrawing");
			
		this.canvas = Canvas.loadXML();
		this.canvas.startup = this;
			
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
			toolButtonText.addOnClicked(delegate void(ToolButton button)
				{
					Text child = new Text(format("text%d", this.canvas.children.length), "Insert text here");
					child.size = 12;
					this.canvas.create(child);
				});
			
			ToolButton toolButtonBox = new ToolButton(BOX);
			toolButtonBox.setTooltipText("Box");
			toolButtonBox.addOnClicked(delegate void(ToolButton button)
				{
					Box child = new Box(format("box%d", this.canvas.children.length));
					this.canvas.create(child);
				});
				
			ToolButton toolButtonTextBox = new ToolButton(TEXT_BOX);
			toolButtonTextBox.setTooltipText("Text Box");
			toolButtonTextBox.addOnClicked(delegate void(ToolButton button)
				{
					TextBox child = new TextBox(format("textBox%d", this.canvas.children.length), "Insert text here");
					this.canvas.create(child);
				});
			
			ToolButton toolButtonLine = new ToolButton(LINE);
			toolButtonLine.setTooltipText("Line");
			toolButtonLine.addOnClicked(delegate void(ToolButton button)
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
		
		buildToolbar();
		buildCanvas();
		
		VBox vboxCenter = new VBox(false, 0);
		vboxCenter.packStart(this.toolbarDrawableObjects, false, false, 0);
		vboxCenter.packStart(this.tableCanvas, true, true, 0);
		
		this.frameDrawing.add(vboxCenter);
		
		VBox vboxLeftTop = getBuilderObject!(VBox, GtkVBox)(builder, "vboxLeftTop");
		
		void setupPalette() {
			this.palette = new ToolPalette();
			this.palette.setIconSize(IconSize.DND);
			
			this.palette.addDragDest(this.canvas, GtkDestDefaults.ALL, GtkToolPaletteDragTargets.ITEMS, GdkDragAction.ACTION_COPY);
			
			ScrolledWindow scrolledWindow = new ScrolledWindow();
			scrolledWindow.setPolicy(GtkPolicyType.NEVER, GtkPolicyType.AUTOMATIC);
			scrolledWindow.setBorderWidth(6);
			
			scrolledWindow.add(this.palette);
			
			vboxLeftTop.packStart(scrolledWindow, true, true, 0);
		}
		
		void populatePalette() {
			ToolItemGroup addItemGroup(string name) {
				ToolItemGroup group = new ToolItemGroup(name);
				this.palette.add(group);
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
			
			ToolItemGroup groupArchitectures = addItemGroup("Architectures");
			string ARCH_SHARED_CACHE_MULTICORE = registerStockId("archSharedCacheMulticore", "Shared Cache Multicore", "X", "../gtk/canvas/arch_shared_cache_multicore.svg");
			addItem(groupArchitectures, ARCH_SHARED_CACHE_MULTICORE, "archSharedCacheMulticore", "Shared Cache Multicore Architecture");
				
			ToolItemGroup groupProcessorCores = addItemGroup("Processor Cores");
			string CPU_SIMPLE = registerStockId("cpuSimple", "Simple CPU", "X", "../gtk/canvas/cpu_simple.svg");
			string CPU_OOO = registerStockId("cpuOOO", "OoO CPU", "X", "../gtk/canvas/cpu_ooo.svg");
			addItem(groupProcessorCores, CPU_SIMPLE, "cpuSimple", "Simple CPU Core");
			addItem(groupProcessorCores, CPU_OOO, "cpuOoO", "Out-of-Order CPU Core");
			
			ToolItemGroup groupCaches = addItemGroup("Memory Hierarchy Objects");
			string CACHE_L1I = registerStockId("cacheL1I", "L1 Instruction Cache", "X", "../gtk/canvas/cache_l1i.svg");
			string CACHE_L1D = registerStockId("cacheL1d", "L1 Data Cache", "X", "../gtk/canvas/cache_l1d.svg");
			string CACHE_L2 = registerStockId("cacheL2", "Shared L2 Cache", "X", "../gtk/canvas/cache_l2.svg");
			string DRAM_FIXED = registerStockId("dramFixed", "Fixed Latency DRAM", "X", "../gtk/canvas/dram_fixed.svg");
			addItem(groupCaches, CACHE_L1I, "cacheL1I", "L1 Instruction Cache");
			addItem(groupCaches, CACHE_L1D, "cacheL1D", "L1 Data Cache");
			addItem(groupCaches, CACHE_L2, "cacheL2", "Shared L2 Cache");
			addItem(groupCaches, DRAM_FIXED, "dramFixed", "Fixed Latency DRAM");
			
			ToolItemGroup groupInterconnects = addItemGroup("Interconnects");
			string INTERCONNECT_FIXED_P2P = registerStockId("interconnectFixedP2P", "Fixed Latency P2P Interconnect", "X", "../gtk/canvas/interconnect_fixed_p2p.svg");			
			addItem(groupInterconnects, INTERCONNECT_FIXED_P2P, "interconnectFixedP2P", "Fixed Latency P2P Interconnect");
		}
		
		void buildPropertiesView() {				
			//this.vboxViewButtonsList = new VBoxViewButtonsList(this);
			//vboxLeftTop.packStart(this.vboxViewButtonsList, false, false, 0);

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
		
		setupPalette();
		populatePalette();
		buildPropertiesView();
	}
	
	void buildSplashScreen() {
		this.splashScreen = getBuilderObject!(Window, GtkWindow)(this.builder, "splashScreen");
		this.splashScreen.showAll();
		
		Label labelLoading = getBuilderObject!(Label, GtkLabel)(this.builder, "labelLoading");
		
		Timeout timeout = new Timeout(100, delegate bool ()
			{
				preloadConfigsAndStats((string text){
					labelLoading.setMarkup(text);
	
					while(Main.eventsPending) {
						Main.iterationDo(false);
					}
				});

				labelLoading.setLabel("Initializing Widgets");
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				this.buildMainWindow();
				
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				
				this.buildDialogs();
				
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				
				this.buildToolbars();

				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				
				this.buildMenus();

				labelLoading.setLabel("Initializing designer");
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				
				this.buildFrameDrawing();
				
				//this.vboxViewButtonsList.refillComboBoxItems();
				
				this.splashScreen.hideAll();
				
				this.mainWindow.showAll();
				
				return false;
			}, false);
	}
	
	void run() {
		Main.run();
	}
	
	Builder builder;
	Window mainWindow;
	
	Dialog dialogEditBenchmarks;
	ComboBox comboBoxBenchmarkSuites;
	VBox vboxBenchmarks;
	
	ToolButton toolButtonNew;
	
	Frame frameDrawing;
	Toolbar toolbarDrawableObjects;
	Table tableCanvas;
	Canvas canvas;
	Window splashScreen;
	//VBoxViewButtonsList vboxViewButtonsList;
	ToolPalette palette;
}

void mainGui(string[] args) {
	new Startup(args);
}
