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

class BuilderCanvas : public DrawingArea
{
	this()
	{
		this.addOnExpose(&this.exposeCallback);
	}
	
	void newDrawing(Context context, void delegate() del) {
		context.save();
		del();
		context.restore();
	}

	bool exposeCallback(GdkEventExpose* event, Widget widget)
	{
		if ( this.timeout is null )
		{
			this.timeout = new Timeout( 1000, &onSecondElapsed, false );
		}

		Drawable dr = this.getWindow();

		int width;
		int height;

		dr.getSize(width, height);

		Context cr = new Context(dr);

		if(event !is null)
		{
			cr.rectangle(event.area.x, event.area.y, event.area.width, event.area.height);
			cr.clip();
		}

		cr.scale(width, height);
		cr.translate(0.5, 0.5);
		cr.setLineWidth(m_lineWidth);
		
		this.newDrawing(cr,
			{
				cr.setSourceColor(new Color(0xADD8E6));
				cr.paint();
			});

		/*this.newDrawing(cr, 
			{
				cr.setSourceRgba(0.3, 0.6, 0.2, 0.9);
				cr.paint();
			});

		cr.arc(0, 0, m_radius, 0, 2 * PI);

		this.newDrawing(cr,
			{
				cr.setSourceRgba(0.0, 0.0, 0.0, 0.8);
				cr.fillPreserve();
			});

		this.newDrawing(cr, 
			{
				cr.setSourceRgba(1.0, 1.0, 1.0, 1.0);
				cr.setLineWidth( m_lineWidth * 1.7);
				cr.strokePreserve();
				cr.clip();
			});

		for (int i = 0; i < 12; i++)
		{
			double inset = 0.07;

			this.newDrawing(cr, 
				{
					cr.setSourceRgba(1.0, 1.0, 1.0, 1.0);
					cr.setLineWidth( m_lineWidth * 0.25);
					cr.setLineCap(cairo_line_cap_t.ROUND);
	
					if (i % 3 != 0)
					{
						inset *= 1.2;
						cr.setLineWidth( m_lineWidth * 0.5 );
					}
	
					cr.moveTo(
						(m_radius - inset) * cos (i * PI / 6),
						(m_radius - inset) * sin (i * PI / 6));
					cr.lineTo (
						m_radius * cos (i * PI / 6),
						m_radius * sin (i * PI / 6));
					cr.stroke();
				});
		}

		d_time lNow;
		string lNowString;

		lNow = std.date.getUTCtime();
		lNowString = std.date.toString(lNow);

		Date timeinfo;
		timeinfo.parse(lNowString);

		double minutes = timeinfo.minute * PI / 30;
		double hours = timeinfo.hour * PI / 6;
		double seconds= timeinfo.second * PI / 30;

		this.newDrawing(cr, 
			{
				cr.setLineCap(cairo_line_cap_t.ROUND);
	
				this.newDrawing(cr, 
					{
						cr.setLineWidth(m_lineWidth / 3);
						cr.setSourceRgba(0.7, 0.7, 0.85, 0.8);
						cr.moveTo(0, 0);
						cr.lineTo(sin(seconds) * (m_radius * 0.8),
							-cos(seconds) * (m_radius * 0.8));
						cr.stroke();
					});
	
				cr.setSourceRgba(0.712, 0.337, 0.117, 0.9);
				cr.moveTo(0, 0);
				cr.lineTo(sin(minutes + seconds / 60) * (m_radius * 0.7),
					-cos(minutes + seconds / 60) * (m_radius * 0.7));
				cr.stroke();
	
				cr.setSourceRgba(0.337, 0.612, 0.117, 0.9);
				cr.moveTo(0, 0);
				cr.lineTo(sin(hours + minutes / 12.0) * (m_radius * 0.4),
					-cos(hours + minutes / 12.0) * (m_radius * 0.4));
				cr.stroke();
			});

		cr.arc(0, 0, m_lineWidth / 3.0, 0, 2 * PI);
		cr.fill();*/

		delete cr;

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

	double m_radius = 0.40;
	double m_lineWidth = 0.065;

	Timeout timeout;
}
