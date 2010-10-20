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

import gtk.Timeout;

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
	
			this.listStore.setValue(iter, 0, new Value(new Pixbuf("../gtk/canvas/cpu.svg")));
			this.listStore.setValue(iter, 1, "<br>" ~ key ~ "</br>");
			this.listStore.setValue(iter, 2, value);
		}
		
		this.setModel(this.listStore);
	}
	
	string[string] data;
	ListStoreBenchmark listStore;
}

class TreeViewNodeProperties1 : TreeView {
	this() {		
		GType[] types;
		
		types ~= GType.STRING;
		types ~= GType.STRING;
		
		this.listStore = new ListStore(types);
		
		this.appendColumn(new TreeViewColumn("Key", new CellRendererText(), "text", 0));
		this.appendColumn(new TreeViewColumn("Value", new CellRendererText(), "text", 1));
		
		this.refreshList();
	}
	
	void refreshList() {
		this.setModel(null);
		this.listStore.clear();
		
		foreach(key, value; this.data) {
			TreeIter iter = this.listStore.createIter();
			
			this.listStore.setValue(iter, 0, key);
			this.listStore.setValue(iter, 1, value);
		}
		
		this.setModel(this.listStore);
	}
	
	string[string] data;	
	ListStore listStore;
}

class Startup {
	this(string[] args) {
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
	
	void buildToolbars() {
		this.toolButtonNew = getBuilderObject!(ToolButton, GtkToolButton)(this.builder, "toolButtonNew");
		this.toolButtonNew.addOnClicked(delegate void(ToolButton toolButton)
			{
				writeln(this.toolButtonNew.getTooltipText());
			});
	}
	
	void buildMenus() {
		this.menuItemFileExportToPDF = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(this.builder, "menuItemFileExportToPDF");
		this.menuItemFileExportToPDF.addOnActivate(delegate void(MenuItem)
			{
				this.exportToPdf();
			});
		
		this.menuItemHelpAbout = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(this.builder, "menuItemHelpAbout");
		this.menuItemHelpAbout.addOnActivate(delegate void(MenuItem)
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
	}
	
	void buildFrameDrawing() {
		this.frameDrawing = getBuilderObject!(Frame, GtkFrame)(this.builder, "frameDrawing");
			
		this.canvas = Canvas.loadXML();
			
		void buildToolbar() {
			this.toolbarDrawableObjects = new Toolbar();
			this.toolbarDrawableObjects.setOrientation(GtkOrientation.HORIZONTAL);
			this.toolbarDrawableObjects.setStyle(GtkToolbarStyle.BOTH_HORIZ);
			
			int position = 0;
			
			string BOX = registerStockId("box", "Box", "X");
			string LINE = registerStockId("line", "Line", "X");
			string FLEX = registerStockId("flex", "Flex", "X");
			string ROUNDED_BOX = registerStockId("rounded-box", "Rounded", "X");
			string TEXT = registerStockId("text", "Text", "X");
			
			ToolButton toolButtonBox = new ToolButton(BOX);
			toolButtonBox.setTooltipText("Box");
			toolButtonBox.addOnClicked(delegate void(ToolButton button)
				{
					Box child = new Box(format("box%d", this.canvas.children.length));
					this.canvas.create(child);
				});
			
			ToolButton toolButtonRoundedBox = new ToolButton(ROUNDED_BOX);
			toolButtonRoundedBox.setTooltipText("Rounded Box");
			toolButtonRoundedBox.addOnClicked(delegate void(ToolButton button)
				{
					RoundedBox child = new RoundedBox(format("roundedBox%d", this.canvas.children.length));
					this.canvas.create(child);
				});
			
			ToolButton toolButtonText = new ToolButton(TEXT);
			toolButtonText.setTooltipText("Text");
			toolButtonText.addOnClicked(delegate void(ToolButton button)
				{
					Text child = new Text(format("text%d", this.canvas.children.length), "Insert text here");
					child.size = 12;
					this.canvas.create(child);
				});
			
			ToolButton toolButtonLine = new ToolButton(LINE);
			toolButtonLine.setTooltipText("Line");
			toolButtonLine.addOnClicked(delegate void(ToolButton button)
				{
					Line child = new Line(format("Line%d", this.canvas.children.length));
					this.canvas.create(child);
				});
			
			this.toolbarDrawableObjects.insert(toolButtonBox, position++);
			this.toolbarDrawableObjects.insert(toolButtonRoundedBox, position++);
			this.toolbarDrawableObjects.insert(toolButtonText, position++);
			this.toolbarDrawableObjects.insert(toolButtonLine, position++);
		}
		
		void buildCanvas() {
			this.tableCanvas = new Table(3, 3, false);
			
			HRuler horizontalRuler = new HRuler();
			horizontalRuler.setMetric(GtkMetricType.PIXELS);
			horizontalRuler.setRange(0, 200, 0, 200);
			this.tableCanvas.attach(horizontalRuler, 1, 2, 0, 1, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, GtkAttachOptions.SHRINK, 4, 4);
			
			VRuler verticalRuler = new VRuler();
			verticalRuler.setMetric(GtkMetricType.PIXELS);
			verticalRuler.setRange(0, 200, 0, 200);
			this.tableCanvas.attach(verticalRuler, 0, 1, 1, 2, GtkAttachOptions.SHRINK, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, 4, 4);
			
			ScrolledWindow scrolledWindow = new ScrolledWindow();
			scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
			this.tableCanvas.attach(scrolledWindow, 1, 2, 1, 2, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, GtkAttachOptions.FILL | GtkAttachOptions.EXPAND, 4, 4);
			
			this.canvas.horizontalRuler = horizontalRuler;
			this.canvas.verticalRuler = verticalRuler;
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
			
			ScrolledWindow scrolledWindow = new ScrolledWindow();
			scrolledWindow.setPolicy(GtkPolicyType.NEVER, GtkPolicyType.AUTOMATIC);
			scrolledWindow.setBorderWidth(6);
			
			scrolledWindow.add(this.palette);
			
			vboxLeftTop.packStart(scrolledWindow, true, true, 0);
		}
		
		void populatePalette() {			
			ToolItemGroup groupProcessorCores = new ToolItemGroup("Processor Cores");
			this.palette.add(groupProcessorCores);
		
			string CPU = registerStockId("cpu", "Cpu", "X", "../gtk/canvas/cpu.svg");
			
			for(int i = 0; i < 10; i++) {
				ToolItem item1 = new ToolButton(CPU);
				item1.setTooltipText("Out-of-Order Processor Core");
				item1.setIsImportant(true);
				groupProcessorCores.insert(item1, -1);
			}
			
			ToolItemGroup groupCaches = new ToolItemGroup("Caches");
			this.palette.add(groupCaches);
			
			string CACHE = registerStockId("cache", "Cache", "X", "../gtk/canvas/cpu.svg");

			for(int i = 0; i < 10; i++) {
				ToolItem item1 = new ToolButton(CACHE);
				item1.setTooltipText("Level One Instruction Cache");
				item1.setIsImportant(true);
				groupCaches.insert(item1, -1);
			}
			
			ToolItemGroup groupInterconnects = new ToolItemGroup("Interconnects");
			this.palette.add(groupInterconnects);
			
			string INTERCONNECT = registerStockId("interconnect", "Interconnect", "X", "../gtk/canvas/cpu.svg");

			for(int i = 0; i < 10; i++) {
				ToolItem item1 = new ToolButton(INTERCONNECT);
				item1.setTooltipText("Fixed-Latency Peer-to-Peer Interconnect");
				item1.setIsImportant(true);
				groupInterconnects.insert(item1, -1);
			}
			
			ToolItemGroup groupMainMemories = new ToolItemGroup("Main Memories");
			this.palette.add(groupMainMemories);
			
			string MAIN_MEMORY = registerStockId("mainMemory", "MainMemory", "X", "../gtk/canvas/cpu.svg");

			for(int i = 0; i < 10; i++) {
				ToolItem item1 = new ToolButton(MAIN_MEMORY);
				item1.setTooltipText("Fixed-Latency DRAM Controller");
				item1.setIsImportant(true);
				groupMainMemories.insert(item1, -1);
			}
		}
		
		void buildPropertiesView() {				
			//this.vboxViewButtonsList = new VBoxViewButtonsList(this);
			//vboxLeftTop.packStart(this.vboxViewButtonsList, false, false, 0);

			VBox vboxLeftBottom = getBuilderObject!(VBox, GtkVBox)(builder, "vboxLeftBottom");
				
			vboxLeftBottom.packStart(new Label("Properties View"), false, false, 0);
				
			TreeViewNodeProperties treeViewNodeProperties = new TreeViewNodeProperties();
			vboxLeftBottom.packStart(treeViewNodeProperties, true, true, 0);
			
			canvas.addOnSelected(delegate void(DrawableObject child) {
				treeViewNodeProperties.data = child.properties;
				treeViewNodeProperties.refreshList();
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
				/*preloadConfigsAndStats((string text){
					labelLoading.setMarkup(text);
	
					while(Main.eventsPending) {
						Main.iterationDo(false);
					}
				});*/

				labelLoading.setLabel("Building main window");
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				this.buildMainWindow();
				
				labelLoading.setLabel("Building toolbars");
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				this.buildToolbars();

				labelLoading.setLabel("Building menus");
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
				this.buildMenus();

				labelLoading.setLabel("Building visualization");
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
	ToolButton toolButtonNew;
	ImageMenuItem menuItemFileExportToPDF, menuItemHelpAbout;
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