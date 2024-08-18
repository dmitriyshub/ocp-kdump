# KDUMP Troubleshooting

Kdump is a critical tool for capturing system crash dumps, providing valuable information for diagnosing and resolving kernel issues. Proper configuration and troubleshooting of kdump are essential to ensure that crash dumps are captured reliably, especially in a production environment. This section will help you to identify and resolve issues that may prevent kdump from functioning correctly.

## Importance of Configuring Serial Console

The primary console may not display the logs in scenarios where a system crashes due to system state or graphical issues. Configuring a serial console allows you to capture detailed output during the crash dump process, which is critical for troubleshooting. This can be especially useful when diagnosing kdump failures, as it gives visibility into the early stages of the dump process and potential kernel panics.

For How to Configure a Serial Console Section see

[Configure Serial Console for KDUMP Issues Troubleshooting](./SERIAL_CONSOLE_README.md)

## Configuring failure_action for Effective Troubleshooting

The `failure_action` directive in the `/etc/kdump.conf` file determines the action to be taken if the kdump service fails to save a crash dump to the intended target. This directive is crucial for troubleshooting because it provides immediate feedback when a crash dump cannot be captured, allowing administrators to diagnose and address issues more effectively.

### Importance of failure_action in Troubleshooting

- When a crash occurs and the dump cannot be saved, `failure_action` ensures that the system provides a shell or reboots, depending on the configuration, allowing administrators to inspect the system state directly

- If set to shell, the directive drops the system into a shell environment, preserving the current system state. This allows for real-time investigation and collection of diagnostic information

- Customizable Behavior: Depending on the environment, `failure_action` can be set to `shell`, `reboot`, or `poweroff`, each offering different troubleshooting advantages. For example, shell is useful in development environments for in-depth debugging, while reboot might be more suitable for production systems where uptime is critical

To configure `failure_action` to drop into a shell on failure:

```text
failure_action shell # Newer versions (Action to perform in case dumping to the intended target fails)
default shell #  Older versions (Same  as  the  "failure_action",  but this directive is obsolete and will be removed in the future)
```

 By understanding and properly configuring failure_action you will be able to troubleshoot and resolve kdump-related issues more effectively, ensuring that crash dumps are captured reliably and your system recovers smoothly.

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

## Apply New Configurations

Apply your changes by running one or more of the following kdumpctl commands:

```bash
kdumpctl reload # Reloads the crash kernel image and initramfs without triggering a rebuild
kdumpctl rebuild # Rebuilds the crash kernel initramfs
kdumpctl restart # Equivalent to stop and start operation
kdumpctl propagate # Sets up key authentication for SSH storage; password authentication is not possible during kdump
```

## Common Issues and Resolutions

### Possible Issues

- No Crash Dump Generated After a System Crash
- The kdump service fails to start and `systemctl status kdump` shows a failure
- Kdump fails or produces incomplete dumps on nodes with specific hardware configurations

### Possible Causes

- **Incorrect crashkernel Parameter:** The value might need to be higher or properly set
- **Missing Kernel Modules:** Required modules might not be included in the initramfs
- **Invalid Configuration Files:** Errors or misconfigurations in `/etc/kdump.conf` or `/etc/sysconfig/kdump`
- **Target Host Configuration:** The remote system may need to be correctly configured to receive the crash dump, for example with incorrect permissions, insufficient disk space or misconfigured SSH settings
- **SELinux and Security Policies:** SELinux or other security modules might be blocking kdump operations
- **File System Errors:** Issues with the target file system where the crash dumps are stored
- **Network Issues with the Target Host:**
  - **Unreachable Target Host:** The remote system where the crash dumps are supposed to be sent might be unreachable due to network issues, DNS resolution problems, or firewall restrictions
  - **Authentication Failures:** Incorrect SSH keys or issues with SSH configuration might prevent kdump from connecting to the remote host
- **Hardware Incompatibility:** Certain RAID controllers, network adapters or other peripherals might not be fully supported or require specific kernel modules and configuration
- **BIOS/UEFI Settings:** Incorrect settings in BIOS/UEFI could prevent kdump from functioning properly

### Possible Resolutions

- Verify the `crashkernel` parameter is set correctly:

```bash
rpm-ostree kargs | grep crashkernel
```

- Verify the dump path and ensure it has sufficient space:
  
```bash
grep ^path /etc/kdump.conf
df -h /var/crash
```

- Verify and correct any errors in configuration files:

```bash
cat /etc/kdump.conf
cat /etc/sysconfig/kdump
```

- Verify that the correct SSH keys are configured:

```bash
cat /root/.ssh/config
cat /root/.ssh/authorized_keys
cat /root/.ssh/id_kdump
```

- Adjust kernel command line parameters:

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb ip=dhcp rootflags=prjquota rootflags=nofail udev.children-max=2 ignition.platform.id=metal"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=60 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never novmcoredd hest_disable module_blacklist=igb,ixgbe"
```

- Temporarily disable SELinux to rule out security policy interference:

```bash
setenforce 0
systemctl restart kdump
```

- Ensure necessary kernel modules are included in the initramfs:

```bash
lsinitrd /boot/initramfs-$(uname -r).img | grep -E 'igb|ixgbe|sd_mod|megaraid_sas'
```

- Check for hardware specific issues and ensure all necessary modules are included:

```bash
extra_modules igb ixgbe sd_mod megaraid_sas
```

- Rebuild the kdump initramfs and restart the service:

```bash
kdumpctl rebuild
kdumpctl restart
```

- Test manual SSH login from the node to the target host to ensure there are no authentication issues
  - Connect to the node:

  ```bash
  ssh -i /path/to/key core@node.dns.name
  ```

  - Check network connectivity:

  ```bash
  ping target-host-ip
  ```

  - Connect to the target host

  ```bash
  ssh -i /path/to/key user@target-host
  ```

## Advanced Debugging Techniques

**NOTE** After any modifications validate that kdump is configured correctly!

```bash
touch /etc/kdump.log
kdumpctl restart
```

### Increase Logging Verbosity

- Adjust message level to gain more insights into kdump issues:

```bash
core_collector makedumpfile -l --message-level 31 -d 31
```

- Add kernel boot options to gather more information during boot and crash:

```bash
rpm-ostree kargs --append='debug loglevel=7'
```

## Analyze Kdump Logs

Look for any critical errors or warnings that indicate why kdump might be failing.

- Review kdump logs:

```bash
cat /var/log/kdump.log
journalctl --unit kdump
dmesg | grep crash

# dmesg destination from reboots
ls -l /sys/fs/pstore
```

## Inspect Kernel Command Line Parameters

Verify that the kernel parameters match the required settings for kdump.

### First Kernel

- TODO

```bash
rpm-ostree kargs
cat /proc/cmdline
```

### Crash Kernel

- TODO

```bash
tail /var/log/kdump.log # Reviews kdump last command line logs
```

## Extract and Analyze initramfs

Extract and inspect the kdump initramfs image to ensure all required modules and configurations are included:

```bash
ls -la /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img
mkdir /var/initrd; cd /var/initrd
/usr/lib/dracut/skipcpio /var/lib/kdump/initramfs-$(uname -r)kdump.img        | cpio -idmv
unsquashfs squash-root.img
ls -la squashfs-root/
```

For more information refer to [How to extract/unpack/uncompress the contents of the initramfs boot image on RHEL 7,8,9 ?](https://access.redhat.com/solutions/2037313#B)

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
