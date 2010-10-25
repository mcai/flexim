/*
 * flexim/ise/startup.d
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

module flexim.ise.startup;

import flexim.all;

import core.thread;

class Startup {
	this(string[] args) {
		Main.init(args);
		
		this.builder = new Builder();
		this.builder.addFromFile("../gtk/flexim_gui.glade");
		this.builder.connectSignals(null); 

		this.buildSplashScreen();
		
		Main.run();
	}
	
	bool keyPressed(GdkEventKey* event, Widget widget) {
		if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_c) {
			this.canvas.copySelected();
			return  true;
		}
		else if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_x) {
			this.canvas.cutSelected();
			return  true;
			
		}
		else if(event.state & ModifierType.CONTROL_MASK && event.keyval == GdkKeysyms.GDK_v) {
			this.canvas.paste();
			return  true;
			
		}
		else if(event.keyval == GdkKeysyms.GDK_Delete) {
			this.canvas.deleteSelected();
			return  true;
		}
		else {
			return false;
		}
	}
	
	void exportToPdf() {		
		FileChooserDialog dialog = new FileChooserDialog("PDF file to generate", this.mainWindow, FileChooserAction.SAVE);
		
		FileFilter filter1 = new FileFilter();
		filter1.setName("PDF Files");
		filter1.addMimeType("document/pdf");
		filter1.addPattern("*.pdf");
		dialog.addFilter(filter1);
			
		FileFilter filter2 = new FileFilter();
		filter2.setName("All Files");
		filter2.addPattern("*");
		dialog.addFilter(filter2);
		
		if(dialog.run() == ResponseType.GTK_RESPONSE_OK) {
			string fileName = dialog.getFilename();
			if(fileName !is null) {
				this.canvas.exportToPdf(fileName);
			}
		}
		
		dialog.destroy();
	}
	
	void buildMainWindow() {
		this.mainWindow = getBuilderObject!(Window, GtkWindow)(this.builder, "mainWindow");
		this.mainWindow.maximize();
		this.mainWindow.addOnDestroy(delegate void(ObjectGtk)
			{
				saveConfigsAndStats();
				Canvas.saveXML(this.canvas);
				Main.exit(0);
			});
			
		this.mainWindow.addOnKeyPress(&this.keyPressed);
	}
	
	void buildDialogs() {
		this.dialogEditSetBenchmarkSuites = new DialogEditSetBenchmarkSuites(this.builder);
		this.dialogEditSetSimulations = new DialogEditSetSimulations(this.builder);
	}
	
	void buildToolbars() {
		bindToolButton(this.builder, "toolButtonNew", {writeln("toolButtonNew is clicked.");});
	}
	
	void buildMenus() {
		bindMenuItem(this.builder, "menuItemFileQuit", {Main.quit();});
		bindMenuItem(this.builder, "menuItemFileExportToPDF", {this.exportToPdf();});
		bindMenuItem(this.builder, "menuItemHelpAbout", 
			{
				string[] authors, documenters, artists;
		
				authors ~= "Min Cai (itecgo@163.com)";
				documenters ~= "Min Cai (itecgo@163.com)";
				artists ~= "Min Cai (itecgo@163.com)";
				
				AboutDialog aboutDialog = new AboutDialog();
				aboutDialog.setProgramName("Flexim ISE");
				aboutDialog.setVersion("0.1 Prelease");
				aboutDialog.setCopyright("Copyright (c) 2010 Min Cai <itecgo@163.com>");
				aboutDialog.setLogo(new Pixbuf("../gtk/flexim.png"));
				aboutDialog.setAuthors(authors);
				aboutDialog.setDocumenters(documenters);
				aboutDialog.setArtists(artists);
				aboutDialog.setLicense("GPL (GNU General Public License)\nsee http://www.gnu.org/licenses/gpl.html");
				aboutDialog.setWebsite("http://github.com/mcai/flexim");
				aboutDialog.setComments("Flexim Integrated Simulation Enviroment (ISE) is a flexible and rich architectural simulator written in D.");

				aboutDialog.run();
				aboutDialog.destroy();
			});
		bindMenuItem(this.builder, "menuItemToolsBenchmarks", {this.dialogEditSetBenchmarkSuites.showDialog();});
		bindMenuItem(this.builder, "menuItemToolsSimulations", {this.dialogEditSetSimulations.showDialog();});
	}
	
	void buildFrameDrawing() {
		this.frameDrawingManager = new FrameDrawingManager(this.builder);
	}
	
	void buildSplashScreen() {
		this.splashScreen = getBuilderObject!(Window, GtkWindow)(this.builder, "splashScreen");
		this.splashScreen.showAll();
		
		Label labelLoading = getBuilderObject!(Label, GtkLabel)(this.builder, "labelLoading");
			
		void doPendingEvents() {
			while(Main.eventsPending) {
				Main.iterationDo(false);
			}
		}
		
		Timeout timeout = new Timeout(100, delegate bool ()
			{
				loadConfigsAndStats((string text){
					labelLoading.setMarkup(text);
					doPendingEvents();
				});

				labelLoading.setLabel("Initializing Widgets");
				doPendingEvents();
				
				this.buildMainWindow();
				
				this.buildDialogs();
				
				this.buildToolbars();
				
				this.buildMenus();

				labelLoading.setLabel("Initializing designer");
				doPendingEvents();
				
				this.buildFrameDrawing();
				
				this.splashScreen.destroy();
				
				this.mainWindow.showAll();
				
				return false;
			}, false);
	}
	
	Canvas canvas() {
		return this.frameDrawingManager.canvas;
	}
	
	Builder builder;
	Window mainWindow;
	Window splashScreen;
	FrameDrawingManager frameDrawingManager;
	DialogEditSetBenchmarkSuites dialogEditSetBenchmarkSuites;
	DialogEditSetSimulations dialogEditSetSimulations;
}

void mainGui(string[] args) {
	new Startup(args);
}
