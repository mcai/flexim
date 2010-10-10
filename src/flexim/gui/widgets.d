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

import cairo.Context;
import cairo.Surface;

void newDrawing(Context context, void delegate() del) {
	context.save();
	del();
	context.restore();
}

class DrawingElement: DrawingArea {
	this() {
		this.addEvents(GdkEventMask.BUTTON_PRESS_MASK);
		this.addEvents(GdkEventMask.BUTTON_RELEASE_MASK);
		
		this.addEvents(GdkEventMask.ENTER_NOTIFY_MASK);
		this.addEvents(GdkEventMask.LEAVE_NOTIFY_MASK);
		
		this.addOnButtonPress(&this.buttonPressCallback);
		this.addOnButtonPress(&this.buttonReleaseCallback);
		
		this.addOnEnterNotify(&this.enterNotifyCallback);
		this.addOnLeaveNotify(&this.leaveNotifyCallback);
		
		this.highlighted = false;
	}
	
	bool buttonPressCallback(GdkEventButton*, Widget) {
		return true;
	}
	
	bool buttonReleaseCallback(GdkEventButton*, Widget) {
		return true;
	}
	
	bool enterNotifyCallback(GdkEventCrossing*, Widget) {
		this.highlighted = true;
		this.queueDraw();
		
		return true;
	}
	
	bool leaveNotifyCallback(GdkEventCrossing*, Widget) {
		this.highlighted = false;
		this.queueDraw();
		
		return true;
	}
	
	double lineWidth() {
		return this.highlighted ? 5 : 2;
	}
		
	bool highlighted;
}

class CircleElement: DrawingElement {
	this(string text, double radius = 50, Color bgColor = new Color(185, 207, 231), Color borderColor = new Color(32, 74, 135)) {
		this.text = text;
		this.radius = radius;
		this.bgColor = bgColor;
		this.borderColor = borderColor;
		
		this.addOnExpose(&this.exposeCallback);
		
		this.setSizeRequest(cast(int) (this.radius * 2 + 5), cast(int) (this.radius * 2 + 5));
		this.setTooltipText(format("%s", this));
	}
	
	bool exposeCallback(GdkEventExpose* event, Widget widget) {
		GtkAllocation alloc = this.getAllocation();
		Context context = new Context(this.getWindow());

		newDrawing(context,
			{
				context.arc(radius + 2, radius + 2, this.radius, 0, 2 * PI);
		
				context.setSourceColor(this.bgColor);
				context.fillPreserve();

				context.setSourceColor(this.borderColor);
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
				
				context.moveTo(20, 30);
				context.showText(format("%s", this));
			});
	
		return true;
	}
	
	override string toString() {
		return format("%s", this.text);
	}

	string text;
	double radius;
	Color bgColor, borderColor;
}

class RectangleElement: DrawingElement {
	this(string text, double width = 200, double height = 50, Color bgColor = new Color(185, 207, 231), Color borderColor = new Color(32, 74, 135)) {
		this.text = text;
		this.width = width;
		this.height = height;
		this.bgColor = bgColor;
		this.borderColor = borderColor;
		
		this.addOnExpose(&this.exposeCallback);
		
		this.setSizeRequest(cast(int) this.width, cast(int) this.height);
		this.setTooltipText(format("%s", this));
	}
	
	bool exposeCallback(GdkEventExpose* event, Widget widget) {
		GtkAllocation alloc = this.getAllocation();
		Context context = new Context(this.getWindow());
		
		newDrawing(context,
			{
				context.rectangle(0, 0, alloc.width, alloc.height);
				
				context.setSourceColor(this.bgColor);
				context.fillPreserve();
				
				context.setSourceColor(this.borderColor);
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
				
				context.moveTo(20, 30);
				context.showText(format("%s", this));
			});
		
		return true;
	}
	
	override string toString() {
		return format("%s", this.text);
	}

	string text;
	double width, height;
	Color bgColor, borderColor;
}

class LineElement: DrawingElement {
	this(double offsetX, double offsetY, Color borderColor = new Color(32, 74, 135)) {
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.borderColor = borderColor;
		
		this.addOnExpose(&this.exposeCallback);
		this.setSizeRequest(cast(int) this.offsetX, cast(int) this.offsetY);
	}
	
	bool exposeCallback(GdkEventExpose* event, Widget widget) {
		GtkAllocation alloc = widget.getAllocation();
		Context context = new Context(this.getWindow());
		
		newDrawing(context,
			{
				context.moveTo(0, 0);
				context.lineTo(alloc.width, alloc.height);
				
				context.setSourceColor(this.borderColor);
				context.setLineWidth(this.lineWidth);
				context.setLineCap(cairo_line_cap_t.ROUND);
				context.stroke();
			});
		
		return true;
	}
	
	double offsetX, offsetY;
	Color borderColor;
}

class DrawingElementCanvas: Fixed {
	this() {
	}
	
	void addNodes(T...)(T widgets) {
		
	}
}