/*
 * flexim/mem/timing/mem.d
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

module flexim.mem.timing.mem;

import flexim.all;

class MemoryController: CoherentCacheNode {
	this(MemorySystem memorySystem) {
		super(memorySystem, "mem"); //TODO: please add configuration and statistics support for memory controller.
	}
	
	override void service(UpdownReadCacheRequest request){
		//logging.infof(LogCategory.MESI, "%s.receiveReadRequest(%s)", this.name, request);
		
		request.isShared = false;
		this.eventQueue.schedule({this.sendCacheResponse(request);}, 400); //TODO: replace 400 with dynamic latency calculation.
	}
	
	override void service(WriteCacheRequest request){
		//logging.infof(LogCategory.MESI, "%s.receiveWriteRequest(%s)", this.name, request);
		
		this.eventQueue.schedule({this.sendCacheResponse(request);}, 400); //TODO: replace 400 with dynamic latency calculation.
	}
	
	override uint level() {
		assert(0);
	}
}