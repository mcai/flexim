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

import core.stdc.errno;

import std.c.stdlib;
import std.c.linux.linux;

alias SyscallReturn function(SyscallDesc, Thread) SyscallAction;

alias uint SyscallReturn;

const uint EINVAL = 22;

alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;

//Basic Linux types.
alias uint off_t;
alias int time_t;
alias int clock_t;
alias uint uid_t;
alias uint git_t;

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

/// Stat buffer.  Note that we can't call it 'stat' since that
/// gets #defined to something else on some systems. This type
/// can be specialized by architecture specific "Linux" classes
struct tgt_stat {
	uint32_t st_dev; // device
	uint32_t st_ino; // inode
	uint32_t st_mode; // mode
	uint32_t st_nlink; // link count
	uint32_t st_uid; // owner's user ID
	uint32_t st_gid; // owner's group ID
	uint32_t st_rdev; // device number
	int32_t _pad1; // for alignment
	int64_t st_size; // file size in bytes
	uint64_t st_atimeX; // time of last access
	uint64_t st_mtimeX; // time of last modification
	uint64_t st_ctimeX; // time of last status change
	uint32_t st_blksize; // optimal I/O block size
	int32_t st_blocks; // number of blocks allocated
	uint32_t st_flags; // flags
	uint32_t st_gen; // unknown
}

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

/// Limit struct for getrlimit/setrlimit.
struct rlimit {
	uint64_t rlim_cur; // soft limit
	uint64_t rlim_max; // hard limit
};

/// For gettimeofday().
struct timeval {
	int64_t tv_sec; // seconds
	int64_t tv_usec; // microseconds
};

/// Clock ticks per second, for times().
static const int M5_SC_CLK_TCK = 100;

/// For times().
struct tms {
	int64_t tms_utime; // user time
	int64_t tms_stime; // system time
	int64_t tms_cutime; // user time of children
	int64_t tms_cstime; // system time of children
};

// For writev/readv
struct tgt_iovec {
	uint iov_base; // void *
	uint iov_len;
};

/// For getrusage().
struct rusage {
	timeval ru_utime; // user time used
	timeval ru_stime; // system time used
	int64_t ru_maxrss; // max rss
	int64_t ru_ixrss; // integral shared memory size
	int64_t ru_idrss; // integral unshared data "
	int64_t ru_isrss; // integral unshared stack "
	int64_t ru_minflt; // page reclaims - total vmfaults
	int64_t ru_majflt; // page faults
	int64_t ru_nswap; // swaps
	int64_t ru_inblock; // block input operations
	int64_t ru_oublock; // block output operations
	int64_t ru_msgsnd; // messages sent
	int64_t ru_msgrcv; // messages received
	int64_t ru_nsignals; // signals received
	int64_t ru_nvcsw; // voluntary thread switches
	int64_t ru_nivcsw; // involuntary "
};

SyscallReturn open_impl(SyscallDesc desc, Thread thread) {
	char path[MAXBUFSIZE];

	int index = 0;

	uint arg0 = thread.getSyscallArg(index);
	uint arg1 = thread.getSyscallArg(index);
	uint arg2 = thread.getSyscallArg(index);

	int strlen = thread.mem.readString(arg0, MAXBUFSIZE, &path[0]);

	int tgtFlags = arg1;
	int mode = arg2;
	int hostFlags = 0;

	//	 translate open flags
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

	char* final_path = path.ptr;

	// open the file
	int fd = open(final_path, hostFlags, mode); //TODO /dev/tty?? see m5 impl.

	string path_str = to!(string)(path.ptr);

	writefln("string final_path: %s", path_str);

	return (fd == -1) ? -errno : thread.process.alloc_fd(fd, path_str, hostFlags, mode, false);
}

SyscallReturn write_impl(SyscallDesc desc, Thread thread) {
	int fd;
	size_t count;
	void* buf;
	Addr buf_addr;

	ssize_t ret;

	int index = 0;

	fd = thread.getSyscallArg(index);
	buf_addr = thread.getSyscallArg(index);
	count = thread.getSyscallArg(index);

	buf = calloc(1, count);
	thread.mem.readBlock(buf_addr, count, cast(ubyte*) buf);

	ret = core.sys.posix.unistd.write(fd, buf, count);

	return ret;

}

SyscallReturn uname_impl(SyscallDesc desc, Thread thread) {
	int index = 0;

	utsname un = {"Linux", "sim", "2.6", "Tue Apr 5 12:21:57 UTC 2005", "mips"};

	thread.mem.writeBlock(thread.getSyscallArg(index), un.sizeof, cast(ubyte*) &un);

	return 0;
}

struct iovec {
	void* iov_base; /* Pointer to data.  */
	uint iov_len; /* Length of data.  */
};

extern(C)
	int writev(int __fd, iovec* __iovec, int __count);

SyscallReturn exit_impl(SyscallDesc desc, Thread thread) {
	int index = 0;
	logging.haltf(LogCategory.SYSCALL, "target called exit(%d)", thread.getSyscallArg(index) & 0xff);
	return 1;
}

SyscallReturn writev_impl(SyscallDesc desc, Thread thread) {
	int index = 0;
	int fd = thread.getSyscallArg(index);
	if(fd < 0 || thread.process.sim_fd(fd) < 0) {
		// doesn't map to any simulator fd: not a valid target fd
		return -EBADF;
	}

	uint tiov_base = thread.getSyscallArg(index);
	uint count = thread.getSyscallArg(index);

	iovec[] hiov = new iovec[count];

	for(int i = 0; i < count; ++i) {
		tgt_iovec tiov;

		thread.mem.readBlock(tiov_base + i * tgt_iovec.sizeof, tgt_iovec.sizeof, cast(ubyte*) &tiov);
		hiov[i].iov_len = tiov.iov_len;
		thread.mem.readBlock(tiov.iov_base, hiov[i].iov_len, cast(ubyte*) hiov[i].iov_base);
	}

	int result = writev(thread.process.sim_fd(fd), &hiov[0], count);

	if(result < 0)
		return -errno;

	return 0;
}

SyscallReturn getuid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.uid;
}

SyscallReturn brk_impl(SyscallDesc desc, Thread thread) {
	int retval;

	int index = 0;

	uint oldbrk, newbrk;
	uint oldbrk_rnd, newbrk_rnd;

	newbrk = thread.getSyscallArg(index);
	oldbrk = thread.process.brk;

	if(newbrk == 0) {
		return thread.process.brk;
	}

	newbrk_rnd = Rounding!(uint).roundUp(newbrk, MEM_PAGESIZE);
	oldbrk_rnd = Rounding!(uint).roundUp(oldbrk, MEM_PAGESIZE);

	if(newbrk > oldbrk) {
		thread.mem.map(oldbrk_rnd, newbrk_rnd - oldbrk_rnd, MemoryAccessType.READ | MemoryAccessType.WRITE);
		thread.process.brk = newbrk;
	} else if(newbrk < oldbrk) {
		thread.mem.unmap(newbrk_rnd, oldbrk_rnd - newbrk_rnd);
		thread.process.brk = newbrk;
	}

	return thread.process.brk;
}

SyscallReturn getgid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.gid;
}

SyscallReturn geteuid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.euid;
}

SyscallReturn getegid_impl(SyscallDesc desc, Thread thread) {
	return thread.process.egid;
}

SyscallReturn ioctl_impl(SyscallDesc desc, Thread thread) {
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

			_register("syscall");
			_register("exit", &exit_impl);
			_register("fork");
			_register("read");
			_register("write", &write_impl);
			_register("open", &open_impl);
			_register("close");
			_register("waitpid");
			_register("creat");
			_register("link");
			_register("unlink");
			_register("execve");
			_register("chdir");
			_register("time");
			_register("mknod");
			_register("chmod");
			_register("lchown");
			_register("break");
			_register("unused#18");
			_register("lseek");
			_register("getpid");
			_register("mount");
			_register("umount");
			_register("setuid");
			_register("getuid", &getuid_impl);
			_register("stime");
			_register("ptrace");
			_register("alarm");
			_register("unused#28");
			_register("pause");
			_register("utime");
			_register("stty");
			_register("gtty");
			_register("access");
			_register("nice");
			_register("ftime");
			_register("sync");
			_register("kill");
			_register("rename");
			_register("mkdir");
			_register("rmdir");
			_register("dup");
			_register("pipe");
			_register("times");
			_register("prof");
			_register("brk", &brk_impl);
			_register("setgid");
			_register("getgid", &getgid_impl);
			_register("signal");
			_register("geteuid", &geteuid_impl);
			_register("getegid", &getegid_impl);
			_register("acct");
			_register("umount2");
			_register("lock");
			_register("ioctl", &ioctl_impl);
			_register("fcntl");
			_register("mpx");
			_register("setpgid");
			_register("ulimit");
			_register("unused#59");
			_register("umask");
			_register("chroot");
			_register("ustat");
			_register("dup2");
			_register("getppid");
			_register("getpgrp");
			_register("setsid");
			_register("sigaction");
			_register("sgetmask");
			_register("ssetmask");
			_register("setreuid");
			_register("setregid");
			_register("sigsuspend");
			_register("sigpending");
			_register("sethostname");
			_register("setrlimit");
			_register("getrlimit");
			_register("getrusage");
			_register("gettimeofday");
			_register("settimeofday");
			_register("getgroups");
			_register("setgroups");
			_register("reserved#82");
			_register("symlink");
			_register("unused#84");
			_register("readlink");
			_register("uselib");
			_register("swapon");
			_register("reboot");
			_register("readdir");
			_register("mmap");
			_register("munmap");
			_register("truncate");
			_register("ftruncate");
			_register("fchmod");
			_register("fchown");
			_register("getpriority");
			_register("setpriority");
			_register("profil");
			_register("statfs");
			_register("fstatfs");
			_register("ioperm");
			_register("socketcall");
			_register("syslog");
			_register("setitimer");
			_register("getitimer");
			_register("stat");
			_register("lstat");
			_register("fstat");
			_register("unused#109");
			_register("iopl");
			_register("vhangup");
			_register("idle");
			_register("vm86");
			_register("wait4");
			_register("swapoff");
			_register("sysinfo");
			_register("ipc");
			_register("fsync");
			_register("sigreturn");
			_register("clone");
			_register("setdomainname");
			_register("uname", &uname_impl);
			_register("modify_ldt");
			_register("adjtimex");
			_register("mprotect");
			_register("sigprocmask");
			_register("create_module");
			_register("init_module");
			_register("delete_module");
			_register("get_kernel_syms");
			_register("quotactl");
			_register("getpgid");
			_register("fchdir");
			_register("bdflush");
			_register("sysfs");
			_register("personality");
			_register("afs_syscall");
			_register("setfsuid");
			_register("setfsgid");
			_register("llseek");
			_register("getdents");
			_register("newselect");
			_register("flock");
			_register("msync");
			_register("readv");
			_register("writev", &writev_impl);
			_register("cacheflush");
			_register("cachectl");
			_register("sysmips");
			_register("unused#150");
			_register("getsid");
			_register("fdatasync");
			_register("sysctl");
			_register("mlock");
			_register("munlock");
			_register("mlockall");
			_register("munlockall");
			_register("sched_setparam");
			_register("sched_getparam");
			_register("sched_setscheduler");
			_register("sched_getscheduler");
			_register("sched_yield");
			_register("sched_get_prioritymax");
			_register("sched_get_priority_min");
			_register("sched_rr_get_interval");
			_register("nanosleep");
			_register("mremap");
			_register("accept");
			_register("bind");
			_register("connect");
			_register("getpeername");
			_register("getsockname");
			_register("getsockopt");
			_register("listen");
			_register("recv");
			_register("recvmsg");
			_register("send");
			_register("sendmsg");
			_register("sendto");
			_register("setsockopt");
			_register("shutdown");
			_register("unknown #182");
			_register("socket");
			_register("socketpair");
			_register("setresuid");
			_register("getresuid");
			_register("query_module");
			_register("poll");
			_register("nfsservctl");
			_register("setresgid");
			_register("getresgid");
			_register("prctl");
			_register("rt_sigreturn");
			_register("rt_sigaction");
			_register("rt_sigprocmask");
			_register("rt_sigpending");
			_register("rt_sigtimedwait");
			_register("rt_sigqueueinfo");
			_register("rt_sigsuspend");
			_register("pread64");
			_register("pwrite64");
			_register("chown");
			_register("getcwd");
			_register("capget");
			_register("capset");
			_register("sigalstack");
			_register("sendfile");
			_register("getpmsg");
			_register("putpmsg");
			_register("mmap2");
			_register("truncate64");
			_register("ftruncate64");
			_register("stat64");
			_register("lstat64");
			_register("fstat64");
			_register("pivot_root");
			_register("mincore");
			_register("madvise");
			_register("getdents64");
			_register("fcntl64");
			_register("reserved#221");
			_register("gettid");
			_register("readahead");
			_register("setxattr");
			_register("lsetxattr");
			_register("fsetxattr");
			_register("getxattr");
			_register("lgetxattr");
			_register("fgetxattr");
			_register("listxattr");
			_register("llistxattr");
			_register("flistxattr");
			_register("removexattr");
			_register("lremovexattr");
			_register("fremovexattr");
			_register("tkill");
			_register("sendfile64");
			_register("futex");
			_register("sched_setaffinity");
			_register("sched_getaffinity");
			_register("io_setup");
			_register("io_destroy");
			_register("io_getevents");
			_register("io_submit");
			_register("io_cancel");
			_register("exit_group");
			_register("lookup_dcookie");
			_register("epoll_create");
			_register("epoll_ctl");
			_register("epoll_wait");
			_register("remap_file_pages");
			_register("set_tid_address");
			_register("restart_syscall");
			_register("fadvise64");
			_register("statfs64");
			_register("fstafs64");
			_register("timer_create");
			_register("timer_settime");
			_register("timer_gettime");
			_register("timer_getoverrun");
			_register("timer_delete");
			_register("clock_settime");
			_register("clock_gettime");
			_register("clock_getres");
			_register("clock_nanosleep");
			_register("tgkill");
			_register("utimes");
			_register("mbind");
			_register("get_mempolicy");
			_register("set_mempolicy");
			_register("mq_open");
			_register("mq_unlink");
			_register("mq_timedsend");
			_register("mq_timedreceive");
			_register("mq_notify");
			_register("mq_getsetattr");
			_register("vserver");
			_register("waitid");
			_register("unknown #279");
			_register("add_key");
			_register("request_key");
			_register("keyctl");
			_register("set_thread_area");
			_register("inotify_init");
			_register("inotify_add_watch");
			_register("inotify_rm_watch");
			_register("migrate_pages");
			_register("openat");
			_register("mkdirat");
			_register("mknodat");
			_register("fchownat");
			_register("futimesat");
			_register("fstatat64");
			_register("unlinkat");
			_register("renameat");
			_register("linkat");
			_register("symlinkat");
			_register("readlinkat");
			_register("fchmodat");
			_register("faccessat");
			_register("pselect6");
			_register("ppoll");
			_register("unshare");
			_register("splice");
			_register("sync_file_range");
			_register("tee");
			_register("vmsplice");
			_register("move_pages");
			_register("set_robust_list");
			_register("get_robust_list");
			_register("kexec_load");
			_register("getcpu");
			_register("epoll_pwait");
			_register("ioprio_set");
			_register("ioprio_get");
			_register("utimensat");
			_register("signalfd");
			_register("timerfd");
			_register("eventfd");
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
			int index = 0;

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