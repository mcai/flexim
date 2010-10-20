/*
 * flexim/ise/views.d
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

module flexim.ise.views;

import flexim.all;

import std.path;

import cairo.Context;

alias Tuple!(double, "x", double, "y") Point;
alias Tuple!(double, "width", double, "height") Size;
alias Tuple!(double, "x", double, "y", double, "width", double, "height") Rectangle;

class CanvasColor {
	this(double red = 0.0, double green = 0.0, double blue = 0.0, double alpha = 0.0) {
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.alpha = alpha;
	}
	
	override string toString() {
		return format("CanvasColor[red=%f, green=%f, blue=%f, alpha=%f]", this.red, this.green, this.blue, this.alpha);
	}
	
	double red, green, blue, alpha;
}

class CanvasColors {
	static this() {
		this.entries["default"] = new CanvasColor(0.25, 0.25, 0.25, 0.25);
		this.entries["red"] = new CanvasColor(1, 0, 0, 0.25);
		this.entries["green"] = new CanvasColor(0, 1, 0, 0.25);
		this.entries["blue"] = new CanvasColor(0, 0, 1, 0.25);
	}
	
	static CanvasColor opIndex(string index) {
		assert(index in this.entries, index);
		return this.entries[index];
	}
	
	static CanvasColor[string] entries;
}

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

class CursorSet {
	this() {
		this(ENTIS);
	}
	
	this(string category) {
		this.category = category;
		
		gtk.Invisible.Invisible invisible = new gtk.Invisible.Invisible();
		gdk.Screen.Screen screen = invisible.getScreen();
		gdk.Display.Display display = screen.getDisplay();
		
		this.normal = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "pointer.png"), 4, 2);
		this.northwest = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-northwest.png"), 6, 6);
		this.north = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-north.png"), 12, 6);
		this.northeast = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-northeast.png"), 18, 6);
		this.west = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-west.png"), 6, 12);
		this.east = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-east.png"), 18, 12);
		this.southwest = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-southwest.png"), 6, 18);
		this.south = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-south.png"), 12, 18);
		this.southeast = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "direction-southeast.png"), 18, 18);
		this.cross = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "stroke.png"), 2, 20);
		this.move = new Cursor(display, new Pixbuf("../gtk/cursors" ~ "/" ~ this.category ~ "/" ~ "move.png"), 11, 11);
	}
	
	override string toString() {
		return format("Cursor[category=%s]", this.category);
	}
	
	static const string DEFAULT = "default";
	static const string AERO = "aero";
	static const string ENTIS = "entis";
	static const string INCARNERRY_MARK = "incarnerry-mark";
	static const string VOLTA_RINGLETS = "volta-ringlets";
	
	string category;
	Cursor normal, northwest, north, northeast, west, east, southwest, south, southeast, cross, move;
}

enum Direction : uint {
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

class Control {
	this() {
		this.offset.x = this.offset.y = 0;
		this.size = 10.0;
		this.limbus = false;
	}
	
	void draw(Context context) {
		this.rect.width = this.size / 2.0;
		this.rect.height = this.size / 2.0;
		
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		
		context.rectangle(this.rect.x - this.rect.width / 2.0, this.rect.y - this.rect.height / 2.0, this.rect.width, this.rect.height);
		
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
		return x >= (this.rect.x - this.size / 2.0) && x <= (this.rect.x + this.size) &&
			y >= (this.rect.y - this.size / 2.0) && y <= (this.rect.y + this.size);
	}
	
	override string toString() {
		return format("Control[x=%f, y=%f, width=%f, height=%f, offset=%s, size=%f, limbus=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.offset, this.size, this.limbus);
	}
	
	Rectangle rect;
	Point offset;
	double size;
	bool limbus;
}

class Margins {
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
			context.rectangle(this.rect.x + this.left, this.rect.y + this.top, this.rect.width - this.right - this.left, this.rect.height - this.bottom - this.top);
			context.stroke();
			
			this.controls[Direction.NORTHWEST].rect.x = this.rect.x + this.left;
			this.controls[Direction.NORTHWEST].rect.y = this.rect.y + this.top;
			
			this.controls[Direction.NORTHEAST].rect.x = this.rect.x + this.rect.width - this.right;
			this.controls[Direction.NORTHEAST].rect.y = this.rect.y + this.top;
			
			this.controls[Direction.SOUTHWEST].rect.x = this.rect.x + this.left;
			this.controls[Direction.SOUTHWEST].rect.y = this.rect.y + this.rect.height - this.bottom;
			
			this.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width - this.right;
			this.controls[Direction.SOUTHEAST].rect.y = this.rect.y + this.rect.height - this.bottom;
			
			this.controls[Direction.NORTH].rect.x = this.rect.x + (this.rect.width - this.right) / 2;
			this.controls[Direction.NORTH].rect.y = this.rect.y + this.top;
			
			this.controls[Direction.SOUTH].rect.x = this.rect.x + (this.rect.width - this.right) / 2;
			this.controls[Direction.SOUTH].rect.y = this.rect.y + this.rect.height - this.bottom;
			
			this.controls[Direction.WEST].rect.x = this.rect.x + this.left;
			this.controls[Direction.WEST].rect.y = this.rect.y + (this.rect.height - this.bottom) / 2;
			
			this.controls[Direction.EAST].rect.x = this.rect.x + this.rect.width - this.right;
			this.controls[Direction.EAST].rect.y = this.rect.y + (this.rect.height - this.bottom) / 2;
			
			foreach(control; this.controls) {
				control.draw(context);
			}
		}
	}
	
	override string toString() {
		return format("Margins[x=%f, y=%f, width=%f, height=%f, active=%s, top=%f, left=%f, bottom=%f, right=%f]", 
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.top, this.left, this.bottom, this.right);
	}
	
	Rectangle rect;
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
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		
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
		context.moveTo(this.rect.x + this.rect.width + shadow / 2.0, this.rect.y + shadow);
		context.lineTo(this.rect.x + this.rect.width + shadow / 2.0, this.rect.y + this.rect.height + shadow / 2.0);
		context.lineTo(this.rect.x + shadow, this.rect.y + this.rect.height + shadow / 2.0);
		context.stroke();
	}
	
	override string toString() {
		return format("Paper[x=%f, y=%f, width=%f, height=%f, active=%s, top=%f, left=%f, bottom=%f, right=%f]", 
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.top, this.left, this.bottom, this.right);
	}
}

class Grid {
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
		
		double _x = this.rect.x;
		double _y = this.rect.y;
		
		while(_x <= this.rect.x + this.rect.width) {
			context.moveTo(_x, this.rect.y);
			context.lineTo(_x, this.rect.y + this.rect.height);
			_x += this.size;
		}
		
		while(_y <= this.rect.y + this.rect.height) {
			context.moveTo(this.rect.x, _y);
			context.lineTo(this.rect.x + this.rect.width, _y);
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
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.snap, this.size);
	}
	
	Rectangle rect;
	bool active, snap;
	double size;
}

class Axis {
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
		
		double _x = this.rect.x;
		double _y = this.rect.y;

		while(_x <= this.rect.x + this.rect.width) {
			context.moveTo(_x, this.rect.y);
			context.lineTo(_x, this.rect.y + this.rect.height);
			_x += this.size;
		}
		
		while(_y <= this.rect.y + this.rect.height) {
			context.moveTo(this.rect.x, _y);
			context.lineTo(this.rect.x + this.rect.width, _y);
			_y += this.size;
		}
		
		context.stroke();
	}
	
	override string toString() {
		return format("Axis[x=%f, y=%f, width=%f, height=%f, active=%s, size=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active, this.size);
	}
	
	Rectangle rect;
	bool active;
	double size;
}

class Selection {
	this() {
		this.active = false;
	}
	
	void draw(Context context) {
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		context.setSourceRgba(0.0, 0.0, 0.5, 0.25);
		context.fillPreserve();
		context.setSourceRgba(0.0, 0.0, 0.25, 0.5);
		context.stroke();
	}
	
	override string toString() {
		return format("Selection[x=%f, y=%f, width=%f, height=%f, active=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.active);
	}
	
	Rectangle rect;
	bool active;
}

class Handler {
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
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
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
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.line);
	}
	
	Rectangle rect;
	Control[Direction] controls;
	bool line;
}

abstract class DrawableObject {
	this(string id) {
		this.id = id;
		this.handler = new Handler();
		this.selected = false;
		this.resize = false;
		this.direction = Direction.NONE;
	}
	
	abstract void post();
	
	void draw(Context context) {
		if(this.selected) {
			this.handler.rect.x = this.rect.x;
			this.handler.rect.y = this.rect.y;
			this.handler.rect.width = this.rect.width;
			this.handler.rect.height = this.rect.height;
			this.post();
			this.handler.draw(context);
		}
	}
	
	bool atPosition(double x, double y) {
		return x >= (this.rect.x - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			x <= (this.rect.x + this.rect.width + this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y >= (this.rect.y - this.handler.controls[Direction.NORTHWEST].size / 2.0) &&
			y <= (this.rect.y + this.rect.height + this.handler.controls[Direction.NORTHWEST].size / 2.0);
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
		return (x + width) > this.rect.x && (y + height) > this.rect.y &&
			x < (this.rect.x + this.rect.width) && y < (this.rect.y + this.rect.height);
	}
	
	bool inSelection(Selection selection) {
		return this.inRegion(selection.rect.x, selection.rect.y, selection.rect.width, selection.rect.height);
	}
	
	abstract XMLConfig save();
	
	override string toString() {
		return format("DrawableObject[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction);
	}

	string id;
	string[string] properties;
	
	Rectangle rect;
	Handler handler;
	Rectangle offset;
	Direction direction;
	bool selected, resize;
}

abstract class BoxBase: DrawableObject {
	this(string id) {
		super(id);
		this.backColor = "green";
	}
	
	override void post() {
	    this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.NORTHEAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.NORTHEAST].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.SOUTHWEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.SOUTHWEST].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.NORTH].rect.x = this.rect.x + this.rect.width / 2;
	    this.handler.controls[Direction.NORTH].rect.y = this.rect.y;
	    
	    this.handler.controls[Direction.SOUTH].rect.x = this.rect.x + this.rect.width / 2;
	    this.handler.controls[Direction.SOUTH].rect.y = this.rect.y + this.rect.height;
	    
	    this.handler.controls[Direction.WEST].rect.x = this.rect.x;
	    this.handler.controls[Direction.WEST].rect.y = this.rect.y + this.rect.height / 2;
	    
	    this.handler.controls[Direction.EAST].rect.x = this.rect.x + this.rect.width;
	    this.handler.controls[Direction.EAST].rect.y = this.rect.y + this.rect.height / 2;
	}
	
	override void draw(Context context) {
		super.draw(context);
		this.drawBox(context);
	}
	
	abstract void drawBox(Context context);
	
	override string toString() {
		return format("BoxBase[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, backColor=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.backColor);
	}

	CanvasColor color() {
		return CanvasColors[this.backColor];
	}
	
	string backColor;
}

class Text: BoxBase {
	this(string id, string text = "") {
		super(id);
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
				context.moveTo(this.rect.x, this.rect.y);
				
				if(!this.preserve) {
					int width, height;
					layout.getSize(width, height);
					width /= PANGO_SCALE;
					height /= PANGO_SCALE;
					this.scale(context, width, height);
				}
				else {
					layout.setWidth(cast(int) (this.rect.width) * PANGO_SCALE);
					int width, height;
					layout.getSize(width, height);
					height /= PANGO_SCALE;
					this.rect.height = height;
				}
	
				PgCairo.showLayout(context, layout);
			});
	}
	
	void scale(Context context, double w, double h) {
		if(this.rect.width == 0) {
			this.rect.width = w;
		}
		
		if(this.rect.height == 0) {
			this.rect.height = h;
		}
		
		double scaleX = this.rect.width / w;
		double scaleY = this.rect.height / h;
		
		if(scaleX != 0) {
			context.scale(scaleX, 1.0);
		}
		
		if(scaleY != 0) {
			context.scale(1.0, scaleY);
		}
	}
	
	override XMLConfig save() {
		return TextXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Text[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
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
		xmlConfig["id"] = text.id;
		xmlConfig["x"] = to!(string)(text.rect.x);
		xmlConfig["y"] = to!(string)(text.rect.y);
		xmlConfig["width"] = to!(string)(text.rect.width);
		xmlConfig["height"] = to!(string)(text.rect.height);
		xmlConfig["backColor"] = text.backColor;
		
		xmlConfig["font"] = text.font;
		xmlConfig["size"] = to!(string)(text.size);
		xmlConfig["preserve"] = to!(string)(text.preserve);
		xmlConfig["text"] = text.text;
			
		return xmlConfig;
	}
	
	override Text load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string textStr = xmlConfig["text"];
			
		Text text = new Text(id);
		text.rect.x = x;
		text.rect.y = y;
		text.rect.width = width;
		text.rect.height = height;
		text.backColor = backColor;
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
	this(string id) {
		super(id);
	}
	
	override void drawBox(Context context) {
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		context.rectangle(this.rect.x, this.rect.y, this.rect.width, this.rect.height);
		context.setSourceRgba(this.color.red, this.color.green, this.color.blue, this.color.alpha);
		context.fillPreserve();
		context.setSourceColor(Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return BoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Box[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
	}
}

class BoxXMLSerializer: XMLSerializer!(Box) {
	this() {
	}
	
	override XMLConfig save(Box box) {
		XMLConfig xmlConfig = new XMLConfig("Box");
		xmlConfig["id"] = box.id;
		xmlConfig["x"] = to!(string)(box.rect.x);
		xmlConfig["y"] = to!(string)(box.rect.y);
		xmlConfig["width"] = to!(string)(box.rect.width);
		xmlConfig["height"] = to!(string)(box.rect.height);
		xmlConfig["backColor"] = box.backColor;
			
		return xmlConfig;
	}
	
	override Box load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
			
		Box box = new Box(id);
		box.rect.x = x;
		box.rect.y = y;
		box.rect.width = width;
		box.rect.height = height;
		box.backColor = backColor;
		return box;
	}
	
	static this() {
		singleInstance = new BoxXMLSerializer();
	}
	
	static BoxXMLSerializer singleInstance;
}

class RoundedBox: BoxBase {
	this(string id) {
		super(id);
		this.radius = 10;
		this.handler.controls[Direction.END] = new Control();
	}
	
	override void post() {
		super.post();
	    
	    this.handler.controls[Direction.END].rect.x = this.rect.x + this.radius;
	    this.handler.controls[Direction.END].rect.y = this.rect.y + this.radius;
	    this.handler.controls[Direction.END].limbus = true;
	}
	
	override void drawBox(Context context) {
		double _radius = this.radius;
		
		double[] dash;
		context.setDash(dash, 0);
		context.setLineWidth(2.5);
		
		if(_radius > (this.rect.height / 2) || _radius > (this.rect.width / 2)) {
			if((this.rect.height / 2) < (this.rect.width / 2)) {
				_radius = this.rect.height / 2;
			}
			else {
				_radius = this.rect.width / 2;
			}
		}
		
		context.moveTo(this.rect.x, this.rect.y + _radius);
		context.arc(this.rect.x + _radius, this.rect.y + _radius, _radius, PI, -PI / 2);
		context.lineTo(this.rect.x + this.rect.width - _radius, this.rect.y);
		context.arc(this.rect.x + this.rect.width - _radius, this.rect.y + _radius, _radius, -PI / 2, 0);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height - _radius);
		context.arc(this.rect.x + this.rect.width - _radius, this.rect.y + this.rect.height - _radius, _radius, 0, PI / 2);
		context.lineTo(this.rect.x + _radius, this.rect.y + this.rect.height);
		context.arc(this.rect.x + this.radius, this.rect.y + this.rect.height - _radius, _radius, PI / 2, PI);
		context.closePath();
		context.setSourceRgba(this.color.red, this.color.green, this.color.blue, this.color.alpha);
		context.fillPreserve();

		context.setSourceColor(Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return RoundedBoxXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("RoundedBox[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, color=%s, radius=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
	}
	
	double radius;
}

class RoundedBoxXMLSerializer: XMLSerializer!(RoundedBox) {
	this() {
	}
	
	override XMLConfig save(RoundedBox box) {
		XMLConfig xmlConfig = new XMLConfig("RoundedBox");
		xmlConfig["id"] = box.id;
		xmlConfig["x"] = to!(string)(box.rect.x);
		xmlConfig["y"] = to!(string)(box.rect.y);
		xmlConfig["width"] = to!(string)(box.rect.width);
		xmlConfig["height"] = to!(string)(box.rect.height);
		xmlConfig["backColor"] = box.backColor;
		xmlConfig["radius"] = to!(string)(box.radius);
			
		return xmlConfig;
	}
	
	override RoundedBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		double radius = to!(double)(xmlConfig["radius"]);
			
		RoundedBox roundedBox = new RoundedBox(id);
		roundedBox.rect.x = x;
		roundedBox.rect.y = y;
		roundedBox.rect.width = width;
		roundedBox.rect.height = height;
		roundedBox.backColor = backColor;
		roundedBox.radius = radius;
		return roundedBox;
	}
	
	static this() {
		singleInstance = new RoundedBoxXMLSerializer();
	}
	
	static RoundedBoxXMLSerializer singleInstance;
}

class TextBox: Box {
	this(string id, string text = "") {
		super(id);
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setAlignment(PangoAlignment.CENTER);
		layout.setFontDescription(font);
		layout.setWidth(cast(int) this.rect.width * PANGO_SCALE);
		layout.setHeight(cast(int) this.rect.height * PANGO_SCALE);
		layout.setMarkup(this.text, -1);

		context.setSourceColor(Color.black);
		context.moveTo(this.rect.x, this.rect.y + 10);

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
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color);
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
		xmlConfig["id"] = textBox.id;
		xmlConfig["x"] = to!(string)(textBox.rect.x);
		xmlConfig["y"] = to!(string)(textBox.rect.y);
		xmlConfig["width"] = to!(string)(textBox.rect.width);
		xmlConfig["height"] = to!(string)(textBox.rect.height);
		xmlConfig["backColor"] = textBox.backColor;
		
		xmlConfig["font"] = textBox.font;
		xmlConfig["size"] = to!(string)(textBox.size);
		xmlConfig["preserve"] = to!(string)(textBox.preserve);
		xmlConfig["text"] = textBox.text;
			
		return xmlConfig;
	}
	
	override TextBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		TextBox textBox = new TextBox(id);
		textBox.rect.x = x;
		textBox.rect.y = y;
		textBox.rect.width = width;
		textBox.rect.height = height;
		textBox.backColor = backColor;
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
	this(string id, string text = "") {
		super(id);
		this.font = "Verdana";
		this.size = 12;
		this.preserve = true;
		this.text = text;
	}
	
	void drawText(Context context) {
		PgLayout layout = PgCairo.createLayout(context);
		
		string description = format("%s %d", this.font, this.size);
		
		PgFontDescription font = PgFontDescription.fromString(description);
		layout.setAlignment(PangoAlignment.CENTER);
		layout.setFontDescription(font);
		layout.setWidth(cast(int) this.rect.width * PANGO_SCALE);
		layout.setHeight(cast(int) this.rect.height * PANGO_SCALE);
		layout.setMarkup(this.text, -1);

		context.setSourceColor(Color.black);
		context.moveTo(this.rect.x, this.rect.y + 10);

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
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.color, this.radius);
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
		xmlConfig["id"] = roundedTextBox.id;
		xmlConfig["x"] = to!(string)(roundedTextBox.rect.x);
		xmlConfig["y"] = to!(string)(roundedTextBox.rect.y);
		xmlConfig["width"] = to!(string)(roundedTextBox.rect.width);
		xmlConfig["height"] = to!(string)(roundedTextBox.rect.height);
		xmlConfig["backColor"] = roundedTextBox.backColor;
		xmlConfig["radius"] = to!(string)(roundedTextBox.radius);
		
		xmlConfig["font"] = roundedTextBox.font;
		xmlConfig["size"] = to!(string)(roundedTextBox.size);
		xmlConfig["preserve"] = to!(string)(roundedTextBox.preserve);
		xmlConfig["text"] = roundedTextBox.text;
			
		return xmlConfig;
	}
	
	override RoundedTextBox load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		string backColor = xmlConfig["backColor"];
		double radius = to!(double)(xmlConfig["radius"]);
		
		string font = xmlConfig["font"];
		int size = to!(int)(xmlConfig["size"]);
		bool preserve = to!(bool)(xmlConfig["preserve"]);
		string text = xmlConfig["text"];
			
		RoundedTextBox roundedTextBox = new RoundedTextBox(id);
		roundedTextBox.rect.x = x;
		roundedTextBox.rect.y = y;
		roundedTextBox.rect.width = width;
		roundedTextBox.rect.height = height;
		roundedTextBox.backColor = backColor;
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
	this(string id) {
		super(id);
		this.handler.line = true;
		this.thickness = 2.5;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
		this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
		
		this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
		this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y +  this.rect.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dash, 0);
		context.setLineWidth(this.thickness);
		context.moveTo(this.rect.x, this.rect.y);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height);
		context.setSourceColor(Color.black);
		context.stroke();
	}
	
	override XMLConfig save() {
		return LineXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Line[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, thickness=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.thickness);
	}
	
	double[] dash;
	double thickness;
}

class LineXMLSerializer: XMLSerializer!(Line) {
	this() {
	}
	
	override XMLConfig save(Line line) {
		XMLConfig xmlConfig = new XMLConfig("Line");
		xmlConfig["id"] = line.id;
		xmlConfig["x"] = to!(string)(line.rect.x);
		xmlConfig["y"] = to!(string)(line.rect.y);
		xmlConfig["width"] = to!(string)(line.rect.width);
		xmlConfig["height"] = to!(string)(line.rect.height);
			
		return xmlConfig;
	}
	
	override Line load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
			
		Line line = new Line(id);
		line.rect.x = x;
		line.rect.y = y;
		line.rect.width = width;
		line.rect.height = height;
		return line;
	}
	
	static this() {
		singleInstance = new LineXMLSerializer();
	}
	
	static LineXMLSerializer singleInstance;
}

enum ArrowHeadStyle: string {
	NONE = "NONE",
	SOLID = "SOLID"
}

class ArrowHead {
	this(ArrowHeadStyle style = ArrowHeadStyle.SOLID) {
		this.length = 5;
		this.degrees = 0.5;
		this.style = style;
	}
	
	void draw(Context context, double startX, double startY, double endX, double endY) {	
		if(this.style == ArrowHeadStyle.SOLID) {
			double angle = atan2(endY - startY, endX - startX) + PI;
		
			double x1 = endX + this.length * cos(angle - this.degrees);
			double y1 = endY + this.length * sin(angle - this.degrees);
			double x2 = endX + this.length * cos(angle + this.degrees);
			double y2 = endY + this.length * sin(angle + this.degrees);
			
			context.moveTo(endX, endY);
			context.lineTo(x1, y1);
			context.lineTo(x2, y2);
			context.closePath();
	
			context.setSourceColor(Color.black);
			context.strokePreserve();
	
			context.fill();
		}
	}
	
	double length, degrees;
	ArrowHeadStyle style;
}

class Arrow: DrawableObject {	
	this(string id) {
		super(id);
		this.handler.line = true;
		this.thickness = 2.5;
		
		this.startHead = new ArrowHead(ArrowHeadStyle.NONE);
		this.endHead = new ArrowHead(ArrowHeadStyle.SOLID);
	}
	
	ArrowHeadStyle startHeadStyle() {
		return this.startHead.style;
	}
	
	void startHeadStyle(ArrowHeadStyle value) {
		this.startHead.style = value;
	}
	
	ArrowHeadStyle endHeadStyle() {
		return this.endHead.style;
	}
	
	void endHeadStyle(ArrowHeadStyle value) {
		this.endHead.style = value;
	}
	
	override void post() {
		this.handler.controls[Direction.NORTHWEST].rect.x = this.rect.x;
		this.handler.controls[Direction.NORTHWEST].rect.y = this.rect.y;
		
		this.handler.controls[Direction.SOUTHEAST].rect.x = this.rect.x + this.rect.width;
		this.handler.controls[Direction.SOUTHEAST].rect.y = this.rect.y +  this.rect.height;
	}
	
	override void draw(Context context) {
		super.draw(context);
		
		context.setDash(this.dash, 0);
		context.setLineWidth(this.thickness);
		context.moveTo(this.rect.x, this.rect.y);
		context.lineTo(this.rect.x + this.rect.width, this.rect.y + this.rect.height);
		context.setSourceColor(Color.black);
		context.stroke();
		
		this.startHead.draw(context, this.rect.x + this.rect.width, this.rect.y + this.rect.height, this.rect.x, this.rect.y);
		this.endHead.draw(context, this.rect.x, this.rect.y, this.rect.x + this.rect.width, this.rect.y + this.rect.height);
	}
	
	override XMLConfig save() {
		return ArrowXMLSerializer.singleInstance.save(this);
	}
	
	override string toString() {
		return format("Arrow[x=%f, y=%f, width=%f, height=%f, handler=%s, offset=%s, selected=%s, resize=%s, direction=%s, thickness=%f]",
			this.rect.x, this.rect.y, this.rect.width, this.rect.height, this.handler, this.offset, this.selected, this.resize, this.direction, this.thickness);
	}
	
	double[] dash;
	double thickness;
	
	ArrowHead startHead, endHead;
}

class ArrowXMLSerializer: XMLSerializer!(Arrow) {
	this() {
	}
	
	override XMLConfig save(Arrow arrow) {
		XMLConfig xmlConfig = new XMLConfig("Arrow");
		xmlConfig["id"] = arrow.id;
		xmlConfig["x"] = to!(string)(arrow.rect.x);
		xmlConfig["y"] = to!(string)(arrow.rect.y);
		xmlConfig["width"] = to!(string)(arrow.rect.width);
		xmlConfig["height"] = to!(string)(arrow.rect.height);
		
		xmlConfig["startHeadStyle"] = to!(string)(arrow.startHeadStyle);
		xmlConfig["endHeadStyle"] = to!(string)(arrow.endHeadStyle);
			
		return xmlConfig;
	}
	
	override Arrow load(XMLConfig xmlConfig) {
		string id = xmlConfig["id"];
		double x = to!(double)(xmlConfig["x"]);
		double y = to!(double)(xmlConfig["y"]);
		double width = to!(double)(xmlConfig["width"]);
		double height = to!(double)(xmlConfig["height"]);
		
		ArrowHeadStyle startHeadStyle = cast(ArrowHeadStyle) (xmlConfig["startHeadStyle"]);
		ArrowHeadStyle endHeadStyle = cast(ArrowHeadStyle) (xmlConfig["endHeadStyle"]);
			
		Arrow arrow = new Arrow(id);
		arrow.rect.x = x;
		arrow.rect.y = y;
		arrow.rect.width = width;
		arrow.rect.height = height;
		
		arrow.startHeadStyle = startHeadStyle;
		arrow.endHeadStyle = endHeadStyle;
		return arrow;
	}
	
	static this() {
		singleInstance = new ArrowXMLSerializer();
	}
	
	static ArrowXMLSerializer singleInstance;
}

class Canvas: DrawingArea {
	this() {
		this.paper = new Paper();
		this.origin.x = this.origin.y = 0;
		this.grid = new Grid();
		this.axis = new Axis();
		this.selection = new Selection();
		this.cursorSet = new CursorSet();
		
		this.total.width = this.total.height = 0;
		
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
		
		this.paper.rect.x = 5;
		this.paper.rect.y = 5;
		this.paper.rect.width = 800;
		this.paper.rect.height = 650;
		
		this.paper.top = 5;
		this.paper.left = 5;
		this.paper.bottom = 5;
		this.paper.right = 5;
		
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
		
		this.total.width = this.paper.rect.width + 2 * this.border;
		this.total.height = this.paper.rect.height + 2 * this.border;
		
		if(width < this.total.width) {
			width = this.total.width;
		}
		
		if(height < this.total.height) {
			height = this.total.height;
		}
		
		this.setSizeRequest(cast(int) width, cast(int) height);
		
		context.setSourceRgb(0.75, 0.75, 0.75);
		context.paint();
		
		this.paper.rect.x = (width - this.paper.rect.width) / 2;
		this.paper.rect.y = (height - this.paper.rect.height) / 2;
		
		if(this.paper.rect.x < this.border) {
			this.paper.rect.x = this.border;
		}
		
		if(this.paper.rect.y < this.border) {
			this.paper.rect.y = this.border;
		}
		
		this.paper.draw(context);
		
		this.origin.x = this.paper.rect.x + this.paper.left;
		this.origin.y = this.paper.rect.y + this.paper.top;
		
		if(this.grid.active) {
			this.grid.rect.x = this.origin.x;
			this.grid.rect.y = this.origin.y;
			this.grid.rect.width = this.paper.rect.width - this.paper.left - this.paper.right;
			this.grid.rect.height = this.paper.rect.height - this.paper.top - this.paper.bottom;
			this.grid.draw(context);
		}
		
		if(this.axis.active) {
			this.axis.rect.x = this.origin.x;
			this.axis.rect.y = this.origin.y;
			this.axis.rect.width = this.paper.rect.width - this.paper.left - this.paper.right;
			this.axis.rect.height = this.paper.rect.height - this.paper.top - this.paper.bottom;
			this.axis.draw(context);
		}
		
		foreach(child; this.children) {
			child.rect.x += this.origin.x;
			child.rect.y += this.origin.y;
			child.draw(context);
			child.rect.x -= this.origin.x;
			child.rect.y -= this.origin.y;
		}
		
		if(this.selection.active) {
			this.selection.rect.x += this.origin.x;
			this.selection.rect.y += this.origin.y;
			this.selection.draw(context);
			this.selection.rect.x -= this.origin.x;
			this.selection.rect.y -= this.origin.y;
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
			child.rect.x = this.grid.nearest(event.x);
			child.rect.y = this.grid.nearest(event.y);
			child.rect.width = 0;
			child.rect.height = 0;
			this.add(child);
			
			child.offset.x = event.x;
			child.offset.y = event.y;
			child.offset.width = child.rect.width;
			child.offset.height = child.rect.height;
			
			child.direction = Direction.SOUTHEAST;
			child.handler.controls[child.direction].offset.x = event.x - child.rect.x;
			child.handler.controls[child.direction].offset.y = event.y - child.rect.y;
			
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
					child.offset.width = child.rect.width;
					child.offset.height = child.rect.height;
					child.resize = true;
					child.direction = child.handler.getDirection(event.x + this.origin.x, event.y + this.origin.y);
					child.handler.controls[child.direction].offset.x = event.x - child.rect.x;
					child.handler.controls[child.direction].offset.y = event.y - child.rect.y;
					resize = true;
				}
				break;
			}
		}
		
		if(!resize) {
			foreach(child; this.children) {
				child.resize = false;
				if(child.selected) {
					child.offset.x = event.x - child.rect.x;
					child.offset.y = event.y - child.rect.y;
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
				this.selection.rect.x = event.x;
				this.selection.rect.y = event.y;
				this.selection.rect.width = 0;
				this.selection.rect.height = 0;
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
		this.getWindow().setCursor(this.cursorSet.normal);
		
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
				this.getWindow().setCursor(this.cursorSet.northwest);
			}
			else if(direction == Direction.NORTH) {
				this.getWindow().setCursor(this.cursorSet.north);
			}
			else if(direction == Direction.NORTHEAST) {
				this.getWindow().setCursor(this.cursorSet.northeast);
			}
			else if(direction == Direction.WEST) {
				this.getWindow().setCursor(this.cursorSet.west);
			}
			else if(direction == Direction.EAST) {
				this.getWindow().setCursor(this.cursorSet.east);
			}
			else if(direction == Direction.SOUTHWEST) {
				this.getWindow().setCursor(this.cursorSet.southwest);
			}
			else if(direction == Direction.SOUTH) {
				this.getWindow().setCursor(this.cursorSet.south);
			}
			else if(direction == Direction.SOUTHEAST) {
				this.getWindow().setCursor(this.cursorSet.southeast);
			}
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
			this.getWindow().setCursor(this.cursorSet.move);
		}
		else if(this.pick) {
			this.getWindow().setCursor(this.cursorSet.cross);
		}
		else {
			this.getWindow().setCursor(this.cursorSet.normal);
		}

		this.horizontalRuler.setRange(0, 200, event.x / this.horizontalRuler.getAllocation().width * 200, 200);
		this.verticalRuler.setRange(0, 200, event.y / this.verticalRuler.getAllocation().height * 200, 200);

		if(this.selection.active) {
			this.selection.rect.width = x - this.selection.rect.x;
			this.selection.rect.height = y - this.selection.rect.y;
			
			this.needUpdate = false;
			this.queueDraw();
		}
		else if(event.state & ModifierType.BUTTON1_MASK) {
			foreach(child; this.children) {
				if(child.selected) {
					if(child.resize) {
						if(child.direction == Direction.EAST) {
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
						}
						else if(child.direction == Direction.NORTH) {
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTH].offset.y);
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.SOUTH) {
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.WEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.WEST].offset.x);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
						}
						else if(child.direction == Direction.SOUTHEAST) {
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.SOUTHWEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.SOUTHWEST].offset.x);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.rect.height = this.grid.nearest(child.offset.height + (y - child.offset.y));
						}
						else if(child.direction == Direction.NORTHEAST) {
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHEAST].offset.y);
							child.rect.width = this.grid.nearest(child.offset.width + (x - child.offset.x));
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.NORTHWEST) {
							child.rect.x = this.grid.nearest(x - child.handler.controls[Direction.NORTHWEST].offset.x);
							child.rect.y = this.grid.nearest(y - child.handler.controls[Direction.NORTHWEST].offset.y);
							child.rect.width = this.grid.nearest(child.offset.width + (child.offset.x - x));
							child.rect.height = this.grid.nearest(child.offset.height + (child.offset.y - y));
						}
						else if(child.direction == Direction.END) {
							child.handler.controls[Direction.END].rect.x = this.grid.nearest(x - child.handler.controls[Direction.END].offset.x);
							child.handler.controls[Direction.END].rect.y = this.grid.nearest(y - child.handler.controls[Direction.END].offset.y);
						}
					}
					else {
						child.rect.x = this.grid.nearest(x - child.offset.x);
						child.rect.y = this.grid.nearest(y - child.offset.y);
					}
					
					if(child.rect.x > 0 || child.rect.y > 0 || child.rect.width > 0 || child.rect.height > 0) {
						this.needUpdate = false;
					}
					
					this.queueDraw();
				}
			}
		}

		this.handlingMotionNotified = false;
		
		return true;
	}
	
	void add(DrawableObject childToAdd) {
		foreach(child; this.children) {
			assert(child.id != childToAdd.id);
		}
		
		this.children ~= childToAdd;
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
	
	void deleteSelected() {
		DrawableObject[] childrenToDelete;
		
		foreach(child; this.children) {
			if(child.selected) {
				childrenToDelete ~= child;
			}
		}
		
		foreach(childToDelete; childrenToDelete) {
			int index = this.children.indexOf(childToDelete);
			this.children = this.children.remove(index);
		}
		
		if(childrenToDelete.length > 0) {
			this.queueDraw();
		}
	}
	
	void exportToPdf(string fileName) {
		Surface surface = PdfSurface.create(fileName, this.paper.rect.width, this.paper.rect.height);
		Context context = Context.create(surface);
		foreach(child; this.children) {
			bool selected = child.selected;
			child.selected = false;
			child.rect.x += this.paper.left;
			child.rect.y += this.paper.top;
			child.draw(context);
			child.rect.x -= this.paper.left;
			child.rect.y -= this.paper.top;
			child.selected = selected;
		}
		surface.finish();
		context.showPage();
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
	Point origin;
	Grid grid;
	Axis axis;
	Selection selection;
	CursorSet cursorSet;
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
			else if(typeName == "Arrow") {
				canvas.add(ArrowXMLSerializer.singleInstance.load(entry));
			}
			else {
				assert(0, typeName);
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