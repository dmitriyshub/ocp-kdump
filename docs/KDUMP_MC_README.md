# KDUMP Machineconfig Configuration

This section outlines configuring kdump using MachineConfig in an OpenShift cluster environment. This method allows for centralized management of kdump settings across all nodes in the pool.

**NOTE:** Always Backup the configuration files

## Choose Your Preffered Target Path `local` or `ssh` and Create Butane File

- Prepare a Butane configuration file to set up the kdump service

**NOTE** The `makedumpfile -F` option is required only for the `SSH` target

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

## Convert the Butane file to YAML format

- Convert the `Butane` file to a `YAML` configuration

```bash
butane 99-worker-kdump.bu -o 99-worker-kdump.yaml
```

## Apply the MachineConfig

- Use `oc` to apply the `MachineConfig`

```bash
oc apply -f 99-worker-kdump.yaml
```

## Monitor the MachineConfigPool Status to Ensure Updates are Applied

- Wait for the update to complete after the new configurations are applied. The status of the `machineconfigpool` will change to `Updated` once all nodes have applied the new configuration

```bash
watch oc get nodes,mcp
```

## Initiate Manual Kernel Crash Dump

- To manually trigger a kernel dump, use the following commands

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

[Local Path Examples](../examples/kdump-local-path/)

---

[SSH Path Examples](../examples/kdump-ssh-path/)

---

[Return to main](../README.md)

---
