# KDUMP in OpenShift CoreOS Baremetal Nodes

This repository is focused on setting up kdump on OpenShift nodes. We created it to address situations where worker nodes freeze without warning, preventing us from troubleshooting the underlying cause. With kdump we can capture detailed crash dumps, providing the insights needed to diagnose and prevent these issues from recurring.

- [Review Summary](/docs/KDUMP_REVIEW_README.md)

## 📖 Table of Content

- [KDUMP Introduction and Key Concepts](/docs/KDUMP_INTRO_README.md)

### KDUMP Configuration, Installation and Troubleshooting

- [KDUMP Manual Configuration](/docs/KDUMP_MANUAL_README.md)

- [KDUMP Machineconfig Configuration](/docs/KDUMP_MC_README.md)

- [KDUMP Examples](/examples/README.md)

- [KDUMP Troubleshooting](/docs/KDUMP_TROUBLESHOOT_README.md)

- [Configure Serial Console for KDUMP Issues Troubleshooting](/docs/SERIAL_CONSOLE_README.md)

### Crash Tool Configuration and Usage

- [Using Crash Tool RPM to Analyze a vmcore](/docs/CRASH_MANUAL_README.md)

- [Using Crash Tool Custom Container to Analyze a vmcore](/docs/CRASH_QUICK_README.md)

- [Crash Tool Guide](/docs/CRASH_TOOL_README.md)

## 🔗 Documentation and Articles

### Official Docs

- [The importance of configuring kernel dumps](https://www.redhat.com/en/blog/importance-configuring-kernel-dumps-rhel) **<-- Recommended**

- [Configuring kdump on the command line (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Configuring kdump on the command line (RHEL9 CoreOS 4.13 and upper)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/managing_monitoring_and_updating_the_kernel/index#configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL9 CoreOS 4.13 and upper)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

- [Butane file Configuration Specifications](https://coreos.github.io/butane/specs/)

### Unofficial Blogs

- [A vmcore for your system may be smaller than you think!](https://blogs.oracle.com/linux/post/vmcore-smaller-than-you-think) **<-- Recommended**

- [Untestand the Machine Config Pool (OpenShift Container Platform 4.x)](https://kamsjec.medium.com/machine-config-pool-openshift-container-platform-4-x-c515e7a093fb)

- [White Paper: Crash Utility by David Anderson](https://crash-utility.github.io/crash_whitepaper.html) **<-- Recommended**

## 🔗 Issues and Solutions

### Configuration

- [Common kdump Configuration Mistakes](https://access.redhat.com/articles/5332081) **<-- Recommended**

- [How do I configure kdump for use with the RHEL 6, 7, 8 High Availability Add-On?](https://access.redhat.com/articles/67570)

- [Setting up kdump in Red Hat Openshift Container Platform and Red Hat CoreOS](https://access.redhat.com/solutions/5907731)

- [What is early kdump support and how do I configure it?](https://access.redhat.com/solutions/3700611)

### Troubleshoot

- [How to troubleshoot kernel crashes, hangs, or reboots with kdump on Red Hat Enterprise Linux](https://access.redhat.com/solutions/6038)

- [How to extract/unpack/uncompress the contents of the initramfs boot image on RHEL 7,8,9 ?](https://access.redhat.com/solutions/6038)

### SSH Target

- [Missing Logs in /var/crash Post Kdump Setup in RHOCP4](https://access.redhat.com/solutions/7058348)

- [How to setup kdump to dump a vmcore on ssh location in Red Hat Openshift Container Platform nodes](https://access.redhat.com/solutions/6978127)

### Hardware and Network

- [kdump fails to generate vmcore with SysRq on servers installed with LEGACY BIOS and vga controller...](https://access.redhat.com/solutions/5770681)

- [Kdump failes with "kdump: get_host_ip exited with non-zero status!"](https://access.redhat.com/solutions/5927171)

- [kdump failure when network requires multiple nics to reach dump target](https://access.redhat.com/solutions/3744271)

## 🔗 Manual Pages

**NOTE:** The links provided below are for reference only, Always refer to the manual pages specific to your **CoreOS** version to ensure compatibility!

- [kdump(5) - Configuration of kdump](https://www.unix.com/man-page/suse/5/kdump/)

- [kdump.conf(5) - configuration file for kdump kernel](https://linux.die.net/man/5/kdump.conf)

- [kdumpctl(8) - control interface for kdump](https://www.linux.org/docs/man8/kdumpctl.html)

- [kexec(8) - Linux man page](https://linux.die.net/man/8/kexec)

- [dracut - low-level tool for generating an initramfs/initrd image](https://manpages.ubuntu.com/manpages/kinetic/man8/dracut.8.html)

- [dracut.cmdline(7) - dracut kernel command line options](https://www.unix.com/man-page/linux/7/dracut.cmdline/)

- [dracut-module-setup.sh - Github Repository](https://github.com/jesa7955/kexec-tools-fedora/blob/master/dracut-module-setup.sh)

- [makedumpfile(8) - make a small dumpfile of kdump](https://www.linux.org/docs/man5/makedumpfile.html)

---
