/*
 * flexim/kernel.d
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

module flexim.kernel;

import flexim.all;

import core.stdc.errno;

import std.c.stdlib;
import std.c.string;
import std.c.linux.linux;

struct FileBuffer {
	string path;
	ubyte[] data;

	static FileBuffer opCall(string path) {
		FileBuffer _this;
		_this.path = path;
		_this.data = cast(ubyte[]) std.file.read(path);
		return _this;
	}

	static FileBuffer opCall(string path, ubyte[] data) {
		FileBuffer _this;
		_this.path = path;
		_this.data = data;
		return _this;
	}

	string getPath() {
		return path;
	}

	void deleteData() {
		delete this.data;
	}
}

enum Anchor {
	None,
	Begin,
	End,
	Current
}

class FileReader {
	public:
		this(void[] data) {
			this.data = cast(ubyte[]) data;
		}

		this(FileBuffer buffer) {
			this.data = buffer.data;
		}

		FileReader peek(ref ubyte x) {
			assert(this.hasMore());
			x = data[position];
			return this;
		}

		FileReader peek(ref ubyte[] x, uint elements = uint.max) {
			if(elements == ulong.max) {
				x = data[position .. $];
			} else {
				x = data[position .. position + elements];
			}
			return this;
		}

		FileReader getAll(ref void[] x) {
			x = data[position .. $];
			position = data.length;
			return this;
		}

		FileReader _get(T)(ref T x) {
			x = *(cast(T*) (data[position .. position + T.sizeof].ptr));
			position += T.sizeof;
			return this;
		}

		alias _get!(char) get;
		alias _get!(wchar) get;
		alias _get!(dchar) get;

		alias _get!(ubyte) get;
		alias _get!(byte) get;
		alias _get!(ushort) get;
		alias _get!(short) get;
		alias _get!(uint) get;
		alias _get!(int) get;
		alias _get!(ulong) get;
		alias _get!(long) get;

		FileReader _getArray(T)(ref T[] x, uint elements = uint.max) {
			uint end;
			if(elements == uint.max) {
				end = data.length - (data.length % T.sizeof);
				x = cast(T[]) (data[position .. end]);
			} else {
				end = position + (elements * T.sizeof);
				x = cast(T[]) (data[position .. end]);
			}
			position = end;
			return this;
		}

		alias _getArray!(char) get;
		alias _getArray!(wchar) get;
		alias _getArray!(dchar) get;

		alias _getArray!(ubyte) get;
		alias _getArray!(byte) get;
		alias _getArray!(ushort) get;
		alias _getArray!(short) get;
		alias _getArray!(uint) get;
		alias _getArray!(int) get;
		alias _getArray!(ulong) get;
		alias _getArray!(long) get;

		bool hasMore() {
			return position < data.length;
		}

		FileReader seek(int offset, Anchor anchor = Anchor.Begin) {
			switch(anchor) {
				case Anchor.Begin:
					assert(offset < data.length);
					position = offset;
				break;
				case Anchor.End:
					assert(position + offset < data.length);
					position = data.length + offset;
				break;
				default:
				case Anchor.None:
				case Anchor.Current:
					assert(position + offset < data.length);
					position += offset;
				break;
			}
			return this;
		}

		int getPosition() {
			return position;
		}

		ubyte[] getData() {
			return data;
		}

	private:
		ubyte[] data;
		int position;
}

class ELFReader: FileReader {
	public:
		this(FileBuffer buffer) {
			super(buffer);
		}

		void setPosition(uint position) {
			super.seek(position, Anchor.Begin);
		}

		alias _get!(Elf32_Ehdr) get;
		alias _get!(Elf32_Shdr) get;
		alias _get!(Elf32_Phdr) get;
		alias _get!(Elf32_Rel) get;
		alias _get!(Elf32_Rela) get;
}

/** Size of the e_ident array. */
const uint EI_NIDENT = 16;

/** Indices in the e_ident array. */
const uint EI_MAG0 = 0;
const uint EI_MAG1 = 1;
const uint EI_MAG2 = 2;
const uint EI_MAG3 = 3;
const uint EI_CLASS = 4;
const uint EI_DATA = 5;
const uint EI_VERSION = 6;
const uint EI_PAD = 7;

/** Values defining the class of the file. */
const uint ELFCLASSNONE = 0;
const uint ELFCLASS32 = 1;
const uint ELFCLASS64 = 2;

/** Values defining the encoding of data. */
const uint ELFDATANONE = 0;
const uint ELFDATA2LSB = 1;
const uint ELFDATA2MSB = 2;

/** Defined version of the ELF specification. */
const uint EV_NONE = 0;
const uint EV_CURRENT = 1; // This can change!

/** The version currently supported by DDL */
const uint DDL_ELFVERSION_SUPP = 1;

/** Values defining the object file type. */
const uint ET_NONE = 0;
const uint ET_REL = 1;
const uint ET_EXEC = 2;
const uint ET_DYN = 3;
const uint ET_CORE = 4;
const uint ET_LOPROC = 0xff00;
const uint ET_HIPROC = 0xffff;

/** Values defining machine architectures. */
const uint EM_NONE = 0;
const uint EM_M32 = 1;
const uint EM_SPARC = 2;
const uint EM_386 = 3;
const uint EM_68K = 4;
const uint EM_88K = 5;
const uint EM_486 = 6;
const uint EM_860 = 7;
const uint EM_MIPS = 8;

/** Values defining section types. */
const uint SHT_NULL = 0;
const uint SHT_PROGBITS = 1;
const uint SHT_SYMTAB = 2;
const uint SHT_STRTAB = 3;
const uint SHT_RELA = 4;
const uint SHT_HASH = 5;
const uint SHT_DYNAMIC = 6;
const uint SHT_NOTE = 7;
const uint SHT_NOBITS = 8;
const uint SHT_REL = 9;
const uint SHT_SHLIB = 10;
const uint SHT_DYNSYM = 11;
const uint SHT_LOPROC = 0x70000000;
const uint SHT_HIPROC = 0x7fffffff;
const uint SHT_LOUSER = 0x80000000;
const uint SHT_HIUSER = 0xffffffff;

const uint SHF_WRITE = 0x1;
const uint SHF_ALLOC = 0x2;
const uint SHF_EXECINSTR = 0x4;

/** Values defining segment types. */
const uint PT_NULL = 0;
const uint PT_LOAD = 1;
const uint PT_DYNAMIC = 2;
const uint PT_INTERP = 3;
const uint PT_NOTE = 4;
const uint PT_SHLIB = 5;
const uint PT_PHDR = 6;
const uint PT_LOPROC = 0x70000000;
const uint PT_HIPROC = 0x7fffffff;

alias uint Elf32_Addr;
alias ushort Elf32_Half;
alias uint Elf32_Off;
alias int Elf32_SWord;
alias uint Elf32_Word;
alias ushort Elf32_Sword;

struct Elf32_Ehdr {
	ubyte[EI_NIDENT] e_ident;
	Elf32_Half e_type;
	Elf32_Half e_machine;
	Elf32_Word e_version;
	Elf32_Addr e_entry;
	Elf32_Off e_phoff;
	Elf32_Off e_shoff;
	Elf32_Word e_flags;
	Elf32_Half e_ehsize;
	Elf32_Half e_phentsize;
	Elf32_Half e_phnum;
	Elf32_Half e_shentsize;
	Elf32_Half e_shnum;
	Elf32_Half e_shstrndx;
}

struct Elf32_Shdr {
	Elf32_Word sh_name;
	Elf32_Word sh_type;
	Elf32_Word sh_flags;
	Elf32_Addr sh_addr;
	Elf32_Off sh_offset;
	Elf32_Word sh_size;
	Elf32_Word sh_link;
	Elf32_Word sh_info;
	Elf32_Word sh_addralign;
	Elf32_Word sh_entsize;
}

struct Elf32_Phdr {
	Elf32_Word p_type;
	Elf32_Off p_offset;
	Elf32_Addr p_vaddr;
	Elf32_Addr p_paddr;
	Elf32_Word p_filesz;
	Elf32_Word p_memsz;
	Elf32_Word p_flags;
	Elf32_Word p_align;
}

struct Elf32_Rel {
	Elf32_Addr r_offset;
	Elf32_Word r_info;
}

struct Elf32_Rela {
	Elf32_Addr r_offset;
	Elf32_Word r_info;
	Elf32_Sword r_addend;

	ubyte symbol() {
		return cast(ubyte) (this.r_info >> 8);
	}

	ubyte type() {
		return cast(ubyte) this.r_info;
	}
}

class ELF32Binary {
	this() {
	}
	
	void parse(string executable) {
		this.parse(new ELFReader(FileBuffer(executable)));
	}

	void printElfHeader() {
		ubyte[] m = this.ehdr.e_ident;

		writefln("  Magic:\t%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11],
				m[12], m[13], m[14], m[15]);
		writefln("  Class:\t\t\t\t%s", classStrings[m[EI_CLASS]]);
		writefln("  Data:\t\t\t\t\t%s", dataStrings[m[EI_DATA]]);
		writefln("  Version:\t\t\t\t%s", versionStrings[m[EI_VERSION]]);
		writefln("  Type:\t\t\t\t\t%s", objectTypeStr(this.ehdr.e_type));
		writefln("  Machine:\t\t\t\t%s", machineStrings[this.ehdr.e_machine]);
		writefln("  Version:\t\t\t\t0x%x", this.ehdr.e_version);
		writefln("  Entry point address:\t\t\t0x%x", this.ehdr.e_entry);
		writefln("  Start of program headers:\t\t%s (bytes into the file)", this.ehdr.e_phoff);
		writefln("  Start of section headers:\t\t%s (bytes into the file)", this.ehdr.e_shoff);
		writefln("  Flags:\t\t\t\t0x%x", this.ehdr.e_flags);
		writefln("  Size of this header:\t\t\t%s (bytes)", this.ehdr.e_ehsize);
		writefln("  Size of program headers:\t\t%s (bytes)", this.ehdr.e_phentsize);
		writefln("  Number of program headers:\t\t%s", this.ehdr.e_phnum);
		writefln("  Size of section headers:\t\t%s (bytes)", this.ehdr.e_shentsize);
		writefln("  Number of section headers:\t\t%s", this.ehdr.e_shnum);
		writefln("  Section header string table index:\t%s", this.ehdr.e_shstrndx);
	}

	void printProgramHeader(uint n, Elf32_Phdr phdr) {
		writefln("Program header %d", n);
		writefln("  Type:\t\t\t\t%s", segmentTypeStr(phdr.p_type));
		writefln("  Offset:\t\t\t0x%x", phdr.p_offset);
		writefln("  Virtual address:\t\t0x%x", phdr.p_vaddr);
		writefln("  Physical address:\t\t0x%x", phdr.p_paddr);
		writefln("  Size in file:\t\t\t%d (in bytes)", phdr.p_filesz);
		writefln("  Size in memory:\t\t%d (in bytes)", phdr.p_offset);
		writefln("  Flags:\t\t\t0x%x", phdr.p_flags);
		writefln("  Alignment:\t\t\t%d", phdr.p_align);
	}

	void printProgramHeaders() {
		writefln("Program Headers: %d", this.phdrs.length);
		foreach(idx, phdr; this.phdrs)
			printProgramHeader(idx, phdr);
	}

	void printSectionHeader(uint n, Elf32_Shdr shdr) {
		writefln("Section header %d: %s", n, this.getSectionName(shdr));
		writefln("  Type:\t\t\t\t%s", sectionTypeStr(shdr.sh_type));
		writefln("  Flags:\t\t\t0x%x", shdr.sh_flags);
		writefln("  Memory address:\t\t0x%x", shdr.sh_addr);
		writefln("  File offset:\t\t\t%d", shdr.sh_offset);
		writefln("  Size:\t\t\t\t%d (in bytes)", shdr.sh_size);
		writefln("  Linked section:\t\t%d", shdr.sh_link);
		writefln("  Info:\t\t\t\t%d", shdr.sh_info);
		writefln("  Alignment:\t\t\t%d", shdr.sh_addralign);
		writefln("  Entry size:\t\t\t%d (in bytes)", shdr.sh_entsize);
	}

	void printSectionHeaders() {
		writefln("Section Headers: %d", this.shdrs.length);
		foreach(idx, shdr; this.shdrs)
			printSectionHeader(idx, shdr);
	}
	
	string getSectionName(Elf32_Shdr shdr) {
		return to!(string)(this.shstr + shdr.sh_name);
	}

	T* ptr(T)(uint offset) {
		return cast(T*) (this.bitslab + offset);
	}

	T[] ptrArray(T)(uint offset, uint len) {
		return (cast(T*) (this.bitslab + offset))[0 .. len];
	}

	void parse(ELFReader reader) {
		void[] data;
		reader.getAll(data);
		this.slabsize = data.length;
		this.bitslab = data.ptr;

		/* Read header */
		this.ehdr = *(cast(Elf32_Ehdr*) bitslab);

		assert(this.ehdr.e_type == ET_EXEC, "Not an executable file");
		assert(this.ehdr.e_ident[0 .. 4] == cast(ubyte[]) "\x7fELF", "Not a valid ELF Object file");

		uint elfversion = this.ehdr.e_ident[EI_VERSION];
		if(elfversion == EV_NONE || elfversion > EV_CURRENT) {
			throw new Exception("Invalid specification version.");
		} else if(elfversion > DDL_ELFVERSION_SUPP) {
			throw new Exception("This version of the specification is still to be implemented.");
		}

		assert(this.ehdr.e_ident[EI_CLASS] == ELFCLASS32, "Only 32 bit binary is supported.");
		assert(this.ehdr.e_ident[EI_DATA] == ELFDATA2LSB, "Only little-endian binary is supported..");
		assert(this.ehdr.e_machine == EM_MIPS, "Only MIPS binary is supported.");
		
		/* Read section headers */
		this.shdrs = ptrArray!(Elf32_Shdr)(this.ehdr.e_shoff, this.ehdr.e_shnum);

		foreach(shdr; this.shdrs) {
			switch(shdr.sh_type) {
				case SHT_NULL:
				break;

				case SHT_PROGBITS:
				break;

				case SHT_SYMTAB:
				case SHT_HASH:
				break;

				case SHT_DYNAMIC:
				case SHT_DYNSYM:
					logging.fatal(LogCategory.ELF, "dynamic linking is not supported");
				break;

				case SHT_STRTAB:
				break;

				case SHT_RELA:
					Elf32_Rela[] relaSet = ptrArray!(Elf32_Rela)(shdr.sh_offset, shdr.sh_size);
					foreach(rela; relaSet) {
					}
				break;

				case SHT_NOTE:
				break;

				case SHT_NOBITS:
				break;

				case SHT_REL:
					Elf32_Rel[] relSet = ptrArray!(Elf32_Rel)(shdr.sh_offset, shdr.sh_size);
					foreach(rela; relSet) {
					}
				break;

				case SHT_SHLIB:
				break;

				default:
				break;
			}
		}

		Elf32_Shdr shstr_shdr = this.shdrs[this.ehdr.e_shstrndx];
		this.shstr = this.ptr!(char)(shstr_shdr.sh_offset);

		this.phdrs = ptrArray!(Elf32_Phdr)(this.ehdr.e_phoff, this.ehdr.e_phnum);
	}

	string sectionTypeStr(uint n) {
		if(n <= SHT_DYNSYM) {
			return sectionTypes[n];
		} else if(n >= SHT_LOPROC && n <= SHT_HIPROC) {
			return "[SHT_LOPROC..SHT_HIPROC]";
		} else if(n >= SHT_LOUSER && n <= SHT_HIUSER) {
			return "[SHT_LOUSER..SHT_HIUSER]";
		}
		return "";
	}

	string segmentTypeStr(uint n) {
		if(n <= PT_SHLIB) {
			return segmentTypes[n];
		} else if(n >= PT_LOPROC && n <= PT_HIPROC) {
			return "[PT_LOPROC..PT_HIPROC]";
		}
		return "";
	}

	string objectTypeStr(uint n) {
		if(n <= ET_CORE) {
			return objectTypes[n];
		} else if(n >= ET_LOPROC && n <= ET_HIPROC) {
			return "[ET_LOPROC..ET_HIPROC]";
		}
		return "";
	}
	
	static const string[] sectionTypes = ["SHT_NULL", "SHT_PROGBITS", "SHT_SYMTAB", "SHT_STRTAB", "SHT_RELA", "SHT_HASH", "SHT_DYNAMIC", "SHT_NOTE", "SHT_NOBITS", "SHT_REL", "SHT_SHLIB", "SHT_DYNSYM"];

	static const string[] segmentTypes = ["PT_NULL", "PT_LOAD", "PT_DYNAMIC", "PT_INTERP", "PT_NOTE", "PT_SHLIB", "PT_PHDR"];

	static const string[] objectTypes = ["ET_NONE", "ET_REL (Relocatable)", "ET_EXEC (Executable)", "ET_DYN (Dynamic)", "ET_CORE"];

	static const string[] classStrings = ["ELFCLASSNONE", "ELFCLASS32", "ELFCLASS64"];

	static const string[] dataStrings = ["ELFDATANONE (Invalid)", "2's complement, little endian", "ELFDATA2MSB"];

	static const string[] versionStrings = ["0", "1 (current)"];

	static const string[] machineStrings = ["EM_NONE", "EM_M32", "EM_SPARC", "EM_386 (Intel 80386)", "EM_68K", "EM_88K", "EM_486", "EM_860", "EM_MIPS"];
	
	char* shstr;

	void* bitslab;
	uint slabsize;
	
	Elf32_Ehdr ehdr;
	Elf32_Shdr[] shdrs;
	Elf32_Phdr[] phdrs;
}

const uint LD_STACK_BASE = 0xc0000000;
const uint LD_MAX_ENVIRON = 0x40000; /* 16KB for environment */
const uint LD_STACK_SIZE = 0x100000; /* 8MB stack size */

//extern(C)
//	extern __gshared char** environ;

struct FdMap {
	int fd = -1;
	string filename = "NULL";
	int mode = 0;
	int flags = 0;
	bool isPipe = false;
	int readPipeSource = 0;
	ulong fileOffset = 0;
};

class Process {
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
		stack_ptr += uint.sizeof;

		/*skip stack_ptr past argv pointer array*/
		argAddr = stack_ptr;
		thread.setSyscallArg(1, argAddr);
		stack_ptr += (this.argc + 1) * uint.sizeof;

		/*skip env pointer array*/
		envAddr = stack_ptr;
		stack_ptr += this.env.length * uint.sizeof + uint.sizeof;

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
		if(stack_ptr + uint.sizeof >= STACK_BASE) {
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
	
	string cwd;
	string[] args;
	int argc;
	char*[] argv;
	char*[] env;
	char* prog_fname;
	
	uint brk, mmap_brk;
	uint prog_entry;
	
	uint uid, euid, gid, egid, pid, ppid;
	
	uint argvp;
}

alias uint function(SyscallDesc, Thread) SyscallAction;

const uint MAXBUFSIZE = 1024;

/// This struct is used to build an target-OS-dependent table that
/// maps the target's open() flags to the host open() flags.
struct OpenFlagTransTable {
	int tgtFlag; // Target system flag value.
	int hostFlag; // Corresponding host system flag value.
};

const uint SIM_O_RDONLY = 0;
const uint SIM_O_WRONLY = 1;
const uint SIM_O_RDWR = 2;
const uint SIM_O_CREAT = 0x100;
const uint SIM_O_EXCL = 0x400;
const uint SIM_O_NOCTTY = 0x800;
const uint SIM_O_TRUNC = 0x200;
const uint SIM_O_APPEND = 8;
const uint SIM_O_NONBLOCK = 0x80;
const uint SIM_O_SYNC = 0x10;

OpenFlagTransTable openFlagTable[] = [{SIM_O_RDONLY, O_RDONLY}, {SIM_O_WRONLY, O_WRONLY}, {SIM_O_RDWR, O_RDWR}, {SIM_O_APPEND, O_APPEND}, {SIM_O_SYNC, O_SYNC}, {SIM_O_NONBLOCK, O_NONBLOCK}, {
		SIM_O_CREAT, O_CREAT}, {SIM_O_TRUNC, O_TRUNC}, {SIM_O_EXCL, O_EXCL}, {SIM_O_NOCTTY, O_NOCTTY}, {0x2000, 0}, ];

// Length of strings in struct utsname (plus 1 for null char).
const int _SYS_NMLN = 65;

/// Interface struct for uname().
struct utsname {
	char sysname[_SYS_NMLN]; // System name.
	char nodename[_SYS_NMLN]; // Node name.
	char release[_SYS_NMLN]; // OS release.
	char ver[_SYS_NMLN]; // OS version.
	char machine[_SYS_NMLN]; // Machine type.
};

/* 1 */
uint exit_impl(SyscallDesc desc, Thread thread) {
	writeln("exiting...");
	thread.halt(thread.getSyscallArg(0) & 0xff);
	return 1;
}

/* 3 */
uint read_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	uint buf_addr = thread.getSyscallArg(1);
	size_t count = thread.getSyscallArg(2);
	
	void* buf = malloc(count);
	ssize_t ret = core.sys.posix.unistd.read(fd, buf, count);
	if(ret > 0) {
		thread.mem.writeBlock(buf_addr, ret, cast(ubyte*) buf);
	}
	free(buf);

	return ret;
}

/* 4 */
uint write_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	uint buf_addr = thread.getSyscallArg(1);
	size_t count = thread.getSyscallArg(2);

	void* buf = malloc(count);
	thread.mem.readBlock(buf_addr, count, cast(ubyte*) buf);
	ssize_t ret = core.sys.posix.unistd.write(fd, buf, count);
	free(buf);

	return ret;
}

/* 5 */
uint open_impl(SyscallDesc desc, Thread thread) {
	char path[MAXBUFSIZE];

	uint addr = thread.getSyscallArg(0);
	uint tgtFlags = thread.getSyscallArg(1);
	uint mode = thread.getSyscallArg(2);

	int strlen = thread.mem.readString(addr, MAXBUFSIZE, &path[0]);

	// translate open flags
	int hostFlags = 0;
	foreach(t; openFlagTable) {
		if(tgtFlags & t.tgtFlag) {
			tgtFlags &= ~t.tgtFlag;
			hostFlags |= t.hostFlag;
		}
	}

	// any target flags left?
	if(tgtFlags != 0)
		logging.fatalf(LogCategory.SYSCALL, "Syscall: open: cannot decode flags 0x%x", tgtFlags);

	// Adjust path for current working directory
	path = thread.process.fullPath(to!(string)(toStringz(path)));

	// open the file
	int fd = open(path.ptr, hostFlags, mode);
	return fd;
}

/* 6 */
uint close_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	int ret = close(fd);
	return ret;
}

/* 19 */
uint lseek_impl(SyscallDesc desc, Thread thread) {
	int fildes = thread.getSyscallArg(0);
	off_t offset = thread.getSyscallArg(1);
	int whence = thread.getSyscallArg(2);
	
	off_t ret = lseek(fildes, offset, whence);
	return cast(uint) ret;
}

/* 20 */
uint getpid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.pid;
}

/* 24 */
uint getuid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.uid;
}

/// For times().
struct tms {
	int64_t tms_utime; // user time
	int64_t tms_stime; // system time
	int64_t tms_cutime; // user time of children
	int64_t tms_cstime; // system time of children
};

/* 43 */
uint times_impl(SyscallDesc desc, Thread thread) {
	assert(0);
	//tms buf;
	//clock_t ret = times(&buf);
	//uint buf_addr = thread.getSyscallArg(0);
	//thread.mem.writeBlock(buf_addr, tms.sizeof, cast(ubyte*) buf);
	//return ret != cast(clock_t)-1;
	//return -EINVAL;
}

/* 45 */
uint brk_impl(SyscallDesc desc, Thread thread) {
	int retval;

	uint oldbrk, newbrk;
	uint oldbrk_rnd, newbrk_rnd;

	newbrk = thread.getSyscallArg(0);
	oldbrk = thread.process.brk;

	if(newbrk == 0) {
		return thread.process.brk;
	}

	newbrk_rnd = Rounding!(uint).roundUp(newbrk, MEM_PAGESIZE);
	oldbrk_rnd = Rounding!(uint).roundUp(oldbrk, MEM_PAGESIZE);

	if(newbrk > oldbrk) {
		thread.mem.map(oldbrk_rnd, newbrk_rnd - oldbrk_rnd, MemoryAccessType.READ | MemoryAccessType.WRITE);
	} else if(newbrk < oldbrk) {
		thread.mem.unmap(newbrk_rnd, oldbrk_rnd - newbrk_rnd);
	}
	thread.process.brk = newbrk;

	return thread.process.brk;
}

/* 47 */
uint getgid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.gid;
}

/* 49 */
uint geteuid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.euid;
}

/* 50 */
uint getegid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.egid;
}

/* 90 */
uint mmap_impl(SyscallDesc desc, Thread thread) {
	assert(0); //TODO
	//return -EINVAL;
}

/* 108 */
uint fstat_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	uint buf_addr = thread.getSyscallArg(1);
	stat_t* buf = cast(stat_t*)(malloc(stat_t.sizeof));
	int ret = fstat(fd, buf);
	if(ret >= 0) {
		thread.mem.writeBlock(buf_addr, stat_t.sizeof, cast(ubyte*) buf);
	}
	free(buf);
	return ret;
}

/* 122 */
uint uname_impl(SyscallDesc desc, Thread thread) {
	utsname un = {"Linux", "sim", "2.6", "Tue Apr 5 12:21:57 UTC 2005", "mips"};
	thread.mem.writeBlock(thread.getSyscallArg(0), un.sizeof, cast(ubyte*) &un);
	return 0;
}

/* 140 */
uint _llseek_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	uint offset_high = thread.getSyscallArg(1);
	uint offset_low = thread.getSyscallArg(2);
	uint result_addr = thread.getSyscallArg(3);
	int whence = thread.getSyscallArg(4);
	
	int ret;
	
	if(offset_high == 0) {
		off_t lseek_ret = lseek(fd, offset_low, whence);
		if(lseek_ret >= 0) {
			ret = 0;
		}
		else {
			ret = -1;
		}
	}
	else {
		ret = -1;
	}
	
	return ret;
}

/* 197 */
uint fstat64_impl(SyscallDesc desc, Thread thread) {
	assert(0); //TODO
	//return -EINVAL;
}

uint invalidArg_impl(SyscallDesc desc, Thread thread) {
	logging.warnf(LogCategory.SYSCALL, "syscall %s is ignored.", desc.name);
	return -EINVAL;
}

class SyscallEmul {
	this() {
		this.initSyscallDescs();
	}

	void initSyscallDescs() {
		uint index = 0;

		void _register(string name, SyscallAction action = null) {
			this.register(name, index, action);
		}

		/* 0 */ _register("syscall");
		/* 1 */ _register("exit", &exit_impl);
		/* 2 */ _register("fork", &invalidArg_impl);
		/* 3 */ _register("read", &read_impl);
		/* 4 */ _register("write", &write_impl);
		/* 5 */ _register("open", &open_impl);
		/* 6 */ _register("close", &close_impl);
		/* 7 */ _register("waitpid", &invalidArg_impl);
		/* 8 */ _register("creat", &invalidArg_impl);
		/* 8 */ _register("link", &invalidArg_impl);
		/* 10 */ _register("unlink", &invalidArg_impl);
		/* 11 */ _register("execve", &invalidArg_impl);
		/* 12 */ _register("chdir", &invalidArg_impl);
		/* 13 */ _register("time", &invalidArg_impl);
		/* 14 */ _register("mknod", &invalidArg_impl);
		/* 15 */ _register("chmod", &invalidArg_impl);
		/* 16 */ _register("lchown", &invalidArg_impl);
		/* 17 */ _register("break", &invalidArg_impl);
		/* 18 */ _register("oldstat", &invalidArg_impl);
		/* 19 */ _register("lseek", &lseek_impl);
		/* 20 */ _register("getpid", &getpid_impl);
		/* 21 */ _register("mount", &invalidArg_impl);
		/* 22 */ _register("umount", &invalidArg_impl);
		/* 23 */ _register("setuid", &invalidArg_impl);
		/* 24 */ _register("getuid", &getuid_impl);
		/* 25 */ _register("stime", &invalidArg_impl);
		/* 26 */ _register("ptrace", &invalidArg_impl);
		/* 27 */ _register("alarm", &invalidArg_impl);
		/* 28 */ _register("oldfstat", &invalidArg_impl);
		/* 29 */ _register("pause", &invalidArg_impl);
		/* 30 */ _register("utime", &invalidArg_impl);
		/* 31 */ _register("stty", &invalidArg_impl);
		/* 32 */ _register("gtty", &invalidArg_impl);
		/* 33 */ _register("access", &invalidArg_impl);
		/* 34 */ _register("nice", &invalidArg_impl);
		/* 35 */ _register("ftime", &invalidArg_impl);
		/* 36 */ _register("sync", &invalidArg_impl);
		/* 37 */ _register("kill", &invalidArg_impl);
		/* 38 */ _register("rename", &invalidArg_impl);
		/* 39 */ _register("mkdir", &invalidArg_impl);
		/* 40 */ _register("rmdir", &invalidArg_impl);
		/* 41 */ _register("dup", &invalidArg_impl);
		/* 42 */ _register("pipe", &invalidArg_impl);
		/* 43 */ _register("times", &times_impl);
		/* 44 */ _register("prof", &invalidArg_impl);
		/* 45 */ _register("brk", &brk_impl);
		/* 46 */ _register("setgid", &invalidArg_impl);
		/* 47 */ _register("getgid", &getgid_impl);
		/* 48 */ _register("signal", &invalidArg_impl);
		/* 49 */ _register("geteuid", &geteuid_impl);
		/* 50 */ _register("getegid", &getegid_impl);
		/* 51 */ _register("acct", &invalidArg_impl);
		/* 52 */ _register("umount2", &invalidArg_impl);
		/* 53 */ _register("lock", &invalidArg_impl);
		/* 54 */ _register("ioctl", &invalidArg_impl);
		/* 55 */ _register("fcntl", &invalidArg_impl);
		/* 56 */ _register("mpx", &invalidArg_impl);
		/* 57 */ _register("setpgid", &invalidArg_impl);
		/* 58 */ _register("ulimit", &invalidArg_impl);
		/* 59 */ _register("oldolduname", &invalidArg_impl);
		/* 60 */ _register("umask", &invalidArg_impl);
		/* 61 */ _register("chroot", &invalidArg_impl);
		/* 62 */ _register("ustat", &invalidArg_impl);
		/* 63 */ _register("dup2", &invalidArg_impl);
		/* 64 */ _register("getppid", &invalidArg_impl);
		/* 65 */ _register("getpgrp", &invalidArg_impl);
		/* 66 */ _register("setsid", &invalidArg_impl);
		/* 67 */ _register("sigaction", &invalidArg_impl);
		/* 68 */ _register("sgetmask", &invalidArg_impl);
		/* 69 */ _register("ssetmask", &invalidArg_impl);
		/* 70 */ _register("setreuid", &invalidArg_impl);
		/* 71 */ _register("setregid", &invalidArg_impl);
		/* 72 */ _register("sigsuspend", &invalidArg_impl);
		/* 73 */ _register("sigpending", &invalidArg_impl);
		/* 74 */ _register("sethostname", &invalidArg_impl);
		/* 75 */ _register("setrlimit", &invalidArg_impl);
		/* 76 */ _register("getrlimit", &invalidArg_impl);
		/* 77 */ _register("getrusage", &invalidArg_impl);
		/* 78 */ _register("gettimeofday", &invalidArg_impl);
		/* 79 */ _register("settimeofday", &invalidArg_impl);
		/* 80 */ _register("getgroups", &invalidArg_impl);
		/* 81 */ _register("setgroups", &invalidArg_impl);
		/* 82 */ _register("select", &invalidArg_impl);
		/* 83 */ _register("symlink", &invalidArg_impl);
		/* 84 */ _register("oldlstat", &invalidArg_impl);
		/* 85 */ _register("readlink", &invalidArg_impl);
		/* 86 */ _register("uselib", &invalidArg_impl);
		/* 87 */ _register("swapon", &invalidArg_impl);
		/* 88 */ _register("reboot", &invalidArg_impl);
		/* 89 */ _register("readdir", &invalidArg_impl);
		/* 90 */ _register("mmap", &mmap_impl);
		/* 91 */ _register("munmap", &invalidArg_impl);
		/* 92 */ _register("truncate", &invalidArg_impl);
		/* 93 */ _register("ftruncate", &invalidArg_impl);
		/* 94 */ _register("fchmod", &invalidArg_impl);
		/* 95 */ _register("fchown", &invalidArg_impl);
		/* 96 */ _register("getpriority", &invalidArg_impl);
		/* 97 */ _register("setpriority", &invalidArg_impl);
		/* 98 */ _register("profil", &invalidArg_impl);
		/* 99 */ _register("statfs", &invalidArg_impl);
		/* 100 */ _register("fstatfs", &invalidArg_impl);
		/* 101 */ _register("ioperm", &invalidArg_impl);
		/* 102 */ _register("socketcall", &invalidArg_impl);
		/* 103 */ _register("syslog", &invalidArg_impl);
		/* 104 */ _register("setitimer", &invalidArg_impl);
		/* 105 */ _register("getitimer", &invalidArg_impl);
		/* 106 */ _register("stat", &invalidArg_impl);
		/* 107 */ _register("lstat", &invalidArg_impl);
		/* 108 */ _register("fstat", &fstat_impl);
		/* 109 */ _register("olduname", &invalidArg_impl);
		/* 110 */ _register("iopl", &invalidArg_impl);
		/* 111 */ _register("vhangup", &invalidArg_impl);
		/* 112 */ _register("idle", &invalidArg_impl);
		/* 113 */ _register("vm86old", &invalidArg_impl);
		/* 114 */ _register("wait4", &invalidArg_impl);
		/* 115 */ _register("swapoff", &invalidArg_impl);
		/* 116 */ _register("sysinfo", &invalidArg_impl);
		/* 117 */ _register("ipc", &invalidArg_impl);
		/* 118 */ _register("fsync", &invalidArg_impl);
		/* 119 */ _register("sigreturn", &invalidArg_impl);
		/* 120 */ _register("clone", &invalidArg_impl);
		/* 121 */ _register("setdomainname", &invalidArg_impl);
		/* 122 */ _register("uname", &uname_impl);
		/* 123 */ _register("modify_ldt", &invalidArg_impl);
		/* 124 */ _register("adjtimex", &invalidArg_impl);
		/* 125 */ _register("mprotect", &invalidArg_impl);
		/* 126 */ _register("sigprocmask", &invalidArg_impl);
		/* 127 */ _register("create_module", &invalidArg_impl);
		/* 128 */ _register("init_module", &invalidArg_impl);
		/* 129 */ _register("delete_module", &invalidArg_impl);
		/* 130 */ _register("get_kernel_syms", &invalidArg_impl);
		/* 131 */ _register("quotactl", &invalidArg_impl);
		/* 132 */ _register("getpgid", &invalidArg_impl);
		/* 133 */ _register("fchdir", &invalidArg_impl);
		/* 134 */ _register("bdflush", &invalidArg_impl);
		/* 135 */ _register("sysfs", &invalidArg_impl);
		/* 136 */ _register("personality", &invalidArg_impl);
		/* 137 */ _register("afs_syscall", &invalidArg_impl);
		/* 138 */ _register("setfsuid", &invalidArg_impl);
		/* 139 */ _register("setfsgid", &invalidArg_impl);
		/* 140 */ _register("_llseek", &_llseek_impl);
		/* 141 */ _register("getdents", &invalidArg_impl);
		/* 142 */ _register("_newselect", &invalidArg_impl);
		/* 143 */ _register("flock", &invalidArg_impl);
		/* 144 */ _register("msync", &invalidArg_impl);
		/* 145 */ _register("readv", &invalidArg_impl);
		/* 146 */ _register("writev", &invalidArg_impl);
		/* 147 */ _register("getsid", &invalidArg_impl);
		/* 148 */ _register("fdatasync", &invalidArg_impl);
		/* 149 */ _register("_sysctl", &invalidArg_impl);
		/* 150 */ _register("mlock", &invalidArg_impl);
		/* 151 */ _register("munlock", &invalidArg_impl);
		/* 152 */ _register("mlockall", &invalidArg_impl);
		/* 153 */ _register("munlockall", &invalidArg_impl);
		/* 154 */ _register("sched_setparam", &invalidArg_impl);
		/* 155 */ _register("sched_getparam", &invalidArg_impl);
		/* 156 */ _register("sched_setscheduler", &invalidArg_impl);
		/* 157 */ _register("sched_getscheduler", &invalidArg_impl);
		/* 158 */ _register("sched_yield", &invalidArg_impl);
		/* 159 */ _register("sched_get_priority_max", &invalidArg_impl);
		/* 160 */ _register("sched_get_priority_min", &invalidArg_impl);
		/* 161 */ _register("sched_rr_get_interval", &invalidArg_impl);
		/* 162 */ _register("nanosleep", &invalidArg_impl);
		/* 163 */ _register("mremap", &invalidArg_impl);
		/* 164 */ _register("setresuid", &invalidArg_impl);
		/* 165 */ _register("getresuid", &invalidArg_impl);
		/* 166 */ _register("vm86", &invalidArg_impl);
		/* 167 */ _register("query_module", &invalidArg_impl);
		/* 168 */ _register("poll", &invalidArg_impl);
		/* 169 */ _register("nfsservctl", &invalidArg_impl);
		/* 170 */ _register("setresgid", &invalidArg_impl);
		/* 171 */ _register("getresgid", &invalidArg_impl);
		/* 172 */ _register("prctl", &invalidArg_impl);
		/* 173 */ _register("rt_sigreturn", &invalidArg_impl);
		/* 174 */ _register("rt_sigaction", &invalidArg_impl);
		/* 175 */ _register("rt_sigprocmask", &invalidArg_impl);
		/* 176 */ _register("rt_sigpending", &invalidArg_impl);
		/* 177 */ _register("rt_sigtimedwait", &invalidArg_impl);
		/* 178 */ _register("rt_sigqueueinfo", &invalidArg_impl);
		/* 179 */ _register("rt_sigsuspend", &invalidArg_impl);
		/* 180 */ _register("pread", &invalidArg_impl);
		/* 181 */ _register("pwrite", &invalidArg_impl);
		/* 182 */ _register("chown", &invalidArg_impl);
		/* 183 */ _register("getcwd", &invalidArg_impl);
		/* 184 */ _register("capget", &invalidArg_impl);
		/* 185 */ _register("capset", &invalidArg_impl);
		/* 186 */ _register("sigalstack", &invalidArg_impl);
		/* 187 */ _register("sendfile", &invalidArg_impl);
		/* 188 */ _register("getpmsg", &invalidArg_impl);
		/* 189 */ _register("putpmsg", &invalidArg_impl);
		/* 190 */ _register("vfork", &invalidArg_impl);
		/* 191 */ _register("ugetrlimit", &invalidArg_impl);
		/* 192 */ _register("mmap2", &invalidArg_impl);
		/* 193 */ _register("truncate64", &invalidArg_impl);
		/* 194 */ _register("ftruncate64", &invalidArg_impl);
		/* 195 */ _register("stat64", &invalidArg_impl);
		/* 196 */ _register("lstat64", &invalidArg_impl);
		/* 197 */ _register("fstat64", &fstat64_impl);
		/* 198 */ _register("lchown32", &invalidArg_impl);
		/* 199 */ _register("getuid32", &invalidArg_impl);
		/* 200 */ _register("getgid32", &invalidArg_impl);
		/* 201 */ _register("geteuid32", &invalidArg_impl);
		/* 202 */ _register("getegid32", &invalidArg_impl);
		/* 203 */ _register("setreuid32", &invalidArg_impl);
		/* 204 */ _register("setregid32", &invalidArg_impl);
		/* 205 */ _register("getgroups32", &invalidArg_impl);
		/* 206 */ _register("setgroups32", &invalidArg_impl);
		/* 207 */ _register("fchown32", &invalidArg_impl);
		/* 208 */ _register("setresuid32", &invalidArg_impl);
		/* 209 */ _register("getresuid32", &invalidArg_impl);
		/* 210 */ _register("setresgid32", &invalidArg_impl);
		/* 211 */ _register("getresgid32", &invalidArg_impl);
		/* 212 */ _register("chown32", &invalidArg_impl);
		/* 213 */ _register("setuid32", &invalidArg_impl);
		/* 214 */ _register("setgid32", &invalidArg_impl);
		/* 215 */ _register("setfsuid32", &invalidArg_impl);
		/* 216 */ _register("setfsgid32", &invalidArg_impl);
		/* 217 */ _register("pivot_root", &invalidArg_impl);
		/* 218 */ _register("mincore", &invalidArg_impl);
		/* 219 */ _register("madvise", &invalidArg_impl);
		/* 220 */ _register("getdents64", &invalidArg_impl);
		/* 221 */ _register("fcntl64", &invalidArg_impl);
	}

	void register(string name, ref uint num) {
		this.register(new SyscallDesc(name, num++));
	}

	void register(string name, ref uint num, SyscallAction action) {
		this.register(new SyscallDesc(name, num++, action));
	}

	void register(SyscallDesc desc) {
		this.syscallDescs[desc.num] = desc;
	}

	void syscall(uint callnum, Thread thread) {
		int syscall_idx = callnum - 4000;

		if(syscall_idx >= 0 && syscall_idx < this.syscallDescs.length && (syscall_idx in this.syscallDescs)) {
			this.syscallDescs[syscall_idx].doSyscall(thread);
		} else {
			logging.warnf(LogCategory.SYSCALL, "Syscall %d (%d) out of range", callnum, syscall_idx);
			thread.setSyscallReturn(-EINVAL);
		}
	}

	SyscallDesc[uint] syscallDescs;
}

class SyscallDesc {
	this(string name, uint num) {
		this.name = name;
		this.num = num;
		this.action = null;
	}

	this(string name, uint num, SyscallAction action) {
		this.name = name;
		this.num = num;
		this.action = action;
	}

	void doSyscall(Thread thread) {
		if(this.action is null) {
			logging.fatalf(LogCategory.SYSCALL, "syscall %s has not been implemented yet.", this.name);
		}

		uint retval = this.action(this, thread);
		thread.setSyscallReturn(retval);
	}
	
	string name;
	uint num;
	SyscallAction action;
}
