# Crash Tool Guide

The `crash` tool is a powerful utility for analyzing the state of a Linux system after a kernel crash, Below are some essential commands and their usage.

When `kdump` captures a system crash, it generates three key files that are crucial for post-mortem analysis:

- `vmcore` is the primary memory dump file containing a snapshot of the system's RAM at the time of the crash. It includes all in-memory data, such as the kernel’s memory and process information, providing the raw data needed for in-depth analysis with tools like `crash`

- `vmcore-dmesg.txt` file logs the kernel message buffer leading up to the crash. It records the kernel’s log messages, helping to identify events or errors that directly preceded the crash, such as hardware faults or out-of-memory conditions

- `kexec-dmesg.log` file details the operations performed by the secondary kdump kernel during the capture process. It is essential for troubleshooting any issues that occur during the dumping of vmcore, such as errors in writing the file to disk

Together these files provide a comprehensive view of the system's state before, during, and after the crash, enabling thorough analysis and diagnosis.

## Kernel File Types

`vmlinux` is the uncompressed kernel code, `vmlinuz`, and `vmlinux.bin` are compressed versions for booting. `zimage` is an older compressed format, and `bzImage` is an improved version.

- [Differences Between vmlinux, vmlinuz, vmlinux.bin, zimage, and bzimage](https://www.baeldung.com/linux/kernel-images)

- `vmlinuz` is a compressed file, but crash requires an uncompressed file `vmlinux`, which is compiled with `-g` option.
Make sure your kernel is compiled with `-g` option, and then you can get an uncompressed `vmlinux` file from compressed `vmlinuz`, using the method as follows: (Not Recommended, Use it only with custom/unofficial kernels)

```bash
od -t x1 -A d /host/usr/lib/modules/4.18.0-372.73.1.el8_6.x86_64/vmlinuz | grep "1f 8b 08"
dd if=/host/usr/lib/modules/$(uname -r)/vmlinuz bs=1 skip=18865 | zcat > /tmp/vmlinux
```

---

## Usage

- For help on any command below, enter `help <command>`

```bash
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

## Start Crash Tool and Start Analyzing VMCORE files

- When starting a crash tool, we'll get detailed system information

```bash
WARNING: kernel relocated [594MB]: patching 105453 gdb minimal_symbol values

      KERNEL: /usr/lib/debug/lib/modules/4.18.0-372.73.1.el8_6.x86_64/vmlinux
    DUMPFILE: /vmcore  [PARTIAL DUMP]
        CPUS: 80
        DATE: Sun Jun 23 10:45:14 UTC 2024
      UPTIME: 00:16:20
LOAD AVERAGE: 0.17, 0.36, 0.49
       TASKS: 2220
    NODENAME: node-name.domain.name
     RELEASE: 4.18.0-372.73.1.el8_6.x86_64 # Kernel Version
     VERSION: #1 SMP Fri Sep 8 13:16:27 EDT 2023
     MACHINE: x86_64  (2400 Mhz)
      MEMORY: 766.7 GB
       PANIC: "sysrq: SysRq : Trigger a crash" # <<- Panic Process 
         PID: 27435 # <<- Panic Process PID
     COMMAND: "bash"
        TASK: ffff9f4e8e8f0000  [THREAD_INFO: ffff9f4e8e8f0000]
         CPU: 14
       STATE: TASK_RUNNING (SYSRQ)
```

- You may see warnings like `kernel relocated`, This indicates that the kernel image was relocated in memory, and symbols were patched accordingly

```bash
WARNING: kernel relocated [594MB]: patching 105453 gdb minimal_symbol values
```

 **NOTE:** The Output With Panic Process `PID: 27435` and Panic Message `PANIC: "sysrq: SysRq : Trigger a crash"`

## Start with the following commands for a high-level overview

- `bt` shows the backtrace of the crashed kernel thread, giving insight into where the crash occurred (process execution history)

```bash
crash> bt
PID: 27435  TASK: ffff9f4e8e8f0000  CPU: 14  COMMAND: "bash"
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

- `ps` Displays information about processes running at the time of the crash. Look for processes in an unusual state (e.g., D state).

```bash
ps | grep ">"
crash> ps | grep ">"
>     0      0   0  ffffffffa7a18840  RU   0.0       0      0  [swapper/0]
>     0      0   1  ffff9f4e8d108000  RU   0.0       0      0  [swapper/1]
>     0      0   2  ffff9f4e8d10c000  RU   0.0       0      0  [swapper/2]
...
...
```

- Check the panic process using the PID given

```bash
crash> ps | grep 27435
> 27435  23470  14  ffff9f4e8e8f0000  RU   0.0   24904   5312  bash
```

- `log` Retrieves the kernel log leading up to the crash. This can provide clues about what caused the system to crash.

```bash
crash> log
[    0.000000] microcode: microcode updated early to revision 0x2007006, date = 2023-03-06
[    0.000000] Linux version 4.18.0-372.73.1.el8_6.x86_64 (mockbuild@x86-vm-07.build.eng.bos.redhat.com) (gcc version 8.5.0 20210514 (Red Hat 8.5.0-10) (GCC)) #1 SMP Fri Sep 8 13:16:27 EDT 2023
...
...
```

- Check the mount points

```bash
crash> mount
     MOUNT           SUPERBLK     TYPE   DEVNAME   DIRNAME
ffff9f4e8d056400 ffff9f4e80014800 rootfs none      /
ffff9f6b04ff6700 ffff9f4f30843800 sysfs  sysfs     /ostree/deploy/rhcos/deploy/ed42540ab2e04a4ac789246a03ee3a742f987d716a69fa910d6d52fc76f489c5.30/sys
ffff9f6b04ff6280 ffff9fadcc8da000 proc   proc      /ostree/deploy/rhcos/deploy/ed42540ab2e04a4ac789246a03ee3a742f987d716a69fa910d6d52fc76f489c5.30/proc
...
...
```

## Investigate Kernel Panics

- If the backtrace shows a kernel panic, investigate the cause:

```bash
bt -a
```

- Check the logs for OOM killer activity:

```bash
crash> log | grep -i "oom"
```

- Check Networking Issues

```bash
crash> net
   NET_DEVICE     NAME   IP ADDRESS(ES)
ffff9fadcda2d000  lo     127.0.0.1
ffff9f4f626ec000  ens5f0
ffff9f4fc1b5c000  ens5f1
...
...
```

- `kmem` gives you an overview of memory usage, including free/used memory and slab information

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
...
```

- Investigate open files and any potential lockups

```bash
crash> files
crash> foreach files | grep "locked"
```

- The `vmcore-dmesg.txt` file saved by kdump can provide system state context

- The `kexec-dmesg.log` file saved by kdump can provide kdump proccess context

## Identify the Root Cause

Correlate the data from the crash tool, dmesg, and any other logs. Typical causes might include:

- Kernel Panics often caused by hardware failures, driver issues, or bugs in the kernel

- OOM (Out of Memory) Indicates a memory leak or inadequate memory allocation for your workload

- For Hardware Issues Look for signs of failing hardware, such as CPU or memory errors

Take Remedial Actions

- If the issue is kernel-related, consider updating to a newer kernel version

- Run hardware diagnostics if the crash indicates potential hardware failure

- Adjust system configurations (e.g., memory limits, swap space) if the crash was related to resource exhaustion

- Always ensure your system and tools are up to date, and consult additional resources if you encounter uncommon issues

---

[Return to main](../README.md)

---
