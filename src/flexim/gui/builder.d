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
			string[] authors, documenters, artists;
	
			authors ~= "Min Cai (itecgo@163.com)";
			documenters ~= "Min Cai (itecgo@163.com)";
			artists ~= "Min Cai (itecgo@163.com)";
			
			AboutDialog aboutDialog = new AboutDialog();
			aboutDialog.setProgramName("Flexim Integrated Simulation Enviroment");
			aboutDialog.setVersion("0.1 Prelease");
			aboutDialog.setCopyright("Copyright (c) 2010 Min Cai <itecgo@163.com>");
			//aboutDialog.setLogo(this.icon.getPixbuf);
			aboutDialog.setAuthors(authors);
			aboutDialog.setDocumenters(documenters);
			aboutDialog.setArtists(artists);
			aboutDialog.setLicense("GPL (GNU General Public License)\nsee http://www.gnu.org/licenses/gpl.html");
			aboutDialog.setWebsite("http://github.com/mcai/flexim");
			aboutDialog.setComments("A flexible and rich architectural simulator written in D.");
			
			if(aboutDialog.run() == GtkResponseType.GTK_RESPONSE_CANCEL) {
				aboutDialog.destroy();
			}
		});
		
	Frame frameDrawing = getBuilderObject!(Frame, GtkFrame)(builder, "frameDrawing");
	
	GraphView canvas = new GraphView();
	frameDrawing.add(canvas);

	VBoxViewButtonsList vboxViewButtonsList = new VBoxViewButtonsList(canvas);
	VBox vboxLeft = getBuilderObject!(VBox, GtkVBox)(builder, "vboxLeft");
	vboxLeft.packStart(vboxViewButtonsList, false, false, 0);
	
	TableTreeNodeProperties tableTreeNodeProperties = new TableTreeNodeProperties();
	VBox vboxCenterBottom = getBuilderObject!(VBox, GtkVBox)(builder, "vboxCenterBottom");
	vboxCenterBottom.packStart(tableTreeNodeProperties, true, true, 0);
	
	mainWindow.showAll();
	
	Main.run();
}