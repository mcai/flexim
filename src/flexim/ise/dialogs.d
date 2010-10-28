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

			this.buttonSetRemove.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do {
			currentBenchmarkSuiteId++;
		} while(format("benchmarkSuite%d", currentBenchmarkSuiteId) in benchmarkSuites);
		
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
		
		VBox vboxBenchmarkSuite = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title: ", benchmarkSuite.title, delegate void(string entryText)
				{
					benchmarkSuites.remove(benchmarkSuite.title);
					benchmarkSuite.title = entryText;
					benchmarkSuites[benchmarkSuite.title] = benchmarkSuite;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, benchmarkSuite.title);
					this.comboBoxSet.setActive(index);
				}),
			newHBoxWithLabelAndEntry("Cwd: ", benchmarkSuite.cwd, delegate void(string entryText)
				{
					benchmarkSuite.cwd = entryText;
				}));
		
		VBox vboxBenchmarks = new VBox(false, 6);
		
		foreach(benchmark; benchmarkSuite.benchmarks) {
			this.newBenchmark(benchmark, vboxBenchmarks);
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
				this.newBenchmark(benchmark, vboxBenchmarks);
			});
		hboxButtonAdd.packEnd(buttonAdd, false, false, 0);
		
		vboxBenchmarkSuite.packStart(hbox0, false, true, 6);
		vboxBenchmarkSuite.packStart(vboxBenchmarks, false, true, 0);
		vboxBenchmarkSuite.packStart(hboxButtonAdd, false, true, 6);
		
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxBenchmarkSuite);
		
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
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry("Title: ", benchmark.title, delegate void(string entryText)
				{
					benchmark.suite.benchmarks.remove(benchmark.title);
					benchmark.title = entryText;
					benchmark.suite.register(benchmark);
					labelBenchmarkTitle.setText(benchmark.title);
				}),
			newHBoxWithLabelAndEntry("Cwd: ", benchmark.cwd, delegate void(string entryText)
				{
					benchmark.cwd = entryText;
				}));
				
		HBox hbox2 = hpack(
			newHBoxWithLabelAndEntry("Exe: ", benchmark.exe, delegate void(string entryText)
				{
					benchmark.exe = entryText;
				}),
			newHBoxWithLabelAndEntry("Args in Literal: ", benchmark.argsLiteral, delegate void(string entryText)
				{
					benchmark.argsLiteral = entryText;
				}));
						
		HBox hbox3 = hpack(
			newHBoxWithLabelAndEntry("Stdin: ", benchmark.stdin, delegate void(string entryText)
				{
					benchmark.stdin = entryText;
				}),
			newHBoxWithLabelAndEntry("Stdout: ", benchmark.stdout, delegate void(string entryText)
				{
					benchmark.stdout = entryText;
				}));
		
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
		
		HBox hboxAddSimulation = getBuilderObject!(HBox, GtkHBox)(builder, "hboxAddSimulation");
			
		this.numCoresWhenAddSimulation = this.numThreadsPerCoreWhenAddSimulation = 2;
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Number of Cores:", to!(string)(this.numCoresWhenAddSimulation), delegate void(string entryText)
			{
				this.numCoresWhenAddSimulation = to!(uint)(entryText);
			}),
			newHBoxWithLabelAndEntry("Number of Threads per Core:", to!(string)(this.numThreadsPerCoreWhenAddSimulation), delegate void(string entryText)
			{
				this.numThreadsPerCoreWhenAddSimulation = to!(uint)(entryText);
			}));
		
		hboxAddSimulation.packStart(hbox0, true, true, 0);
		
		foreach(simulationConfigTitle, simulationConfig; simulationConfigs) {
			this.newSimulationConfig(simulationConfig);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string simulationConfigTitle = this.comboBoxSet.getActiveText();
		
		if(simulationConfigTitle != "") {
			assert(simulationConfigTitle in simulationConfigs, simulationConfigTitle);
			SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
			assert(simulationConfig !is null);
			
			int indexOfSimulationConfig = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfSimulationConfig);
			
			this.buttonSetRemove.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
		}
	}
	
	override void onButtonSetAddClicked() {
		do {
			currentSimulationId++;
		}while(format("simulation%d", currentSimulationId) in simulationConfigs);
		
		ProcessorConfig processor = new ProcessorConfig(2000000, 2000000, 7200, 1);
		
		for(uint i = 0; i < this.numCoresWhenAddSimulation; i++) {
			CoreConfig core = new CoreConfig(CacheConfig.newL1(format("l1I-%d", i)), CacheConfig.newL1(format("l1D-%d", i)));
			processor.cores ~= core;
			
			for(uint j = 0; j < this.numThreadsPerCoreWhenAddSimulation; j++) {
				ContextConfig context = new ContextConfig("../tests/benchmarks", "WCETBench", "fir");
				processor.contexts ~= context;
			}
		}
		
		CacheConfig l2Cache = CacheConfig.newL2();
		MainMemoryConfig mainMemory = new MainMemoryConfig(400);
		
		SimulationConfig simulationConfig = new SimulationConfig(format("simulation%d", currentSimulationId), "", processor, l2Cache, mainMemory);
		
		simulationConfigs[simulationConfig.title] = simulationConfig;
		this.newSimulationConfig(simulationConfig);
		
		int indexOfSimulationConfig = simulationConfigs.length - 1;
		
		this.comboBoxSet.setActive(indexOfSimulationConfig);
		this.notebookSets.setCurrentPage(indexOfSimulationConfig);
	}
	
	override void onButtonSetRemoveClicked() {
		string simulationConfigTitle = this.comboBoxSet.getActiveText();
		
		if(simulationConfigTitle != "") {
			SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
			assert(simulationConfig !is null);
			
			simulationConfigs.remove(simulationConfig.title);
			
			int indexOfSimulationConfig = this.comboBoxSet.getActive();
			this.comboBoxSet.removeText(indexOfSimulationConfig);
			
			this.notebookSets.removePage(indexOfSimulationConfig);
			
			if(indexOfSimulationConfig > 0) {
				this.comboBoxSet.setActive(indexOfSimulationConfig - 1);
			}
			else {
				this.comboBoxSet.setActive(simulationConfigs.length > 0 ? 0 : -1);
			}
		}
	}
	
	HBox newCache(CacheConfig cache) {
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Name:", cache.name), 
			newHBoxWithLabelAndEntry("Level:", to!(string)(cache.level)));
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry("Number of Sets:", to!(string)(cache.numSets), delegate void(string entryText)
			{
				cache.numSets = to!(uint)(entryText);
			}),
			newHBoxWithLabelAndEntry("Associativity:", to!(string)(cache.assoc), delegate void(string entryText)
			{
				cache.assoc = to!(uint)(entryText);
			}), 
			newHBoxWithLabelAndEntry("Block Size:", to!(string)(cache.blockSize), delegate void(string entryText)
			{
				cache.blockSize = to!(uint)(entryText);
			}));
		
		HBox hbox2 = hpack(
			newHBoxWithLabelAndEntry("Hit Latency:", to!(string)(cache.hitLatency), delegate void(string entryText)
			{
				cache.hitLatency = to!(uint)(entryText);
			}),
			newHBoxWithLabelAndEntry("Miss Latency:", to!(string)(cache.missLatency), delegate void(string entryText)
			{
				cache.missLatency = to!(uint)(entryText);
			}),
			newHBoxWithLabelAndEntry("Replacement Policy", to!(string)(cache.policy), delegate void(string entryText)
			{
				cache.policy = cast(CacheReplacementPolicy) entryText;
			}));
				
		return hpack(new Label(cache.name), new VSeparator(), vpack(hbox0, hbox1, hbox2));
	}
	
	void newSimulationConfig(SimulationConfig simulationConfig) {
		this.comboBoxSet.appendText(simulationConfig.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title: ", simulationConfig.title, delegate void(string entryText)
				{
					simulationConfigs.remove(simulationConfig.title);
					simulationConfig.title = entryText;
					simulationConfigs[simulationConfig.title] = simulationConfig;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, simulationConfig.title);
					this.comboBoxSet.setActive(index);
				}),
			newHBoxWithLabelAndEntry("Cwd: ", simulationConfig.cwd, delegate void(string entryText)
				{
					simulationConfig.cwd = entryText;
				}));
		
		vboxSimulation.packStart(hbox0, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry("Max Cycle:", format("%d", simulationConfig.processor.maxCycle), delegate void(string entryText)
			{
				simulationConfig.processor.maxCycle = to!(ulong)(entryText);
			}),
			newHBoxWithLabelAndEntry("Max Insts:", format("%d", simulationConfig.processor.maxInsts), delegate void(string entryText)
			{
				simulationConfig.processor.maxInsts = to!(ulong)(entryText);
			}),
			newHBoxWithLabelAndEntry("Max Time:", format("%d", simulationConfig.processor.maxTime), delegate void(string entryText)
			{
				simulationConfig.processor.maxTime = to!(ulong)(entryText);
			}),
			newHBoxWithLabelAndEntry("Number of Threads per Core:", format("%d", simulationConfig.processor.numThreadsPerCore)));
			
		vboxProcessor.packStart(hbox1, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		Widget[] vboxesCore;
		
		foreach(i, core; simulationConfig.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(newCache(core.iCache), newCache(core.dCache)));
		}
		
		VBox vboxCores = vpack2(vboxesCore);
			
		vboxProcessor.packStart(vboxCores, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		Widget[] vboxesContext;
		
		foreach(i, context; simulationConfig.processor.contexts) {
			vboxesContext ~= hpack(
				new Label(format("context-%d", i)),
				new VSeparator(), 
				newHBoxWithLabelAndEntry("Binaries Directory:", context.binariesDir, delegate void(string entryText)
				{
					context.binariesDir = entryText;
				}),
				newHBoxWithLabelAndEntry("Benchmark Suite Title:", context.benchmarkSuiteTitle, delegate void(string entryText)
				{
					context.benchmarkSuiteTitle = entryText;
				}),
				newHBoxWithLabelAndEntry("Benchmark Title:", context.benchmarkTitle, delegate void(string entryText)
				{
					context.benchmarkTitle = entryText;
				}));
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);
		
		vboxSimulation.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		vboxSimulation.packStart(newCache(simulationConfig.l2Cache), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndEntry("Latency:", to!(string)(simulationConfig.mainMemory.latency), delegate void(string entryText)
			{
				simulationConfig.mainMemory.latency = to!(uint)(entryText);
			}));
			
		HBox hboxMainMemory = hpack(new Label("Main Memory"), new VSeparator(), vpack(hbox13));
		
		vboxSimulation.packStart(hboxMainMemory, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
			
		//////////////////////
			
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxSimulation);
		
		this.notebookSets.appendPage(scrolledWindow, simulationConfig.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
	
	uint numCoresWhenAddSimulation, numThreadsPerCoreWhenAddSimulation;
	int currentSimulationId = -1;
}