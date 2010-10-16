/*
 * flexim/sim/ideCanvas.d
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

module flexim.sim.ideCanvas;

import flexim.all;

import cairo.Context;
import gdk.Cursor;

enum Direction {
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

class Holder {
	this() {
	}
	
	string[string] properties;
}

class Cursor {
	this() {
		this.set = "default";
		this.set = "aero";
		this.set = "entis";
		this.set = "incarnerry-mark";
		this.set = "volta-ringlets";
		
		gtk.Invisible.Invisible invisible = new gtk.Invisible.Invisible();
		gdk.Screen.Screen screen = invisible.getScreen();
		gdk.Display.Display display = screen.getDisplay();
		
		this.normal = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "pointer.png"), 4, 2);
		this.northwest = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-northwest.png"), 6, 6);
		this.north = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-north.png"), 12, 6);
		this.northeast = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-northeast.png"), 18, 6);
		this.west = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-west.png"), 6, 12);
		this.east = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-east.png"), 18, 12);
		this.southwest = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-southwest.png"), 6, 18);
		this.south = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-south.png"), 12, 18);
		this.southeast = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "direction-southeast.png"), 18, 18);
		this.cross = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "stroke.png"), 2, 20);
		this.move = new gdk.Cursor.Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.set ~ "/" ~ "move.png"), 11, 11);
	}
	
	string set;
	gdk.Cursor.Cursor normal, northwest, north, northeast, west, east, southwest, south, southeast, cross, move;
}

class Point: Holder {
	this() {
		this.x = this.y = 0.0;
	}
	
	double x, y;
}

class Size: Holder {
	this() {
		this.width = this.height = 0.0;
	}
	
	double width, height;
}

class Scale {
	this() {
		this.x = this.y = 1.0;
	}
	
	double x, y;
}

class Color {
	this() {
		this.red = this.green = this.blue = this.alpha = 0.0;
	}
	
	double red, green, blue, alpha;
}

alias Point Origin, Position;

class Rectangle: Holder {
	this() {
		this.x = this.y = this.width = this.height = 0.0;
	}
	
	double x, y, width, height;
}

class Control: Rectangle {
	this() {
		this.offset = new Point();
		this.size = 10.0;
		this.limbus = false;
	}
	
	void draw(Context context) {
		this.width = this.size / 2.0;
		this.height = this.size / 2.0;
		
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		
		context.rectangle(this.x - this.width / 2.0, this.y - this.height / 2.0, this.width, this.height);
		
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
		return x >= (this.x - this.size / 2.0) && x <= (this.x + this.size) && y >= (this.y - this.size / 2.0) && y <= (this.y + this.size);
	}
	
	Point offset;
	double size;
	bool limbus;
}

class Margins: Rectangle {
	this() {
		this.active = true;
		this.top = this.left = this.bottom = this.right = 0;
		
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
		if(this.active) {
			context.setSourceRgb(0.5, 0.5, 0.5);
			double[] dash;
			dash ~= 8.0;
			dash ~= 4.0;
			context.setDash(dash, 0);
			
			context.setLineWidth(2);
			context.rectangle(this.x + this.left, this.y + this.top, this.width - this.right - this.left, this.height - this.bottom - this.top);
			context.stroke();
			
			this.controls[Direction.NORTHWEST].x = this.x + this.left;
			this.controls[Direction.NORTHWEST].y = this.y + this.top;
			
			this.controls[Direction.NORTHEAST].x = this.x + this.width - this.right;
			this.controls[Direction.NORTHEAST].y = this.y + this.top;
			
			this.controls[Direction.SOUTHWEST].x = this.x + this.left;
			this.controls[Direction.SOUTHWEST].y = this.y + this.height - this.bottom;
			
			this.controls[Direction.SOUTHEAST].x = this.x + this.width - this.right;
			this.controls[Direction.SOUTHEAST].y = this.y + this.height - this.bottom;
			
			this.controls[Direction.NORTH].x = this.x + (this.width - this.right) / 2;
			this.controls[Direction.NORTH].y = this.y + this.top;
			
			this.controls[Direction.SOUTH].x = this.x + (this.width - this.right) / 2;
			this.controls[Direction.SOUTH].y = this.y + this.height - this.bottom;
			
			this.controls[Direction.WEST].x = this.x + this.left;
			this.controls[Direction.WEST].y = this.y + (this.height - this.bottom) / 2;
			
			this.controls[Direction.EAST].x = this.x + this.width - this.right;
			this.controls[Direction.EAST].y = this.y + (this.height - this.bottom) / 2;
			
			foreach(control; this.controls) {
				control.draw(context);
			}
		}
	}
	
	bool active;
	double top, left, bottom, right;
	
	Control[Direction] controls;
}

class Paper: Margins {
	this() {
	}
	
	override void draw(Context context) {
		int shadow = 5;
		
		context.setLineWidth(2.5);
		context.rectangle(this.x, this.y, this.width, this.height);
		
		context.setSourceRgb(1.0, 1.0, 1.0);
		context.fillPreserve();
		
		context.setSourceRgb(0.0, 0.0, 0.0);
		double[] dash;
		context.setDash(dash, 0);
		context.stroke();
		
		super.draw(context);
		
		context.setSourceRgba(0.0, 0.0, 0.0, 0.25);
		double[] dash2;
		context.setDash(dash2, 0);
		
		context.setLineWidth(shadow);
		context.moveTo(this.x + this.width + shadow / 2.0, this.y + shadow);
		context.lineTo(this.x + this.width + shadow / 2.0, this.y + this.height + shadow / 2.0);
		context.lineTo(this.x + shadow, this.y + this.height + shadow / 2.0);
		context.stroke();
	}
}

class Grid: Rectangle {
	this() {
		this.active = true;
		this.size = 15.0;
		this.snap = false;
	}
	
	void draw(Context context) {
		context.setLineWidth(0.15);
		context.setSourceRgb(0.0, 0.0, 0.0);
		double[] dash;
		dash ~= 2.0;
		dash ~= 5.0;
		context.setDash(dash, 0);
		
		double _x = this.x;
		double _y = this.y;
		
		while(_x <= this.x + this.width) {
			context.moveTo(_x, this.y);
			context.lineTo(_x, this.y + this.height);
			_x += this.size;
		}
		
		while(_y <= this.y + this.height) {
			context.moveTo(this.x, _y);
			context.lineTo(this.x + this.width, _y);
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
	
	bool active, snap;
	double size;
}

class Axis: Rectangle {
	this() {
		this.active = true;
		this.size = 15.0 * 8.0;
	}
	
	void draw(Context context) {
		context.setLineWidth(0.5);
		context.setSourceRgb(0.0, 0.0, 0.0);
		double[] dash;
		dash ~= 2.0;
		dash ~= 4.0;
		dash ~= 24.0;
		dash ~= 4.0;
		context.setDash(dash, 0);
		
		double _x = this.x;
		double _y = this.y;
		
		while(_x <= this.x + this.width) {
			context.moveTo(_x, this.y);
			context.moveTo(_x, this.y + this.height);
			_x += this.size;
		}
		
		while(_y <= this.y + this.height) {
			context.moveTo(this.x, _y);
			context.lineTo(this.x + this.width, _y);
			_y += this.size;
		}
		
		context.stroke();
	}
	
	bool active;
	double size;
}

class Selection: Rectangle {
	this() {
		this.active = false;
	}
	
	void draw(Context context) {
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.x, this.y, this.width, this.height);
		context.setSourceRgba(0.0, 0.0, 0.5, 0.25);
		context.fillPreserve();
		context.setSourceRgba(0.0, 0.0, 0.25, 0.5);
		context.stroke();
	}
	
	bool active;
}

class Handler: Rectangle {
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
		context.rectangle(this.x, this.y, this.width, this.height);
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
	
	Control[Direction] controls;
	bool line;
}

abstract class DrawableObject: Rectangle {
	this() {
		this.handler = new Handler();
		this.offset = new Rectangle();
		this.selected = false;
		this.resize = false;
		this.direction = Direction.NONE;
	}
	
	abstract void post();
	
	void draw(Context context) {
		if(this.selected) {
			this.handler.x = this.x;
			this.handler.y = this.y;
			this.handler.width = this.width;
			this.handler.height = this.height;
			this.post();
			this.handler.draw(context);
		}
	}
	
	bool atPosition(double x, double y) {
		return x >= (this.x - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			x <= (this.x + this.width + this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y >= (this.y - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y <= (this.y + this.height + this.handler.controls[Direction.NORTHWEST].size / 2.0);
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
		return (x + width) > this.x && (y + height) > this.y &&
			x < (this.x + this.width) && y < (this.y + this.height);
	}
	
	bool inSelection(Selection selection) {
		return this.inRegion(selection.x, selection.y, selection.width, selection.height);
	}
	
	Handler handler;
	Rectangle offset;
	bool selected, resize;
	Direction direction;
}

/*class Text: DrawableObject {
	this(string text) {
		this.properties["font"] = "Verdana";
		this.properties["size"] = "32";
		this.properties["preserve"] = "True";
		this.properties["text"] = text;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].x = this.x;
		this.handler.controls[Direction.NORTHWEST].y = this.y;
		
		this.handler.controls[Direction.NORTHEAST].x = this.x + this.width;
		this.handler.controls[Direction.NORTHEAST].y = this.y;
		
		this.handler.controls[Direction.SOUTHWEST].x = this.x;
		this.handler.controls[Direction.SOUTHWEST].y = this.y + this.height;
		
		this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
		this.handler.controls[Direction.SOUTHEAST].y = this.y + this.height;
		
		this.handler.controls[Direction.NORTH].x = this.x + this.width / 2;
		this.handler.controls[Direction.NORTH].y = this.y;
		
		this.handler.controls[Direction.SOUTH].x = this.x + this.width / 2;
		this.handler.controls[Direction.SOUTH].y = this.y + this.height;
		
		this.handler.controls[Direction.WEST].x = this.x;
		this.handler.controls[Direction.WEST].y = this.y + this.height / 2;
		
		this.handler.controls[Direction.EAST].x = this.x + this.width;
		this.handler.controls[Direction.EAST].y = this.y + this.height / 2;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		newDrawing(context, 
			{
				Context _context = new pangocairo.Context(context); //TODO
				Layout layout = new pangocairo.Layout(context); //TODO
				
				string fontname = this.properties["font"];
				//TODO
				FontDescription font = new FontDescription(description);
				layout.setJustify(true);
				layout.setFontDescription(font);
				string text = this.properties["text"];
				layout.setMarkup(text);
				
				_context.setSourceRgb(0.0, 0.0, 0.0);
				_context.moveTo(this.x, this.y);
				
				bool preserve = to!(bool)(this.properties["preserve"]);
				
				if(!preserve) {
					double width = layout.size.width;
					double height = layout.size.height;
					width /= pango.SCALE;
					height /= pango.SCALE;
					this.scale(context, width, height);
				}
				else {
					layout.setWidth(cast(int) (this.width) * pango.SCALE);
					double width = layout.size.width;
					double height = layout.size.height;
					height /= pango.SCALE;
					this.height = height;
				}
				
				context.showLayout(layout);
			});
	}
	
	void scale(Context context, double width, double height) {
		if(this.width == 0) {
			this.width = width;
		}
		
		if(this.height == 0) {
			this.height = height;
		}
		
		Scale scale = new Scale();
		scale.x = this.width / width;
		scale.y = this.height / height;
		
		if(scale.x != 0) {
			context.scale(scale.x, 1.0);
		}
		
		if(scale.y != 0) {
			context.scale(1.0, scale.y);
		}
	}
}*/

class Box: DrawableObject {
	this() {
		this.color = new Color();
		this.color.red = 0.25;
		this.color.green = 0.25;
		this.color.blue = 0.25;
		this.color.alpha = 0.25;
	}
	
	override void post() {
	    this.handler.controls[Direction.NORTHWEST].x = this.x;
	    this.handler.controls[Direction.NORTHWEST].y = this.y;
	    
	    this.handler.controls[Direction.NORTHEAST].x = this.x + this.width;
	    this.handler.controls[Direction.NORTHEAST].y = this.y;
	    
	    this.handler.controls[Direction.SOUTHWEST].x = this.x;
	    this.handler.controls[Direction.SOUTHWEST].y = this.y + this.height;
	    
	    this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
	    this.handler.controls[Direction.SOUTHEAST].y = this.y + this.height;
	    
	    this.handler.controls[Direction.NORTH].x = this.x + this.width / 2;
	    this.handler.controls[Direction.NORTH].y = this.y;
	    
	    this.handler.controls[Direction.SOUTH].x = this.x + this.width / 2;
	    this.handler.controls[Direction.SOUTH].y = this.y + this.height;
	    
	    this.handler.controls[Direction.WEST].x = this.x;
	    this.handler.controls[Direction.WEST].y = this.y + this.height / 2;
	    
	    this.handler.controls[Direction.EAST].x = this.x + this.width;
	    this.handler.controls[Direction.EAST].y = this.y + this.height / 2;
	}
	
	override void draw(Context context) {
		super.draw(context);
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.x, this.y, this.width, this.height);
		context.setSourceRgba(this.color.red, this.color.green, this.color.blue, this.color.alpha);
		context.fillPreserve();
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	Color color;
}

class RoundedBox: DrawableObject {
	this() {
		this.color = new Color();
		this.color.red = 0.25;
		this.color.green = 0.25;
		this.color.blue = 0.25;
		this.color.alpha = 0.25;
		
		this.handler.controls[Direction.END] = new Control();
	}
	
	override void post() {
	    this.handler.controls[Direction.NORTHWEST].x = this.x;
	    this.handler.controls[Direction.NORTHWEST].y = this.y;
	    
	    this.handler.controls[Direction.NORTHEAST].x = this.x + this.width;
	    this.handler.controls[Direction.NORTHEAST].y = this.y;
	    
	    this.handler.controls[Direction.SOUTHWEST].x = this.x;
	    this.handler.controls[Direction.SOUTHWEST].y = this.y + this.height;
	    
	    this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
	    this.handler.controls[Direction.SOUTHEAST].y = this.y + this.height;
	    
	    this.handler.controls[Direction.NORTH].x = this.x + this.width / 2;
	    this.handler.controls[Direction.NORTH].y = this.y;
	    
	    this.handler.controls[Direction.SOUTH].x = this.x + this.width / 2;
	    this.handler.controls[Direction.SOUTH].y = this.y + this.height;
	    
	    this.handler.controls[Direction.WEST].x = this.x;
	    this.handler.controls[Direction.WEST].y = this.y + this.height / 2;
	    
	    this.handler.controls[Direction.EAST].x = this.x + this.width;
	    this.handler.controls[Direction.EAST].y = this.y + this.height / 2;
	    
	    this.handler.controls[Direction.END].x = this.x + this.radius;
	    this.handler.controls[Direction.END].y = this.y + this.radius;
	    this.handler.controls[Direction.END].limbus = true;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		double _radius = this.radius;
		
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		
		if(_radius > (this.height / 2) || _radius > (this.width / 2)) {
			if((this.height / 2) < (this.width / 2)) {
				_radius = this.height / 2;
			}
			else {
				_radius = this.width / 2;
			}
		}
		
		context.moveTo(this.x, this.y + _radius);
		context.arc(this.x + _radius, this.y + _radius, _radius, PI, -PI / 2);
		context.lineTo(this.x + this.width - _radius, this.y);
		context.arc(this.x + this.width - _radius, this.y + _radius, _radius, -PI / 2, 0);
		context.lineTo(this.x + this.width, this.y + this.height - _radius);
		context.arc(this.x + this.width - _radius, this.y + this.height - _radius, _radius, 0, PI / 2);
		context.lineTo(this.x + _radius, this.y + this.height);
		context.arc(this.x + this.radius, this.y + this.height - _radius, _radius, PI / 2, PI);
		context.closePath();
		
		context.setSourceRgba(this.color.red, this.color.green, this.color.blue, this.color.alpha);
		context.fillPreserve();
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	double radius;
	Color color;
}

class Line: DrawableObject {
	this() {
		this.handler.line = true;
		this.thickness = 2.5;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].x = this.x;
		this.handler.controls[Direction.NORTHWEST].y = this.y;
		
		this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
		this.handler.controls[Direction.SOUTHEAST].y = this.y +  this.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dash, 0);
		context.setLineWidth(this.thickness);
		context.moveTo(this.x, this.y);
		context.lineTo(this.x + this.width, this.y + this.height);
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	double[] dash;
	double thickness;
}

class Flex: DrawableObject {
	this() {
		this.thickness = 2.5;
		this.radius = 20;
		
		this.handler.controls[Direction.END] = new Control();
		this.handler.controls[Direction.END2] = new Control();
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].x = this.x;
		this.handler.controls[Direction.NORTHWEST].y = this.y;
		
		this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
		this.handler.controls[Direction.SOUTHEAST].y = this.y + this.height;
		
		this.handler.controls[Direction.END].limbus = true;
		this.handler.controls[Direction.END].x = this.x + this.width / 2;
		this.handler.controls[Direction.END].y = this.y;
		
		this.handler.controls[Direction.END2].limbus = true;
		this.handler.controls[Direction.END2].x = this.x + this.width / 2;
		this.handler.controls[Direction.END2].y = this.y + this.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dash, 0);
		context.setLineWidth(this.thickness);
		context.curveTo(this.x, this.y, this.handler.controls[Direction.END].x, this.handler.controls[Direction.END].y,
			this.x + this.width / 2, this.y + this.height / 2);
		context.curveTo(this.x + this.width / 2, this.y + this.height / 2, this.handler.controls[Direction.END2].x, this.handler.controls[Direction.END2].y,
			this.x + this.width, this.y + this.height);
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	double thickness, radius;
	double[] dash;
}

class Curve: DrawableObject {
	this() {
		this.thickness = 2.5;
		this.radius = 20;
		
		this.handler.controls[Direction.END] = new Control();
		
		this.block = false;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].x = this.x;
		this.handler.controls[Direction.NORTHWEST].y = this.y;
		this.handler.controls[Direction.SOUTHEAST].x = this.x + this.width;
		this.handler.controls[Direction.SOUTHEAST].y = this.y + this.height;
		
		if(!this.block) {
			this.handler.controls[Direction.END].limbus = true;
			this.handler.controls[Direction.END].x = this.x + this.width;
			this.handler.controls[Direction.END].y = this.y;
			this.block = !this.block;
		}
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(dash, 0);
		context.setLineWidth(this.thickness);
		context.curveTo(this.x, this.y, this.handler.controls[Direction.END].x, this.handler.controls[Direction.END].y, this.x + this.width, this.y + this.height);
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	double thickness, radius;
	double[] dash;
	bool block;
}

class Canvas: DrawingArea {
	this() {
		this.paper = new Paper();
		this.origin = new Origin();
		this.grid = new Grid();
		this.axis = new Axis();
		this.selection = new Selection();
		this.cursor = new Cursor();
		
		this.total = new Size();

		this.origin.x = 0;
		this.origin.y = 0;
		
		this.border = 25;
		
		this.pick = false;
		this.updated = false;
		this.selectedChild = null;
		
		this.addEvents(GdkEventMask.BUTTON_PRESS_MASK);
		this.addEvents(GdkEventMask.BUTTON_RELEASE_MASK);
		this.addEvents(GdkEventMask.POINTER_MOTION_MASK);
		this.addEvents(GdkEventMask.BUTTON_MOTION_MASK);
		
		this.addOnExpose(&this.exposed);
		this.addOnButtonPress(&this.buttonPressed);
		this.addOnButtonRelease(&this.buttonReleased);
		this.addOnMotionNotify(&this.motionNotified);
		
		this.setupSampleData();
	}
	
	void setupSampleData() {
		this.paper.x = 25;
		this.paper.y = 25;
		this.paper.top = 25;
		this.paper.left = 25;
		this.paper.bottom = 25;
		this.paper.right = 25;
		this.paper.width = 800;
		this.paper.height = 500;
		
		/*Text text = new Text("foo");
		this.add(text);
		
		text = new Text("bar");
		text.y += 100;
		this.add(text);
		
		text = new Text("baz");
		text.y += 200;
		this.add(text);*/
		
		Box box = new Box();
		box.x = 200;
		box.y = 200;
		box.width = 100;
		box.height = 100;
		this.add(box);
		
		Line line = new Line();
		line.y = 300;
		line.width = 100;
		line.height = 100;
		this.add(line);
		
		RoundedBox rounded = new RoundedBox();
		rounded.width = 100;
		rounded.height = 100;
		rounded.x = 500;
		this.add(rounded);
		
		Curve curve = new Curve();
		curve.width = 100;
		curve.height = 100;
		curve.x = 600;
		curve.y = 250;
		this.add(curve);
		
		this.grid.snap = true;
	}
	
	void addOnSelected(void delegate(DrawableObject child) del) {
		this.selectedListeners ~= del;
	}
	
	void fireSelected(DrawableObject child) {
		foreach(listener; this.selectedListeners) {
			listener(child);
		}
	}
	
	void delegate(DrawableObject)[] selectedListeners;
	
	bool exposed(GdkEventExpose* event, Widget widget) {
		Context context = new Context(this.getWindow());
		
		double width = event.area.width;
		double height = event.area.height;
		
		this.total.width = this.paper.width + 2 * this.border;
		this.total.height = this.paper.height + 2 * this.border;
		
		if(width < this.total.width) {
			width = this.total.width;
		}
		
		if(height < this.total.height) {
			height = this.total.height;
		}
		
		this.setSizeRequest(cast(int) width, cast(int) height);
		
		context.setSourceRgb(0.75, 0.75, 0.75);
		context.paint();
		
		this.paper.x = (width - this.paper.width) / 2;
		this.paper.y = (width - this.paper.height) / 2;
		
		if(this.paper.x < this.border) {
			this.paper.x = this.border;
		}
		
		if(this.paper.y < this.border) {
			this.paper.y = this.border;
		}
		
		this.paper.draw(context);
		
		this.origin.x = this.paper.x + this.paper.left;
		this.origin.y = this.paper.y + this.paper.top;
		
		if(this.grid.active) {
			this.grid.x = this.origin.x;
			this.grid.y = this.origin.y;
			this.grid.width = this.paper.width - this.paper.left - this.paper.right;
			this.grid.height = this.paper.height - this.paper.top - this.paper.bottom;
			this.grid.draw(context);
		}
		
		if(this.axis.active) {
			this.axis.x = this.origin.x;
			this.axis.y = this.origin.y;
			this.axis.width = this.paper.width - this.paper.left - this.paper.right;
			this.axis.height = this.paper.height - this.paper.top - this.paper.bottom;
			this.axis.draw(context);
		}
		
		foreach(child; this.children) {
			child.x += this.origin.x;
			child.y += this.origin.y;
			child.draw(context);
			child.x -= this.origin.x;
			child.y -= this.origin.y;
		}
		
		if(this.selection.active) {
			this.selection.x += this.origin.x;
			this.selection.y += this.origin.y;
			this.selection.draw(context);
			this.selection.x -= this.origin.x;
			this.selection.y -= this.origin.y;
		}
		
		this.updated = true;
		
		return false;
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
			
			DrawableObject child = this.selectedChild;
			child.selected = true;
			this.fireSelected(child);
			child.resize = true;
			child.x = this.grid.nearest(event.x);
			child.y = this.grid.nearest(event.y);
			child.width = 0;
			child.height = 0;
			this.add(child);
			
			child.offset.x = event.x;
			child.offset.y = event.y;
			child.offset.width = child.width;
			child.offset.height = child.height;
			
			child.direction = Direction.SOUTHEAST;
			child.handler.controls[child.direction].offset.x = event.x - child.x;
			child.handler.controls[child.direction].offset.y = event.y - child.y;
			
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
					child.offset.width = child.width;
					child.offset.height = child.height;
					child.resize = true;
					child.direction = child.handler.getDirection(event.x + this.origin.x, event.y + this.origin.y);
					child.handler.controls[child.direction].offset.x = event.x - child.x;
					child.handler.controls[child.direction].offset.y = event.y - child.y;
				}
				break;
			}
		}
		
		if(!resize) {
			foreach(child; this.children) {
				child.resize = false;
				if(child.selected) {
					child.offset.x = event.x - child.x;
					child.offset.y = event.y - child.y;
					if(!child.atPosition(event.x, event.y) && !move && event.state != ModifierType.CONTROL_MASK  || child.atPosition(event.x, event.y) && move && event.state == ModifierType.CONTROL_MASK) {
						child.selected = false;
					}
					else {
						child.selected = true;
						this.fireSelected(child);
					}
				}
			}
			
			if(!selected && !move) {
				this.selection.x = event.x;
				this.selection.y = event.y;
				this.selection.width = 0;
				this.selection.height = 0;
				this.selection.active = true;
			}
			else {
				this.updated = false;
			}
			
			this.queueDraw();
		}
		
		return false;
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
		this.getWindow().setCursor(this.cursor.normal);
		
		this.needUpdate = false;
		this.queueDraw();
		
		return true;
	}
	
	bool motionNotified(GdkEventMotion* event, Widget widget) {
		//TODO: disconnect motion id
		
		double x = event.x - this.origin.x;
		double y = event.y - this.origin.y;
		
		Direction direction = Direction.NONE;
		if(event.state != ModifierType.BUTTON1_MASK) {
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
				this.getWindow().setCursor(this.cursor.northwest);
			}
			else if(direction == Direction.NORTH) {
				this.getWindow().setCursor(this.cursor.north);
			}
			else if(direction == Direction.NORTHEAST) {
				this.getWindow().setCursor(this.cursor.northeast);
			}
			else if(direction == Direction.WEST) {
				this.getWindow().setCursor(this.cursor.west);
			}
			else if(direction == Direction.EAST) {
				this.getWindow().setCursor(this.cursor.east);
			}
			else if(direction == Direction.SOUTHWEST) {
				this.getWindow().setCursor(this.cursor.southwest);
			}
			else if(direction == Direction.SOUTH) {
				this.getWindow().setCursor(this.cursor.south);
			}
			else if(direction == Direction.SOUTHEAST) {
				this.getWindow().setCursor(this.cursor.southwest);
			}
		}
		else if(event.state == ModifierType.BUTTON1_MASK) {
			this.getWindow().setCursor(this.cursor.move);
		}
		else if(this.pick) {
			this.getWindow().setCursor(this.cursor.cross);
		}
		else {
			this.getWindow().setCursor(this.cursor.normal);
		}
		
		if(this.selection.active) {
			this.selection.width = x - this.selection.x;
			this.selection.height = y - this.selection.y;
			
			this.needUpdate = false;
			this.queueDraw();
		}
		else if(event.state == ModifierType.BUTTON1_MASK) {
			foreach(child; this.children) {
				if(child.selected) {
					if(child.resize) {
						if(child.direction == Direction.EAST) {
							child.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
						}
						else if(child.direction == Direction.NORTH) {
							child.y = this.grid.nearest(y - child.handler.controls[Direction.NORTH].offset.y);
							child.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.SOUTH) {
							child.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.WEST) {
							child.x = this.grid.nearest(x - child.handler.controls[Direction.WEST].offset.x);
							child.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
						}
						else if(child.direction == Direction.SOUTHEAST) {
							child.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.SOUTHWEST) {
							child.x = this.grid.nearest(x - child.handler.controls[Direction.SOUTHWEST].offset.x);
							child.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.NORTHEAST) {
							child.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHEAST].offset.y);
							child.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.NORTHWEST) {
							child.x = this.grid.nearest(x - child.handler.controls[Direction.NORTHWEST].offset.x);
							child.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHWEST].offset.y);
							child.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.END) {
							child.handler.controls[Direction.END].x = this.grid.nearest(x - child.handler.controls[Direction.END].offset.x);
							child.handler.controls[Direction.END].y = this.grid.nearest(y - child.handler.controls[Direction.END].offset.y);
						}
					}
					else {
						child.x = this.grid.nearest(x - child.offset.x);
						child.y = this.grid.nearest(y - child.offset.y);
					}
					
					if(child.x > 0 || child.y > 0 || child.width > 0 || child.height > 0) {
						this.needUpdate = false;
					}
					
					this.queueDraw();
				}
			}
		}
		
		//TODO: connect motion id
		
		return true;
	}
	
	void add(DrawableObject child) {
		this.children ~= child;
	}
	
	void create(DrawableObject child) {
		this.pick = true;
		this.selectedChild = child;
	}
	
	void update(DrawableObject child) {
		this.queueDraw();
	}
	
	void remove() {
		bool restart = true;
		
		while(restart) {
			restart = false;
			foreach(i, child; this.children) {
				if(child.selected) {
					this.children = this.children.remove(i);
					restart = true;
					break;
				}
			}
		}
		
		this.queueDraw();
	}
	
	Paper paper;
	Origin origin;
	Grid grid;
	Axis axis;
	Selection selection;
	Cursor cursor;
	DrawableObject[] children;
	Size total;
	double border;
	bool pick, updated, needUpdate;
	DrawableObject selectedChild;
}