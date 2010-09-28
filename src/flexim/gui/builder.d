/*
 * flexim/gui/builder.d
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

module flexim.gui.builder;

import flexim.all;

T getBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

T getBuilderObject(T, K)(Builder builder, string name) {
	return getBuilderObject!(T, K)(builder.getObject(name));
}

class BuilderCanvas: BuilderCanvasBase {
	this() {
		this.initObjectsToDraw();
	}
	
	void initObjectsToDraw() {
		this.objectsToDraw ~= new CircleCanvasObject(0, 0, 0.4);
		
		double x = 0, y = 0;
		double radius = 0.4;
		
		for(uint i = 0; i < 12; i++) {
			double inset = (i % 3 == 0) ? 0.2 * radius : 0.1 * radius;
			
			this.objectsToDraw ~= new LineCanvasObject(x + (radius - inset) * cos(i * PI / 6),
				y + (radius - inset) * sin(i * PI / 6),
				inset * cos(i * PI / 6),
				inset * sin(i * PI / 6));
		}		
		
		this.objectsToDraw ~= new RectangleCanvasObject(-0.4, -0.4, 0.2, 0.3);
	}
}

void guiActionNotImplemented(Window parent, string text) {
	MessageDialog d = new MessageDialog(parent, GtkDialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, text);
	d.run();
	d.destroy();
}

void mainGui(string[] args) {
	Main.init(args);
	
	Builder builder = new Builder();
	builder.addFromFile("../gtk/flexim_gui.glade");
	builder.connectSignals(null); 
	
	Window mainWindow = getBuilderObject!(Window, GtkWindow)(builder, "mainWindow");
	mainWindow.addOnDestroy(delegate void(ObjectGtk)
		{
			Main.exit(0);
		});
	
	ToolButton toolButtonNew = getBuilderObject!(ToolButton, GtkToolButton)(builder, "toolButtonNew");
	toolButtonNew.addOnClicked(delegate void(ToolButton toolButton)
		{
			writeln(toolButtonNew.getTooltipText());
		});
	
	ImageMenuItem menuItemHelpAbout = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(builder, "menuItemHelpAbout");
	menuItemHelpAbout.addOnActivate(delegate void(MenuItem)
		{
			AboutDialog aboutDialog = getBuilderObject!(AboutDialog, GtkAboutDialog)(builder, "aboutDialogFleximBuilder");
			
			aboutDialog.run();
			aboutDialog.hideAll();
		});
		
	Frame frameDrawing = getBuilderObject!(Frame, GtkFrame)(builder, "frameDrawing");
	//BuilderCanvas builderCanvas = new BuilderCanvas();
	//frameDrawing.add(builderCanvas);
	PersonBoxTable builderCanvas = new PersonBoxTable();
	frameDrawing.add(builderCanvas);
	
	mainWindow.showAll();
	
	Main.run();
}