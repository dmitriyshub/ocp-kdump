# KDUMP Manual Configuration

This section provides instructions for manually configuring kdump to capture crash dumps on CoreOS nodes. While manual configuration is generally not recommended due to the risk of errors and the large number of nodes involved, some scenarios may require specific adjustments. Always back up all relevant configuration files before making any changes.

**NOTE:** Always Backup the configuration files!

## Prepare the Configuration Files

To manually configure kdump you need to prepare the following configuration files.

- Prepare `/etc/kdump.conf` file:

```bash
path /var/crash
core_collector makedumpfile -l --message-level 7 -d 31
default shell
```

- Prepare `/etc/sysconfig/kdump` file:

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=10 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never nokaslr novmcoredd hest_disable rd.net.timeout.carrier=30"
KEXEC_ARGS="-s"
KDUMP_IMG="vmlinuz"
```

Consult these examples for reference:

| [Configuration Files Examples](../examples/kdump-conf-files/) | [Local Target Examples](../examples/kdump-local-path/) | [SSH Target Examples](../examples/kdump-ssh-path/) |
|---------------------------------------------------------------|--------------------------------------------------------|----------------------------------------------------|

## Configure and Enable Kdump

Follow these steps to configure the `crashkernel` parameter, enable `kdump` and ensure it is ready by rebuilding the `initramfs` and restarting the service:

```bash
# Add crashkernel parameter
rpm-ostree kargs --append='crashkernel=256M'

# Enable kdump and reboot machine
systemctl enable --now kdump

# Rebuild the initramfs and restart kdump
kdumpctl rebuild
kdumpctl restart
```

## Prepare the Node for Rebooting

To ensure a safe reboot `cordon` and `drain` the node and then reboot it:

```bash
oc adm cordon <node-name>
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
oc debug node/<node-name>
chroot /host
systemctl reboot
```

## Manually Trigger Kernel Crash Dump

To manually initiate a kernel dump use the following commands.

- Check if kdump is active:

```bash
systemctl is-active kdump
```

- Verify that `kdump.service` started and exited successfully:

```bash
cat /sys/kernel/kexec_crash_loaded
```

A return value of 1 indicates success.

- Trigger the kernel crash dump:

```bash
echo c > /proc/sysrq-trigger
```

---

| [Previous Page - Introduction](./KDUMP_INTRO_README.md) | [Next Page - MachineConfig Configuration](./KDUMP_MC_README.md) | [Return to Main Page](../README.md) |
|---------------------------------------------------------|-----------------------------------------------------------------|-------------------------------------|

---
