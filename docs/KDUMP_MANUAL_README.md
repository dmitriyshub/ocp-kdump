# KDUMP Manual Configuration (Not Recommended)

- **NOTE:** Always Backup the configuration files

- Modify `/etc/kdump.conf` and `/etc/sysconfig/kdump`

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
# checking that the kdump.service has started and exited successfully and prints 1
cat /sys/kernel/kexec_crash_loaded
# trigger kernel dump
echo c > /proc/sysrq-trigger
```

---

[Conf Files Examples](../examples/kdump-conf-files/)

---

[Return to main](../README.md)

---
