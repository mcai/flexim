/*
 * flexim/mem/tm.d
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

module flexim.mem.tm;

import flexim.all;

class Transaction {
	void begin() {
		//TODO
	}
	
	void commit() {
		//TODO
	}
	
	void abort() {
		//TODO
	}
	
	void resume() {
		//TODO
	}
	
	void clear() {
		//TODO
	}
	
	void clearReadSet() {
		//TODO
	}
	
	void clearWriteSet() {
		//TODO
	}
	
	void checkpointRegisters() {
		//TODO
	}
	
	void restoreRegisters() {
		//TODO
	}
	
	bool checkForReadConflict(Addr addr) {
		//TODO
		return false;
	}
	
	void abortAndReset() {
		//TODO
	}
	
	void earlyRelease() {
		//TODO
	}
	
	uint nestingLevel;
	bool running;
	
	Addr pc;
	Addr lastLoad;
	
}