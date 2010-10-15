/*
 * flexim/gui/graph.d
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

module flexim.gui.graph;

import flexim.all;

import std.file;
import std.getopt;
import std.path;
import core.thread;

import cairo.Context;

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

enum ImmutableTreeNodeShape: string {
	RECTANGLE = "RECTANGLE",
	CIRCLE = "CIRCLE"
}

class ImmutableTreeNode {
	this(string text, ImmutableTreeNodeShape shape = ImmutableTreeNodeShape.CIRCLE) {
		this.text = text;
		this.shape = shape;
		
		this.x = 0.0;
		this.y = 0.0;
		
		this.size = 40;
		this.drawSize = this.size / 6;

		this.locked = false;
		this.selected = false;
	}
	
	void expose(Context context) {
		if(this.shape == ImmutableTreeNodeShape.RECTANGLE) {
			context.moveTo(this.x + this.drawSize + 15, this.y + 5);
			context.showText(format("%s", this.text));
				
			newDrawing(context,
				{
					context.setSourceColor(new Color(0x6287E7));
					context.rectangle(this.x - this.drawSize - 10,
						this.y - this.drawSize - 10,
						this.drawSize * 2 + 20,
						this.drawSize * 2 + 20);
					context.fillPreserve();
					context.setSourceColor(new Color(0x000000));
					context.stroke();
				});
		}
		else if (this.shape == ImmutableTreeNodeShape.CIRCLE){
			newDrawing(context,
				{
					context.setSourceColor(new Color(0x6287E7));
					context.arc(this.x, this.y, (this.drawSize * 2 + 20) / 2, 0, 2 * PI);
					context.closePath();
					context.fillPreserve();
					context.setSourceColor(new Color(0x000000));
					context.stroke();
				});
			
			context.moveTo(this.x + (this.drawSize * 2 + 20) / 2 + 5, this.y + 5);
			context.showText(format("%s", this.text));
		}
	}
	
	override string toString() {
		return format("%s[x=%f, y=%f, size=%d, drawSize=%d, locked=%s, selected=%s, childrenEdges.length=%d]",
			this.text, this.x, this.y, this.size, this.drawSize, this.locked, this.selected, this.childrenEdges.length);
	}
	
	string text;
	double x, y;
	int size, drawSize;
	bool locked, selected;
	
	ImmutableTreeNodeShape shape;
	
	ImmutableTreeEdge parentEdge;
	ImmutableTreeEdge[] childrenEdges;
}

class ImmutableTreeEdge {
	this(ImmutableTreeNode v1, ImmutableTreeNode v2) {
		this.v1 = v1;
		this.v2 = v2;
	}
	
	void expose(Context context) {
		newDrawing(context, 
			{
				if(this.selected) {
					context.setSourceRgb(0.8, 0.0, 0.0);
				}
				
				context.moveTo(this.v1.x, this.v1.y);
				context.lineTo(this.v2.x, this.v2.y);
				context.stroke();
			});
	}
	
	double slope() {
		return (this.v1.y - this.v2.y) / (this.v1.x - this.v2.x);
	}
	
	double constant() {
		return this.v1.y - (this.slope * this.v1.x);
	}
	
	bool lies(double x, double y) {
		return ((this.v1.x - x) * (x - this.v2.x) >= 0 && (this.v1.y - y) * (y - this.v2.y) >= 0);
	}
	
	bool intersect(ImmutableTreeEdge otherEdge) {
		double xi = -(this.constant - otherEdge.constant) / (this.slope - otherEdge.slope);
		double yi = this.constant + (this.slope * xi);
		
		return this.lies(xi, yi) && otherEdge.lies(xi, yi);
	}
	
	override string toString() {
		return format("ImmutableTreeEdge[%s->%s, selected=%s]", this.v1.text, this.v2.text, this.selected);
	}
	
	ImmutableTreeNode v1, v2;
	bool selected;
}

abstract class ImmutableTree {
	this() {
		this.width = 600;
		this.height = 400;
	}
	
	void createGraph() {
		this.doCreateGraph();
		
		InorderTraversalTreeLayout treeLayout = new InorderTraversalTreeLayout(this);
		treeLayout.apply();
	}
	
	abstract void doCreateGraph();
	
	void addEdge(ImmutableTreeNode v1, ImmutableTreeNode v2) {
		ImmutableTreeEdge e = new ImmutableTreeEdge(v1, v2);
		this.edges ~= e;
		
		v1.childrenEdges ~= e;
		v2.parentEdge = e;
	}
	
	void createBinaryTreeEdges() {		
		foreach(i, v; this.vertices) {
			int otherVertexIndex = i * 2;
			
			if(otherVertexIndex + 1 > this.vertices.length - 1) {
				break;
			}
			else {
				this.addEdge(this.vertices[i], this.vertices[otherVertexIndex + 1]);
			}
			
			if(otherVertexIndex + 2 > this.vertices.length - 1) {
				break;
			}
			else {
				this.addEdge(this.vertices[i], this.vertices[otherVertexIndex + 2]);
			}
		}
	}
	
	ImmutableTreeNode getVertexByPosition(double x, double y) {
		foreach(v; this.vertices) {
			if(x >= v.x - v.drawSize &&
				x <= v.x + v.drawSize &&
				y >= v.y - v.drawSize &&
				y <= v.y + v.drawSize) {
				return v;
			}
		}
		
		return null;
	}
	
	void shiftVerticesBy(double x, double y) {
		if(x == 0.0 && y == 0.0) {
			return;
		}
		
		foreach(v; this.vertices) {
			v.x += x;
			v.y += y;
		}
	}
	
	void highlightIntersections() {
		foreach(i, e; this.edges) {
			foreach(f; this.edges[i + 1..$]) {
				e.selected = f.selected = e.intersect(f);
			}
		}
	}
	
	void expose(Context context) {
		if(this.wall) {
			newDrawing(context, 
				{
					context.setSourceRgb(0.8, 0.0, 0.0);
					context.setLineWidth(10.0);
					context.rectangle(0, 0, this.width, this.height);
					context.stroke();
				});
		}
		
		foreach(e; this.edges) {
			e.expose(context);
		}
		
		foreach(v; this.vertices) {
			v.expose(context);
		}
	}
	
	int indexOf(Vertex v) {
		return this.vertices.indexOf(v);
	}
	
	void inorderTraversal(void delegate(ImmutableTreeNode, int) del) {
		this.inorderTraversal(this.vertices[0], 0, del);
	}
	
	void inorderTraversal(ImmutableTreeNode rootNode, int level, void delegate(ImmutableTreeNode, int) del) {
		for(int i = 0; i < rootNode.childrenEdges.length / 2; i++) {
			this.inorderTraversal(rootNode.childrenEdges[i].v2, level + 1, del);
		}
		
		del(rootNode, level);
		
		for(int i = rootNode.childrenEdges.length / 2; i < rootNode.childrenEdges.length; i++) {
			this.inorderTraversal(rootNode.childrenEdges[i].v2, level + 1, del);
		}
	}
	
	override string toString() {
		string str;
		
		str ~= format("ImmutableTree[width=%d, height=%d, wall=%s]\n", this.width, this.height, this.wall);
		
		str ~= "vertices:\n";
		foreach(i, v; this.vertices) {
			str ~= format("[%d] %s\n", i, v);
		}
		
		str ~= "edges:\n";
		foreach(i, e; this.edges) {
			str ~= format("[%d] %s\n", i, e);
		}
		
		return str;
	}
	
	ImmutableTreeNode[] vertices;
	ImmutableTreeEdge[] edges;
	int width, height;
	bool wall;
}

abstract class TreeLayout {
	this(ImmutableTree tree) {
		this.tree = tree;
	}
	
	abstract void apply();
	
	ImmutableTree tree;
}

class InorderTraversalTreeLayout : TreeLayout {
	this(ImmutableTree tree) {
		super(tree);
	}
	
	override void apply() {
		//writeln(format("before performing layout: %s", this.tree));
			
		int xCoord = 0;
		
		this.tree.inorderTraversal(
			(ImmutableTreeNode treeNode, int level)
			{
				//writefln("Visiting tree node %s... at level %d", treeNode, level);

				treeNode.x = 100 + xCoord++ * this.tree.width / 10;
				treeNode.y = 100 + level * this.tree.height / 10;
			});
		
		//writeln(format("after performing layout: %s", this.tree));
	}
}

class GraphView : DrawingArea {
	this() {
		this.addEvents(GdkEventMask.BUTTON_PRESS_MASK);
		this.addEvents(GdkEventMask.BUTTON_RELEASE_MASK);
		
		this.addOnExpose(&this.exposed);
		this.addOnButtonPress(&this.buttonPressed);
		this.addOnButtonRelease(&this.buttonReleased);
		this.addOnMotionNotify(&this.motionNotified);
	}
	
	void redraw() {		
		Drawable dr = this.getWindow();

		int width;
		int height;

		dr.getSize(width, height);

		Context context = new Context(dr);
		
		newDrawing(context,
			{
				context.setSourceColor(new Color(0xDAE3E6));
				context.paint();
			});
			
		context.setSourceRgb(0.2, 0.2, 0.2);
		context.setLineWidth(1.0);

		if(this.graph !is null) {
			this.graph.expose(context);
		}
		
		this.setSizeRequest(1024, 768);
	}
	
	bool exposed(GdkEventExpose* event, Widget widget) {
		this.redraw();
		
		return true;
	}
	
	bool buttonPressed(GdkEventButton* event, Widget widget) {
		if(this.graph !is null) {
			ImmutableTreeNode v = this.graph.getVertexByPosition(event.x, event.y);
			if(v is null) {
				return false;
			}
			
			if(event.button == 1) {
				this.dragged = v;
			}
		}
		
		return false;
	}
	
	bool buttonReleased(GdkEventButton* event, Widget widget) {
		if(this.graph !is null) {
			this.dragged = null;
		}
		return false;
	}
	
	bool motionNotified(GdkEventMotion* event, Widget widget) {
		if(this.graph !is null) {
			if(this.dragged !is null) {
				this.dragged.x = event.x;
				this.dragged.y = event.y;
				this.queueDraw();
			}
		}
		
		return false;
	}
	
	ImmutableTree graph;
	ImmutableTreeNode dragged, selected;
}

class VBoxViewButtonsList : VBox {	
	this(GraphView graphView) {
		super(false, 5);
		
		this.graphView = graphView;
		
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
		    foreach (string name; dirEntries("../configs/benchmarks", SpanMode.breadth))
		    {
				appendText(basename(name, ".xml"));
		    }
			setActive(0);
		}
		
		with(this.boxBenchmarkSuites = new VBox(false, 5)) {
			packStart(new Label("Benchmark Browser"), false, false, 0);
			packStart(new HSeparator(), true, true, 0);
			packStart(new Label("Please select a benchmark suite:"), false, false, 0);
			packStart(this.comboBoxBenchmarkSuites, true, true, 0);
			packStart(this.buttonBenchmarkConfigView, true, true, 0);
		}
		
		with(this.comboBoxExperiments = new ComboBox()) {
		    foreach (string name; dirEntries("../configs/experiments", SpanMode.breadth))
		    {
				appendText(basename(name, ".config.xml"));
		    }
			setActive(0);
		}
		
		with(this.boxExperiments = new VBox(false, 5)) {
			packStart(new Label("Experiment Browser"), false, false, 0);
			packStart(new HSeparator(), true, true, 0);
			packStart(new Label("Please select an experiment:"), false, false, 0);
			packStart(this.comboBoxExperiments, true, true, 0);
			packStart(this.buttonExperimentConfigView, true, true, 0);
			packStart(this.buttonExperimentStatView, true, true, 0);
			packStart(this.buttonExperimentRun, true, true, 0);
		}
		
		this.packStart(this.boxBenchmarkSuites, false, false, 0);
		packStart(new Label(""), false, false, 0);
		this.packStart(this.boxExperiments, false, false, 0);
	}

	void buttonBenchmarkConfigViewClicked(Button button) {
		core.thread.Thread thread = new core.thread.Thread(
			{
				BenchmarkSuite benchmarkSuite = BenchmarkSuite.loadXML("../configs/benchmarks", this.selectedBenchmarkSuiteName ~ ".xml");
				this.graphView.graph = new BenchmarkSuiteConfigTree(benchmarkSuite);
				this.graphView.redraw();
			});
		thread.start();
	}

	void buttonExperimentConfigViewClicked(Button button) {
		core.thread.Thread thread = new core.thread.Thread(
			{
				ExperimentConfig experimentConfig = ExperimentConfig.loadXML("../configs/experiments", this.selectedExperimentName ~ ".config.xml");
				this.graphView.graph = new ExperimentConfigTree(experimentConfig);
				this.graphView.redraw();
			});
		thread.start();
	}

	void buttonExperimentStatViewClicked(Button button) {
	}

	void buttonExperimentRunClicked(Button button) {
		string oldButtonLabel = button.getLabel();
		
		core.thread.Thread threadRunExperiment = new core.thread.Thread(
			{
				runExperiment(this.selectedExperimentName);
				
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
	
	GraphView graphView;
}

class TableTreeNodeProperties: Table {
	this(int numProperties = 20) {
		super(numProperties / 2, 2, true);
		
		this.numProperties = numProperties;
		
		for(int i = 0; i < this.numProperties; i++) {
			HBox boxProperty = new HBox(false, 5);
			
			Label labelPropertyName = new Label(format("#%d Name: ", i));
			Label labelPropertyValue = new Label("Value");
			
			boxProperty.packStart(labelPropertyName, true, false, 5);
			boxProperty.packStart(labelPropertyValue, true, false, 5);
			
			this.attach(boxProperty);
		}
	}
	
	int numProperties;
}

class BenchmarkSuiteConfigTree : ImmutableTree {
	this(BenchmarkSuite benchmarkSuite) {
		this.benchmarkSuite = benchmarkSuite;
		
		this.createGraph();
	}
	
	override void doCreateGraph() {
		ImmutableTreeNode nodeRoot = new ImmutableTreeNode(this.benchmarkSuite.title, ImmutableTreeNodeShape.RECTANGLE);
		this.vertices ~= nodeRoot;
		
		foreach(benchmarkTitle, benchmark; this.benchmarkSuite.benchmarks) {
			ImmutableTreeNode nodeBenchmark = new ImmutableTreeNode(benchmark.title, ImmutableTreeNodeShape.RECTANGLE);
			this.vertices ~= nodeBenchmark;
			
			this.addEdge(nodeRoot, nodeBenchmark);
		}
	}
	
	BenchmarkSuite benchmarkSuite;
}

class ExperimentConfigTree : ImmutableTree {
	this(ExperimentConfig experimentConfig) {
		this.experimentConfig = experimentConfig;
		
		this.createGraph();
	}
	
	override void doCreateGraph() {
		ImmutableTreeNode nodeRoot = new ImmutableTreeNode(this.experimentConfig.title, ImmutableTreeNodeShape.RECTANGLE);
		this.vertices ~= nodeRoot;
		
		foreach(simulationConfig; this.experimentConfig.simulationConfigs) {
			ImmutableTreeNode nodeSimulationConfig = new ImmutableTreeNode(simulationConfig.title, ImmutableTreeNodeShape.RECTANGLE);
			this.vertices ~= nodeSimulationConfig;
			
			this.addEdge(nodeRoot, nodeSimulationConfig);
			
			ImmutableTreeNode nodeProcessorConfig = new ImmutableTreeNode("processor config", ImmutableTreeNodeShape.RECTANGLE);
			this.vertices ~= nodeProcessorConfig;
			
			this.addEdge(nodeSimulationConfig, nodeProcessorConfig);
			
			ImmutableTreeNode nodeMemorySystemConfig = new ImmutableTreeNode("memory system config", ImmutableTreeNodeShape.RECTANGLE);
			this.vertices ~= nodeMemorySystemConfig;

			this.addEdge(nodeSimulationConfig, nodeMemorySystemConfig);
		}
	}
	
	ExperimentConfig experimentConfig;
}