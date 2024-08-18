# KDUMP Troubleshooting

This section provides essential troubleshooting steps to help diagnose and resolve common issues with kdump configurations. Follow these procedures to ensure that kdump is configured and operating correctly.

## Estimate the KDUMP Memory Usage

To determine the default and required size for the crash kernel memory use the following commands:

```bash
kdumpctl showmem # Displays current memory reserved for the crash kernel
kdumpctl estimate # Estimates the memory size required for kdump
```

## Estimate the Dump File Size

To calculate the space required for the crash dump file execute:

```bash
# The makedumpfile --mem-usage command estimates how much space the crash dump file requires
# By default the RHEL kernel uses 4 KB sized pages on AMD64 and Intel 64 CPU , and 64 KB sized pages on IBM POWER
makedumpfile --mem-usage /proc/kcore
```

## Verify Kernel Commandline Parameters

To check the kernel parameters:

```bash
rpm-ostree kargs # Shows desired kernel parameters
cat /proc/cmdline # Displays actual kernel parameters
tail /var/log/kdump.log # Reviews kdump last command line logs
```

## Review Kdump Configuration Files

Inspect the content of `kdump` related configuration files:

```bash
cat /etc/sysconfig/kdump 
cat /etc/kdump.conf

# If using an SSH target path also check
cat /root/.ssh/config
cat /root/.ssh/id_kdump
```

## Verify initramfs Image Kernel Modules

Ensure that the required kernel modules are present in the `initramfs` image:

```bash
lsinitrd /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img | grep sd_mod
```

## Inspect the kdump initramfs Image

For detailed troubleshooting you can extract the content of the `initramfs` image:

```bash
ls -la /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img
mkdir /var/initrd; cd /var/initrd
/usr/lib/dracut/skipcpio /var/lib/kdump/initramfs-$(uname -r)kdump.img        | cpio -idmv
unsquashfs squash-root.img
ls -la squashfs-root/
```

For more information refer to [How to extract/unpack/uncompress the contents of the initramfs boot image on RHEL 7,8,9 ?](https://access.redhat.com/solutions/2037313#B)

## Add Additional Kernel Modules

To include necessary kernel modules modify the `/etc/kdump.conf` file:

```bash
extra_modules megaraid_sas sd_mod
```

## Configure Default or Failure Behavior

Adjust the behavior of `initramfs` for default or failure actions within `/etc/kdump.conf` The exact directive depends on the `kexec-tools` version:

```bash
failure_action shell # Newer Versions (Action to perform in case dumping to the intended target fails)
default shell #  Older Versions (Same  as  the  "failure_action",  but this directive is obsolete and will be removed in the future)
```

## Modify Kernel Command Line Parameters

To tweak the kernel command line parameters edit the `/etc/sysconfig/kdump` file:

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb ip=dhcp rootflags=prjquota rootflags=nofail udev.children-max=2 ignition.platform.id=metal"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=60 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never novmcoredd hest_disable module_blacklist=igb,ixgbe"
```

## Apply New Configurations

Apply your changes by running one or more of the following kdumpctl commands:

```bash
kdumpctl reload # Reloads the crash kernel image and initramfs without triggering a rebuild
kdumpctl rebuild # Rebuilds the crash kernel initramfs
kdumpctl restart # Equivalent to stop and start operation
kdumpctl propagate # Sets up key authentication for SSH storage; password authentication is not possible during kdump
```

## Check Logs

To debug issues review the kdump logs using the following commands:

```bash
cat /var/log/kdump.log
journalctl --unit kdump
dmesg | grep dracut
dmesg | grep crash

# dmesg destination from reboots
ls -l /sys/fs/pstore
```

## Decode Rendered MachineConfig

If the `MachineConfigPool` status shows `Degraded` due to configuration mismatches, decode the rendered `MachineConfig` content and replace the files:

```bash
# Check node desired rendered machineconfig name
oc get node node_name -o yaml | grep desiredConfig
    machineconfiguration.openshift.io/desiredConfig: [rendered-worker_name]

# Check encoding type
oc get mc [rendered-worker_name] -o yaml | grep -B5 "path: [escaped_path]" | grep source | tail -n 1 | cut -d"," -f1

# base64 encoding
oc get mc machineconfig-name -o yaml | grep -B5 "path: \/etc\/kdump.conf" | grep source | tail -n 1 | cut -d"," -f2 | base64 -d

# url encoding
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; } ;  urldecode "$(oc get mc machineconfig-name -o yaml | grep -B5 "path: \/etc\/kdump.conf" | grep source | tail -n 1 | cut -d"," -f2)"
```

For further details see [on-disk validation fails on file content mismatch during MCO upgrade in OpenShift 4](https://access.redhat.com/solutions/5315421)

---

| [Previous Page - Examples](../examples/README.md) | [Next Page - Configure Serial Console](./SERIAL_CONSOLE_README.md) | [Return to Main Page](../README.md) |
|---------------------------------------------------|--------------------------------------------------------------------|-------------------------------------|

---
