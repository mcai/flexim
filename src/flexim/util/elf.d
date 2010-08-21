/*
 * flexim/util/elf.d
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

module flexim.util.elf;

import flexim.all;

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
	public:
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

	private:
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

		mixin Property!(Elf32_Ehdr, "ehdr");
		mixin Property!(Elf32_Shdr[], "shdrs");
		mixin Property!(Elf32_Phdr[], "phdrs");
}
