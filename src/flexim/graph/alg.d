/*
 * flexim/graph/alg.d
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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flexim.	If not, see <http ://www.gnu.org/licenses/>.
 */

module flexim.graph.alg;

import flexim.all;

void createEdges(Graph g, GraphShape shape) {
	switch(shape) {
		case GraphShape.CIRCULAR:
			g.edges.length = g.vertices.length;
			circularEdges(g);
		break;
		case GraphShape.CENTERED:
			g.edges.length = g.vertices.length - 1;
			centeredEdges(g);
		break;
		case GraphShape.INTERCONNECTED:
			g.edges.length = g.vertices.length * (g.vertices.length - 1) / 2;
			interconnectedEdges(g);
		break;
		case GraphShape.BINARY_TREE:
			g.edges.length = g.vertices.length - 1;
			binaryTreeEdges(g);
		break;
		default:
			g.edges.length = 0;
		break;
	}
}

void circularEdges(Graph g) {
	foreach(i, ref v; g.vertices) {
		g.edges[i] = new Edge();
		g.edges[i].v1 = v;
		if(i == g.vertices.length - 1) {
			g.edges[i].v2 = g.vertices[0];
		}
		else {
			g.edges[i].v2 = g.vertices[i + 1];
		}
	}
}

void centeredEdges(Graph g) {
	foreach(i, ref v; g.vertices[1..$]) {
		g.edges[i] = new Edge();
		g.edges[i].v1 = g.vertices[0];
		g.edges[i].v2 = v;
	}
}

void interconnectedEdges(Graph g) {
	int edgeIndex = 0;
	
	foreach(i, ref v; g.vertices) {
		foreach(ref w; g.vertices[i + 1 .. $]) {
			g.edges[edgeIndex] = new Edge();
			g.edges[edgeIndex].v1 = v;
			g.edges[edgeIndex].v2 = w;
			++edgeIndex;
		}
	}
}

void binaryTreeEdges(Graph g) {
	int othVertexIndex = 0, edgeIndex = 0;
	
	foreach(i, ref v; g.vertices) {
		othVertexIndex = i * 2;
		
		if(othVertexIndex + 1 > g.vertices.length - 1) {
			break;
		}
		else {
			g.edges[edgeIndex] = new Edge();
			g.edges[edgeIndex].v1 = g.vertices[i];
			g.edges[edgeIndex].v2 = g.vertices[othVertexIndex + 1];
			edgeIndex++;
		}
		
		if(othVertexIndex + 2 > g.vertices.length - 1) {
			break;
		}
		else {
			g.edges[edgeIndex] = new Edge();
			g.edges[edgeIndex].v1 = g.vertices[i];
			g.edges[edgeIndex].v2 = g.vertices[othVertexIndex + 2];
			edgeIndex++;
		}
	}
}

void randomVertices(Graph g, int size) {
	g.vertices.length = size;
	foreach(ref v; g.vertices) {
		v = new Vertex();
		v.size = 40;
		v.drawSize = v.size / 6;
		v.pos.x = uniform(v.size, g.width - v.size);
		v.pos.y = uniform(v.size, g.height - v.size);
	}
}

bool intersect(Edge e, Edge f) {
	double xi = -(e.constant - f.constant) / (e.slope - f.slope);
	double yi = e.constant + (e.slope * xi);
	
	return e.lies(xi, yi) && f.lies(xi, yi);
}

void highlightIntersections(Graph g) {
	foreach(i, ref e; g.edges) {
		foreach(ref f; g.edges[i + 1..$]) {
			e.selected = f.selected = intersect(e, f);
		}
	}
}

enum ForceLayoutType {
	SIMPLE,
	TIME,
	BH
}

abstract class ForceLayout {
	this() {
		this.energy = new Vector();
	}
	
	abstract void run();
	abstract void update(Vertex v);
	
	int eConst, sConst, sLength, nThreads;
	bool sNL;
	double damping, timeStep;
	Vector energy;
	Graph graph;
}

class SimpleForceLayout: ForceLayout {
	this() {
	}
	
	override void run() {
		this.energy.x = 0.0;
		this.energy.y = 0.0;
		
		foreach(ref curV; this.graph.vertices) {
			if(curV.locked) {
				continue;
			}
			
			foreach(ref othV; this.graph.vertices) {
				if(curV != othV) {
					this.repulsion(curV, othV);
				}
			}
			
			foreach(ref curE; this.graph.edges) {
				if(curV == curE.v1 || curV == curE.v2) {
					if(this.sNL) {
						this.attractionNL(curE, curV);
					}
					else {
						this.attraction(curE, curV);
					}
				}
			}
			
			this.update(curV);
		}
	}
	
	void attractionNL(Edge e, Vertex v) {
		Vertex a, b;
		
		if(v == e.v1) {
			a = e.v1;
			b = e.v2;
		}
		else {
			b = e.v1;
			a = e.v2;
		}

		Vector delta = new Vector();
		delta.x = a.pos.x - b.pos.x;
		delta.y = a.pos.y - b.pos.y;
		
		double distance = sqrt(delta.x * delta.x + delta.y * delta.y);
		
		double factor = -this.sConst * (distance - this.sLength) / distance;
		
		a.netf.x += delta.x * factor;
		b.netf.y += delta.y * factor;
	}
	
	void attraction(Edge e, Vertex v) {
		Vertex a, b;
		
		if(v == e.v1) {
			a = e.v1;
			b = e.v2;
		}
		else {
			b = e.v1;
			a = e.v2;
		}

		Vector distance = new Vector();
		distance.x = a.pos.x - b.pos.x;
		distance.y = a.pos.y - b.pos.y;
		
		a.netf.x += -this.sConst * distance.x;
		a.netf.y += -this.sConst * distance.y;
	}
	
	void repulsion(Vertex v1, Vertex v2) {
		Vector distance = new Vector();
		distance.x = v1.pos.x - v2.pos.x;
		distance.y = v1.pos.y - v2.pos.y;
		
		double numer = v1.size * v2.size * this.eConst;
		double denom = pow(distance.x * distance.x + distance.y * distance.y, 1.5);
		
		v1.netf.x += numer * distance.x / denom;
		v1.netf.y += numer * distance.y / denom;
	}
	
	override void update(Vertex v) {
		v.vel.x = (v.vel.x + this.timeStep * v.netf.x) * this.damping;
		v.vel.y = (v.vel.y + this.timeStep * v.netf.y) * this.damping;
		v.pos.x += v.vel.x * timeStep;
		v.pos.y += v.vel.y * timeStep;
		
		if(graph.wall) {
			if(v.pos.x < v.drawSize) {
				v.pos.x = v.drawSize;
				v.vel.x = 0.0;
			}
			if(v.pos.x > this.graph.width - v.drawSize) {
				v.pos.x = this.graph.width - v.drawSize;
				v.vel.x = 0.0;
			}
			if(v.pos.y < v.drawSize) {
				v.pos.y = v.drawSize;
				v.vel.y = 0.0;
			}
			if(v.pos.y > this.graph.height - v.drawSize) {
				v.pos.y = this.graph.height - v.drawSize;
				v.vel.y = 0.0;
			}
		}
		
		this.energy.x += v.size * v.vel.x * v.vel.x / 2;
		this.energy.y += v.size * v.vel.y * v.vel.y / 2;
		
		v.netf.x = 0.0;
		v.netf.y = 0.0;
	}
}

class TimeForceLayout: SimpleForceLayout {
	this() {
	}
	
	override void run() {
		this.energy.x = 0.0;
		this.energy.y = 0.0;
		
		foreach(i, ref curV; this.graph.vertices) {
			foreach(ref othV; this.graph.vertices[i + 1..$]) {
				this.repulsion(curV, othV);
			}
		}
		
		foreach(ref curE; this.graph.edges) {
			if(this.sNL) {
				this.attractionNL(curE);
			}
			else {
				this.attraction(curE);
			}
		}
		
		foreach(ref curV; this.graph.vertices) {
			update(curV);
		}
	}
	
	void attractionNL(Edge e) {
		Vertex a = e.v1, b = e.v2;
		
		Vector delta = new Vector();
		delta.x = a.pos.x - b.pos.x;
		delta.y = a.pos.y - b.pos.y;
		
		double distance = sqrt(delta.x * delta.x + delta.y * delta.y);
		
		double factor = -this.sConst * (distance - this.sLength) / distance;
		
		Vector res = new Vector();
		res.x = delta.x * factor;
		res.y = delta.y * factor;
		
		a.netf.x += res.x;
		a.netf.y += res.y;
		b.netf.x -= res.x;
		b.netf.y -= res.y;
	}
	
	void attraction(Edge e) {
		Vertex a = e.v1, b = e.v2;
		
		Vector res = new Vector();		
		res.x = -this.sConst * (a.pos.x - b.pos.x);
		res.y = -this.sConst * (a.pos.y - b.pos.y);
		
		a.netf.x += res.x;
		a.netf.y += res.y;
		b.netf.x -= res.x;
		b.netf.y -= res.y;
	}
	
	override void repulsion(Vertex v1, Vertex v2) {		
		Vector distance = new Vector();
		distance.x = v1.pos.x - v2.pos.x;
		distance.y = v1.pos.y - v2.pos.y;
		
		double numer = v1.size * v2.size * this.eConst;
		double denom = pow(distance.x * distance.x + distance.y * distance.y, 1.5);
		
		Vector res = new Vector();
		res.x = numer * distance.x / denom;
		res.y = numer * distance.y / denom;
		
		v1.netf.x += res.x;
		v1.netf.y += res.y;
		v2.netf.x -= res.x;
		v2.netf.y -= res.y;
	}
}

class BHForceLayout: TimeForceLayout {
	this() {
	}
	
	override void run() {
		QuadTree tree = new QuadTree();
		this.graph.getQuadrant(tree.quadrant);
		
		foreach(ref v; graph.vertices) {
			tree.insertVertex(v);
		}
		
		tree.calculateCenterOfMass();
		
		this.energy.x = 0.0;
		this.energy.y = 0.0;
		
		foreach(ref v; this.graph.vertices) {
			this.repulsion(v, tree);
		}
		
		foreach(ref curE; this.graph.edges) {
			if(this.sNL) {
				this.attractionNL(curE);
			}
			else {
				this.attraction(curE);
			}
		}
		
		foreach(ref curV; this.graph.vertices) {
			this.update(curV);
		}
		
		tree.destroy();
		delete tree;
	}
	
	void repulsion(Vertex v, QuadTree t) {
		if(t.vertex == v) {
			return;
		}
		else {
			if(t.isLeaf) {
				this.repulsion(v, t.vertex);
			}
			else {
				double ratio = t.quadrant.length / this.distance(v, t.vertex);
				if(ratio < this.theta) {
					this.repulsion(v, t.vertex);
				}
				else {
					foreach(c; t.children) {
						if(c !is null) {
							this.repulsion(v, c);
						}
					}
				}
			}
		}
	}
	
	override void repulsion(Vertex v1, Vertex v2) {		
		Vector distance = new Vector();
		distance.x = v1.pos.x - v2.pos.x;
		distance.y = v1.pos.y - v2.pos.y;
		
		double numer = v1.size * v2.size * this.eConst;
		double denom = pow(distance.x * distance.x + distance.y * distance.y, 1.5);
		
		Vector res = new Vector();
		res.x = numer * distance.x / denom;
		res.y = numer * distance.y / denom;
		
		v1.netf.x += res.x;
		v1.netf.y += res.y;
	}
	
	double distance(Vertex v1, Vertex v2) {
		double dx = v1.pos.x - v2.pos.x, dy = v1.pos.y - v2.pos.y;
		return sqrt(dx * dx + dy * dy);
	}
	
	double theta = 0.5;
}