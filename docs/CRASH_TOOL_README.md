# Crash Tool Guide

The `crash` tool is a powerful utility for analyzing the state of a Linux system after a kernel crash, Below are some command examples and their usage.

When `kdump` captures a system crash, it generates three key files that are crucial for post-mortem analysis:

- `vmcore` is the primary memory dump file containing a snapshot of the system RAM at the time of the crash. It includes all in-memory data, such as the kernel’s memory and process information, providing the raw data needed for in-depth analysis with tools like `crash`

- `vmcore-dmesg.txt` file logs the kernel message buffer leading up to the crash. It records the kernel log messages, helping to identify events or errors that directly preceded the crash, such as hardware faults or out-of-memory conditions

- `kexec-dmesg.log` file details the operations performed by the secondary kdump kernel during the capture process. It is important for troubleshooting any issues that occur during the dumping of vmcore, such as errors in writing the file to disk

Together these files provide a comprehensive view of the system state before, during, and after the crash, enabling thorough analysis and diagnosis.

## Kernel File Types

`vmlinux` is the uncompressed kernel code, `vmlinuz`, and `vmlinux.bin` are compressed versions for booting. `zimage` is an older compressed format, and `bzImage` is an improved version.

- [Differences Between vmlinux, vmlinuz, vmlinux.bin, zimage, and bzimage](https://www.baeldung.com/linux/kernel-images)

## To uncompress the kernel use the command below (Use it only with custom/unofficial kernels <<- Not Recommended)

- `vmlinuz` is a compressed file, but crash requires an uncompressed file `vmlinux`, which is compiled with `-g` option.
Make sure your kernel is compiled with `-g` option, and then you can get an uncompressed `vmlinux` file from compressed `vmlinuz`, using the method as follows:

```bash
od -t x1 -A d /host/usr/lib/modules/4.18.0-372.73.1.el8_6.x86_64/vmlinuz | grep "1f 8b 08"
dd if=/host/usr/lib/modules/$(uname -r)/vmlinuz bs=1 skip=18865 | zcat > /tmp/vmlinux
```

## Crash Tool Basic Usage

- For help on any command below, enter `help <command>`

```bash
crash> help
crash> help bt
crash> help log
```

- To display basic system information, use the `sys` command

- To list all loaded kernel modules, use the `mod` command

- To list all loaded kernel modules, use the `ps` command

- To display the kernel message buffer, use the `log` (Type `help log` for more information)

- To display the kernel stack trace, use the `bt` command (Type `bt <pid>` to display the backtrace of a specific process or type `help bt`)

- To display the status of processes in the system, use the `ps` command (Use `ps <pid>` to display the status of a single specific process or type `help ps`)

- To display basic virtual memory information, type the `vm` command at the interactive prompt

- To display memory usage information, use the `kmem -i`

- To analyze the slab allocator, which manages kernel memory allocations, use the `kmem -s`

- To analyze the slab allocator, which manages kernel memory allocations

```bash
crash> struct task_struct.<field> <task_struct_address>
```

---

## Start Analyzing VMCORE files

- When starting a crash tool, we'll get detailed system information

```bash
WARNING: kernel relocated [594MB]: patching 105453 gdb minimal_symbol values

      KERNEL: /usr/lib/debug/lib/modules/4.18.0-372.73.1.el8_6.x86_64/vmlinux
    DUMPFILE: /vmcore  [PARTIAL DUMP]
        CPUS: 80 # <<- Total CPU
        DATE: Sun Jun 23 10:45:14 UTC 2024
      UPTIME: 00:16:20
LOAD AVERAGE: 0.17, 0.36, 0.49
       TASKS: 2220 # <<- The total number of processes running on the system at the time of the crash
    NODENAME: node-name.domain.name
     RELEASE: 4.18.0-372.73.1.el8_6.x86_64 # <<- Kernel Version
     VERSION: #1 SMP Fri Sep 8 13:16:27 EDT 2023 <<- (#1=version, SMP=multiprocess, realese/comiple date)
     MACHINE: x86_64  (2400 Mhz)
      MEMORY: 766.7 GB # <<- Total RAM
       PANIC: "sysrq: SysRq : Trigger a crash" # <<- Panic Process Message
         PID: 27435 # <<- Panic Process PID
     COMMAND: "bash" # <<- Panic Process Command that caused the panic
        TASK: ffff9f4e8e8f0000  [THREAD_INFO: ffff9f4e8e8f0000] # The memory address of the task structure
         CPU: 14 # <<- Panic occurred on CPU number 14
       STATE: TASK_RUNNING (SYSRQ) # <<- The state of the process when the panic occurred
```

- You may see warnings like `kernel relocated`, This indicates that the kernel image was relocated in memory, and symbols were patched accordingly

```bash
WARNING: kernel relocated [594MB]: patching 105453 gdb minimal_symbol values
```

 **NOTE:** The Output With Panic Process `PID: 27435`, Panic Message `PANIC: "sysrq: SysRq : Trigger a crash"` and `COMMAND: "bash"` indicates which process was causing the kernel dump crash!

## Commands for a high-level overview

### `bt` shows the backtrace of the crashed kernel thread giving insight into where the crash occurred (process execution history)

This backtrace shows the sequence of function calls leading to a kernel panic.
The output shows the series of function calls that were active in the kernel when the crash occurred. Each line represents a frame in the stack, with the most recent function call at the top.

```bash
crash> bt
PID: 27435  TASK: ffff9f4e8e8f0000  CPU: 14  COMMAND: "bash" #
 #0 [ffffafcfb0de7cd8] machine_kexec at ffffffffa626822e
 #1 [ffffafcfb0de7d30] __crash_kexec at ffffffffa63af3ba
 #2 [ffffafcfb0de7df0] panic at ffffffffa62f1d9f
 #3 [ffffafcfb0de7e70] sysrq_handle_crash at ffffffffa67e6fb1
 #4 [ffffafcfb0de7e78] __handle_sysrq.cold.13 at ffffffffa67e78d4
 #5 [ffffafcfb0de7ea8] write_sysrq_trigger at ffffffffa67e777b
 #6 [ffffafcfb0de7eb8] proc_reg_write at ffffffffa65d9a99
 #7 [ffffafcfb0de7ed0] vfs_write at ffffffffa6554485
 #8 [ffffafcfb0de7f00] ksys_write at ffffffffa655470f
 #9 [ffffafcfb0de7f38] do_syscall_64 at ffffffffa62043ab
#10 [ffffafcfb0de7f50] entry_SYSCALL_64_after_hwframe at ffffffffa6c000a9
    RIP: 00007f768c0275a8  RSP: 00007fffd470ad28  RFLAGS: 00000246 
    RAX: ffffffffffffffda  RBX: 0000000000000002  RCX: 00007f768c0275a8
    RDX: 0000000000000002  RSI: 000055898f2923b0  RDI: 0000000000000001
    RBP: 000055898f2923b0   R8: 000000000000000a   R9: 00007f768c087800
    R10: 000000000000000a  R11: 0000000000000246  R12: 00007f768c2c76e0
    R13: 0000000000000002  R14: 00007f768c2c2860  R15: 0000000000000002
    ORIG_RAX: 0000000000000001  CS: 0033  SS: 002b
```

#### `bt` Output Explained

- `#0` The first frame in the backtrace, indicating the function that was executing when the panic occurred

- `[ffffafcfb0de7cd8]` The address of the stack frame

- `machine_kexec` The name of the function. `machine_kexec` is used to shut down the current kernel and start a new one (often used during a kexec reboot or crash dump)

- `fffffffa626822e` The address of the machine_kexec function in the kernel's virtual memory

### `ps` Displays information about processes running at the time of the crash. Look for processes in an unusual state (e.g. D state)

```bash
ps | grep ">"
crash> ps | grep ">"
>     0      0   0  ffffffffa7a18840  RU   0.0       0      0  [swapper/0]
>     0      0   1  ffff9f4e8d108000  RU   0.0       0      0  [swapper/1]
>     0      0   2  ffff9f4e8d10c000  RU   0.0       0      0  [swapper/2]
...
```

- Check the panic process using `ps` with the PID given

```bash
crash> ps | grep 27435
> 27435  23470  14  ffff9f4e8e8f0000  RU   0.0   24904   5312  bash
```

#### `ps` Output Explained

- `>` symbol indicates that these processes are currently running on their respective CPUs

- `27435` Process ID (PID) of the process, The PID uniquely identifies this process within the system

- `23470` Parent Process ID (PPID), indicating the PID of the parent process that started this process

- `14` Indicates the CPU on which each process is running, 14 for CPU 14

- `ffff9f4e8e8f0000` The task structure address in memory, The task structure contains all the information about this process

- `RU` stands for Running, it indicates that these processes are currently in the TASK_RUNNING state

- `0.0` The CPU usage or percentage of CPU time used by the process, which is 0.0 in this case

- `24904` The virtual memory size of the process in kilobytes, This value (24904 KB) represents the total amount of virtual memory allocated to the process

- `5312` The resident set size, or the portion of memory occupied by the process in RAM, measured in kilobytes, This process is using 5312 KB of physical memory

- `bash` The command or name of the process

### `log` Retrieves the kernel log leading up to the crash. This can provide clues about what caused the system to crash

```bash
crash> log
[    0.000000] microcode: microcode updated early to revision 0x2007006, date = 2023-03-06
[    0.000000] Linux version 4.18.0-372.73.1.el8_6.x86_64 (mockbuild@x86-vm-07.build.eng.bos.redhat.com) (gcc version 8.5.0 20210514 (Red Hat 8.5.0-10) (GCC)) #1 SMP Fri Sep 8 13:16:27 EDT 2023
...
```

### `mount` shows the mount points

```bash
crash> mount
     MOUNT           SUPERBLK     TYPE   DEVNAME   DIRNAME
ffff9f4e8d056400 ffff9f4e80014800 rootfs none      /
ffff9f6b04ff6700 ffff9f4f30843800 sysfs  sysfs     /ostree/deploy/rhcos/deploy/ed42540ab2e04a4ac789246a03ee3a742f987d716a69fa910d6d52fc76f489c5.30/sys
ffff9f6b04ff6280 ffff9fadcc8da000 proc   proc      /ostree/deploy/rhcos/deploy/ed42540ab2e04a4ac789246a03ee3a742f987d716a69fa910d6d52fc76f489c5.30/proc
...
```

#### `mount` Output Explained

- `MOUNT` This field shows the memory address of the mount structure in the kernel. This structure contains information about the mounted filesystem

- `SUPERBLK` The memory address of the superblock structure. The superblock contains metadata about the filesystem, like its size, status, and other information

- `TYPE` The type of filesystem mounted. This could be ext4, xfs, sysfs, proc, etc., depending on the specific filesystem

- `DEVNAME` The device name associated with the mount. This could be a physical device (like /dev/sda1) or a virtual device (like none for certain special filesystems)

- `DIRNAME` The directory on which the filesystem is mounted. This is the path where the filesystem is accessible.

## Investigate Kernel Panics

The first step in diagnosing a kernel crash is to examine the backtrace, which shows the sequence of function calls leading up to the crash. This is crucial for pinpointing the exact location in the kernel code where the panic occurred.

### If the backtrace shows a kernel panic, investigate the cause

```bash
bt -a
```

Review the backtrace for any functions or modules that might have caused the crash. Pay attention to the final few function calls before the panic, as these often provide clues about the root cause.

### Check the logs for OOM killer activity

Out-of-memory (OOM) situations can trigger the kernel to kill processes to reclaim memory, which might lead to instability or crashes

```bash
crash> log | grep -i "oom"
```

Identify any logs related to the OOM killer, If found, note which processes were terminated and consider whether these OOM events correlate with the timing of the crash.

### Check Networking Issues

Network interface problems can contribute to kernel crashes, especially if they cause critical system services to fail.

```bash
crash> net
   NET_DEVICE     NAME   IP ADDRESS(ES)
ffff9fadcda2d000  lo     127.0.0.1
ffff9f4f626ec000  ens5f0
ffff9f4fc1b5c000  ens5f1
...
```

Check the list of network devices and their IP addresses, Look for any interfaces that are down or have unusual configurations, Also note any network-related logs.

### `kmem` gives you an overview of memory usage, including free/used memory and slab information

Memory pressure or mismanagement can often lead to kernel crashes.

```bash
crash> kmem -i
                 PAGES        TOTAL      PERCENTAGE
    TOTAL MEM  197474909     753.3 GB         ----
         FREE  192895231     735.8 GB   97% of TOTAL MEM
         USED  4579678      17.5 GB    2% of TOTAL MEM
       SHARED   317997       1.2 GB    0% of TOTAL MEM
      BUFFERS      539       2.1 MB    0% of TOTAL MEM
       CACHED  2155325       8.2 GB    1% of TOTAL MEM
         SLAB   110027     429.8 MB    0% of TOTAL MEM
...
```

### Investigate open files and any potential lockups

File system locks or an huge number of open files can lead to system hangs or lockups, contributing to instability.

```bash
crash> files
crash> foreach files | grep "locked"
```

Look for any files that are locked or processes with a large number of open files. This could indicate deadlocks, resource contention, or file system issues that contributed to the crash.

### To gain additional context around the system's state leading up to the crash, review the dmesg logs saved by kdump

The kdump mechanism captures critical system information at the time of the crash. Reviewing these logs provides additional context about the system's state and the kdump process itself.

- The `vmcore-dmesg.txt` file saved by kdump can provide system state context

- The `kexec-dmesg.log` file saved by kdump can provide kdump proccess context

## Identify the Root Cause

Correlate the data from the crash tool and dmesg logs. Typical causes might include:

- Kernel Panics often caused by hardware failures, driver issues, or bugs in the kernel

- OOM (Out of Memory) Indicates a memory leak or inadequate memory allocation for your workload

- For Hardware Issues Look for signs of failing hardware, such as CPU or memory errors

## Take Remedial Actions

- If the issue is kernel-related, consider upgrading to a newer OS version

- Run hardware diagnostics if the crash indicates potential hardware failure

- Adjust system configurations (e.g., memory limits, swap space) if the crash was related to resource exhaustion

---

[Previous Page - Quick Crash Tool](./CRASH_QUICK_README.md)

---

[Return to main](../README.md)

---
