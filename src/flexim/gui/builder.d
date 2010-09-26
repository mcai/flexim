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

T castFromGtkBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

T getBuilderObject(T, K)(Builder builder, string name) {
	return castFromGtkBuilderObject!(T, K)(builder.getObject(name));
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
	BuilderCanvas builderCanvas = new BuilderCanvas();
	frameDrawing.add(builderCanvas);
	
	mainWindow.showAll();
	
	Main.run();
}