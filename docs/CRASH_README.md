# Using `crash` Tool to analyze a vmcore

- `vmlinux` is the uncompressed kernel code, `vmlinuz`, and `vmlinux.bin` are compressed versions for booting. `zimage` is an older compressed format, and `bzImage` is an improved version.

```bash
od -t x1 -A d /host/usr/lib/modules/4.18.0-372.73.1.el8_6.x86_64/vmlinuz | grep "1f 8b 08"
dd if=/host/usr/lib/modules/$(uname -r)/vmlinuz bs=1 skip=18865 | zcat > /tmp/vmlinux
```

---

[Return to main](../README.md)

---
