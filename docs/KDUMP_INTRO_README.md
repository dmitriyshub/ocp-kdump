# KDUMP Introduction and Key Concepts

`Kdump` is a kernel feature that allows crash dumps to be created during a kernel crash. It produces a `vmcore`(a system-wide coredump), which is the recorded state of the working memory in the host at the time of the crash, that can be analyzed for the root cause analysis of the crash.

`kdump` uses a mechanism called `kexec` to boot into a second kernel whenever the system crashes. This second kernel, often called the crash kernel, boots with small memory and captures the dump image.

If `kdump` is enabled on your system, the standard boot kernel will reserve a small section of system RAM and load the `kdump` kernel into the reserved space. When a kernel panic or other fatal error occurs, `kexec` is used to boot into the `kdump` kernel without going through BIOS. The system reboots to the `kdump` kernel that is confined to the memory space reserved by the standard boot kernel, and this kernel writes a copy or image of the system memory to the storage mechanism defined in the configuration files.

One of the key steps in configuring `kdump` is to reserve a portion of the system's memory for the `kdump` kernel. This is done using the `crashkernel` parameter, which specifically reserves memory for the `kdump` kernel during boot.

The `kdump` service uses a `core_collector` program to capture the crash dump image. In rhel, the `makedumpfile` utility is the default `core_collector`. It helps shrink the dump file by:

- Compressing the size of a crash dump file and copying only necessary pages using various `dump_levels`

- Excluding unnecessary crash dump pages

- Filtering the page types to be included in the crash dump

To ensure sufficient storage for vmcore dumps, it's **recommended** that storage space be at least equal to the total RAM on the server. While predicting vmcore size with 100% accuracy isn't possible, analyzing over 1500 vmcores from various Red Hat Enterprise Linux versions showed that using the default dump_level setting of `-d 31` typically results in vmcores under 10% of RAM.

The crash dump or `vmcore` is usually stored as a file in a local file system, written directly to a device. Alternatively, you can set up for the crash dump to be sent over a network using the `NFS` or `SSH` protocols. Only one of these options to preserve a crash dump file can be set at a time. The default behavior is to store it in the `/var/crash` directory of the local file system.

## Kdump Procedure Overview

1. The normal kernel is booted with `crashkernel=<value>` as a kernel option, reserving some memory for the `kdump` kernel. The memory reserved by the crashkernel parameter is not available to the normal kernel during regular operation. It is reserved for later use by the `kdump` kernel

2. The system panics

3. The `kdump` kernel is booted using kexec, it used the memory area that was reserved w/ the `crashkernel` parameter

4. The normal kernel's memory is captured into a `vmcore`

## Controlling which events trigger a Kernel Panic

When you enable kdump on a system, its important to understand the conditions under which a crash dump will be triggered. By default, `kdump` doesnt automatically trigger on every possible failure or crash scenario. it relies on specific kernel parameters to determine when to activate and capture a dump.

**NOTE** Typically on `CoreOS` and similar immutable systems, `kdump` is configured to automatically capture a crash dump when a kernel panic occurs without requiring manual configuration of specific events but its important to understand them.

Applying kernel parameters to control kdump behavior can be done in two primary ways:

1. **PermanentMethod:** Through the kernel command line (e.g. via a `MachineConfig`)

2. **Temporary Method:** By manually setting the parameters at runtime through system files (e.g. using echo commands in `/proc/sys/` or `/sys/`)

### Kernel Parameters Overview

There are several parameters that control under which circumstances kdump is activated. Most of these can be enabled via kernel tunable parameters, you can refer to the most commonly used below

**System hangs due to NMI** Occurs when a `Non-Maskable` Interrupt is issued, usually due to a hardware fault:

```bash
kernel.unknown_nmi_panic = 1
kernel.panic_on_io_nmi = 1
kernel.panic_on_unrecovered_nmi = 1
```

**Control NMI behavior** using the `nmi_watchdog`:

```bash
nmi_watchdog = 1
```

**Configure watchdog timeout threshold** using `watchdog_thresh`:

```bash
watchdog_thresh = 10
```

**Machine Check Exceptions (MCE)** indicate hardware errors and configure the system to panic on `MCE` events:

```bash
mce = 0
```

**Out of memory (OOM) Kill event** Occurs when a memory request (Page Fault or kernel memory allocation) is made while not enough memory is available, thus the system terminates an active task (usually a non-prioritized process utilizing a lot of memory):

```bash
vm.panic_on_oom = 1
```

**CPU Soft Lockup event** Occurs when a task is using the `CPU` for more than time the allowed threshold (the tunable `kernel.watchdog_thresh`, default is `20` seconds):

```bash
kernel.softlockup_panic = 1
```

**CPU Hard Lockup event**  More severe than soft lockups, typically indicating that a `CPU` has stopped working entirely:

```bash
kernel.hardlockup_panic = 1
```

**Hung / Blocked Task event** Occurs when a process is stuck in Uninterruptible-Sleep (D-state) for more time than the allowed threshold (the tunable `kernel.hung_task_timeout_secs`, default is `120` seconds):

```bash
kernel.hung_task_panic = 1
```

#### Adjust Kernel Parameters

For temporary method use `rpm-ostree` when configuring this parameters manually:

```bash
rpm-ostree kargs --append='crashkernel=512M' --append='kernel.panic=1' --append='vm.panic_on_oom=1'
```

For permanent method use `kernelArguments` when configuring this parameters with a MachineConfig:

```yaml
  kernelArguments:
    - "crashkernel=512M"
    - "vm.panic_on_oom=1"
    - "kernel.softlockup_panic=1"
    - "kernel.hung_task_panic=1"
    - "nmi_watchdog=1"
    - "watchdog_thresh=10"
    - "mce=0"
```

### Why KDUMP Configuration Matters

Properly configuring both the crash triggers and memory reservation is essential for `kdump` to function as intended.

- By setting the appropriate parameters (e.g. `kernel.panic=1`, `vm.panic_on_oom=1`), you ensure that `kdump` will trigger on specific events, allowing you to capture memory dumps that are critical for diagnosing issues

- Without these parameters, your system might simply reboot or remain unresponsive during critical failures, leaving you without valuable diagnostic data

Enabling `kdump` without configuring the associated kernel parameters and memory reservation means that `kdump` might not activate during critical events, leading to missed opportunities for diagnostics. To ensure `kdump` functions effectively, it's important to:

- Set kernel parameters like `kernel.softlockup_panic`, `vm.panic_on_oom`, and others according to the events you want to capture

- Configure `crashkernel` parameter to reserve sufficient memory for kdump to operate

These steps help ensure that when a crash occurs, `kdump` can capture the necessary information to diagnose the underlying issue.

## KDUMP in Clustered Environments

Cluster environments potentially invite their own unique obstacles to `vmcore` collection. Some clusterware provides functionality to fence nodes via the `SysRq` or an `NMI` allows for `vmcore` collection upon fencing a node.

In addition to ensuring that the cluster and `kdump` configuration is sound, if a system encounters a kernel panic there is the possibility that it can be fenced and rebooted by the cluster before finishing dumping the vmcore. If this is suspected in a cluster environment it may be a good idea to remove the node from the cluster and reproduce the issue as a test or try to extand the fence timeout.

### KDUMP With Node Self Remediation Operator

Integrating `kdump` with a Node Self Remediation Operator in a cluster environment involves configuring both systems to work in harmony. Here is how you can set up and adjust the parameters of the `SNR` operator to optimize its behavior with `kdump`, ensuring that the system can properly handle kernel crashes and initiate remediation processes effectively.

Node Self Remediation Operator is a component that monitors node health and performs remediation actions (like rebooting) if it detects issues such as unresponsive nodes or specific failure conditions.

#### Operator Configuration Parameters

- `apiServerTimeout` Defines the timeout for communication with the API server. Setting this to `5s` ensures that the SNR operator does not wait too long for API server responses, which can be crucial in a crash scenario where quick detection and response are necessary

- `peerApiServerTimeout` Similar to `apiServerTimeout`, this sets the timeout for communication with peer nodes. A `5s` timeout helps ensure that the operator detects issues promptly when interacting with other nodes

- `isSoftwareRebootEnabled` When set to true, this allows the SNR operator to initiate a software reboot if necessary. This is important for kdump as it ensures that the system can reboot cleanly and attempt to capture a dump if a crash occurs

- `watchdogFilePath` Points to the watchdog device (e.g. `/dev/watchdog`). This device is used for hardware watchdog functions, which can help reset the system in case of a hang or severe issue. Ensure that kdump is properly configured to work with your watchdog device

- `peerDialTimeout` Sets the timeout for dialing peers. A `5s` timeout helps ensure that peer communication issues are detected quickly

- `peerUpdateInterval` Defines how often the operator updates the status of peers. Setting this to `15m` helps balance between frequent checks and resource usage

- `apiCheckInterval` Sets the interval at which the SNR operator checks the API server’s health. A `15s` interval is reasonable for detecting issues without overwhelming the system with checks

- `peerRequestTimeout` Timeout for peer requests. A `5s` timeout ensures timely detection of communication problems with peers.

- `safeTimeToAssumeNodeRebootedSeconds` Time to wait before assuming a node is rebooted. A `180s` setting provides a buffer to handle scenarios where the node may be recovering or performing tasks post-crash

- `maxApiErrorThreshold` Maximum number of API errors before taking action. Setting this to `3` helps in determining when to act on persistent issues with the API server.

#### Operator Recommendations

- **Monitor and Adjust Timeouts** Fine-tune the timeouts and intervals based on your environment performance and network conditions. For example, if your cluster nodes are slow to respond or network latency is high, you might need to adjust the timeouts accordingly

- **Enable Software Reboot** Ensure that `isSoftwareRebootEnabled` is set to true so that the operator can handle crashes effectively, allowing the system to reboot and kdump to capture the necessary dump

- **Configure Watchdog** Make sure that the `watchdogFilePath` is correctly set and that the hardware watchdog is functioning as expected to reset unresponsive nodes

- **Test Remediation Actions** Perform testing to ensure that the `SNR` operator can handle various crash scenarios, including those where `kdump` is triggered. Verify that the system captures dumps and that remediation actions (like reboots) occur as expected

By aligning these parameters and ensuring proper configuration, you can enhance the effectiveness of `kdump` and the Node Self Remediation Operator in managing and recovering from crashes in a cluster environment.

## Kdump Testing Summary Steps

1. Test the `kdump` in rhel host and ensure that everything is working correctly and the `kdump` generates the vmcore files in the target path successfully (Optional)

2. Configure the `machineconfig` yaml file with all the necessary configuration of `kdump` systemd unit, `kdump` configuration files, and memory reservation `crashkernel=value` parameter

3. Create the `machineconfig` object in the cluster and wait until the `machineconfig` operator picks up the changes and starts to update, initialize, and reboot the nodes

4. Wait until the `machineconfigpool` updated status is `True` and the nodes are in `Ready` status

5. Ensure that all new configuration provided by the `machineconfig` was configured correctly on the nodes

6. Trigger the kernel crash and wait until the node reboots and becomes in `Ready` status again

7. Start the debug pod again and check if the `vmcore` files exist in the target path

---

| [Next Page - Manual Configuration](./KDUMP_MANUAL_README.md) | [Return to Main Page](../README.md) |
|--------------------------------------------------------------|-------------------------------------|

---
