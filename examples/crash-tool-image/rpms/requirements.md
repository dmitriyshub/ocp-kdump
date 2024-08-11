# Containerfile RPM Requirements

**NOTE** This file is only a reference for which rpm packages the crash tool container requires!

- Always check the CoreOS kernel version before download the debuginfo packages

```bash
uname -r
4.18.0-372.73.1.el8_6.x86_64
```

- Download all the required packages for the `vmcore` kernel version from the [Customer Portal](https://access.redhat.com/downloads/content/package-browser)

```bash
ls -l rpms/
-rw-r--r--  1 dshtranv  staff    3049136 Aug  6 11:28 crash-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff    6944684 Aug  6 11:28 crash-debuginfo-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff    4662464 Aug  6 11:28 crash-debugsource-7.3.1-5.el8.x86_64.rpm
-rw-r--r--  1 dshtranv  staff  662685964 Aug  6 11:27 kernel-debuginfo-4.18.0-372.73.1.el8_6.x86_64.rpm
-rw-r--r--  1 dshtranv  staff   73930952 Aug  6 11:27 kernel-debuginfo-common-x86_64-4.18.0-372.73.1.el8_6.x86_64.rpm
```

## Crash Utility Packages

- crash-7.3.1-5.el8.x86_64.rpm

- crash-debuginfo-7.3.1-5.el8.x86_64.rpm

- crash-debugsource-7.3.1-5.el8.x86_64.rpm

## Kernel Version Packages

- kernel-debuginfo-4.18.0-372.73.1.el8_6.x86_64.rpm

- kernel-debuginfo-common-x86_64-4.18.0-372.73.1.el8_6.x86_64.rpm

---
