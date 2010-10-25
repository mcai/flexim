/*
 * flexim/ise/dialogs.d
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

module flexim.ise.dialogs;

import flexim.all;

class DialogEditSet {
	this(
		Dialog dialogEditSet, 
		ComboBox comboBoxSet, 
		Button buttonSetAdd, 
		Button buttonSetRemove, 
		VBox vboxContent, 
		Button buttonClose) {
		this.dialogEditSet = dialogEditSet;
		this.comboBoxSet = comboBoxSet;
		this.buttonSetAdd = buttonSetAdd;
		this.buttonSetRemove = buttonSetRemove;
		this.vboxContent = vboxContent;
		this.buttonClose = buttonClose;

		setupTextComboBox(this.comboBoxSet);
		this.comboBoxSet.addOnChanged(delegate void(ComboBox)
			{
				this.onComboBoxSetChanged();
			});
		this.comboBoxSet.setActive(0);
		
		this.buttonSetAdd.addOnClicked(delegate void(Button)
			{
				this.onButtonSetAddClicked();
			});
			
		this.buttonSetRemove.addOnClicked(delegate void(Button)
			{
				this.onButtonSetRemoveClicked();
			});
			
		this.notebookSets = new Notebook();
		this.notebookSets.setShowTabs(false);
		this.notebookSets.setBorderWidth(2);
		this.notebookSets.setCurrentPage(0);
		this.vboxContent.packStart(this.notebookSets, true, true, 0);
			
		this.buttonClose.addOnClicked(delegate void(Button)
			{
				this.dialogEditSet.hideAll();
			});
		hideOnDelete(this.dialogEditSet);
	}
	
	void showDialog() {
		this.dialogEditSet.showAll();
	}
	
	abstract void onComboBoxSetChanged();
	abstract void onButtonSetAddClicked();
	abstract void onButtonSetRemoveClicked();
	
	Dialog dialogEditSet;
	ComboBox comboBoxSet;
	Button buttonSetAdd, buttonSetRemove;
	VBox vboxContent;
	Notebook notebookSets;
	Button buttonClose;
}

class DialogEditSetBenchmarkSuites : DialogEditSet {
	this(Builder builder) {
		Dialog dialogEditBenchmarks = getBuilderObject!(Dialog, GtkDialog)(builder, "dialogEditBenchmarks");
		ComboBox comboBoxBenchmarkSuites = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxBenchmarkSuites");
		Button buttonAddBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonAddBenchmarkSuite");
		Button buttonRemoveBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveBenchmarkSuite");
		VBox vboxBenchmarks = getBuilderObject!(VBox, GtkVBox)(builder, "vboxBenchmarks");
		Button buttonCloseDialogEditBenchmarks = getBuilderObject!(Button, GtkButton)(builder, "buttonCloseDialogEditBenchmarks");
			
		super(dialogEditBenchmarks, comboBoxBenchmarkSuites, buttonAddBenchmarkSuite, buttonRemoveBenchmarkSuite, vboxBenchmarks, buttonCloseDialogEditBenchmarks);
			
		foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
			this.newBenchmarkSuite(benchmarkSuite);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string benchmarkSuiteTitle = this.comboBoxSet.getActiveText();
		
		if(benchmarkSuiteTitle != "") {
			assert(benchmarkSuiteTitle in benchmarkSuites, benchmarkSuiteTitle);
			BenchmarkSuite benchmarkSuite = benchmarkSuites[benchmarkSuiteTitle];
			assert(benchmarkSuite !is null);
			
			int indexOfBenchmarkSuite = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfBenchmarkSuite);

			buttonSetRemove.setSensitive(true);
		}
		else {
			buttonSetRemove.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do
		{
			currentBenchmarkSuiteId++;
		}
		while(format("benchmarkSuite%d", currentBenchmarkSuiteId) in benchmarkSuites);
		
		BenchmarkSuite benchmarkSuite = new BenchmarkSuite(format("benchmarkSuite%d", currentBenchmarkSuiteId), "");
		benchmarkSuites[benchmarkSuite.title] = benchmarkSuite;
		this.newBenchmarkSuite(benchmarkSuite);
		
		int indexOfBenchmarkSuite = benchmarkSuites.length - 1;
		
		this.comboBoxSet.setActive(indexOfBenchmarkSuite);
		this.notebookSets.setCurrentPage(indexOfBenchmarkSuite);
	}
	
	override void onButtonSetRemoveClicked() {
		string benchmarkSuiteTitle = this.comboBoxSet.getActiveText();
		
		if(benchmarkSuiteTitle != "") {
			BenchmarkSuite benchmarkSuite = benchmarkSuites[benchmarkSuiteTitle];
			assert(benchmarkSuite !is null);
				
			benchmarkSuites.remove(benchmarkSuite.title);
			
			int indexOfBenchmarkSuite = this.comboBoxSet.getActive();
			this.comboBoxSet.removeText(indexOfBenchmarkSuite);
			
			this.notebookSets.removePage(indexOfBenchmarkSuite);
			
			if(indexOfBenchmarkSuite > 0) {
				this.comboBoxSet.setActive(indexOfBenchmarkSuite - 1);
			}
			else {
				this.comboBoxSet.setActive(benchmarkSuites.length > 0 ? 0 : -1);
			}
		}
	}
	
	void newBenchmarkSuite(BenchmarkSuite benchmarkSuite) {
		this.comboBoxSet.appendText(benchmarkSuite.title);
					
		VBox vboxBenchmarkListContainer = new VBox(false, 0);
		
		HBox boxProperties = new HBox(false, 6);
		
		Label labelTitle = new Label("Title");
		Entry entryTitle = new Entry(benchmarkSuite.title);
		entryTitle.addOnChanged(delegate void(EditableIF)
			{
				benchmarkSuites.remove(benchmarkSuite.title);
				benchmarkSuite.title = entryTitle.getText();
				benchmarkSuites[benchmarkSuite.title] = benchmarkSuite;
				
				int index = this.comboBoxSet.getActive();
				this.comboBoxSet.removeText(index);
				this.comboBoxSet.insertText(index, benchmarkSuite.title);
				this.comboBoxSet.setActive(index);
			});
		
		Label labelCwd = new Label("Cwd");
		Entry entryCwd = new Entry(benchmarkSuite.cwd);
		entryCwd.addOnChanged(delegate void(EditableIF)
			{
				benchmarkSuite.cwd = entryCwd.getText();
			});
		
		boxProperties.packStart(labelTitle, false, false, 0);
		boxProperties.packStart(entryTitle, true, true, 0);
		boxProperties.packStart(labelCwd, false, false, 0);
		boxProperties.packStart(entryCwd, true, true, 0);
		
		VBox vboxBenchmarkList = new VBox(false, 6);
		
		foreach(benchmark; benchmarkSuite.benchmarks) {
			this.newBenchmark(benchmark, vboxBenchmarkList);
		}
		
		HBox hboxButtonAdd = new HBox(false, 6);
		
		Button buttonAdd = new Button("Add Benchmark");
		buttonAdd.addOnClicked(delegate void(Button)
			{
				do
				{
					currentBenchmarkId++;
				}
				while(format("benchmark%d", currentBenchmarkId) in benchmarkSuite.benchmarks);
				
				Benchmark benchmark = new Benchmark(format("benchmark%d", currentBenchmarkId), "", "", "", "", "");
				benchmarkSuite.register(benchmark);
				this.newBenchmark(benchmark, vboxBenchmarkList);
			});
		hboxButtonAdd.packEnd(buttonAdd, false, false, 0);
		
		vboxBenchmarkListContainer.packStart(boxProperties, false, true, 6);
		vboxBenchmarkListContainer.packStart(vboxBenchmarkList, false, true, 0);
		vboxBenchmarkListContainer.packStart(hboxButtonAdd, false, true, 6);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxBenchmarkListContainer);
		
		this.notebookSets.appendPage(scrolledWindow, benchmarkSuite.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	void newBenchmark(Benchmark benchmark, VBox vboxBenchmarkList) {
		HBox hboxBenchmark = new HBox(false, 6);
		
		HSeparator sep = new HSeparator();
		vboxBenchmarkList.packStart(sep, false, true, 4);
		
		VBox vbox2 = new VBox(false, 6);
		Label labelBenchmarkTitle = new Label(benchmark.title);
		Button buttonRemoveBenchmark = new Button("Remove");
		buttonRemoveBenchmark.addOnClicked(delegate void(Button)
			{
				sep.destroy();
				hboxBenchmark.destroy();
				benchmark.suite.benchmarks.remove(benchmark.title);
			});
		vbox2.packStart(labelBenchmarkTitle, false, false, 0);
		vbox2.packStart(buttonRemoveBenchmark, false, false, 0);
		
		HBox hbox1 = new HBox(false, 6);
		
		Label labelTitle = new Label("Title: ");
		Entry entryTitle = new Entry(benchmark.title);
		entryTitle.addOnChanged(delegate void(EditableIF)
			{
				benchmark.suite.benchmarks.remove(benchmark.title);
				benchmark.title = entryTitle.getText();
				benchmark.suite.register(benchmark);
				labelBenchmarkTitle.setText(benchmark.title);
			});
		
		Label labelCwd = new Label("Cwd: ");
		Entry entryCwd = new Entry(benchmark.cwd);
		entryCwd.addOnChanged(delegate void(EditableIF)
			{
				benchmark.cwd = entryCwd.getText();
			});
		
		hbox1.packStart(labelTitle, false, false, 0);
		hbox1.packStart(entryTitle, true, true, 0);
		hbox1.packStart(labelCwd, false, false, 0);
		hbox1.packStart(entryCwd, true, true, 0);
		
		HBox hbox2 = new HBox(false, 6);
		
		Label labelExe = new Label("Exe: ");
		Entry entryExe = new Entry(benchmark.exe);
		
		Label labelArgsLiteral = new Label("Args in Literal: ");
		Entry entryArgsLiteral = new Entry(benchmark.argsLiteral);
		entryArgsLiteral.addOnChanged(delegate void(EditableIF)
			{
				benchmark.argsLiteral = entryArgsLiteral.getText();
			});
		
		hbox2.packStart(labelExe, false, false, 0);
		hbox2.packStart(entryExe, true, true, 0);
		hbox2.packStart(labelArgsLiteral, false, false, 0);
		hbox2.packStart(entryArgsLiteral, true, true, 0);
		
		HBox hbox3 = new HBox(false, 6);
		
		Label labelStdin = new Label("Stdin: ");
		Entry entryStdin = new Entry(benchmark.stdin);
		entryStdin.addOnChanged(delegate void(EditableIF)
			{
				benchmark.stdin = entryStdin.getText();
			});
		
		Label labelStdout = new Label("Stdout: ");
		Entry entryStdout = new Entry(benchmark.stdout);
		entryStdout.addOnChanged(delegate void(EditableIF)
			{
				benchmark.stdout = entryStdout.getText();
			});
		
		hbox3.packStart(labelStdin, false, false, 0);
		hbox3.packStart(entryStdin, true, true, 0);
		hbox3.packStart(labelStdout, false, false, 0);
		hbox3.packStart(entryStdout, true, true, 0);
		
		VBox vbox = new VBox(false, 6);
		vbox.packStart(hbox1, false, true, 0);
		vbox.packStart(hbox2, false, true, 0);
		vbox.packStart(hbox3, false, true, 0);
		
		hboxBenchmark.packStart(vbox2, false, false, 0);
		hboxBenchmark.packStart(new VSeparator(), false, false, 0);
		hboxBenchmark.packStart(vbox, true, true, 0);
		
		vboxBenchmarkList.packStart(hboxBenchmark, false, true, 0);
		
		vboxBenchmarkList.showAll();
	}

	int currentBenchmarkSuiteId = -1;
	int currentBenchmarkId = -1;
}

class DialogEditSetSimulations : DialogEditSet {
	this(Builder builder) {		
		Dialog dialogEditSimulations = getBuilderObject!(Dialog, GtkDialog)(builder, "dialogEditSimulations");
		ComboBox comboBoxSimulations = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulations");
		Button buttonAddSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonAddSimulation");
		Button buttonRemoveSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveSimulation");
		VBox vboxSimulation = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulation");
		Button buttonCloseDialogEditSimulations = getBuilderObject!(Button, GtkButton)(builder, "buttonCloseDialogEditSimulations");
			
		super(dialogEditSimulations, comboBoxSimulations, buttonAddSimulation, buttonRemoveSimulation, vboxSimulation, buttonCloseDialogEditSimulations);
		
		foreach(simulationConfigTitle, simulationConfig; simulationConfigs) {
			this.newSimulationConfig(simulationConfig);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		
	}
	
	override void onButtonSetAddClicked() {
		
	}
	
	override void onButtonSetRemoveClicked() {
		
	}
	
	void newSimulationConfig(SimulationConfig simulationConfig) {
		
	}
}