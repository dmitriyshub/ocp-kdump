## KDUMP in OpenShift CoreOS **baremetal** Nodes

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

---

### Kdump Procedure

1. The normal kernel is booted with `crashkernel=<value>` as a kernel option, reserving some memory for the `kdump` kernel. The memory reserved by the crashkernel parameter is not available to the normal kernel during regular operation. It is reserved for later use by the `kdump` kernel

2. The system panics

3. The `kdump` kernel is booted using kexec, it used the memory area that was reserved w/ the `crashkernel` parameter

4. The normal kernel's memory is captured into a `vmcore`

---

### Summary Steps

1. Test the `kdump` in rhel host and ensure that everything is working correctly and the `kdump` generates the vmcore files in the target path successfully (Optionl)

2. Configure the `machineconfig` yaml file with all the necessary configuration of `kdump` systemd unit, `kdump` configuration files, and memory reservation `crashkernel=value` parameter

3. Create the `machineconfig` object in the cluster and wait until the `machineconfig` operator picks up the changes and starts to update, initialize, and reboot the nodes

4. Wait until the `machineconfigpool` updated status is `True` and the nodes are in `Ready` status

5. Ensure that all new configuration provided by the `machineconfig` was configured correctly on the nodes

6. Trigger the kernel crash and wait until the node reboots and becomes in `Ready` status again

7. Start the debug pod again and check if the `vmcore` files exist in the target path

---

### Documentation

- [The importance of configuring kernel dumps](https://www.redhat.com/en/blog/importance-configuring-kernel-dumps-rhel)

- [Configuring kdump on the command line (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Configuring kdump on the command line (RHEL9 CoreOS 4.13 and upper)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/managing_monitoring_and_updating_the_kernel/index#configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL8 CoreOS 4.12 and lower)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

- [Supported kdump configurations and targets (RHEL9 CoreOS 4.13 and upper)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

---

### Manual Pages

- **NOTE:** Always refer to your **CoreOS** tools version manual page

- [kexec(8) - Linux man page](https://linux.die.net/man/8/kexec)

- [makedumpfile(8) - make a small dumpfile of kdump](https://www.linux.org/docs/man5/makedumpfile.html)

- [kdump.conf(5) - configuration file for kdump kernel](https://linux.die.net/man/5/kdump.conf)

- [kdump(5) - Configuration of kdump](https://www.unix.com/man-page/suse/5/kdump/)

- [kdumpctl(8) - control interface for kdump](https://www.linux.org/docs/man8/kdumpctl.html)

- [dracut.cmdline(7) - dracut kernel command line options](https://www.unix.com/man-page/linux/7/dracut.cmdline/)

---

### Issues and Solutions

- [Setting up kdump in Red Hat Openshift Container Platform and Red Hat CoreOS](https://access.redhat.com/solutions/5907731)

- [Missing Logs in /var/crash Post Kdump Setup in RHOCP4](https://access.redhat.com/solutions/7058348)

- [How to setup kdump to dump a vmcore on ssh location in Red Hat Openshift Container Platform nodes](https://access.redhat.com/solutions/6978127)

- [Common kdump Configuration Mistakes](https://access.redhat.com/articles/5332081)

- [kdump fails to generate vmcore with SysRq on servers installed with LEGACY BIOS and vga controller...](https://access.redhat.com/solutions/5770681)

---

### KDUMP Manual Configuration (Not Recommended)

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
```

- Execute `cordon`, `drain` and Reboot the Node

```bash
oc adm cordon <node-name>
oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
oc debug node/<node-name>
chroot /host
systemctl reboot
```

---

### KDUMP Machineconfig Configuration

1. Choose the Preffered Target Path (`local`/`ssh`) and Create Butane File

```yaml
variant: openshift
version: 4.12.0
metadata:
  name: 99-worker-kdump
  labels:
    machineconfiguration.openshift.io/role: worker
openshift:
  kernel_arguments:
    - crashkernel=1024M   
storage:
  files:
  - path: /root/.ssh/id_kdump
    mode: 0600                                                                 
    overwrite: true
    contents:
      inline: |
        -----BEGIN OPENSSH PRIVATE KEY-----
        SSH Private Key Content                                      
        -----END OPENSSH PRIVATE KEY-----

  - path: /root/.ssh/config
    mode: 0644
    overwrite: true
    contents:
      inline: |
         Host <ip_or_dns_address>
             StrictHostKeyChecking no

  - path: /etc/kdump.conf
    mode: 0644
    overwrite: true
    contents:
      inline: | 
        path /mnt/ocp_kdump/crash
        ssh user@<ip_or_dns_address>
        sshkey /root/.ssh/id_kdump
        core_collector makedumpfile -F -l --message-level 1 -d 31
        extra_modules megaraid_sas
        default shell        
        #failure_action shell

  - path: /etc/sysconfig/kdump 
    mode: 0644
    overwrite: true
    contents:
      inline: |
        KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb"
        KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=10 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never nokaslr novmcoredd hest_disable" 
        KEXEC_ARGS="-s"
        KDUMP_IMG="vmlinuz"

systemd:
  units:
    - name: kdump.service
      enabled: true
```

2. Convert Butane file to `yaml` and Apply the `MachineConfig`

```bash
butane 99-worker-kdump.bu -o 99-worker-kdump.yaml
oc apply -f 99-worker-kdump.yaml
```

3. Monitor the `MachineConfigPool` and wait for the update to complete after the new configurations are applied. The status of the `machineconfigpool` will change to `Updated` once all nodes have applied the new configuration
```bash
watch oc get nodes,mcp
```

---

### Initiate Manual Kernel Crash

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

## Troubleshooting KDUMP

- Estimate the `crashkernel` Parameter
```bash
kdumpctl get-default-crashkernel
kdumpctl estimate
```

- Estimate the `VMCORE` Files Size

```bash
# The makedumpfile --mem-usage command estimates how much space the crash dump file requires
# By default the RHEL kernel uses 4 KB sized pages on AMD64 and Intel 64 CPU , and 64 KB sized pages on IBM POWER
makedumpfile --mem-usage /proc/kcore
```

- Check Kernel `cmdline` Parameters

```bash
rpm-ostree kargs # Desired parameters
cat /proc/cmdline # Actual Parameters
```

- Check `Kdump` Configuration Files Content

```bash
cat /etc/sysconfig/kdump 
cat /etc/kdump.conf
# For ssh target path
cat /root/.ssh/config
cat /root/.ssh/id_kdump
```

- Add Additional Kernel Modules `/etc/kdump.conf`

```bash
lsinitrd /var/lib/kdump/initramfs-4.18.0-372.73.1.el8_6.x86_64kdump.img | grep sd_mod
```

```bash
extra_modules megaraid_sas sd_mod
```

- Add default or failure Behavior `/etc/kdump.conf` (depends on `kdump-utils` version)

```bash
default shell # Newer Versions
failure_action shell # Older Versions
```

- Modifiy the kernel command line `/etc/sysconfig/kdump`

```bash
KDUMP_COMMANDLINE_REMOVE="hugepages hugepagesz slub_debug quiet log_buf_len swiotlb ip=dhcp rootflags=prjquota rootflags=nofail udev.children-max=2 ignition.platform.id=metal"
KDUMP_COMMANDLINE_APPEND="irqpoll nr_cpus=1 reset_devices cgroup_disable=memory mce=off numa=off udev.children-max=2 panic=60 rootflags=nofail acpi_no_memhotplug transparent_hugepage=never novmcoredd hest_disable module_blacklist=igb,ixgbe"
```

- To Apply New `kdump` Configuration Execute One of `kdumpctl` Examples After Every Change
```bash
kdumpctl reload # reload the crash kernel image and initramfs without triggering a rebuild.
kdumpctl rebuild # rebuild the crash kernel initramfs.
kdumpctl restart # Is equal to start; stop
```

- Check `kdump` Logs

```bash
cat /var/log/kdump.log
journalctl --unit kdump
dmesg | grep dracut
dmesg | grep crash
# dmesg destination from reboots
ls -l /sys/fs/pstore
```

- If The `kdump` Configuration Files Manually Modified and the `MachineConfigPool` Status Changed to `Degraded`, Its possible to Decode the Rendered `MachineConfig` File Content - [Link](https://access.redhat.com/solutions/5315421)
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
---

### Configure Serial Console to Troubleshoot KDUMP Issues

- [How does one set up a serial terminal and/or console in Red Hat Enterprise Linux?](https://access.redhat.com/articles/3166931)

1. Create a Butane file for Kernel Arguments and systemd service

```yaml
variant: openshift
version: 4.12.0
metadata:
  name: 99-worker-getty-ttyS0
  labels:
    machineconfiguration.openshift.io/role: worker
openshift:
  kernel_arguments:
    - console=ttyS0,115200n8
    - console=tty0
systemd:
  units:  
    - name: serial-getty@ttyS0.service
      enabled: true
      contents: |
        [Unit]
        Description=Serial Getty on ttyS0
        Documentation=man:agetty(8) man:systemd-getty-generator(8)
        After=systemd-user-sessions.service plymouth-quit-wait.service
        After=rc-local.service
        After=systemd-journald.socket
        Wants=systemd-user-sessions.service plymouth-quit-wait.service

        [Service]
        ExecStart=-/sbin/agetty --keep-baud 115200,9600,38400,19200,9600 ttyS0 $TERM
        Type=idle
        Restart=always
        RestartSec=0
        UtmpIdentifier=ttyS0
        TTYPath=/dev/ttyS0
        TTYReset=yes
        TTYVHangup=yes
        KillMode=process
        IgnoreSIGPIPE=no
        SendSIGHUP=yes

        [Install]
        WantedBy=multi-user.target
```

- Note: The primary console for system output will be the last console listed in the kernel parameters. In the above example, the VGA console `tty0` is the primary and the serial console is the secondary display. This means messages from init scripts will not go to the serial console, since it is the secondary console, but boot messages and critical warnings will go to the serial console. If init script messages need to be seen on the serial console as well, it should be made the primary by swapping the order of the console parameters.

2. Convert Butane file to MachineConfig YAML and Apply the MachineConfigs

```bash
butane 99-worker-getty-ttyS0.bu -o 99-worker-getty-ttyS0.yaml
oc apply -f 99-worker-getty-ttyS0.yaml
```

3. Monitor the `MachineConfigPool` and wait for the update to complete after the new configurations are applied. The status of the `machineconfigpool` will change to `Updated` once all nodes have applied the new configuration

```bash
watch oc get nodes,mcp
```

---

### Access Serial Console via CIMC's Serial Over LAN

1. Open a web browser and navigate to the CIMC interface using the IP address or hostname of the Cisco bmc server and log in with user credentials

2. In the CIMC web interface, locate the section for remote management (This is often found under the **Compute** tab)

3. Configure Serial over LAN:

- Enabled: Ensure the "Serial over LAN" option is enabled
- Baud Rate: Set the baud rate to 115.2kbps (115200 bps)
- Com Port: Choose the appropriate COM port (com0)
- SSH Port: The default SSH port is typically 22, but CIMC might use a specific port like 2400. Make sure this port is noted for later use

4. Save the Configuration

5. To connect to the serial console via SSH, open a terminal on your local machine and use an SSH client to connect to the CIMC's IP address on the specified SSH port. For example: `ssh -p 2400 ocp@cimc_node_dns_address`

---