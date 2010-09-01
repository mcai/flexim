/*
 * flexim/linux/process.d
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

module flexim.linux.process;

import flexim.all;

import std.c.string;

const uint LD_STACK_BASE = 0xc0000000;
const uint LD_MAX_ENVIRON = 0x40000; /* 16KB for environment */
const uint LD_STACK_SIZE = 0x100000; /* 8MB stack size */

//extern(C)
//	extern __gshared char** environ;

struct FdMap {
	public:
		int fd = -1;
		string filename = "NULL";
		int mode = 0;
		int flags = 0;
		bool isPipe = false;
		int readPipeSource = 0;
		ulong fileOffset = 0;
};

class Process {
	public:
		this(string cwd, string[] args) {
			this.cwd = cwd;
			this.args = args;

			this.argc = this.args.length;

			foreach(arg; this.args) {
				this.argv = this.argv ~ cast(char*) toStringz(arg);
			}

			this.uid = 100;
			this.euid = 100;
			this.gid = 100;
			this.egid = 100;

			this.pid = 100;
			this.ppid = 99;
		}

		void loadInternal(Thread thread, ELF32Binary binary) {
			uint data_base = 0;
			uint data_size = 0;
			uint envAddr, argAddr;
			uint stack_ptr;

			foreach(phdr; binary.phdrs) {
				if(phdr.p_type == PT_LOAD && phdr.p_vaddr > data_base) {
					data_base = phdr.p_vaddr;
					data_size = phdr.p_memsz;
				}
			}

			foreach(shdr; binary.shdrs) {
				if(shdr.sh_type == SHT_PROGBITS || shdr.sh_type == SHT_NOBITS) {

					Elf32_Word new_section_type, new_section_flags;
					Elf32_Addr new_section_addr;

					new_section_addr = shdr.sh_addr;

					if(shdr.sh_size > 0 && (shdr.sh_flags & SHF_ALLOC)) {
						//logging.infof(LogCategory.PROCESS, "Loading %s (%d bytes) at address 0x%08x", binary.getSectionName(shdr), shdr.sh_size, new_section_addr);

						MemoryAccessType perm = MemoryAccessType.INIT | MemoryAccessType.READ;

						/* Permissions */
						if(shdr.sh_flags & SHF_WRITE)
							perm |= MemoryAccessType.WRITE;
						if(shdr.sh_flags & SHF_EXECINSTR)
							perm |= MemoryAccessType.EXEC;

						thread.mem.map(shdr.sh_addr, shdr.sh_size, perm);

						if(shdr.sh_type == SHT_NOBITS) {
							thread.mem.zero(shdr.sh_addr, shdr.sh_size);
						} else {
							ubyte* buf = binary.ptr!(ubyte)(shdr.sh_offset);
							thread.mem.initBlock(shdr.sh_addr, shdr.sh_size, buf);
						}
					}
				} else if(shdr.sh_type == SHT_DYNAMIC || shdr.sh_type == SHT_DYNSYM) {
					logging.fatal(LogCategory.PROCESS, "dynamic linking is not supported");
				}
			}

			this.prog_entry = binary.ehdr.e_entry;

			const uint STACK_BASE = 0xc0000000;
			const uint MMAP_BASE = 0xd4000000;
			const uint MAX_ENVIRON = (16 * 1024);
			const uint STACK_SIZE = (1024 * 1024);

			thread.mem.map(STACK_BASE - STACK_SIZE, STACK_SIZE, MemoryAccessType.READ | MemoryAccessType.WRITE);
			thread.mem.zero(STACK_BASE - STACK_SIZE, STACK_SIZE);

			stack_ptr = STACK_BASE - MAX_ENVIRON;

			thread.intRegs[StackPointerReg] = stack_ptr;

			/*write argc to stack*/
			thread.mem.writeWord(stack_ptr, this.argc);
			thread.setSyscallArg(0, this.argc);
			stack_ptr += 4;

			/*skip stack_ptr past argv pointer array*/
			argAddr = stack_ptr;
			thread.setSyscallArg(1, argAddr);
			stack_ptr += (this.argc + 1) * 4;

			/*skip env pointer array*/
			envAddr = stack_ptr;
			foreach(i, e; this.env) {
				stack_ptr += 4;
			}
			stack_ptr += 4;

			/*write argv to stack*/
			foreach(i, arg; this.argv) {
				thread.mem.writeWord(argAddr + i * uint.sizeof, stack_ptr);
				thread.mem.writeString(stack_ptr, arg);
				/*0 already at the end of the string as done by initialization*/
				stack_ptr += strlen(arg) + 1;
			}

			/*0 already at the end argv pointer array*/

			/*write env to stack*/
			foreach(i, e; this.env) {
				thread.mem.writeWord(envAddr + i * uint.sizeof, stack_ptr);
				thread.mem.writeString(stack_ptr, e);
				stack_ptr += strlen(e) + 1;
			}

			/*0 already at the end argv pointer array*/

			/*stack overflow*/
			if(stack_ptr + 4 >= STACK_BASE) {
				logging.fatal(LogCategory.PROCESS, "Environment overflow. Need to increase MAX_ENVIRON.");
			}

			/* initialize brk point to 4k byte boundary */
			uint abrk = data_base + data_size + MEM_PAGESIZE;
			abrk -= abrk % MEM_PAGESIZE;

			this.brk = abrk;

			this.mmap_brk = MMAP_BASE;

			thread.npc = this.prog_entry;
			thread.nnpc = thread.npc + uint.sizeof;
		}

		bool load(Thread thread) {
			ELF32Binary binary = new ELF32Binary();

			binary.parse(this.args[0]);

			this.loadInternal(thread, binary);

			return true;
		}

		string fullPath(string filename) {
			if(filename[0] == '/' || this.cwd == null || this.cwd == "")
				return filename;

			string full = this.cwd;
			if(this.cwd[this.cwd.length - 1] != '/')
				full ~= '/';

			return full ~ filename;
		}

		mixin Property!(string, "cwd", PROTECTED, PUBLIC, PRIVATE);

		mixin Property!(string[], "args");

		mixin Property!(int, "argc");

		mixin Property!(char*[], "argv");

		mixin Property!(char*[], "env");

		mixin Property!(char*, "prog_fname");

		mixin Property!(uint, "brk");

		mixin Property!(uint, "mmap_brk");

		mixin Property!(uint, "prog_entry");

		// Id of the owner of the process
		mixin Property!(uint, "uid");

		mixin Property!(uint, "euid");

		mixin Property!(uint, "gid");

		mixin Property!(uint, "egid");

		// pid of the process and it's parent
		mixin Property!(uint, "pid");

		mixin Property!(uint, "ppid");

		mixin Property!(uint, "argvp");

		// file descriptor remapping support
		static const int MAX_FD = 256; // max legal fd value
		FdMap fd_map[MAX_FD + 1];
}