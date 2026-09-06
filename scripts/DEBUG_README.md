# Debug symbols (crash PC/LR → function / line)

This archive matches a ProSystem (Atari 7800) Retro-Go SD core release build.

| File | Purpose |
|------|---------|
| `prosystem_core.elf` | Linked image with DWARF (`-g`). Use for address resolution. |
| `prosystem_core.map` | Linker map (symbol addresses, section layout). |

## Resolve a crash

From a device log, take the **PC** and **LR** (hex), then:

```bash
arm-none-eabi-addr2line -e prosystem_core.elf -f -C -a 0x24012abc 0x24004567
```

Example output:

```
0x24012abc
app_main
/path/to/src/main.c:142
0x24004567
common_emu_frame_loop
…
```

Without a local toolchain, use the builder image:

```bash
docker run --rm -v "$PWD:/w" -w /w sylverb/retro-go-sd-builder:v1.5 \
  arm-none-eabi-addr2line -e prosystem_core.elf -f -C -a 0x24012abc
```

If you have a checkout of this repo, you can also use:

```bash
python3 scripts/resolve_addr.py --elf prosystem_core.elf 0x24012abc 0x24004567
```

The packed `.bin` on the SD card is stripped of DWARF; only this ELF is
useful for source-level crash investigation.
