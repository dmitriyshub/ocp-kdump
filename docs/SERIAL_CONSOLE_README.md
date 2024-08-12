# Configure Serial Console for KDUMP Issues Troubleshooting

Enabling the serial console (e.g. `ttyS0`) for kdump troubleshooting lets you capture kernel messages and kdump output even if the graphical interface is unresponsive. It ensures that diagnostic information is accessible during a crash, which is important for remote debugging and analyzing the cause of the failure.

[How does one set up a serial terminal and/or console in Red Hat Enterprise Linux?](https://access.redhat.com/articles/3166931)

## Create a Butane File

- Prepare a Butane configuration file to set up the serial console

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

**Note** The primary console for system output will be the last console listed in the kernel parameters. In the above example, the VGA console `tty0` is the primary and the serial console is the secondary display. This means messages from init scripts will not go to the serial console, since it is the secondary console, but boot messages and critical warnings will go to the serial console. If init script messages need to be seen on the serial console as well, it should be made the primary by swapping the order of the console parameters.

## Convert Butane File to MachineConfig

- Convert the `Butane` file to a `YAML` configuration and apply it

```bash
butane 99-worker-getty-ttyS0.bu -o 99-worker-getty-ttyS0.yaml
```

## Apply the MachineConfig

- Use `oc` to apply the `MachineConfig`

```bash
oc apply -f 99-worker-getty-ttyS0.yaml
```

## Monitor the MachineConfigPool Status to Ensure Updates are Applied

- Wait for the update to complete after the new configurations are applied. The status of the `machineconfigpool` will change to `Updated` once all nodes have applied the new configuration

```bash
watch oc get nodes,mcp
```

## Access Serial Console via CIMC Serial Over LAN

1. Open a web browser and navigate to the `CIMC` interface using the IP address or hostname of the Cisco BMC server and log in with user credentials

2. In the `CIMC` web interface, locate the section for remote management (This is often found under the **Compute** tab)

3. Configure `Serial over LAN`:

- Ensure the `Serial over LAN` option is enabled

- Set the Baud Rate to `115.2kbps` (115200 bps)

- Choose the appropriate `COM` port (`com0`)

- The default `SSH` port is typically 22, but `CIMC` might use a specific port like 2400

- Save the Configuration

- To connect to the serial console via `SSH`, open a terminal on your local machine and use an `SSH` client to connect to the `CIMC` IP address on the specified `SSH` port, for example: `ssh -p 2400 ocp@cimc_node_dns_address`

---

[Serial Console Configuration Example](../examples/serial-console-conf/)

---

| [Previous Page - Troubleshooting](./KDUMP_TROUBLESHOOT_README.md) | [Next Page - Manual Crash Tool](./CRASH_MANUAL_README.md) | [Return to Main Page](../README.md) |
|-------------------------------------------------------------------|------------------------------------------------------------|------------------------------------|

---
