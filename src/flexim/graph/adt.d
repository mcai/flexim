/*
 * flexim/graph/adt.d
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

module flexim.graph.adt;

import flexim.all;

import cairo.Context;

class Vector {
	this() {
		this.x = 0.0;
		this.y = 0.0;
	}
	
	double x, y;
}

class Vertex {
	this() {
		this.locked = false;
		this.selected = false;
		
		this.pos = new Vector();
		this.vel = new Vector();
		this.netf = new Vector();
	}
	
	void expose(Context context) {
		newDrawing(context, 
			{
				if(this.selected) {
					newDrawing(context,
						{
							context.setSourceRgb(0.9, 0.6, 0.0);
							context.rectangle(this.pos.x - this.drawSize - 10,
								this.pos.y - this.drawSize - 10,
								this.drawSize * 2 + 20,
								this.drawSize * 2 + 20);
							context.fillPreserve();
							context.setSourceRgb(0.7, 0.4, 0.0); 
							context.stroke();	
						});
				}
				
				if(this.locked) {
					context.setSourceRgb(0.8, 0.0, 0.0);
				}
				
				context.arc(this.pos.x, this.pos.y, this.drawSize, 0, 2 * PI);
				context.closePath();
				context.fill();
			});
	}

	Vector pos, vel, netf;
	int size, drawSize;
	bool locked, selected;
}

class Edge {
	this() {
	}
	
	void expose(ref Context context) {
		newDrawing(context, 
			{
				if(this.selected) {
					context.setSourceRgb(0.8, 0.0, 0.0);
				}
				
				context.moveTo(this.v1.pos.x, this.v1.pos.y);
				context.lineTo(this.v2.pos.x, this.v2.pos.y);
				context.stroke();
			});
	}
	
	double slope() {
		return (this.v1.pos.y - this.v2.pos.y) / (this.v1.pos.x - this.v2.pos.x);
	}
	
	double constant() {
		return this.v1.pos.y - (this.slope * this.v1.pos.x);
	}
	
	bool lies(double x, double y) {
		return ((this.v1.pos.x - x) * (x - this.v2.pos.x) >= 0 && (this.v1.pos.y - y) * (y - this.v2.pos.y) >= 0);
	}
	
	Vertex v1, v2;
	bool selected;
}

class Quadrant {
	this() {
	}
	
	double centerX() {
		return this.x + (this.length / 2);
	}
	
	double centerY() {
		return this.y + (this.length / 2);
	}
	
	double x, y;
	int length;
}

class QuadTree {
	this() {
		this.quadrant = new Quadrant();
	}
	
	void insertVertex(Vertex v) {
		int childNum;
		
		if(this.vertex is null) {
			this.vertex = v;
		}
		else {
			if(this.isLeaf) {
				if(v.pos.x == this.vertex.pos.x && v.pos.y == this.vertex.pos.y) {
					v.pos.x += min(20, this.quadrant.length - v.pos.x);
					v.pos.y += min(20, this.quadrant.length - v.pos.y);
				}
				
				childNum = this.getChildQuadrantByPosition(v.pos.x, v.pos.y);
				this.createChildQuadTree(childNum);
				this.children[childNum].insertVertex(v);
				childNum = this.getChildQuadrantByPosition(this.vertex.pos.x, this.vertex.pos.y);
				this.createChildQuadTree(childNum);
				this.children[childNum].insertVertex(this.vertex);
			}
			else {
				childNum = this.getChildQuadrantByPosition(v.pos.x, v.pos.y);
				this.createChildQuadTree(childNum);
				this.children[childNum].insertVertex(v);
			}
		}
	}
	
	void createChildQuadTree(int index) {
		if(this.children[index] is null) {
			this.children[index] = new QuadTree();
			this.children[index].quadrant.length = this.quadrant.length / 2;
			switch(index) {
				case 0:
					this.children[index].quadrant.x = this.quadrant.x;
					this.children[index].quadrant.y = this.quadrant.y;
				break;
				case 1:
					this.children[index].quadrant.x = this.quadrant.x + this.children[index].quadrant.length;
					this.children[index].quadrant.y = this.quadrant.y;
				break;
				case 2:
					this.children[index].quadrant.x = this.quadrant.x;
					this.children[index].quadrant.y = this.quadrant.y + this.children[index].quadrant.length;
				break;
				case 3:
					this.children[index].quadrant.x = this.quadrant.x + this.children[index].quadrant.length;
					this.children[index].quadrant.y = this.quadrant.y + this.children[index].quadrant.length;
				break;
				default:
					assert(0);
			}
		}
	}
	
	Vertex calculateCenterOfMass() {
		if(this.isLeaf) {
			return this.vertex;
		}
		
		this.vertex = new Vertex();
		
		foreach(ref child; this.children) {
			if(child !is null) {
				Vertex tempVertex = child.calculateCenterOfMass();
				this.vertex.size += tempVertex.size;
				this.vertex.pos.x += (tempVertex.pos.x * tempVertex.size);
				this.vertex.pos.y += (tempVertex.pos.y * tempVertex.size);
			}
		}
		
		this.vertex.pos.x /= this.vertex.size;
		this.vertex.pos.y /= this.vertex.size;
		
		return this.vertex;
	}
	
	int getChildQuadrantByPosition(double x, double y) {
		if(x >= this.quadrant.x && x <= this.quadrant.centerX) {
			return (y >= this.quadrant.y && y <= this.quadrant.centerY) ? 0 : 2;
		}
		else {
			return (y >= this.quadrant.y && y <= this.quadrant.centerY) ? 1 : 3;
		}
	}
	
	bool isLeaf() {
		foreach(child; this.children) {
			if(child !is null) {
				return false;
			}
		}
		
		return true;
	}
	
	void destroy() {
		if(!this.isLeaf) {
			delete this.vertex;
		}
		
		foreach(child; this.children) {
			if(child !is null) {
				child.destroy();
				delete child;
			}
		}
	}
	
	Quadrant quadrant;
	Vertex vertex;
	QuadTree[4] children;
}

enum GraphShape {
	NONE,
	CIRCULAR,
	CENTERED,
	INTERCONNECTED,
	BINARY_TREE
}

class Graph {
	this() {
	}
	
	Vertex getVertexByPosition(double x, double y) {
		foreach(ref v; this.vertices) {
			if(x >= v.pos.x - v.drawSize &&
				x <= v.pos.x + v.drawSize &&
				y >= v.pos.y - v.drawSize &&
				y <= v.pos.y + v.drawSize) {
				return v;
			}
		}
		
		return null;
	}
	
	void shiftVerticesBy(double x, double y) {
		if(x == 0.0 && y == 0.0) {
			return;
		}
		
		foreach(ref v; this.vertices) {
			v.pos.x += x;
			v.pos.y += y;
		}
	}
	
	void getQuadrant(ref Quadrant q) {
		if(this.vertices.length == 0) {
			q.x = 0;
			q.y = 0;
			q.length = 0;
			return;
		}
		
		double minX, minY, maxX, maxY;
		minX = minY = maxX = maxY = this.vertices[0].pos.x;
		
		foreach(v; this.vertices) {
			minX = min(v.pos.x, minX);
			minY = min(v.pos.y, minY);
			maxX = max(v.pos.x, maxX);
			maxY = max(v.pos.y, maxY);
		}
		
		q.x = minX - 20;
		q.y = minY - 20;
		q.length = cast(int) max(maxX - minX, maxY - minY) + 40;		
	}
	
	void expose(ref Context context) {
		if(this.wall) {
			newDrawing(context, 
				{
					context.setSourceRgb(0.8, 0.0, 0.0);
					context.setLineWidth(10.0);
					context.rectangle(0, 0, this.width, this.height);
					context.stroke();
				});
		}
		
		foreach(ref e; this.edges) {
			e.expose(context);
		}
		
		foreach(ref v; this.vertices) {
			v.expose(context);
		}
	}
	
	int getVertexIndex(Vertex v) {
		foreach(i, ver; this.vertices) {
			if(ver == v) {
				return i;
			}
		}
		
		return -1;
	}
	
	Vertex[] vertices;
	Edge[] edges;
	int width, height;
	bool wall;
}