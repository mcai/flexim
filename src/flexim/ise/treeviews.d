/*
 * flexim/ise/treeviews.d
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

module flexim.ise.treeviews;

import flexim.all;

class TreeViewArchitecturalSpecificationProperties: TreeView {
	bool delegate(string)[string] rowToActionMappings;
	
	this(Canvas canvas) {
		this.canvas = canvas;
		this.canvas.addOnArchitecturalSpecificationChanged(delegate void(SharedCacheMulticoreSpecification specification)
			{
				this.populate();
			});
			
		this.canvas.addOnArchitecturalSpecificationAssociated(delegate void(DrawableObject child, ArchitecturalSpecification specification)
			{
				this.populateComboItems();
			});
		
		GType[] types;
		types ~= GType.STRING;
		types ~= GType.STRING;
				
		this.treeStore = new TreeStore(types);

		GType[] types2;
		types2 ~= GType.STRING;
		types2 ~= GType.STRING;
		types2 ~= GType.STRING;
		this.listStoreCombo = new ListStore(types2);
		this.populateComboItems();

		this.appendColumn(new TreeViewColumn("Component", new CellRendererText(), "text", 0));
		
		CellRendererCombo cellRendererCombo = new CellRendererCombo();
		
		g_object_set(
			cellRendererCombo.getCellRendererComboStruct(), 
			Str.toStringz("model"), this.listStoreCombo.getListStoreStruct(), 
			Str.toStringz("text-column"), 0,
			Str.toStringz("editable"), true,
			Str.toStringz("has-entry"), false,
			null);
		
		cellRendererCombo.addOnEdited(delegate void(string pathString, string newText, CellRendererText cellRendererText)
			{
				TreeIter iter = new TreeIter();
				this.treeStore.getIterFromString(iter, pathString);
				
				assert(pathString in this.rowToActionMappings);
				
				if(newText != "" && this.rowToActionMappings[pathString](newText)) {
					this.treeStore.setValue(iter, 1, newText);
				}
			});
		
		this.appendColumn(new TreeViewColumn("Specification", cellRendererCombo, "text", 1));
		
		this.setRulesHint(true);
		
		this.populate();
	}
	
	void populateComboItems() {
		this.listStoreCombo.clear();
		
		foreach(child; this.canvas.children) {
			if(child.specification !is null) {
				TreeIter iter = this.listStoreCombo.createIter();
				this.listStoreCombo.setValue(iter, 0, child.specification.id);
			}
		}
	}
	
	void populate() {
		this.setModel(null);
		this.treeStore.clear();
		
		int currentRow = -1;
		
		if(this.canvas.specification !is null) {
			foreach(i, ref coreId; this.canvas.specification.coreIds) {
				TreeIter iterCore = this.treeStore.createIter();
				this.treeStore.setValue(iterCore, 0, format("core#%d", i));
				this.treeStore.setValue(iterCore, 1, coreId);
				
				this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
					OoOProcessorCoreSpecification specification = this.canvas.getSpecification!(OoOProcessorCoreSpecification)(text);
					coreId = specification.id;
					return (cast(OoOProcessorCoreSpecification) specification !is null);
				};

				OoOProcessorCoreSpecification specCore = this.canvas.getSpecification!(OoOProcessorCoreSpecification)(coreId);
				string iCacheId = specCore.iCacheId;
				string dCacheId = specCore.dCacheId;
				
				TreeIter iterICache = this.treeStore.append(iterCore);
				this.treeStore.setValue(iterICache, 0, "icache");
				this.treeStore.setValue(iterICache, 1, iCacheId);
				
				this.rowToActionMappings[format("%d:%d", currentRow, 0)] = delegate bool(string text) {
					ICacheSpecification specification = this.canvas.getSpecification!(ICacheSpecification)(text);
					if(specification !is null) {
						specCore.iCacheId = specification.id;
						return true;
					}
					else {
						return false;
					}
				};
				
				TreeIter iterDCache = this.treeStore.append(iterCore);
				this.treeStore.setValue(iterDCache, 0, "dcache");
				this.treeStore.setValue(iterDCache, 1, dCacheId);
				
				this.rowToActionMappings[format("%d:%d", currentRow, 1)] = delegate bool(string text) {
					DCacheSpecification specification = this.canvas.getSpecification!(DCacheSpecification)(text);
					if(specification !is null) {
						specCore.dCacheId = specification.id;
						return true;
					}
					else {
						return false;
					}
				};
			}
			
			TreeIter iterL2 = this.treeStore.createIter();
			this.treeStore.setValue(iterL2, 0, "l2");
			this.treeStore.setValue(iterL2, 1, this.canvas.specification.l2CacheId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				L2CacheSpecification specification = this.canvas.getSpecification!(L2CacheSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.l2CacheId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
			
			TreeIter iterInterconnect = this.treeStore.createIter();
			this.treeStore.setValue(iterInterconnect, 0, "interconnect");
			this.treeStore.setValue(iterInterconnect, 1, this.canvas.specification.interconnectId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				FixedLatencyP2PInterconnectSpecification specification = this.canvas.getSpecification!(FixedLatencyP2PInterconnectSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.interconnectId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
			
			TreeIter iterMainMemory = this.treeStore.createIter();
			this.treeStore.setValue(iterMainMemory, 0, "mainMemory");
			this.treeStore.setValue(iterMainMemory, 1, this.canvas.specification.mainMemoryId);
			
			this.rowToActionMappings[format("%d", ++currentRow)] = delegate bool(string text) {
				FixedLatencyDRAMSpecification specification = this.canvas.getSpecification!(FixedLatencyDRAMSpecification)(text);
				if(specification !is null) {
					this.canvas.specification.mainMemoryId = specification.id;
					return true;
				}
				else {
					return false;
				}
			};
		}
		
		this.setModel(this.treeStore);
	}
	
	TreeStore treeStore;
	ListStore listStoreCombo;
	
	Canvas canvas;
}