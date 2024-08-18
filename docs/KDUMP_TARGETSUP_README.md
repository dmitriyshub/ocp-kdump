# Supported Targets

| Target Type       | Supported Targets                                                                 | Unsupported Targets                                                   |
|-------------------|-----------------------------------------------------------------------------------|------------------------------------------------------------------------|
| **Physical Storage** | Logical Volume Manager (LVM)                                                      | BIOS RAID                                                              |
|                   | Thin provisioning volume                                                          | Software iSCSI with iBFT                                               |
|                   | Fibre Channel (FC) disks such as qla2xxx, lpfc, bnx2fc, and bfa                    | Currently supported transports are bnx2i, cxgb3i, and cxgb4i           |
|                   | An iSCSI software-configured logical device on a networked storage server          | Software iSCSI with a hybrid device driver such as be2iscsi            |
|                   | The mdraid subsystem as a software RAID solution                                   | Fibre Channel over Ethernet (FCoE)                                     |
|                   | Hardware RAID such as cciss, hpsa, megaraid_sas, mpt2sas, and aacraid              | Legacy IDE                                                             |
|                   | SCSI and SATA disks                                                               | GlusterFS servers                                                      |
|                   | iSCSI and HBA offloads                                                            | GFS2 file system                                                       |
|                   | Hardware FCoE such as qla2xxx and lpfc                                            | Clustered Logical Volume Manager (CLVM)                                |
|                   |                                                                                   | High availability LVM volumes (HA-LVM)                                 |
| **Network**       | Hardware using kernel modules: tg3, igb, ixgbe, sfc, e1000e, bna, cnic, netxen_nic, qlge, bnx2x, bnx, qlcnic, be2net, enic, virtio-net, ixgbevf, igbvf | IPv6 protocol                                  |
|                   | IPv4 protocol                                                                     | Wireless connections                                                   |
|                   | Network bonding on different devices, such as Ethernet devices or VLAN            | InfiniBand networks                                                    |
|                   | VLAN network                                                                      | VLAN network over bridge and team                                      |
|                   | Network Bridge                                                                    |                                                                        |
|                   | Network Teaming                                                                   |                                                                        |
|                   | Tagged VLAN and VLAN over a bond                                                  |                                                                        |
|                   | Bridge network over bond, team, and VLAN                                          |                                                                        |
| **Hypervisor**    | Kernel-based virtual machines (KVM)                                               |                                                                        |
|                   | Xen hypervisor in certain configurations only                                     |                                                                        |
|                   | VMware ESXi 4.1 and 5.1                                                           |                                                                        |
|                   | Hyper-V 2012 R2 on RHEL Gen1 UP Guest only                                        |                                                                        |
| **File Systems**  | The ext[234], XFS, and NFS file systems                                           | The Btrfs file system                                                  |
| **Firmware**      | BIOS-based systems                                                                |                                                                        |
|                   | UEFI Secure Boot                                                                  |                                                                        |

---

| [Previous Page - Introduction](./KDUMP_INTRO_README.md) | [Return to Main Page](../README.md) |
|---------------------------------------------------------|-------------------------------------|

---
