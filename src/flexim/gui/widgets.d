/*
 * flexim/gui/widgets.d
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

module flexim.gui.widgets;

import flexim.all;

import std.date;

import cairo.Context;
import cairo.Surface;

import gdk.GC;

import gtk.Timeout;

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

abstract class BuilderCanvasObject {
	this(double lineWidth) {
		this.lineWidth = lineWidth;
	}
	
	abstract void render(Context context);
	
	double lineWidth;
}

class CircleCanvasObject: BuilderCanvasObject {
	this(double x, double y, double radius,  double lineWidth = 0.005) {
		super(lineWidth);
		
		this.x = x;
		this.y = y;
		this.radius = radius;
	}
	
	override void render(Context context) {
		newDrawing(context,
			{
				context.arc(x, y, radius, 0, 2 * PI);
		
				context.setSourceColor(new Color(0xF7FBE5));
				context.fillPreserve();

				context.setSourceColor(new Color(0xFF0000));
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
			});
	}
	
	double x, y, radius;
}

class LineCanvasObject: BuilderCanvasObject {
	this(double x, double y, double offsetX, double offsetY,  double lineWidth = 0.005) {
		super(lineWidth);
		
		this.x = x;
		this.y = y;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
	
	override void render(Context context) {
		newDrawing(context,
			{
				context.moveTo(x, y);
				context.lineTo(x + offsetX, y + offsetY);
				
				context.setSourceColor(new Color(0xFF0000));
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
			});
	}
	
	double x, y, offsetX, offsetY;
}

class RectangleCanvasObject: BuilderCanvasObject {
	this(double x, double y, double width, double height,  double lineWidth = 0.005) {
		super(lineWidth);
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	override void render(Context context) {
		newDrawing(context,
			{
				context.rectangle(this.x, this.y, this.width, this.height);
				
				context.setSourceColor(new Color(0xEEE5F3));
				context.fillPreserve();
				
				context.setSourceColor(new Color(0xFF0000));
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
			});
	}
	
	double x, y, width, height;
}

enum Gender: string {
	MALE = "MALE",
	FEMALE = "FEMALE"
}

class Person {
	this(bool alive = true, Gender gender = Gender.MALE) {
		this.alive = alive;
		this.gender = gender;
	}
	
	override string toString() {
		return format("Person[alive=%s, gender=%s]", this.alive, this.gender);
	}
	
	bool alive;
	Gender gender;
}

class PersonBoxWidget: DrawingArea {
	this() {
		this(new Person());
	}
	
	this(Person person) {
		this.person = person;

		this.addEvents(GdkEventMask.BUTTON_PRESS_MASK);
		this.addEvents(GdkEventMask.BUTTON_RELEASE_MASK);
		
		this.addEvents(GdkEventMask.ENTER_NOTIFY_MASK);
		this.addEvents(GdkEventMask.LEAVE_NOTIFY_MASK);
		
		this.addOnButtonPress(&this.buttonPressCallback);
		this.addOnButtonPress(&this.buttonReleaseCallback);
		
		this.addOnEnterNotify(&this.enterNotifyCallback);
		this.addOnLeaveNotify(&this.leaveNotifyCallback);
		
		this.addOnRealize(&this.realizeCallback);
		this.addOnExpose(&this.exposeCallback);
		
		this.highlighted = false;
		
		if(this.person !is null) {
			if(this.person.alive && this.person.gender == Gender.MALE) {
				this.bgColor = new Color(185, 207, 231);
				this.borderColor = new Color(32, 74, 135);
			}
			else if(this.person.alive && this.person.gender == Gender.FEMALE) {
				this.bgColor = new Color(255, 205, 241);
				this.borderColor = new Color(135, 32, 106);
			}
			else if(this.person.alive) {
				this.bgColor = new Color(244, 220, 183);
				this.borderColor = new Color(143, 89, 2);
			}
			else if(this.person.gender == Gender.MALE) {
				this.bgColor = new Color(185, 207, 231);
				this.borderColor = new Color(0, 0, 0);
			}
			else if(this.person.gender == Gender.FEMALE) {
				this.bgColor = new Color(255, 205, 241);
				this.borderColor = new Color(0, 0, 0);
			}
			else{
				this.bgColor = new Color(244, 220, 183);
				this.borderColor = new Color(0, 0, 0);
			}
		}
		else {
			this.bgColor = new Color(211, 215, 207);
			this.borderColor = new Color(0, 0, 0);
		}
		
		this.setSizeRequest(120, 25);
	}
	
	bool buttonPressCallback(GdkEventButton*, Widget) {
		return true;
	}
	
	bool buttonReleaseCallback(GdkEventButton*, Widget) {
		return true;
	}
	
	bool enterNotifyCallback(GdkEventCrossing*, Widget) {
		if(this.person !is null) {
			this.highlighted = true;
			this.queueDraw();
		}
		
		return true;
	}
	
	bool leaveNotifyCallback(GdkEventCrossing*, Widget) {
		this.highlighted = false;
		this.queueDraw();
		
		return true;
	}
	
	void realizeCallback(Widget widget) {
		this.context = new Context(this.getWindow());
	}
	
	bool exposeCallback(GdkEventExpose* event, Widget widget) {
		GtkAllocation alloc = this.getAllocation();
		
		this.context = new Context(this.getWindow());
			
		this.context.moveTo(0, 5);
		this.context.curveTo(0, 2, 2, 0, 5, 0);
		this.context.lineTo(alloc.width - 8, 0);
		this.context.curveTo(alloc.width-5, 0, alloc.width-3, 2, alloc.width-3,5);
		this.context.lineTo(alloc.width-3,alloc.height-8);
		this.context.curveTo(alloc.width-3,alloc.height-5, alloc.width-5,alloc.height-3, alloc.width-8,alloc.height-3);
		this.context.lineTo(5,alloc.height-3);
		this.context.curveTo(2,alloc.height-3,0,alloc.height-5,0,alloc.height-8);
		this.context.closePath();
		
		cairo_path_t* path = this.context.copyPath();
		
		newDrawing(this.context,
			{
		        this.context.translate(3,3);
				this.context.newPath();
				this.context.appendPath(path);
				this.context.setSourceColor(this.borderColor); //TODO
				this.context.fillPreserve();
				this.context.setLineWidth(0);
				this.context.stroke();
			});
		
		this.context.appendPath(path);
		this.context.clip();
		
		this.context.appendPath(path);
		this.context.setSourceColor(this.bgColor);
		this.context.fillPreserve();
		this.context.stroke();
		
		this.context.moveTo(5, 4);
		this.context.setSourceColor(new Color(0, 0, 0));
		
		this.context.setLineWidth(this.highlighted ? 5 : 2);
		this.context.appendPath(path);
		this.context.setSourceColor(this.borderColor);
		this.context.stroke();
		
		this.context.moveTo(10, 15);
		this.context.showText("Hello world.");
		
		return true;
	}
	
	Person person;
	bool highlighted;
	
	Color bgColor, borderColor;
	
	Context context;
}

class ParentBoxLocationData {
	this(uint x, uint y, uint h) {
		this.x = x;
		this.y = y;
		this.h = h;
	}
	
	uint x, y, h;
}

class LabelLocationData {
	this(uint x, uint y, uint w, uint h) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
	
	uint x, y, w, h;
}

class PersonBoxLocationData {
	this(uint x, uint y, uint w, uint h, ParentBoxLocationData father, ParentBoxLocationData mother, LabelLocationData label = null) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
		
		this.father = father;
		this.mother = mother;
		this.label = label;
	}
	
	uint x, y, w, h;
	ParentBoxLocationData father, mother;
	LabelLocationData label;
}

class PersonBoxTable: Table {
	this() {
		super(1, 1, false);
		
		PersonBoxLocationData[] locations;
		
		locations ~= new PersonBoxLocationData(0, 10, 3, 11, 
			new ParentBoxLocationData(1, 5, 5), new ParentBoxLocationData(1, 21, 5),
			new LabelLocationData(3,13,2,5));
		locations ~= new PersonBoxLocationData(2, 5, 3, 5, new ParentBoxLocationData(3, 2, 3), new ParentBoxLocationData(3, 10, 3),
			new LabelLocationData(5, 6,2,3));
		locations ~= new PersonBoxLocationData(2, 21, 3, 5, new ParentBoxLocationData(3, 18, 3), new ParentBoxLocationData(3, 26, 3),
			new LabelLocationData(5,22,2,3));
		locations ~= new PersonBoxLocationData(4, 2, 3, 3, new ParentBoxLocationData(5, 1, 1), new ParentBoxLocationData(5, 5, 1),
			new LabelLocationData(7,3,2,1));
		locations ~= new PersonBoxLocationData(4, 10, 3, 3, new ParentBoxLocationData(5, 9, 1), new ParentBoxLocationData(5, 13, 1),
			new LabelLocationData(7,11,2,1));
		locations ~= new PersonBoxLocationData(4, 18, 3, 3, new ParentBoxLocationData(5, 17, 1), new ParentBoxLocationData(5, 21, 1),
			new LabelLocationData(7,19,2,1));
		locations ~= new PersonBoxLocationData(4, 26, 3, 3, new ParentBoxLocationData(5, 25, 1), new ParentBoxLocationData(5, 29, 1),
			new LabelLocationData(7,27,2,1));
		locations ~= new PersonBoxLocationData(6, 1, 3, 1, new ParentBoxLocationData(7, 0, 1), new ParentBoxLocationData(7, 2, 1),
			new LabelLocationData(9,1,2,1));
		locations ~= new PersonBoxLocationData(6, 5, 3, 1, new ParentBoxLocationData(7, 4, 1), new ParentBoxLocationData(7, 6, 1),
			new LabelLocationData(9,5,2,1));
		locations ~= new PersonBoxLocationData(6, 9, 3, 1, new ParentBoxLocationData(7, 8, 1), new ParentBoxLocationData(7, 10, 1),
			new LabelLocationData(9,9,2,1));
		locations ~= new PersonBoxLocationData(6, 13, 3, 1, new ParentBoxLocationData(7, 12, 1), new ParentBoxLocationData(7, 14, 1),
			new LabelLocationData(9,13,2,1));
		locations ~= new PersonBoxLocationData(6, 17, 3, 1, new ParentBoxLocationData(7, 16, 1), new ParentBoxLocationData(7, 18, 1),
			new LabelLocationData(9,17,2,1));
		locations ~= new PersonBoxLocationData(6, 21, 3, 1, new ParentBoxLocationData(7, 20, 1), new ParentBoxLocationData(7, 22, 1),
			new LabelLocationData(9,21,2,1));
		locations ~= new PersonBoxLocationData(6, 25, 3, 1, new ParentBoxLocationData(7, 24, 1), new ParentBoxLocationData(7, 26, 1),
			new LabelLocationData(9,25,2,1));
		locations ~= new PersonBoxLocationData(6, 29, 3, 1, new ParentBoxLocationData(7, 28, 1), new ParentBoxLocationData(7, 30, 1),
			new LabelLocationData(9,29,2,1));
		
		locations ~= new PersonBoxLocationData(8, 0, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 2, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 4, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 6, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 8, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 10, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 12, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 14, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 16, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 18, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 20, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 22, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 24, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 26, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 28, 3, 1, null, null, null);
		locations ~= new PersonBoxLocationData(8, 30, 3, 1, null, null, null);
		
		uint xmax = 0, ymax = 0;
		
		foreach(i, location; locations) {
			PersonBoxWidget pw = new PersonBoxWidget();
			pw.setTooltipText(format("%s", pw.person));
			
			uint x = location.x + 1;
			uint y = location.y + 1; 
			uint w = location.w;
			uint h = location.h;
			
			if(w > 1) {
				this.attach(pw, x, x + w, y, y + h, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, 0, 0);
			}
			else {
				this.attach(pw, x, x + w, y, y + h, GtkAttachOptions.FILL, GtkAttachOptions.FILL, 0, 0);
			}
			
			if(x + w > xmax) {
				xmax = x + w;
			}
			if(y + h > ymax) {
				ymax = y + h;
			}
			
			if(location.father !is null && location.mother !is null) {
				void drawParentLine(ParentBoxLocationData parent, bool isFather) {
					uint fatherX = parent.x + 1;
					uint fatherY = parent.y + 1;
					uint fatherW = 1;
					uint fatherH = parent.h;
					
					DrawingArea line = new DrawingArea();
					line.setSizeRequest(20, -1);
					
					line.setData("idx", cast(void*) (i * 2 + (isFather ? 1 : 2)));
					
					line.addOnExpose(&this.lineExposeCallback);
					
					this.attach(line, fatherX, fatherX + fatherW, fatherY, fatherY + fatherH, GtkAttachOptions.FILL, GtkAttachOptions.FILL, 0, 0);
					
					if(fatherX + fatherW > xmax) {
						xmax = fatherX + fatherW;
					}
					if(fatherY + fatherH > ymax) {
						ymax = fatherY + fatherH;
					}
				}
				
				drawParentLine(location.father, true);
				drawParentLine(location.mother, false);
			}
			
			if(location.label !is null) {
				Label label = new Label("hello world");
				label.setJustify(GtkJustification.JUSTIFY_LEFT);
				label.setLineWrap(true);
				label.setAlignment(0.1, 0.5);
				
				uint labelX = location.label.x + 1;
				uint labelY = location.label.y + 1;
				uint labelW = location.label.w;
				uint labelH = location.label.h;
				
				this.attach(label, labelX, labelX + labelW, labelY, labelY + labelH, GtkAttachOptions.FILL, GtkAttachOptions.FILL, 0, 0);
			}
		}
		
		Label labelDummy1 = new Label("");
		this.attach(labelDummy1, 0, 1, 0, 1, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, 0, 0);
		
		Label labelDummy2 = new Label("");
		this.attach(labelDummy2, xmax, xmax + 1, ymax, ymax + 1, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, GtkAttachOptions.EXPAND | GtkAttachOptions.FILL, 0, 0);
	}

	bool lineExposeCallback(GdkEventExpose* event, Widget widget) {		
		GC gc = new GC(widget.getWindow());
		GtkAllocation alloc = widget.getAllocation();
		uint idx =  cast(uint) (widget.getData("idx"));
		
		gc.setForeground(new Color(0, 0, 1));
		gc.setBackground(new Color(1, 1, 0));
		
		bool rela = false;
		
		gc.setLineAttributes(3, rela ? GdkLineStyle.SOLID : GdkLineStyle.ON_OFF_DASH, GdkCapStyle.ROUND, GdkJoinStyle.MITER);
		
		if(idx % 2 == 0) {
			widget.getWindow().drawLine(gc, alloc.width, alloc.height / 2, alloc.width / 2, alloc.height / 2);
			widget.getWindow().drawLine(gc, alloc.width / 2, 0, alloc.width / 2, alloc.height / 2);
		}
		else {
			widget.getWindow().drawLine(gc, alloc.width, alloc.height / 2, alloc.width / 2, alloc.height / 2);
			widget.getWindow().drawLine(gc, alloc.width / 2, alloc.height, alloc.width / 2, alloc.height / 2);
		}
			
		return true;
	}
}

class BuilderCanvasBase: DrawingArea {
	this()
	{
		this.addOnExpose(&this.exposeCallback);
	}

	bool exposeCallback(GdkEventExpose* event, Widget widget)
	{
		if(this.timeout is null)
		{
			this.timeout = new Timeout( 1000, &onSecondElapsed, false );
		}
		
		Drawable dr = this.getWindow();

		int width;
		int height;

		dr.getSize(width, height);

		Context context = new Context(dr);

		if(event !is null)
		{
			context.rectangle(event.area.x, event.area.y, event.area.width, event.area.height);
			context.clip();
		}

		context.scale(width, height);
		context.translate(0.5, 0.5);
		context.setLineWidth(0.005);
		
		newDrawing(context,
			{
				context.setSourceColor(new Color(0xADD8E6));
				context.paint();
			});
		
		foreach(obj; this.objectsToDraw) {
			obj.render(context);
		}

		context.destroy();
		
		return true;
	}

	bool onSecondElapsed()
	{
		gdk.Window.Window win = this.getWindow();
		if(win !is null)
		{
			int width;
			int height;

			win.getSize(width, height);

			GdkRectangle* grect = new GdkRectangle();
			grect.x = 0;
			grect.y = 0;
			grect.width = width;
			grect.height = height;

			Rectangle r = new Rectangle(grect);

			win.invalidateRect(r, false);
		}

		return true;
	}
	
	BuilderCanvasObject[] objectsToDraw;

	Timeout timeout;
}
