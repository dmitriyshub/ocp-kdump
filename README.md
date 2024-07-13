# KDUMP in OpenShift CoreOS Baremetal Nodes

---

`Kdump` is a kernel feature that allows crash dumps to be created during a kernel crash. It produces a `vmcore`(a system-wide coredump, which is the recorded state of the working memory in the host at the time of the crash) that can be analyzed for the root cause analysis of the crash.

`kdump` uses a mechanism called `kexec` to boot into a second kernel whenever the system crashes. This second kernel, often called the crash kernel, boots with very little memory and captures the dump image.

If `kdump` is enabled on your system, the standard boot kernel will reserve a small section of system RAM and load the `kdump` kernel into the reserved space. When a kernel panic or other fatal error occurs, `kexec` is used to boot into the `kdump` kernel without going through BIOS. The system reboots to the `kdump` kernel that is confined to the memory space reserved by the standard boot kernel, and this kernel writes a copy or image of the system memory to the storage mechanism defined in the configuration files.

One of the key steps in configuring `kdump` is to reserve a portion of the system's memory for the `kdump` kernel. This is done using the `crashkernel` parameter, which specifically reserves memory for the `kdump` kernel during boot.

The `kdump` service uses a `core_collector` program to capture the crash dump image. In rhel, the `makedumpfile` utility is the default `core_collector`. It helps shrink the dump file by:

- Compressing the size of a crash dump file and copying only necessary pages using various `dump_levels`
- Excluding unnecessary crash dump pages
- Filtering the page types to be included in the crash dump

To ensure sufficient storage for vmcore dumps, it's **recommended** that storage space be at least equal to the total RAM on the server. While predicting vmcore size with 100% accuracy isn't possible, analyzing over 1500 vmcores from various Red Hat Enterprise Linux versions showed that using the default dump_level setting of `-d 31` typically results in vmcores under 10% of RAM.

The crash dump or `vmcore` is usually stored as a file in a local file system, written directly to a device. Alternatively, you can set up for the crash dump to be sent over a network using the `NFS` or `SSH` protocols. Only one of these options to preserve a crash dump file can be set at a time. The default behavior is to store it in the `/var/crash/` directory of the local file system.

## Controlling which events trigger a Kernel Panic

There are several parameters that control under which circumstances kdump is activated. Most of these can be enabled via `sysctl` tunable parameters, you can refer to the most commonly used below

- **System hangs due to NMI:** Occurs when a Non-Maskable Interrupt is issued, usually due to a hardware fault

```bash
kernel.unknown_nmi_panic = 1
kernel.panic_on_io_nmi = 1
kernel.panic_on_unrecovered_nmi = 1
```

- **Out of memory (OOM) Kill event:** Occurs when a memory request (Page Fault or kernel memory allocation) is made while not enough memory is available, thus the system terminates an active task (usually a non-prioritized process utilizing a lot of memory)

```bash
vm.panic_on_oom = 1
```

- **CPU Soft Lockup event:** Occurs when a task is using the CPU for more than time the allowed threshold (the tunable `kernel.watchdog_thresh`, default is `20` seconds)

```bash
kernel.softlockup_panic = 1
```

- **Hung / Blocked Task event:** Occurs when a process is stuck in Uninterruptible-Sleep (D-state) for more time than the allowed threshold (the tunable `kernel.hung_task_timeout_secs`, default is `120` seconds)

```bash
kernel.hung_task_panic = 1
```

## In Clustered Environments

Cluster environments potentially invite their own unique obstacles to vmcore collection. Some clusterware provides functionality to fence nodes via the SysRq or an NMI allows for vmcore collection upon fencing a node.

In addition to ensuring that the cluster and kdump configuration is sound, if a system encounters a kernel panic there is the possibility that it can be fenced and rebooted by the cluster before finishing dumping the vmcore. If this is suspected in a cluster environment it may be a good idea to remove the node from the cluster and reproduce the issue as a test.

---

## Kdump Procedure

1. The normal kernel is booted with `crashkernel=<value>` as a kernel option, reserving some memory for the `kdump` kernel. The memory reserved by the crashkernel parameter is not available to the normal kernel during regular operation. It is reserved for later use by the `kdump` kernel

2. The system panics

3. The `kdump` kernel is booted using kexec, it used the memory area that was reserved w/ the `crashkernel` parameter

4. The normal kernel's memory is captured into a `vmcore`

---

## Summary Steps

1. Test the `kdump` in rhel host and ensure that everything is working correctly and the `kdump` generates the vmcore files in the target path successfully (Optionl)

2. Configure the `machineconfig` yaml file with all the necessary configuration of `kdump` systemd unit, `kdump` configuration files, and memory reservation `crashkernel=value` parameter

3. Create the `machineconfig` object in the cluster and wait until the `machineconfig` operator picks up the changes and starts to update, initialize, and reboot the nodes

4. Wait until the `machineconfigpool` updated status is `True` and the nodes are in `Ready` status

5. Ensure that all new configuration provided by the `machineconfig` was configured correctly on the nodes

6. Trigger the kernel crash and wait until the node reboots and becomes in `Ready` status again

7. Start the debug pod again and check if the `vmcore` files exist in the target path

---

### Table of Content

- [Manual Configuration](/docs/MANUAL_README.md)

- [Machineconfig Configuration](/docs/MC_README.md)

- [KDUMP Troubleshooting](/docs/TROUBLESHOOT_README.md)

- [Configure Serial Console to Troubleshoot KDUMP Issues](/examples/serial-console-conf/README.md)

- [KDUMP examples](/examples/README.md)

---

### Documentation and Articles

- [The importance of configuring kernel dumps](https://www.redhat.com/en/blog/importance-configuring-kernel-dumps-rhel) <- Recommended

- [Configuring kdump on the command line (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Configuring kdump on the command line (RHEL9 CoreOS 4.13 and upper)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/managing_monitoring_and_updating_the_kernel/index#configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL9 CoreOS 4.13 and upper)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

- [Untestand the Machine Config Pool — OpenShift Container Platform 4.x](https://kamsjec.medium.com/machine-config-pool-openshift-container-platform-4-x-c515e7a093fb)

---

### Manual Pages

- **NOTE:** Always refer to your **CoreOS** tools version manual page

- [kexec(8) - Linux man page](https://linux.die.net/man/8/kexec)

- [makedumpfile(8) - make a small dumpfile of kdump](https://www.linux.org/docs/man5/makedumpfile.html)

- [kdump.conf(5) - configuration file for kdump kernel](https://linux.die.net/man/5/kdump.conf)

- [kdump(5) - Configuration of kdump](https://www.unix.com/man-page/suse/5/kdump/)

- [kdumpctl(8) - control interface for kdump](https://www.linux.org/docs/man8/kdumpctl.html)

- [dracut - low-level tool for generating an initramfs/initrd image](https://manpages.ubuntu.com/manpages/kinetic/man8/dracut.8.html)

- [dracut.cmdline(7) - dracut kernel command line options](https://www.unix.com/man-page/linux/7/dracut.cmdline/)

- [dracut-module-setup.sh - Github Repository](https://github.com/jesa7955/kexec-tools-fedora/blob/master/dracut-module-setup.sh)

---

### Issues and Solutions

- [Common kdump Configuration Mistakes](https://access.redhat.com/articles/5332081) **(Recommended)**

- [Setting up kdump in Red Hat Openshift Container Platform and Red Hat CoreOS](https://access.redhat.com/solutions/5907731)

- [Missing Logs in /var/crash Post Kdump Setup in RHOCP4](https://access.redhat.com/solutions/7058348)

- [How to setup kdump to dump a vmcore on ssh location in Red Hat Openshift Container Platform nodes](https://access.redhat.com/solutions/6978127)

- [kdump fails to generate vmcore with SysRq on servers installed with LEGACY BIOS and vga controller...](https://access.redhat.com/solutions/5770681)

- [kdump failure when network requires multiple nics to reach dump target](https://access.redhat.com/solutions/3744271)

- [What is early kdump support and how do I configure it?](https://access.redhat.com/solutions/3700611)

- [How to troubleshoot kernel crashes, hangs, or reboots with kdump on Red Hat Enterprise Linux](https://access.redhat.com/solutions/6038)

- [How do I configure kdump for use with the RHEL 6, 7, 8 High Availability Add-On?](https://access.redhat.com/articles/67570)

---
