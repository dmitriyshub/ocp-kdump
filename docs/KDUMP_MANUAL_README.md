# KDUMP Manual Configuration (Not Recommended)

- **NOTE:** Always Backup the configuration files

- Modify `/etc/kdump.conf` and `/etc/sysconfig/kdump`

- [KDUMP Configuration Files Examples](../examples/kdump-conf-files/)

```bash
vim /etc/kdump.conf
path /var/crash
core_collector makedumpfile -l --message-level 7 -d 31
default shell
```

```bash
vim /etc/sysconfig/kdump
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=10 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never nokaslr novmcoredd hest_disable rd.net.timeout.carrier=30"
KEXEC_ARGS="-s"
KDUMP_IMG="vmlinuz"
```

- Use `rpm-ostree` to Add Kernel Parameter and Enable `kdump`

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

- Execute `cordon` and `drain` Before Reboot the Node

```bash
oc adm cordon <node-name>
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
oc debug node/<node-name>
chroot /host
systemctl reboot
```

## Initiate Manual Kernel Crash Dump

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

[Return to main](../README.md)

---
