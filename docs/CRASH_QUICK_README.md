# Using Crash Tool Custom Container to Analyze a vmcore

To determine the cause of the system crash, you can use the `crash` utility, which provides an interactive prompt very similar to the GNU Debugger (GDB). This utility allows you to interactively analyze a running Linux system as well as a core dump created by `kdump`, `netdump`, `diskdump`, or  `xendump` as well as a running Linux system.

Kernel crashes can be tricky to diagnose, but with the crash utility, you can gain valuable insights into the causes of system failures.

You can use a custom container image pre-configured with the crash tool to streamline this process. This setup lets you quickly analyze vmcore files by simply mounting them into the container.

- [Managing, Monitoring and updating the Kernel - Analyizing a core dump](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/analyzing-a-core-dump_managing-monitoring-and-updating-the-kernel#analyzing-a-core-dump_managing-monitoring-and-updating-the-kernel)

## Build a new container image with crash tool and the kernel debuginfo packages

- Download all the required packages for the `vmcore` kernel version from the [Customer Portal](https://access.redhat.com/downloads/content/package-browser)

```bash
ls -l rpms/
-rw-r--r--  1 dshtranv  staff    3049136 Aug  6 11:28 crash-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff    6944684 Aug  6 11:28 crash-debuginfo-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff    4662464 Aug  6 11:28 crash-debugsource-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff  662685964 Aug  6 11:27 kernel-debuginfo-4.18.0-372.73.1.el8_6.x86_64.rpm
-rw-r--r--  1 dshtranv  staff   73930952 Aug  6 11:27 kernel-debuginfo-common-x86_64-4.18.0-372.73.1.el8_6.x86_64.rpm
```

- Create the `Containerfile` and build the image

```docker
FROM registry.url/ubi8/ubi

# Copy the RPM packages to the container
COPY rpms/ /tmp/rpms/

# Install necessary packages
RUN yum localinstall -y /tmp/rpms/*.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum

# Set up the entry point to use the crash utility
ENTRYPOINT ["crash", /usr/lib/debug/lib/modules/<kernel.version>/vmlinux]
```

```bash
podman build -t registry.url/kdump-crash-tool:<kernel.version> .
```

## Use The Pre Configured Container Image with crash tool and kernel debuginfo requirements

The image is configured with all the necessary tools and dependencies for the crash utility kernel version `registry.url/kdump-crash-tool:<kernel.version>`

- `<registry.url>/` `kdump-crash-tool` `:4.18.0-372.73.1.el8_6` (Current Kernel Version Tag)

- Verify that the vmcore file matches the kernel version you're working with:

```bash
crash --osrelease /path/to/vmcore
```

- Example command to run the container and analyze a vmcore file, this command mounts the vmcore file into the container and runs the crash utility with the necessary arguments:

**NOTE:** Replace /path/to/vmcore with the actual path to the vmcore

```bash
podman run --rm -it -v /path/to/vmcore:/vmcore:Z kdump-crash-tool:4.18.0-372.73.1.el8_6 /vmcore
...
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

---

[Crash Tool Guide](CRASH_TOOL_README.md)

---

[Return to main](../README.md)

---
