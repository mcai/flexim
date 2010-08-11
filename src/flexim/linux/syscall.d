/*
 * flexim/linux/syscall.d
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

module flexim.linux.syscall;

import flexim.all;

import std.c.stdlib;
import std.c.linux.linux;

alias SyscallReturn function(SyscallDesc, Thread) SyscallAction;

alias uint SyscallReturn;

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
SyscallReturn exit_impl(SyscallDesc desc, Thread thread) {
	logging.haltf(LogCategory.SYSCALL, "target called exit(%d)", thread.getSyscallArg(0) & 0xff);
	return 1;
}

/* 3 */
SyscallReturn read_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	Addr buf_addr = thread.getSyscallArg(1);
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
SyscallReturn write_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	Addr buf_addr = thread.getSyscallArg(1);
	size_t count = thread.getSyscallArg(2);

	void* buf = malloc(count);
	thread.mem.readBlock(buf_addr, count, cast(ubyte*) buf);
	ssize_t ret = core.sys.posix.unistd.write(fd, buf, count);
	free(buf);

	return ret;
}

/* 5 */
SyscallReturn open_impl(SyscallDesc desc, Thread thread) {
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
	path = thread.process.fullPath(to!(string)(path));

	// open the file
	int fd = open(path.ptr, hostFlags, mode);
	return fd;
}

/* 6 */
SyscallReturn close_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	int ret = close(fd);
	return ret;
}

/* 19 */
SyscallReturn lseek_impl(SyscallDesc desc, Thread thread) {
	int fildes = thread.getSyscallArg(0);
	off_t offset = thread.getSyscallArg(1);
	int whence = thread.getSyscallArg(2);
	
	off_t ret = lseek(fildes, offset, whence);
	return ret;
}

/* 20 */
SyscallReturn getpid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.pid;
}

/* 24 */
SyscallReturn getuid_impl(SyscallDesc desc, Thread thread) {
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
SyscallReturn times_impl(SyscallDesc desc, Thread thread) {
	assert(0);
	//tms buf;
	//clock_t ret = times(&buf);
	//Addr buf_addr = thread.getSyscallArg(0);
	//thread.mem.writeBlock(buf_addr, tms.sizeof, cast(ubyte*) buf);
	//return ret != cast(clock_t)-1;
	//return 0;
	return -EINVAL;
}

/* 45 */
SyscallReturn brk_impl(SyscallDesc desc, Thread thread) {
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
SyscallReturn getgid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.gid;
}

/* 49 */
SyscallReturn geteuid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.euid;
}

/* 50 */
SyscallReturn getegid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.egid;
}

/* 90 */
SyscallReturn mmap_impl(SyscallDesc desc, Thread thread) {
	assert(0); //TODO
	return -EINVAL;
}

/* 108 */
SyscallReturn fstat_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	Addr buf_addr = thread.getSyscallArg(1);
	stat_t* buf = cast(stat_t*)(malloc(stat_t.sizeof));
	int ret = fstat(fd, buf);
	if(ret >= 0) {
		thread.mem.writeBlock(buf_addr, stat_t.sizeof, cast(ubyte*) buf);
	}
	free(buf);
	return ret;
}

/* 122 */
SyscallReturn uname_impl(SyscallDesc desc, Thread thread) {
	utsname un = {"Linux", "sim", "2.6", "Tue Apr 5 12:21:57 UTC 2005", "mips"};
	thread.mem.writeBlock(thread.getSyscallArg(0), un.sizeof, cast(ubyte*) &un);
	return 0;
}

/* 140 */
SyscallReturn _llseek_impl(SyscallDesc desc, Thread thread) {
	int fd = thread.getSyscallArg(0);
	uint offset_high = thread.getSyscallArg(1);
	uint offset_low = thread.getSyscallArg(2);
	Addr result_addr = thread.getSyscallArg(3);
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
SyscallReturn fstat64_impl(SyscallDesc desc, Thread thread) {
	assert(0); //TODO
	return -EINVAL;
}

SyscallReturn invalidArg_impl(SyscallDesc desc, Thread thread) {
	logging.warnf(LogCategory.SYSCALL, "syscall %s is ignored.", desc.name);
	return -EINVAL;
}

class SyscallEmul {
	public:
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

	private:

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

			SyscallReturn retval = this.action(this, thread);
			thread.setSyscallReturn(retval);
		}
		
		string name;
		uint num;
		SyscallAction action;
}