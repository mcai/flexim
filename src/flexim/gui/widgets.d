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
