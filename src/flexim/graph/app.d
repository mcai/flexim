/*
 * flexim/graph/app.d
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

module flexim.graph.app;

import flexim.all;

import cairo.Context;
import cairo.ImageSurface;

class UILayout: Expander {
	this() {
		super("Layout");
		
		with(this.comboBoxAlg = new ComboBox()) {
			appendText("Simple");
			appendText("Time");
			appendText("Barnes-Hut");
			setActive(0);
		}
		
		with(this.boxAlg = new HBox(false, 5)) {
			packStart(new Label("Algorithm"), false, false, 0);
			packStart(this.comboBoxAlg, true, true, 0);
		}
		
		with(this.spinButtonEConst = new SpinButton(0, 10000, 10)) {
			setValue(100);
		}
		
		with(this.boxEConst = new HBox(false, 5)) {
			packStart(new Label("Repulsion Constant"), false, false, 0);
			packStart(this.spinButtonEConst, true, true, 0);
		}
		
		with(this.spinButtonSConst = new SpinButton(0, 10000, 10)) {
			setValue(10);
		}
		
		with(this.boxSConst = new HBox(false, 5)) {
			packStart(new Label("Attraction Constant"), false, false, 0);
			packStart(this.spinButtonSConst, true, true, 0);
		}
		
		with(this.checkButtonSNL = new CheckButton("Edge Length")) {
			addOnToggled((ToggleButton button)
				{
					this.spinButtonSNL.setSensitive(button.getActive);
				});
		}
		
		with(this.spinButtonSNL = new SpinButton(0, 1000, 1)) {
			setValue(20);
			setSensitive(false);
		}
		
		with(this.boxSNL = new HBox(false, 5)) {
			packStart(this.checkButtonSNL, false, false, 0);
			packStart(this.spinButtonSNL, true, true, 0);
		}
		
		with(this.spinButtonDamp = new SpinButton(0, 10, 1)) {
			setValue(9);
		}
		
		with(this.boxDamp = new HBox(false, 5)) {
			packStart(new Label("Damping"), false, false, 0);
			packStart(this.spinButtonDamp, true, true, 0);
		}
		
		with(this.spinButtonTimeStep = new SpinButton(0, 100, 1)) {
			setValue(4);
		}
		
		with(this.boxTimeStep = new HBox(false, 5)) {
			packStart(new Label("TimeStep"), false, false, 0);
			packStart(this.spinButtonTimeStep, true, true, 0);
		}
		
		with(this.checkButtonAnimate = new CheckButton("Animate")) {
		}
		
		with(this.checkButtonWall = new CheckButton("Wall")) {
		}
		
		with(this.buttonRun = new Button(StockID.EXECUTE, false)) {
		}
		
		with(this.buttonStop = new Button(StockID.STOP, false)) {
			setSensitive(false);
		}
		
		with(this.boxButtons = new HBox(false, 5)) {
			packStart(this.buttonRun, true, true, 0);
			packStart(this.buttonStop, true, true, 0);
		}
		
		with(this.box = new VBox(false, 5)) {
			packStart(this.boxAlg, false, false, 0);
			packStart(this.boxEConst, false, false, 0);
			packStart(this.boxSConst, false, false, 0);
			packStart(this.boxSNL, false, false, 0);
			packStart(this.boxDamp, false, false, 0);
			packStart(this.boxTimeStep, false, false, 0);
			packStart(this.checkButtonAnimate, false, false, 0);
			packStart(this.checkButtonWall, false, false, 0);
			packStart(this.boxButtons, false, false, 0);
		}
		
		this.add(box);
	}
	
	~this() {
		delete this.comboBoxAlg;
		delete this.spinButtonEConst;
		delete this.spinButtonSConst;
		delete this.spinButtonDamp;
		delete this.spinButtonTimeStep;
		delete this.checkButtonAnimate;
		delete this.checkButtonWall;
		delete this.checkButtonSNL;
		delete this.spinButtonSNL;
		delete this.boxAlg;
		delete this.boxSNL;
		delete this.boxSConst;
		delete this.boxEConst;
		delete this.boxDamp;
		delete this.boxTimeStep;
		delete this.boxButtons;
	}
	
	bool isAnimationEnabled() {
		return cast(bool) this.checkButtonAnimate.getActive;
	}
	
	bool isWallEnabled() {
		return cast(bool) this.checkButtonWall.getActive;
	}
	
	int electricConst() {
		return this.spinButtonEConst.getValueAsInt;
	}
	
	int springConst() {
		return this.spinButtonSConst.getValueAsInt;
	}
	
	int damping() {
		return this.spinButtonDamp.getValueAsInt;
	}
	
	int timeStep() {
		return this.spinButtonTimeStep.getValueAsInt;
	}
	
	int springNL() {
		return this.spinButtonSNL.getValueAsInt;
	}
	
	bool enableNL() {
		return cast(bool) this.checkButtonSNL.getActive;
	}
	
	ForceLayoutType algorithmType() {
		switch(this.comboBoxAlg.getActiveText) {
			case "Time": return ForceLayoutType.TIME;
			case "Barnes-Hut": return ForceLayoutType.BH;
			default: return ForceLayoutType.SIMPLE;
		}
	}
	
	ComboBox comboBoxAlg;
	SpinButton spinButtonEConst, spinButtonSConst, spinButtonDamp, spinButtonTimeStep, spinButtonSNL;
	CheckButton checkButtonAnimate, checkButtonWall, checkButtonSNL;
	Button buttonRun, buttonStop;
	HBox boxButtons, boxAlg, boxSNL, boxSConst, boxEConst, boxDamp, boxTimeStep;
	VBox box;
}

class UIGraph: Expander {
	this() {
		super("Graph");
		
		with(this.spinButtonVertices = new SpinButton(0, 100000, 10)) {
			setValue(100);
		}
		
		with(this.buttonVertices = new Button(StockID.APPLY, true)) {
		}
		
		with(this.boxVertices = new HBox(false, 5)) {
			packStart(new Label("Vertices"), false, false, 0);
			packStart(this.spinButtonVertices, true, true, 0);
			packStart(this.buttonVertices, false, false, 0);
		}
		
		with(this.comboBoxEdges = new ComboBox()) {
			appendText("None");
			appendText("Circular");
			appendText("Centered");
			appendText("Interconnected");
			appendText("Binary Tree");
			setActive(0);
		}
		
		with(this.buttonEdges = new Button(StockID.APPLY, true)) {
		}
		
		with(this.boxEdges = new HBox(false, 5)) {
			packStart(new Label("Edges"), false, false, 0);
			packStart(this.comboBoxEdges, true, true, 0);
			packStart(this.buttonEdges, false, false, 0);
		}
		
		with(this.box = new VBox(false, 5)) {
			packStart(this.boxVertices, false, false, 0);
			packStart(this.boxEdges, false, false, 0);
		}
		
		this.add(box);
	}
	
	~this() {
		delete this.spinButtonVertices;
		delete this.comboBoxEdges;
		delete this.buttonEdges;
		delete this.buttonVertices;
		delete this.boxVertices;
		delete this.boxEdges;
		delete this.box;
	}
	
	int numberOfVertices() {
		return this.spinButtonVertices.getValueAsInt;
	}
	
	GraphShape graphShape() {
		switch(this.comboBoxEdges.getActiveText) {
			case "Circular": return GraphShape.CIRCULAR;
			case "Centered": return GraphShape.CENTERED;
			case "Interconnected": return GraphShape.INTERCONNECTED;
			case "Binary Tree": return GraphShape.BINARY_TREE;
			default: return GraphShape.NONE;
		}
	}
	
	VBox box;
	HBox boxVertices, boxEdges;
	SpinButton spinButtonVertices;
	ComboBox comboBoxEdges;
	Button buttonEdges, buttonVertices;
}

class UIFile: Expander {
	this() {
		super("File");
		
		with(this.buttonOpen = new Button(StockID.OPEN, false)) {
		}
		
		with(this.buttonSave = new Button(StockID.SAVE, false)) {
		}
		
		with(this.buttonExport = new Button(StockID.CONVERT, false)) {
		}
		
		with(this.boxFile = new HBox(false, 5)) {
			packStart(this.buttonOpen, true, true, 0);
			packStart(this.buttonSave, true, true, 0);
		}
		
		with(this.box = new VBox(false, 5)) {
			packStart(this.boxFile, false, false, 0);
			packStart(this.buttonExport, true, true, 0);
		}
		
		this.add(box);
	}
	
	~this() {
		delete this.buttonSave;
		delete this.buttonExport;
		delete this.buttonOpen;
		delete this.box;
	}
	
	VBox box;
	HBox boxFile;
	Button buttonExport, buttonSave, buttonOpen;
}

class UI: MainWindow {
	this() {
		super("Grafer");
		this.setBorderWidth(5);
		this.maximize();
		
		this.icon = new Image("../gtk/icon.svg");
		this.setDefaultIcon(this.icon.getPixbuf);
		
		this.buttonAbout = new Button(StockID.ABOUT);
		this.buttonAbout.addOnClicked(&this.buttonAboutClicked);
		
		with(this.buttonQuit = new Button(StockID.QUIT, false)) {
		}
		
		this.graphUI = new UIGraph();
		this.layoutUI = new UILayout();
		this.fileUI = new UIFile();
		this.canvas = new DrawingArea();
		
		with(this.canvasViewport = new ScrolledWindow(this.canvas)) {
			setPolicy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		}
		
		with(this.workspace = new Notebook()) {
			appendPage(this.canvasViewport, "Graph1");
		}
		
		with(this.boxMainButtons = new HBox(false, 5)) {
			packStart(this.buttonAbout, true, true, 0);
			packStart(this.buttonQuit, true, true, 0);
		}
		
		with(this.boxTool = new VBox(false, 5)) {
			packStart(this.graphUI, false, false, 0);
			packStart(this.layoutUI, false, false, 0);
			packStart(this.fileUI, false, false, 0);
			packStart(new Label(""), true, true, 0);
			packStart(this.boxMainButtons, false, false, 0);
		}
		
		with(this.boxMain = new HBox(false, 5)) {
			packStart(this.boxTool, false, false, 0);
			packStart(this.workspace, true, true, 0);
		}
		
		this.add(this.boxMain);
		this.showAll();
		
		this.canvas.queueResize();
	}
	
	void buttonAboutClicked(Button button) {
		string[] authors, documenters, artists;

		authors ~= "Frederic Morcos <fred.morcos@gmail.com>";
		documenters ~= "Frederic Morcos <fred.morcos@gmail.com>";
		artists ~= "Frederic Morcos <fred.morcos@gmail.com>";
		
		this.about = new AboutDialog();
		this.about.setProgramName("Grafer");
		this.about.setVersion("0.1");
		this.about.setCopyright("Copyright (C) 2008	Frederic-Gerald Morcos");
		this.about.setLogo(this.icon.getPixbuf);
		this.about.setAuthors(authors);
		this.about.setDocumenters(documenters);
		this.about.setArtists(artists);
		this.about.setLicense("Licensed under the GPLv3");
		this.about.setWebsite("http://grafer.googlecode.com");
		
		if(this.about.run() == GtkResponseType.GTK_RESPONSE_CANCEL) {
			this.about.destroy();
		}
		
		delete authors;
		delete documenters;
		delete artists;
		delete about;
	}
	
	~this() {
		delete this.graphUI;
		delete this.layoutUI;
		delete this.fileUI;
		delete this.canvas;
		delete this.boxTool;
		delete this.boxMain;
		delete this.icon;
		delete this.buttonAbout;
		delete this.buttonQuit;
	}
	
	Notebook workspace;
	HBox boxMain, boxMainButtons;
	VBox boxTool;
	DrawingArea canvas;
	ScrolledWindow canvasViewport;
	UIGraph graphUI;
	UILayout layoutUI;
	UIFile fileUI;
	AboutDialog about;
	Button buttonAbout, buttonQuit;
	Image icon;
}

class Application: UI {
	this() {
		this.graph = new Graph();
		
		this.graphUI.buttonEdges.addOnClicked(&this.buttonEdgesClicked);
		this.graphUI.buttonVertices.addOnClicked(&this.buttonVerticesClicked);
		this.layoutUI.buttonRun.addOnClicked(&this.buttonRunClicked);
		this.layoutUI.buttonStop.addOnClicked(&this.buttonStopClicked);
		this.layoutUI.checkButtonWall.addOnToggled(&this.checkButtonWallToggled);
		this.layoutUI.checkButtonAnimate.addOnToggled(&this.checkButtonAnimateToggled);
		this.fileUI.buttonExport.addOnClicked(&this.buttonExportClicked);
		this.fileUI.buttonSave.addOnClicked(&this.buttonSaveClicked);
		this.fileUI.buttonOpen.addOnClicked(&this.buttonOpenClicked);
		this.canvas.addOnExpose(&this.canvasExpose);
		this.canvas.addOnConfigure(&this.canvasConfigure);
		this.canvas.addOnButtonPress(&this.canvasButtonPress);
		this.canvas.addOnButtonRelease(&this.canvasButtonRelease);
		this.canvas.addOnMotionNotify(&this.canvasMotionNotify);
		
		this.buttonQuit.addOnClicked(&this.buttonQuitClicked);
	}
	
	~this() {
		delete this.context;
		delete this.graph;
	}
	
	void checkButtonAnimateToggled(ToggleButton button) {
		this.animate = this.layoutUI.isAnimationEnabled;
	}
	
	void checkButtonWallToggled(ToggleButton button) {
		this.graph.wall = this.layoutUI.isWallEnabled;
		this.canvas.queueDraw();
	}
	
	bool canvasConfigure(GdkEventConfigure* event, Widget widget) {
		this.graph.width = event.width;
		this.graph.height = event.height;
		
		return true;
	}
	
	bool canvasButtonPress(GdkEventButton* event, Widget widget) {
		Vertex v = this.graph.getVertexByPosition(event.x, event.y);
		if(v is null) {
			return false;
		}
		
		if(event.button == 3) {
			v.locked = !v.locked;
			canvas.queueDraw();
		}
		else if(event.button == 1) {
			this.dragged = v;
		}
		
		return false;
	}
	
	bool canvasButtonRelease(GdkEventButton* event, Widget widget) {
		this.dragged = null;
		return false;
	}
	
	bool canvasMotionNotify(GdkEventMotion* event, Widget widget) {
		if(this.dragged !is null) {
			this.dragged.pos.x = event.x;
			this.dragged.pos.y = event.y;
			this.canvas.queueDraw();
		}
		
		return false;
	}
	
	void buttonStopClicked(Button button) {
		this.stop = true;
	}
	
	void buttonRunClicked(Button button) {
		double limit = 0.0;
		
		switch(this.layoutUI.algorithmType) {
			case ForceLayoutType.TIME:
			this.layout = new TimeForceLayout();
			break;
			case ForceLayoutType.BH:
			this.layout = new BHForceLayout();
			break;
			default:
			this.layout = new SimpleForceLayout();
			break;
		}
		
		this.layout.eConst = this.layoutUI.electricConst;
		this.layout.sConst = this.layoutUI.springConst;
		this.layout.sLength = this.layoutUI.springNL;
		this.layout.sNL = this.layoutUI.enableNL;
		this.layout.damping = cast(double) (this.layoutUI.damping / 10.0);
		this.layout.timeStep = cast(double) (this.layoutUI.timeStep /100.0);
		this.layout.graph = graph;

		limit = this.graph.vertices.length + 1;
		
		this.layoutUI.buttonStop.setSensitive(true);
		this.layoutUI.buttonRun.setSensitive(false);
		
		while(!this.stop) {
			this.layout.run();
			
			if(this.layout.energy.x < limit && this.layout.energy.y < limit) {
				break;
			}
			
			if(this.animate) {
				this.canvas.queueDraw();
				while(Main.eventsPending) {
					Main.iterationDo(false);
				}
			}
		}
		
		this.centerGraph();
		this.canvas.queueDraw();
		while(Main.eventsPending) {
			Main.iterationDo(false);
		}
		
		this.layoutUI.buttonStop.setSensitive(false);
		this.layoutUI.buttonRun.setSensitive(true);
		this.stop = false;
		
		delete this.layout;
	}
	
	void centerGraph() {
		Quadrant q = new Quadrant();
		this.graph.getQuadrant(q);
		this.canvas.setSizeRequest(q.length, q.length);
		this.graph.shiftVerticesBy(-q.x, -q.y);
	}
	
	bool canvasExpose(GdkEventExpose* event, Widget widget) {
		this.context = new Context(widget.getWindow());
		this.context.setSourceRgb(0.2, 0.2, 0.2);
		this.context.setLineWidth(1.0);
		this.context.rectangle(event.area.x, event.area.y, event.area.width, event.area.height);
		this.context.clip();
		this.graph.expose(context);
		return true;
	}
	
	void buttonQuitClicked(Button button) {
		delete this;
		Main.exit(0);
	}
	
	void buttonEdgesClicked(Button button) {
		if(this.graph.vertices is null) {
			return;
		}
		
		createEdges(this.graph, this.graphUI.graphShape);
		this.canvas.queueDraw();
	}
	
	void buttonVerticesClicked(Button button) {
		randomVertices(this.graph, this.graphUI.numberOfVertices);
		createEdges(this.graph, this.graphUI.graphShape);
		this.canvas.queueDraw();
	}
	
	void buttonExportClicked(Button button) {
		if(this.graph.vertices is null) {
			return;
		}
		
		string[] texts;
		texts ~= "OK";
		texts ~= "Cancel";
		
		ResponseType[] responses;
		responses ~= ResponseType.GTK_RESPONSE_OK;
		responses ~= ResponseType.GTK_RESPONSE_CANCEL;
		
		FileChooserDialog dialog = new FileChooserDialog("Export",
			this, FileChooserAction.SAVE, texts, responses);
		
		if(dialog.run() != ResponseType.GTK_RESPONSE_OK) {
			dialog.hide();
			return;
		}
		
		Quadrant q;
		graph.getQuadrant(q);
		ImageSurface surface = ImageSurface.create(CairoFormat.RGB24, q.length, q.length);
		Context contextExport = Context.create(surface);
		
		contextExport.setSourceRgb(1.0, 1.0, 1.0);
		contextExport.rectangle(0, 0, q.length, q.length);
		contextExport.fill();
		contextExport.setSourceRgb(0.2, 0.2, 0.2);
		contextExport.setLineWidth(1.0);
		this.graph.expose(contextExport);
		
		surface.writeToPng(dialog.getFilename());
		
		dialog.hide();
		contextExport.destroy();
		surface.destroy();
		
		delete dialog;
	}
	
	void buttonSaveClicked(Button button) {
		string[] texts;
		texts ~= "OK";
		texts ~= "Cancel";
		
		ResponseType[] responses;
		responses ~= ResponseType.GTK_RESPONSE_OK;
		responses ~= ResponseType.GTK_RESPONSE_CANCEL;
		
		FileChooserDialog dialog = new FileChooserDialog("Save",
			this, FileChooserAction.SAVE, texts, responses);
		
		if(dialog.run() != ResponseType.GTK_RESPONSE_OK) {
			dialog.hide();
			return;
		}
		
		//saveGraph(this.graph, dialog.getFilename()); //TODO
			
		dialog.destroy();
		delete dialog;
	}
	
	void buttonOpenClicked(Button button) {
		string[] texts;
		texts ~= "OK";
		texts ~= "Cancel";
		
		ResponseType[] responses;
		responses ~= ResponseType.GTK_RESPONSE_OK;
		responses ~= ResponseType.GTK_RESPONSE_CANCEL;
		
		FileChooserDialog dialog = new FileChooserDialog("Open",
			this, FileChooserAction.OPEN, texts, responses);
		
		if(dialog.run() != ResponseType.GTK_RESPONSE_OK) {
			dialog.hide();
			return;
		}
		
		delete this.graph;
		//this.graph = loadGraph(dialog.getFilename()); //TODO
			
		dialog.destroy();
		delete dialog;
		
		this.canvas.queueDraw();
	}
	
	Graph graph;
	ForceLayout layout;
	bool stop = false, animate = false;
	Vertex dragged, selected;
	Context context;
}