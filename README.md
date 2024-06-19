## Enable and Configure KDUMP on OpenShift Clusters
Kdump is a kernel feature that allows crash dumps to be created during a kernel crash. It produces a vmcore(a system-wide coredump, which is the recorded state of the working memory in the host at the time of the crash) that can be analyzed for the root cause analysis of the crash.
To ensure sufficient storage for vmcore dumps, it's recommended that storage space be at least equal to the total RAM on the server. While predicting vmcore size with 100% accuracy isn't possible, analyzing over 1500 vmcores from various Red Hat Enterprise Linux versions showed that using the default dump_level setting of `-d 31` typically results in vmcores under 10% of RAM.
One of the key steps in configuring KDUMP is to reserve a portion of the system's memory for the kdump kernel. This is done using the crashkernel=value parameter, which specifically reserves memory for the kdump kernel during boot.

### Kdump procedure:
1. The normal kernel is booted with crashkernel=<value> as a kernel option, reserving some memory for the kdump kernel. The memory reserved by the crashkernel parameter is not available to the normal kernel during regular operation.  It is reserved for later use by the kdump kernel

2. The system panics

3. The kdump kernel is booted using kexec, it used the memory area that was reserved w/ the crashkernel parameter

4. The normal kernel's memory is captured into a vmcore

### Summary Steps:

1. Test the kdump on local rhel vm and ensure that everything is working correctly and the kdump generates the vmcore files in the target path successfully (Optionl)

2. Configure the machineconfig yaml file with all the necessary configuration of kdump systemd unit, kdump configuration files, and memory reservation `crashkernel=value` parameter

3. Create a kdump machineconfig object in the cluster and wait until the machineconfig operator picks up the changes and starts to update, initialize, and reboot the nodes

4. Wait until the machineconfigpool updated status is True and the nodes are in Ready status

5. Ensure that all new configuration provided by the machineconfig was configured correctly on the nodes

6. Trigger the kernel crash and wait until the node reboots and becomes in Ready status again

7. Start the debug pod again and check if the vmcore files exist in the target path

### Documentation:
- [Configuring kdump on the command line](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/configuring-kdump-on-the-command-line_managing-monitoring-and-updating-the-kernel)
- [Supported kdump configurations and targets](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/supported-kdump-configurations-and-targets_managing-monitoring-and-updating-the-kernel)

### Manual Pages:
- [makedumpfile - make a small dumpfile of kdump](https://www.linux.org/docs/man5/makedumpfile.html)
- [kdump.conf - configuration file for kdump kernel](https://linux.die.net/man/5/kdump.conf)
- [dracut.cmdline - dracut kernel command line options](https://www.unix.com/man-page/linux/7/dracut.cmdline/)

### Issues and Solutions:
- [Setting up kdump in Red Hat Openshift Container Platform and Red Hat CoreOS](https://access.redhat.com/solutions/5907731)
- [Missing Logs in /var/crash Post Kdump Setup in RHOCP4](https://access.redhat.com/solutions/7058348)
- [How to setup kdump to dump a vmcore on ssh location in Red Hat Openshift Container Platform nodes](https://access.redhat.com/solutions/6978127)
- [Common kdump Configuration Mistakes](https://access.redhat.com/articles/5332081)

### KDUMP Manual Configuration (Not Recommended)
- Use rpm-ostree tool to add kernel parameter and enable kdump
```bash
# add crashkernel parameter
$ rpm-ostree kargs --append='crashkernel=256M'
# enable kdump and reboot machine
$ systemctl enable kdump
```
- Cordon and drain the node before reboot 
```bash
$ oc adm cordon <node-name>
$ oc adm drain <node-name> --ignore-daemonsets --delete-emptydir-data --force
$ oc debug node/<node-name>
$ chroot /host
$ systemctl reboot
```

### KDUMP Machineconfig Configuration:
1. Choose the preffered target path (local/ssh) and create butane file
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
        failure_action shell

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

2. Convert Butane file to MachineConfig YAML and Apply the MachineConfigs

```bash
$ butane 99-worker-kdump.bu -o 99-worker-kdump.yaml
$ oc apply -f 99-worker-kdump.yaml
```

3. Monitor the MachineConfigPool and wait for the update to complete after the new configurations are applied. The status of the machineconfigpool will change to "Updated" once all nodes have applied the new configuration
```bash
$ watch oc get nodes,mcp
```

### Initiate Manual Kernel Crash
```bash
# Check if kdump is active
$ systemctl is-active kdump
# OPTIONAL: Enable “softlockup_panic” so the kdump will write the vmcore file before the system restarts in case of a crash
$ echo "1" >> /proc/sys/kernel/softlockup_panic
# checking that the kdump.service has started and exited successfully and prints 1
$ cat /sys/kernel/kexec_crash_loaded
# trigger kernel dump
$ echo c > /proc/sysrq-trigger
```

## Troubleshooting KDUMP

### Estimating the VMCORE Files Size:
```bash
# The makedumpfile --mem-usage command estimates how much space the crash dump file requires
# By default the RHEL kernel uses 4 KB sized pages on AMD64 and Intel 64 CPU , and 64 KB sized pages on IBM POWER
$ makedumpfile --mem-usage /proc/kcore
```

### Check Kernel Command-line Parameters:
```bash
rpm-ostree kargs # Desired parameters
cat /proc/cmdline # Actual Parameters
```

### Check KDUMP Configuration Files Content
```bash
$ cat /etc/sysconfig/kdump 
$ cat /etc/kdump.conf
# For ssh target path
$ cat /root/.ssh/config
$ cat /root/.ssh/id_kdump
```

### Check KDUMP logs
```bash
$ cat /var/log/kdump.log
$ journalctl --unit kdump
$ dmesg | grep dracut
$ dmesg | grep crash
```

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
2. Convert Butane file to MachineConfig YAML and Apply the MachineConfigs

```bash
$ butane 99-worker-getty-ttyS0.bu -o 99-worker-getty-ttyS0.yaml
$ oc apply -f 99-worker-getty-ttyS0.yaml
```

3. Monitor the MachineConfigPool and wait for the update to complete after the new configurations are applied. The status of the machineconfigpool will change to "Updated" once all nodes have applied the new configuration
```bash
$ watch oc get nodes,mcp
```

### Access Serial Console via CIMC's Serial Over LAN
1. Log in to the CIMC Interface: Open a web browser and navigate to the CIMC interface using the IP address or hostname of the Cisco bmc server. Log in with ocp user credentials
2. Navigate to Remote Management: In the CIMC web interface, locate the section for remote management. This is often found under the Compute tab
3. Configure Serial over LAN:
- Enabled: Ensure the "Serial over LAN" option is enabled
- Baud Rate: Set the baud rate to 115.2kbps (115200 bps)
- Com Port: Choose the appropriate COM port (com0)
- SSH Port: The default SSH port is typically 22, but CIMC might use a specific port like 2400. Make sure this port is noted for later use
4. Save the Configuration: After configuring the Serial over LAN settings, save your changes in the CIMC interface
Access the Serial Console: To connect to the serial console via SSH, open a terminal on your local machine and use an SSH client to connect to the CIMC's IP address on the specified SSH port. For example: `ssh -p 2400 ocp@cimc_node_dns_address`
