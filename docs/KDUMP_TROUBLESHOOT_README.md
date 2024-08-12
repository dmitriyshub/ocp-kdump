# KDUMP Troubleshooting

This section provides essential troubleshooting steps for diagnosing and resolving common issues with kdump configurations. Follow these procedures to ensure proper configuration and operation of kdump.

## Estimate the crashkernel= Parameter

- To determine the default and required size for the crash kernel memory

```bash
kdumpctl get-default-crashkernel
kdumpctl estimate
```

## Estimate the Size of VMCORE Files

- Use the following command to estimate the space required for the crash dump file

```bash
# The makedumpfile --mem-usage command estimates how much space the crash dump file requires
# By default the RHEL kernel uses 4 KB sized pages on AMD64 and Intel 64 CPU , and 64 KB sized pages on IBM POWER
makedumpfile --mem-usage /proc/kcore
```

## Check Kernel Commandline Parameters

- Verify the kernel parameters for accuracy

```bash
rpm-ostree kargs # Desired parameters
cat /proc/cmdline # Actual Parameters
```

## Review Kdump Configuration Files

- Check the contents of key configuration files

```bash
cat /etc/sysconfig/kdump 
cat /etc/kdump.conf
# For ssh target path
cat /root/.ssh/config
cat /root/.ssh/id_kdump
```

## Verify initramfs Image Kernel Modules

- Ensure required kernel modules are present in the initramfs image

```bash
lsinitrd /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img | grep sd_mod
```

## Add Additional Kernel Modules

- Modify `/etc/kdump.conf` to include necessary kernel modules

```bash
extra_modules megaraid_sas sd_mod
```

## Configure Default or Failure Behavior

- Adjust the initramfs behavior for default or failure actions in `/etc/kdump.conf` (depends on `kdump-utils` version)

```bash
failure_action shell # Newer Versions (Action to perform in case dumping to the intended target fails)
default shell #  Older Versions (Same  as  the  "failure_action",  but this directive is obsolete and will be removed in the future)
```

## Modify Kernel Command Line Parameters

- Modify `/etc/sysconfig/kdump` to adjust kernel command line parameters:

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb ip=dhcp rootflags=prjquota rootflags=nofail udev.children-max=2 ignition.platform.id=metal"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=60 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never novmcoredd hest_disable module_blacklist=igb,ixgbe"
```

## Apply New kdump Configurations

- Execute one or more `kdumpctl` commands to apply changes

```bash
kdumpctl reload # Reload the crash kernel image and initramfs without triggering a rebuild.
kdumpctl rebuild # Rebuild the crash kernel initramfs.
kdumpctl restart # Is equal to start; stop
kdumpctl propagate # Helps to setup key authentication for ssh storage since it's impossible to use password authentication during kdump.
```

## Check `kdump` Logs

- Review logs for debugging purposes

```bash
cat /var/log/kdump.log
journalctl --unit kdump
dmesg | grep dracut
dmesg | grep crash
# dmesg destination from reboots
ls -l /sys/fs/pstore
```

## Decode Rendered MachineConfig

- If `MachineConfigPool` status shows `Degraded` due to configuration mismatches, decode the rendered `MachineConfig` content

[on-disk validation fails on file content mismatch during MCO upgrade in OpenShift 4](https://access.redhat.com/solutions/5315421)

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

## Extract and Inspect the kdump initramfs Image

- Extract the content of the `initramfs` image for further `squashfs-root` troubleshooting

[How to extract/unpack/uncompress the contents of the initramfs boot image on RHEL 7,8,9 ?](https://access.redhat.com/solutions/2037313#B)

```bash
ls -la /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img
mkdir /var/initrd; cd /var/initrd
/usr/lib/dracut/skipcpio /var/lib/kdump/initramfs-$(uname -r)kdump.img        | cpio -idmv
unsquashfs squash-root.img
ls -la squashfs-root/
```

---

| [Previous Page - Examples](../examples/README.md) | [Next Page - Configure Serial Console](./SERIAL_CONSOLE_README.md) | [Return to Main Page](../README.md) |
|---------------------------------------------------|--------------------------------------------------------------------|-------------------------------------|

---
