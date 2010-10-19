/*
 * flexim/ise/models.d
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

module flexim.ise.models;

import flexim.all;

import core.thread;

import std.file;
import std.getopt;
import std.path;

import cairo.Context;

import gtk.Timeout;

enum ImmutableTreeNodeShape: string {
	RECTANGLE = "RECTANGLE",
	CIRCLE = "CIRCLE"
}

class ImmutableTreeNode {
	this(string text, ImmutableTreeNodeShape shape = ImmutableTreeNodeShape.CIRCLE) {
		string[string] props;
		this(text, props, shape);
	}
	
	this(string text, string[string] properties, ImmutableTreeNodeShape shape = ImmutableTreeNodeShape.CIRCLE) {
		this.text = text;
		this.properties = properties;
		
		this.shape = shape;
		
		this.x = 0.0;
		this.y = 0.0;
		
		this.size = 60;
		this.drawSize = this.size / 3;

		this.selected = false;
	}
	
	void expose(Context context) {
		if(this.shape == ImmutableTreeNodeShape.RECTANGLE) {
			context.moveTo(this.x + this.drawSize, this.y + 2);
			context.showText(format("%s", this.text));
				
			newDrawing(context,
				{
					context.setSourceColor(new gdk.Color.Color(this.selected ? 0x36539C: 0x6287E7));
					context.rectangle(this.x - this.drawSize/2,
						this.y - this.drawSize/2,
						this.drawSize,
						this.drawSize);
					context.fillPreserve();
					context.setSourceColor(new gdk.Color.Color(0x000000));
					context.stroke();
				});
		}
		else if (this.shape == ImmutableTreeNodeShape.CIRCLE){
			newDrawing(context,
				{
					context.setSourceColor(new gdk.Color.Color(0x6287E7));
					context.arc(this.x, this.y, (this.drawSize * 2 + 20) / 2, 0, 2 * PI);
					context.closePath();
					context.fillPreserve();
					context.setSourceColor(new gdk.Color.Color(0x000000));
					context.stroke();
				});
			
			context.moveTo(this.x + (this.drawSize * 2 + 20) / 2 + 5, this.y + 5);
			context.showText(format("%s", this.text));
		}
	}
	
	override string toString() {
		return format("%s[x=%f, y=%f, size=%d, drawSize=%d, selected=%s, childrenEdges.length=%d]",
			this.text, this.x, this.y, this.size, this.drawSize, this.selected, this.childrenEdges.length);
	}
	
	string text;
	string[string] properties;
	double x, y;
	int size, drawSize;
	bool selected;
	
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
	
	ImmutableTreeNode getNodeByPosition(double x, double y) {
		foreach(v; this.nodes) {
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
		
		foreach(v; this.nodes) {
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
		
		foreach(v; this.nodes) {
			v.expose(context);
		}
	}
	
	int indexOf(ImmutableTreeNode v) {
		return this.nodes.indexOf(v);
	}
	
	void inorderTraversal(void delegate(ImmutableTreeNode, int) del) {
		this.inorderTraversal(this.nodes[0], 0, del);
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
		
		str ~= "nodes:\n";
		foreach(i, v; this.nodes) {
			str ~= format("[%d] %s\n", i, v);
		}
		
		str ~= "edges:\n";
		foreach(i, e; this.edges) {
			str ~= format("[%d] %s\n", i, e);
		}
		
		return str;
	}
	
	ImmutableTreeNode[] nodes;
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
	
	void addOnNodeDeselected(void delegate(ImmutableTreeNode node) del) {
		this.nodeDeselectedListeners ~= del;
	}
	
	void fireNodeDeselected(ImmutableTreeNode node) {
		foreach(listener; this.nodeDeselectedListeners) {
			listener(node);
		}
	}
	
	void addOnNodeSelected(void delegate(ImmutableTreeNode node) del) {
		this.nodeSelectedListeners ~= del;
	}
	
	void fireNodeSelected(ImmutableTreeNode node) {
		foreach(listener; this.nodeSelectedListeners) {
			listener(node);
		}
	}
	
	void delegate(ImmutableTreeNode node)[] nodeDeselectedListeners;
	void delegate(ImmutableTreeNode node)[] nodeSelectedListeners;
	
	void redraw() {		
		Drawable dr = this.getWindow();

		int width;
		int height;

		dr.getSize(width, height);

		Context context = new Context(dr);
		
		newDrawing(context,
			{
				context.setSourceColor(new gdk.Color.Color(0xDAE3E6));
				context.rectangle(0, 0, this.getAllocation().width, this.getAllocation().height);
				context.fillPreserve();
				context.clip();
				if(this.graph !is null) {
					context.scale(this.getAllocation().width/this.graph.width, this.getAllocation().height/this.graph.height);
				}
				//context.paint();
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
			ImmutableTreeNode v = this.graph.getNodeByPosition(event.x, event.y);
			if(v is null) {
				return false;
			}
			
			if(event.button == 1) {
				if(this.selectedNode !is null && this.selectedNode != v) {
					this.selectedNode.selected = false;
					this.fireNodeDeselected(this.selectedNode);
				}
				
				if(this.selectedNode != v) {
					this.selectedNode = v;
					this.selectedNode.selected = true;
					this.fireNodeSelected(v);
				}
				
				this.draggedNode = v;
				
				this.queueDraw();
			}
		}
		
		return false;
	}
	
	bool buttonReleased(GdkEventButton* event, Widget widget) {
		if(this.graph !is null) {
			this.draggedNode = null;
			
			this.queueDraw();
		}
		return false;
	}
	
	bool motionNotified(GdkEventMotion* event, Widget widget) {
		if(this.graph !is null) {
			if(this.draggedNode !is null) {
				this.draggedNode.x = event.x;
				this.draggedNode.y = event.y;
				this.queueDraw();
			}
		}
		
		return false;
	}
	
	ImmutableTree graph;
	ImmutableTreeNode draggedNode, selectedNode;
}

class BenchmarkSuiteConfigTree : ImmutableTree {
	this(BenchmarkSuite benchmarkSuite) {
		this.benchmarkSuite = benchmarkSuite;
		
		this.createGraph();
	}
	
	override void doCreateGraph() {
		ImmutableTreeNode nodeRoot = new ImmutableTreeNode(this.benchmarkSuite.title, this.benchmarkSuite.properties, ImmutableTreeNodeShape.RECTANGLE);
		this.nodes ~= nodeRoot;
		
		foreach(benchmarkTitle, benchmark; this.benchmarkSuite.benchmarks) {
			ImmutableTreeNode nodeBenchmark = new ImmutableTreeNode(benchmark.title, benchmark.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeBenchmark;
			
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
		ImmutableTreeNode nodeRoot = new ImmutableTreeNode(this.experimentConfig.title, this.experimentConfig.properties, ImmutableTreeNodeShape.RECTANGLE);
		this.nodes ~= nodeRoot;
		
		foreach(simulationConfig; this.experimentConfig.simulationConfigs) {
			ImmutableTreeNode nodeSimulationConfig = new ImmutableTreeNode(simulationConfig.title, simulationConfig.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeSimulationConfig;
			
			this.addEdge(nodeRoot, nodeSimulationConfig);
			
			ImmutableTreeNode nodeProcessorConfig = new ImmutableTreeNode("processor config", simulationConfig.processorConfig.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeProcessorConfig;
			
			this.addEdge(nodeSimulationConfig, nodeProcessorConfig);
			
			ImmutableTreeNode nodeMemorySystemConfig = new ImmutableTreeNode("memory system config", simulationConfig.memorySystemConfig.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeMemorySystemConfig;

			this.addEdge(nodeSimulationConfig, nodeMemorySystemConfig);
		}
	}
	
	ExperimentConfig experimentConfig;
}

class ExperimentStatTree : ImmutableTree {
	this(ExperimentStat experimentStat) {
		this.experimentStat = experimentStat;
		
		this.createGraph();
	}
	
	override void doCreateGraph() {
		ImmutableTreeNode nodeRoot = new ImmutableTreeNode(this.experimentStat.title, this.experimentStat.properties, ImmutableTreeNodeShape.RECTANGLE);
		this.nodes ~= nodeRoot;
		
		foreach(simulationStat; this.experimentStat.simulationStats) {
			ImmutableTreeNode nodeSimulationStat = new ImmutableTreeNode(simulationStat.title, simulationStat.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeSimulationStat;
			
			this.addEdge(nodeRoot, nodeSimulationStat);
			
			ImmutableTreeNode nodeProcessorStat = new ImmutableTreeNode("processor stat", simulationStat.processorStat.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeProcessorStat;
			
			this.addEdge(nodeSimulationStat, nodeProcessorStat);
			
			ImmutableTreeNode nodeMemorySystemStat = new ImmutableTreeNode("memory system stat", simulationStat.memorySystemStat.properties, ImmutableTreeNodeShape.RECTANGLE);
			this.nodes ~= nodeMemorySystemStat;

			this.addEdge(nodeSimulationStat, nodeMemorySystemStat);
		}
	}
	
	ExperimentStat experimentStat;
}