module flexim.memsys.tm;

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