# KDUMP Manual Configuration (Not Recommended)

This section provides guidance on manually configuring kdump for capturing crash dumps. Manual configuration is generally not recommended due to the potential errors and huge amount of nodes. Ensure you back up all configuration files before making changes. Use this guide if you need to manually adjust settings for specific scenarios.

**NOTE:** Always Backup the configuration files!

## Modify the Configuration Files `/etc/kdump.conf` and `/etc/sysconfig/kdump`

| [KDUMP Configuration Files Examples](../examples/kdump-conf-files/) | [Local Path Examples](../examples/kdump-local-path/) | [SSH Path Examples](../examples/kdump-ssh-path/) |
|---------------------------------------------------------------------|------------------------------------------------------|--------------------------------------------------|

- Modify `/etc/kdump.conf`

```bash
path /var/crash
core_collector makedumpfile -l --message-level 7 -d 31
default shell
```

- Modify `/etc/sysconfig/kdump`

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=10 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never nokaslr novmcoredd hest_disable rd.net.timeout.carrier=30"
KEXEC_ARGS="-s"
KDUMP_IMG="vmlinuz"
```

## Configure and Enable `kdump`

```bash
# Check and modify configuration files
vi /etc/kdump.conf
vi /etc/sysconfig/kdump
# Add crashkernel parameter
rpm-ostree kargs --append='crashkernel=256M'
# Enable kdump and reboot machine
systemctl enable --now kdump
# Optional
kdumpctl rebuild
kdumpctl restart
```

## Prepare the node for rebooting

```bash
oc adm cordon <node-name>
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
oc debug node/<node-name>
chroot /host
systemctl reboot
```

## Initiate Manual Kernel Crash Dump

- To manually trigger a kernel dump, use the following commands

```bash
# Check if kdump is active
systemctl is-active kdump
# OPTIONAL: Enable “softlockup_panic” so the kdump will write the vmcore file before the system restarts in case of a crash 
echo "1" >> /proc/sys/kernel/softlockup_panic
# Checking that the kdump.service has started and exited successfully and prints 1
cat /sys/kernel/kexec_crash_loaded
# Trigger kernel dump
echo c > /proc/sysrq-trigger
```

---

| [Previous Page - Introduction](./KDUMP_INTRO_README.md) | [Next Page - MachineConfig Configuration](./KDUMP_MC_README.md) | [Return to Main Page](../README.md) |
|---------------------------------------------------------|-----------------------------------------------------------------|-------------------------------------|

---
