/*
 * flexim/ise/canvas.d
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

module flexim.ise.canvas;

import flexim.all;

import std.path;

import cairo.Context;
import cairo.ImageSurface;

import gdk.Cursor;

import gtk.StockItem;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

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
	
	override string toString() {
		return format("Holder[]");
	}
	
	string[string] properties;
}

class Cursor {
	this() {
		//this.set = "default";
		//this.set = "aero";
		this.set = "entis";
		//this.set = "incarnerry-mark";
		//this.set = "volta-ringlets";
		
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
	
	override string toString() {
		return format("Cursor[set=%s]", this.set);
	}
	
	string set;
	gdk.Cursor.Cursor normal, northwest, north, northeast, west, east, southwest, south, southeast, cross, move;
}

class Point: Holder {
	this(double x = 0.0, double y = 0.0) {
		this.x = x;
		this.y = y;
	}
	
	override string toString() {
		return format("Point[x=%f, y=%f]", this.x, this.y);
	}
	
	double x, y;
}

class Size: Holder {
	this(double width = 0.0, double height = 0.0) {
		this.width = width;
		this.height = height;
	}
	
	override string toString() {
		return format("Size[width=%f, height=%f]", this.width, this.height);
	}
	
	double width, height;
}

class Scale {
	this(double x = 1.0, double y = 1.0) {
		this.x = x;
		this.y = y;
	}
	
	override string toString() {
		return format("Scale[x=%f, y=%f]", this.x, this.y);
	}
	
	double x, y;
}

class Color {
	this(double red = 0.0, double green = 0.0, double blue = 0.0, double alpha = 0.0) {
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.alpha = alpha;
	}
	
	override string toString() {
		return format("Color[red=%f, green=%f, blue=%f, alpha=%f]", this.red, this.green, this.blue, this.alpha);
	}
	
	double red, green, blue, alpha;
}

alias Point Origin, Position;

class Rectangle: Holder {
	this(double x = 0.0, double y = 0.0, double width = 0.0, double height = 0.0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	override string toString() {
		return format("Rectangle[x=%f, y=%f, width=%f, height=%f]", this.x, this.y, this.width, this.height);
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
		return x >= (this.x - this.size / 2.0) && x <= (this.x + this.size) &&
			y >= (this.y - this.size / 2.0) && y <= (this.y + this.size);
	}
	
	override string toString() {
		return format("Control[x=%f, y=%f, width=%f, height=%f, offset=%s, size=%f, limbus=%s]",
			this.x, this.y, this.width, this.height, this.offset, this.size, this.limbus);
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
	
	override string toString() {
		return format("Margins[x=%f, y=%f, width=%f, height=%f, active=%s, top=%f, left=%f, bottom=%f, right=%f]", 
			this.x, this.y, this.width, this.height, this.active, this.top, this.left, this.bottom, this.right);
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
	
	override string toString() {
		return format("Paper[x=%f, y=%f, width=%f, height=%f, active=%s, top=%f, left=%f, bottom=%f, right=%f]", 
			this.x, this.y, this.width, this.height, this.active, this.top, this.left, this.bottom, this.right);
	}
}

class Grid: Rectangle {
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
	
	override string toString() {
		return format("Grid[x=%f, y=%f, width=%f, height=%f, active=%s, snap=%s, size=%f]",
			this.x, this.y, this.width, this.height, this.active, this.snap, this.size);
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
	
	override string toString() {
		return format("Axis[x=%f, y=%f, width=%f, height=%f, active=%s, size=%f]",
			this.x, this.y, this.width, this.height, this.active, this.size);
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
	
	override string toString() {
		return format("Selection[x=%f, y=%f, width=%f, height=%f, active=%s]",
			this.x, this.y, this.width, this.height, this.active);
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
	
	override string toString() {
		return format("Handler[x=%f, y=%f, width=%f, height=%f, line=%s]",
			this.x, this.y, this.width, this.height, this.line);
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
	
	abstract XMLConfig save();
	
	override string toString() {
		return format("DrawableObject[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction);
	}
	
	Handler handler;
	Rectangle offset;
	bool selected, resize;
	Direction direction;
}

abstract class BoxBase: DrawableObject {
	this() {
		this.color = new Color(0.25, 0.25, 0.25, 0.25);
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
		
		this.drawBox(context);
	}
	
	abstract void drawBox(Context context);
	
	override string toString() {
		return format("BoxBase[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
	
	Color color;
}

class Text: BoxBase {
	this(string text = "") {
		this.font = "Verdana";
		this.size = 32;
		this.preserve = true;
		this.text = text;
	}
	
	override void drawBox(Context context) {
		newDrawing(context, 
			{
				PgLayout layout = PgCairo.createLayout(context);
				
				string description = format("%s %d", this.font, this.size);
				
				PgFontDescription font = PgFontDescription.fromString(description);
				layout.setJustify(true);
				layout.setFontDescription(font);
				layout.setMarkup(this.text, -1);
				
				context.setSourceRgb(0.0, 0.0, 0.0);
				context.moveTo(this.x, this.y);
				
				if(!this.preserve) {
					int width, height;
					layout.getSize(width, height);
					width /= PANGO_SCALE;
					height /= PANGO_SCALE;
					this.scale(context, width, height);
				}
				else {
					layout.setWidth(cast(int) (this.width) * PANGO_SCALE);
					int width, height;
					layout.getSize(width, height);
					height /= PANGO_SCALE;
					this.height = height;
				}
	
				PgCairo.showLayout(context, layout);
			});
	}
	
	void scale(Context context, double w, double h) {
		if(this.width == 0) {
			this.width = width;
		}
		
		if(this.height == 0) {
			this.height = height;
		}
		
		Scale scale = new Scale();
		scale.x = this.width / w;
		scale.y = this.height / h;
		
		if(scale.x != 0) {
			context.scale(scale.x, 1.0);
		}
		
		if(scale.y != 0) {
			context.scale(1.0, scale.y);
		}
	}
	
	override XMLConfig save() {
		return TextXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Text[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
}

class TextXMLSerializer: XMLSerializer!(Text) {
	this() {
	}
	
	override XMLConfig save(Text text) {
		XMLConfig xmlConfig = new XMLConfig("Text");
		xmlConfig["x"] = to!(string)(text.x);
		xmlConfig["y"] = to!(string)(text.y);
		xmlConfig["width"] = to!(string)(text.width);
		xmlConfig["height"] = to!(string)(text.height);
		
		xmlConfig["font"] = text.font;
		xmlConfig["size"] = to!(string)(text.size);
		xmlConfig["preserve"] = to!(string)(text.preserve);
		xmlConfig["text"] = text.text;
			
		return xmlConfig;
	}
	
	override Text load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string textStr = xmlConfig["text"];
			
		Text text = new Text();
		text.x = x;
		text.y = y;
		text.width = width;
		text.height = height;
		text.font = font;
		text.size = size;
		text.preserve = preserve;
		text.text = textStr;
		return text;
	}
	
	static this() {
		singleInstance = new TextXMLSerializer();
	}
	
	static TextXMLSerializer singleInstance;
}

class Box: BoxBase {
	this() {
	}
	
	override void drawBox(Context context) {
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.x, this.y, this.width, this.height);
		context.setSourceRgba(this.color.red, this.color.green, this.color.blue, this.color.alpha);
		context.fillPreserve();
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.stroke();
	}
	
	override XMLConfig save() {
		return BoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Box[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
}

class BoxXMLSerializer: XMLSerializer!(Box) {
	this() {
	}
	
	override XMLConfig save(Box box) {
		XMLConfig xmlConfig = new XMLConfig("Box");
		xmlConfig["x"] = to!(string)(box.x);
		xmlConfig["y"] = to!(string)(box.y);
		xmlConfig["width"] = to!(string)(box.width);
		xmlConfig["height"] = to!(string)(box.height);
			
		return xmlConfig;
	}
	
	override Box load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
			
		Box box = new Box();
		box.x = x;
		box.y = y;
		box.width = width;
		box.height = height;
		return box;
	}
	
	static this() {
		singleInstance = new BoxXMLSerializer();
	}
	
	static BoxXMLSerializer singleInstance;
}

class RoundedBox: BoxBase {
	this() {
		this.radius = 10;
		this.handler.controls[Direction.END] = new Control();
	}
	
	override void post() {
		super.post();
	    
	    this.handler.controls[Direction.END].x = this.x + this.radius;
	    this.handler.controls[Direction.END].y = this.y + this.radius;
	    this.handler.controls[Direction.END].limbus = true;
	}
	
	override void drawBox(Context context) {
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
	
	override XMLConfig save() {
		return RoundedBoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("RoundedBox[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s, radius=%f]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
	}
	
	double radius;
}

class RoundedBoxXMLSerializer: XMLSerializer!(RoundedBox) {
	this() {
	}
	
	override XMLConfig save(RoundedBox box) {
		XMLConfig xmlConfig = new XMLConfig("RoundedBox");
		xmlConfig["x"] = to!(string)(box.x);
		xmlConfig["y"] = to!(string)(box.y);
		xmlConfig["width"] = to!(string)(box.width);
		xmlConfig["height"] = to!(string)(box.height);
		xmlConfig["radius"] = to!(string)(box.radius);
			
		return xmlConfig;
	}
	
	override RoundedBox load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		double radius = to!(double)(xmlConfig["radius"]);
			
		RoundedBox roundedBox = new RoundedBox();
		roundedBox.x = x;
		roundedBox.y = y;
		roundedBox.width = width;
		roundedBox.height = height;
		roundedBox.radius = radius;
		return roundedBox;
	}
	
	static this() {
		singleInstance = new RoundedBoxXMLSerializer();
	}
	
	static RoundedBoxXMLSerializer singleInstance;
}

class TextBox: Box {
	this(string text = "") {
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setJustify(true);
		layout.setFontDescription(font);
		layout.setMarkup(this.text, -1);
		
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.moveTo(this.x + 10, this.y + 10);

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
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
}

class TextBoxXMLSerializer: XMLSerializer!(TextBox) {
	this() {
	}
	
	override XMLConfig save(TextBox textBox) {
		XMLConfig xmlConfig = new XMLConfig("TextBox");
		xmlConfig["x"] = to!(string)(textBox.x);
		xmlConfig["y"] = to!(string)(textBox.y);
		xmlConfig["width"] = to!(string)(textBox.width);
		xmlConfig["height"] = to!(string)(textBox.height);
		
		xmlConfig["font"] = textBox.font;
		xmlConfig["size"] = to!(string)(textBox.size);
		xmlConfig["preserve"] = to!(string)(textBox.preserve);
		xmlConfig["text"] = textBox.text;
			
		return xmlConfig;
	}
	
	override TextBox load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		TextBox textBox = new TextBox();
		textBox.x = x;
		textBox.y = y;
		textBox.width = width;
		textBox.height = height;
		textBox.font = font;
		textBox.size = size;
		textBox.preserve = preserve;
		textBox.text = text;
		return textBox;
	}
	
	static this() {
		singleInstance = new TextBoxXMLSerializer();
	}
	
	static TextBoxXMLSerializer singleInstance;
}

class RoundedTextBox: RoundedBox {
	this(string text = "") {
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setJustify(true);
		layout.setFontDescription(font);
		layout.setMarkup(this.text, -1);
		
		context.setSourceRgb(0.0, 0.0, 0.0);
		context.moveTo(this.x + 10, this.y + 10);

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
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
	}
	
	string font;
	int size;
	bool preserve;
	string text;
}

class RoundedTextBoxXMLSerializer: XMLSerializer!(RoundedTextBox) {
	this() {
	}
	
	override XMLConfig save(RoundedTextBox roundedTextBox) {
		XMLConfig xmlConfig = new XMLConfig("RoundedTextBox");
		xmlConfig["x"] = to!(string)(roundedTextBox.x);
		xmlConfig["y"] = to!(string)(roundedTextBox.y);
		xmlConfig["width"] = to!(string)(roundedTextBox.width);
		xmlConfig["height"] = to!(string)(roundedTextBox.height);
		xmlConfig["radius"] = to!(string)(roundedTextBox.radius);
		
		xmlConfig["font"] = roundedTextBox.font;
		xmlConfig["size"] = to!(string)(roundedTextBox.size);
		xmlConfig["preserve"] = to!(string)(roundedTextBox.preserve);
		xmlConfig["text"] = roundedTextBox.text;
			
		return xmlConfig;
	}
	
	override RoundedTextBox load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		double radius = to!(double)(xmlConfig["radius"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		RoundedTextBox roundedTextBox = new RoundedTextBox();
		roundedTextBox.x = x;
		roundedTextBox.y = y;
		roundedTextBox.width = width;
		roundedTextBox.height = height;
		roundedTextBox.radius = radius;
		roundedTextBox.font = font;
		roundedTextBox.size = size;
		roundedTextBox.preserve = preserve;
		roundedTextBox.text = text;
		return roundedTextBox;
	}
	
	static this() {
		singleInstance = new RoundedTextBoxXMLSerializer();
	}
	
	static RoundedTextBoxXMLSerializer singleInstance;
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
	
	override XMLConfig save() {
		return LineXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Line[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, thickness=%f]",
			this.x, this.y, this.width, this.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.thickness);
	}
	
	double[] dash;
	double thickness;
}

class LineXMLSerializer: XMLSerializer!(Line) {
	this() {
	}
	
	override XMLConfig save(Line line) {
		XMLConfig xmlConfig = new XMLConfig("Line");
		xmlConfig["x"] = to!(string)(line.x);
		xmlConfig["y"] = to!(string)(line.y);
		xmlConfig["width"] = to!(string)(line.width);
		xmlConfig["height"] = to!(string)(line.height);
			
		return xmlConfig;
	}
	
	override Line load(XMLConfig xmlConfig) {
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
			
		Line line = new Line();
		line.x = x;
		line.y = y;
		line.width = width;
		line.height = height;
		return line;
	}
	
	static this() {
		singleInstance = new LineXMLSerializer();
	}
	
	static LineXMLSerializer singleInstance;
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
		
		this.border = 10;
		
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
		
		this.addOnSelected(delegate void(DrawableObject child)
			{
				this.selectedChild = child;
			});
		
		this.paper.x = 5;
		this.paper.y = 5;
		this.paper.top = 5;
		this.paper.left = 5;
		this.paper.bottom = 5;
		this.paper.right = 5;
		this.paper.width = 800;
		this.paper.height = 650;
		
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
		this.paper.y = (height - this.paper.height) / 2;
		
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
			
			DrawableObject child = this.childToAdd;
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
					resize = true;
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
		this.getWindow().setCursor(this.cursor.normal);
		
		this.needUpdate = false;
		this.queueDraw();
		
		return true;
	}
	
	bool handlingMotionNotified = false;
	
	bool motionNotified(GdkEventMotion* event, Widget widget) {
		if(this.handlingMotionNotified) {
			return true;
		}
		
		if(!this.handlingMotionNotified) {
			this.handlingMotionNotified = true;
		}
		
		double x = event.x - this.origin.x;
		double y = event.y - this.origin.y;
		
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
				this.getWindow().setCursor(this.cursor.southeast);
			}
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
			this.getWindow().setCursor(this.cursor.move);
		}
		else if(this.pick) {
			this.getWindow().setCursor(this.cursor.cross);
		}
		else {
			this.getWindow().setCursor(this.cursor.normal);
		}

		this.horizontalRuler.setRange(0, 200, event.x / this.horizontalRuler.getAllocation().width * 200, 200);
		this.verticalRuler.setRange(0, 200, event.y / this.verticalRuler.getAllocation().height * 200, 200);

		if(this.selection.active) {
			this.selection.width = x - this.selection.x;
			this.selection.height = y - this.selection.y;
			
			this.needUpdate = false;
			this.queueDraw();
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
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

		this.handlingMotionNotified = false;
		
		return true;
	}
	
	void add(DrawableObject child) {
		this.children ~= child;
	}
	
	void create(DrawableObject child) {
		this.pick = true;
		this.childToAdd = child;
	}
	
	void update(DrawableObject child) {
		this.queueDraw();
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
	
	/*void remove() {
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
	}*/
	
	void deleteSelected() {
		if(this.selectedChild !is null) {
			int index = this.children.indexOf(this.selectedChild);
			this.children = this.children.remove(index);
			this.queueDraw();
		}
	}
	
	override string toString() {
		return format("Canvas[origin=%s, total=%s, border=%f, pick=%s, updated=%s, needUpdate=%s, childToAdd=%s]",
			this.origin, this.total, this.border, this.pick, this.updated, this.needUpdate, this.childToAdd);
	}
	
	static Canvas loadXML(string cwd = "../configs/layouts", string fileName = "canvas" ~ ".xml") {
		return CanvasXMLFileSerializer.singleInstance.loadXML(join(cwd, fileName));
	}
	
	static void saveXML(Canvas canvas, string cwd = "../configs/layouts", string fileName = "canvas" ~ ".xml") {
		CanvasXMLFileSerializer.singleInstance.saveXML(canvas, join(cwd, fileName));
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
	DrawableObject childToAdd, selectedChild;
	HRuler horizontalRuler;
	VRuler verticalRuler;
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
		}
		
		return canvas;
	}
	
	static this() {
		singleInstance = new CanvasXMLFileSerializer();
	}
	
	static CanvasXMLFileSerializer singleInstance;
}

string registerStockId(string name, string label, string key) {
	string fileName = format("../gtk/stock/%s.png", name);
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