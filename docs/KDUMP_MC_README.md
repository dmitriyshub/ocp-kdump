# KDUMP MachineConfig Configuration

This section describes how to configure kdump using MachineConfig within an OpenShift cluster environment. This method enables centralized management of kdump settings across all nodes in the pool, ensuring consistency and ease of maintenance.

**NOTE:** Always Backup the configuration files!

## Prepare the Configuration Files

Start by preparing a Butane configuration file to set up the kdump service:

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

**NOTE** The `makedumpfile -F` option is required only for the `SSH` target! If you are using local target, use `-l` instead!

Consult these examples for reference:

| [Local Path Examples](../examples/kdump-local-path/) | [SSH Path Examples](../examples/kdump-ssh-path/) |
|------------------------------------------------------|--------------------------------------------------|

## Convert the Butane File to MachineConfig

After creating the Butane file, convert it to a YAML MachineConfig:

```bash
butane 99-worker-kdump.bu -o 99-worker-kdump.yaml
```

## Apply the MachineConfig

Apply the MachineConfig to your cluster using the `oc` command:

```bash
oc apply -f 99-worker-kdump.yaml
```

## Monitor the MachineConfigPool Status

Monitor the status of the `MachineConfigPool` to confirm that the update has been successfully applied to all nodes. The pool status will change to `Updated` once the new configuration is in effect:

```bash
watch oc get nodes,mcp
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

| [Previous Page - Manual Configuration](./KDUMP_MANUAL_README.md) | [Next Page - Examples](../examples/README.md) | [Return to Main Page](../README.md) |
|------------------------------------------------------------------|-----------------------------------------------|-------------------------------------|

---
