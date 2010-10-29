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
		
		if(this.buttonSetAdd !is null) {
			this.buttonSetAdd.addOnClicked(delegate void(Button)
				{
					this.onButtonSetAddClicked();
				});
		}
		
		if(this.buttonSetRemove !is null) {	
			this.buttonSetRemove.addOnClicked(delegate void(Button)
				{
					this.onButtonSetRemoveClicked();
				});
		}
			
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
		Dialog dialogEditBenchmarkConfigs = getBuilderObject!(Dialog, GtkDialog)(builder, "dialogEditBenchmarkConfigs");
		ComboBox comboBoxBenchmarkSuites = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxBenchmarkSuites");
		Button buttonAddBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonAddBenchmarkSuite");
		Button buttonRemoveBenchmarkSuite = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveBenchmarkSuite");
		VBox vboxBenchmarks = getBuilderObject!(VBox, GtkVBox)(builder, "vboxBenchmarks");
		Button buttonCloseDialogEditBenchmarks = getBuilderObject!(Button, GtkButton)(builder, "buttonCloseDialogEditBenchmarks");
			
		super(dialogEditBenchmarkConfigs, comboBoxBenchmarkSuites, buttonAddBenchmarkSuite, buttonRemoveBenchmarkSuite, vboxBenchmarks, buttonCloseDialogEditBenchmarks);
		
		dialogEditBenchmarkConfigs.maximize();
		
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
		Dialog dialogEditSimulationConfigs = getBuilderObject!(Dialog, GtkDialog)(builder, "dialogEditSimulationConfigs");
		ComboBox comboBoxSimulations = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulations");
		Button buttonAddSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonAddSimulation");
		Button buttonRemoveSimulation = getBuilderObject!(Button, GtkButton)(builder, "buttonRemoveSimulation");
		VBox vboxSimulation = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulation");
		this.buttonSimulate = getBuilderObject!(Button, GtkButton)(builder, "buttonSimulate");
		Button buttonCloseDialogEditSimulations = getBuilderObject!(Button, GtkButton)(builder, "buttonCloseDialogEditSimulations");
			
		super(dialogEditSimulationConfigs, comboBoxSimulations, buttonAddSimulation, buttonRemoveSimulation, vboxSimulation, buttonCloseDialogEditSimulations);

		dialogEditSimulationConfigs.maximize();
		
		HBox hboxAddSimulation = getBuilderObject!(HBox, GtkHBox)(builder, "hboxAddSimulation");
			
		this.numCoresWhenAddSimulation = this.numThreadsPerCoreWhenAddSimulation = 2;
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Number of Cores:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numCoresWhenAddSimulation = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, 2, delegate void(uint newValue)
			{
				this.numThreadsPerCoreWhenAddSimulation = newValue;
			}));
		
		hboxAddSimulation.packStart(hbox0, true, true, 0);
		
		foreach(simulationConfigTitle, simulationConfig; simulationConfigs) {
			this.newSimulationConfig(simulationConfig);
		}

		this.buttonSimulate.addOnClicked(delegate void(Button)
			{
				string oldButtonLabel = this.buttonSimulate.getLabel();
				
				string simulationConfigTitle = this.comboBoxSet.getActiveText();
				SimulationConfig simulationConfig = simulationConfigs[simulationConfigTitle];
				
				Simulation simulation = new Simulation(simulationConfig);
				
				core.thread.Thread threadRunSimulation = new core.thread.Thread(
					{
						simulation.execute();
								
						this.buttonSimulate.setSensitive(true);
						this.buttonSimulate.setLabel(oldButtonLabel);
					});
	
				this.buttonSimulate.setSensitive(false);
				this.buttonSimulate.setLabel("Simulating.. Please Wait");
				
				threadRunSimulation.start();
			});
		
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
			this.buttonSimulate.setSensitive(true);
		}
		else {
			this.buttonSetRemove.setSensitive(false);
			this.buttonSimulate.setSensitive(false);
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
				Benchmark workload = benchmarkSuites["WCETBench"]["fir"];
				ContextConfig context = new ContextConfig("../tests/benchmarks", workload);
				processor.contexts ~= context;
			}
		}
		
		CacheConfig l2Cache = CacheConfig.newL2();
		MainMemoryConfig mainMemory = new MainMemoryConfig(400);
		
		SimulationConfig simulationConfig = new SimulationConfig(format("simulation%d", currentSimulationId), "../stats/simulations", processor, l2Cache, mainMemory);
		
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
			newHBoxWithLabelAndSpinButton!(uint)("Number of Sets:", 1, 1024, 1, cache.numSets, delegate void(uint newValue)
			{
				cache.numSets = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Associativity:", 1, 1024, 1, cache.assoc, delegate void(uint newValue)
			{
				cache.assoc = newValue;
			}), 
			newHBoxWithLabelAndSpinButton!(uint)("Block Size:", 1, 1024, 1, cache.blockSize, delegate void(uint newValue)
			{
				cache.blockSize = newValue;
			}));
		
		HBox hbox2 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Hit Latency:", 1, 1024, 1, cache.hitLatency, delegate void(uint newValue)
			{
				cache.hitLatency = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Miss Latency:", 1, 1024, 1, cache.missLatency, delegate void(uint newValue)
			{
				cache.missLatency = newValue;
			}),
			newHBoxWithLabelAndEntry("Replacement Policy", to!(string)(cache.policy), delegate void(string entryText)
			{
				cache.policy = cast(CacheReplacementPolicy) entryText;
			}));
				
		return hpack(new Label(cache.name), new VSeparator(), vpack(hbox0, hbox1, hbox2));
	}
	
	ComboBox newContext(ContextConfig context) {
		ComboBox comboBoxBenchmark = new ComboBox();
		
		foreach(benchmarkSuiteTitle, benchmarkSuite; benchmarkSuites) {
			foreach(benchmarkTitle, benchmark; benchmarkSuite.benchmarks) {
				comboBoxBenchmark.appendText(format("%s (%s)", benchmarkTitle, benchmarkSuiteTitle));
			}
		}
		
		comboBoxBenchmark.addOnChanged(delegate void(ComboBox comboBox)
			{
				string benchmarkName = comboBox.getActiveText();
				
				if(benchmarkName != "") {
					int index1 = std.algorithm.indexOf(benchmarkName, '(');
					int index2 = std.algorithm.indexOf(benchmarkName, ')');
					string benchmarkSuiteTitle = benchmarkName[(index1 + 1)..index2];
					string benchmarkTitle = benchmarkName[0..(index1 - 1)];
					
					Benchmark workload = benchmarkSuites[benchmarkSuiteTitle][benchmarkTitle];
					context.workload = workload;
				}
			});
					
		comboBoxBenchmark.setActive(comboBoxBenchmark.getIndex(format("%s (%s)", context.workload.title, context.workload.suite.title)));
			
		return comboBoxBenchmark;
	}
	
	void newSimulationConfig(SimulationConfig simulationConfig) {
		this.comboBoxSet.appendText(simulationConfig.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", simulationConfig.title, delegate void(string entryText)
				{
					simulationConfigs.remove(simulationConfig.title);
					simulationConfig.title = entryText;
					simulationConfigs[simulationConfig.title] = simulationConfig;
					
					int index = this.comboBoxSet.getActive();
					this.comboBoxSet.removeText(index);
					this.comboBoxSet.insertText(index, simulationConfig.title);
					this.comboBoxSet.setActive(index);
				}),
			newHBoxWithLabelAndEntry("Cwd:", simulationConfig.cwd, delegate void(string entryText)
				{
					simulationConfig.cwd = entryText;
				}));
		
		vboxSimulation.packStart(hbox0, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		HBox hbox1 = hpack(
			newHBoxWithLabelAndSpinButton!(ulong)("Max Cycle:", 1, 2000000, 1000, simulationConfig.processor.maxCycle, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxCycle = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Insts:", 1, 2000000, 1000, simulationConfig.processor.maxInsts, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxInsts = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(ulong)("Max Time:", 1, 7200, 100, simulationConfig.processor.maxTime, delegate void(ulong newValue)
			{
				simulationConfig.processor.maxTime = newValue;
			}),
			newHBoxWithLabelAndSpinButton!(uint)("Number of Threads per Core:", 1, 8, 1, simulationConfig.processor.numThreadsPerCore));
			
		vboxProcessor.packStart(hbox1, false, true, 6);
		
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		Widget[] vboxesCore;
		
		foreach(i, core; simulationConfig.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(this.newCache(core.iCache), this.newCache(core.dCache)));
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
				newHBoxWithLabelAndWidget("Benchmark:", this.newContext(context)));
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);
		
		vboxSimulation.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		vboxSimulation.packStart(newCache(simulationConfig.l2Cache), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndSpinButton!(uint)("Latency:", 1, 1024, 1, simulationConfig.mainMemory.latency, delegate void(uint newValue)
			{
				simulationConfig.mainMemory.latency = newValue;
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
	
	Button buttonSimulate;
}

class DialogEditSetSimulationStats: DialogEditSet {
	this(Builder builder) {		
		Dialog dialogSimulationStats = getBuilderObject!(Dialog, GtkDialog)(builder, "dialogSimulationStats");
		ComboBox comboBoxSimulationStats = getBuilderObject!(ComboBox, GtkComboBox)(builder, "comboBoxSimulationStats");
		VBox vboxSimulationStat = getBuilderObject!(VBox, GtkVBox)(builder, "vboxSimulationStat");
		Button buttonCloseDialogSimulationStats = getBuilderObject!(Button, GtkButton)(builder, "buttonCloseDialogSimulationStats");
			
		super(dialogSimulationStats, comboBoxSimulationStats, null, null, vboxSimulationStat, buttonCloseDialogSimulationStats);

		dialogSimulationStats.maximize();
		
		foreach(simulationStatTitle, simulationStat; simulationStats) {
			this.newSimulationStat(simulationStat);
		}
		
		this.notebookSets.setCurrentPage(0);
		this.comboBoxSet.setActive(0);
	}
	
	override void onComboBoxSetChanged() {
		string simulationStatTitle = this.comboBoxSet.getActiveText();
		
		if(simulationStatTitle != "") {
			assert(simulationStatTitle in simulationStats, simulationStatTitle);
			SimulationStat simulationStat = simulationStats[simulationStatTitle];
			assert(simulationStat !is null);
			
			int indexOfSimulationStat = this.comboBoxSet.getActive();
			
			this.notebookSets.setCurrentPage(indexOfSimulationStat);
		}
	}
	
	override void onButtonSetAddClicked() {
		assert(0);
	}
	
	override void onButtonSetRemoveClicked() {
		assert(0);
	}
	
	HBox newCache(CacheStat cache) {
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Name:", cache.name));
			
		HBox hbox1 = hpack(
			newHBoxWithLabelAndEntry("Accesses", to!(string)(cache.accesses)),
			newHBoxWithLabelAndEntry("Hits", to!(string)(cache.hits)),
			newHBoxWithLabelAndEntry("Evictions", to!(string)(cache.evictions)));
				
		HBox hbox2 = hpack(
			newHBoxWithLabelAndEntry("Reads", to!(string)(cache.reads)),
			newHBoxWithLabelAndEntry("Blocking Reads", to!(string)(cache.blockingReads)),
			newHBoxWithLabelAndEntry("Nonblocking Reads", to!(string)(cache.nonblockingReads)),
			newHBoxWithLabelAndEntry("Read Hits", to!(string)(cache.readHits)));
				
		HBox hbox3 = hpack(
			newHBoxWithLabelAndEntry("Writes", to!(string)(cache.writes)),
			newHBoxWithLabelAndEntry("Blocking Writes", to!(string)(cache.blockingWrites)),
			newHBoxWithLabelAndEntry("Nonblocking Writes", to!(string)(cache.nonblockingWrites)),
			newHBoxWithLabelAndEntry("Write Hits", to!(string)(cache.writeHits)));
				
		HBox hbox4 = hpack(
			newHBoxWithLabelAndEntry("Read Retries", to!(string)(cache.readRetries)),
			newHBoxWithLabelAndEntry("Write Retries", to!(string)(cache.writeRetries)));
				
		HBox hbox5 = hpack(
			newHBoxWithLabelAndEntry("No-Retry Accesses", to!(string)(cache.noRetryAccesses)),
			newHBoxWithLabelAndEntry("No-Retry Hits", to!(string)(cache.noRetryHits)));
				
		HBox hbox6 = hpack(
			newHBoxWithLabelAndEntry("No-Retry Reads", to!(string)(cache.noRetryReads)),
			newHBoxWithLabelAndEntry("No-Retry Read Hits", to!(string)(cache.noRetryReadHits)));
					
		HBox hbox7 = hpack(
			newHBoxWithLabelAndEntry("No-Retry Writes", to!(string)(cache.noRetryWrites)),
			newHBoxWithLabelAndEntry("No-Retry Write Hits", to!(string)(cache.noRetryWriteHits)));
	
		return hpack(new Label(cache.name), new VSeparator(), vpack(hbox0, hbox1, hbox2, hbox3, hbox4, hbox5, hbox6, hbox7));
	}
	
	void newSimulationStat(SimulationStat simulationStat) {
		this.comboBoxSet.appendText(simulationStat.title);
		
		VBox vboxSimulation = new VBox(false, 6);
		
		HBox hbox0 = hpack(
			newHBoxWithLabelAndEntry("Title:", simulationStat.title),
			newHBoxWithLabelAndEntry("Cwd:", simulationStat.cwd),
			newHBoxWithLabelAndEntry("Duration:", to!(string)(simulationStat.duration)));
		
		vboxSimulation.packStart(hbox0, false, true, 0);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		//////////////////////
		
		VBox vboxProcessor = new VBox(false, 6);
		
		Widget[] vboxesCore;
		
		foreach(i, core; simulationStat.processor.cores) {
			vboxesCore ~= hpack(
				new Label(format("core-%d", i)),
				new VSeparator(),
				vpack(this.newCache(core.iCache), this.newCache(core.dCache)));
		}
		
		VBox vboxCores = vpack2(vboxesCore);
		
		vboxProcessor.packStart(vboxCores, false, true, 6);
	
		vboxProcessor.packStart(new HSeparator(), false, true, 4);
		
		Widget[] vboxesContext;
		
		foreach(i, context; simulationStat.processor.contexts) {
			vboxesContext ~= hpack(
				new Label(format("context-%d", i)),
				new VSeparator(),
				newHBoxWithLabelAndEntry("Total Instructions Committed:", to!(string)(context.totalInsts))); 		
		}
		
		VBox vboxContexts = vpack2(vboxesContext);
		
		vboxProcessor.packStart(vboxContexts, false, true, 6);
		
		vboxSimulation.packStart(vboxProcessor, false, true, 6);
			
		//////////////////////
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
		
		vboxSimulation.packStart(newCache(simulationStat.l2Cache), false, true, 6);
			
		//////////////////////
		
		HBox hbox13 = hpack(
			newHBoxWithLabelAndEntry("Reads:", to!(string)(simulationStat.mainMemory.reads)),
			newHBoxWithLabelAndEntry("Writes:", to!(string)(simulationStat.mainMemory.writes)),
			newHBoxWithLabelAndEntry("Accesses:", to!(string)(simulationStat.mainMemory.accesses)));
		
		HBox hboxMainMemory = hpack(new Label("Main Memory"), new VSeparator(), vpack(hbox13));
		
		vboxSimulation.packStart(hboxMainMemory, false, true, 6);
		
		vboxSimulation.packStart(new HSeparator(), false, true, 4);
			
		//////////////////////
			
		ScrolledWindow scrolledWindow = new ScrolledWindow();
		scrolledWindow.setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
		
		scrolledWindow.addWithViewport(vboxSimulation);
		
		this.notebookSets.appendPage(scrolledWindow, simulationStat.title);
		
		this.notebookSets.hideAll();
		this.notebookSets.showAll();
	}
}