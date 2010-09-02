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
		super("mem", memorySystem);
	}
	
	override void receiveRequest(LoadCacheRequest cpuRequest){
		assert(0);
	}
	
	override void receiveRequest(StoreCacheRequest cpuRequest){
		assert(0);
	}
	
	override void receiveRequest(EvictCacheRequest request) {
		assert(0);
	}
	
	override void receiveRequest(UpdownReadCacheRequest request){
		//logging.infof(LogCategory.MESI, "%s.receiveReadRequest(%s)", this.name, request);
		this.sendCacheResponse(request);
	}
	
	override void receiveRequest(DownupReadCacheRequest request){
		assert(0);
	}
	
	override void receiveRequest(WriteCacheRequest request){
		//logging.infof(LogCategory.MESI, "%s.receiveWriteRequest(%s)", this.name, request);
	}
	
	override void receiveRequest(InvalidateCacheRequest request){
		assert(0);
	}
	
	override void receiveResponse(LoadCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(StoreCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(EvictCacheRequest request) {
		assert(0);
	}
	
	override void receiveResponse(UpdownReadCacheRequest request){
		assert(0);
	}
	
	override void receiveResponse(DownupReadCacheRequest request){
		assert(0);
	}
	
	override void receiveResponse(WriteCacheRequest request){
		assert(0);
	}
	
	override void receiveResponse(InvalidateCacheRequest request){
		assert(0);
	}
	
	void sendCacheResponse(UpdownReadCacheRequest request){
		//logging.infof(LogCategory.MESI, "%sendCacheResponse(%s)", this.name, request);
		
		request.isShared = false;
		request.source.receiveResponse(request);
	}
}