/*
 * Atari 7800 (ProSystem) — RAM_EMU entry + ITCM hot CODE only.
 *
 * ITCM (no .data / .bss / .rodata):
 *   Sally (6502), Maria (video), Memory R/W, ProSystem frame,
 *   Tia / Pokey / Riot (I/O + audio tick).
 *
 * Cold code (Database, Cartridge, Bios, Hash, Palette, Region, main)
 * stays in RAM_EMU. Large BSS (maria_surface, pokey_poly17, memory_rom,
 * save buffer) stays in RAM_EMU; hot 64 KiB memory_ram is dtc_calloc'd.
 *
 * Object paths match BUILD_DIR=build/core (PROJECT_KIND=core).
 */

INCLUDE gnw_ram_emu.ld
INCLUDE gnw_itcm_core.ld

MEMORY
{
  RAM_EMU (xrw) : ORIGIN = __RAM_EMU_START__, LENGTH = __RAM_EMU_LENGTH__
  ITCM    (xrw) : ORIGIN = __ITCM_CORE_START__, LENGTH = __ITCM_CORE_LENGTH__
}

PHDRS
{
  text PT_LOAD FLAGS(5); /* PF_R | PF_X */
  data PT_LOAD FLAGS(6); /* PF_R | PF_W */
  itcm PT_LOAD FLAGS(5);
}

SECTIONS
{
  .core_entry __RAM_EMU_START__ :
  {
    KEEP(*(.core_entry))
    KEEP(*(.gw_core_bridge_probe))
    . = ALIGN(4);
    EXCLUDE_FILE(
      build/core/Sally.o
      build/core/Maria.o
      build/core/Memory.o
      build/core/ProSystem.o
      build/core/Tia.o
      build/core/Pokey.o
      build/core/Riot.o
    ) *(.text*)
    *(.rodata*)
    *(.glue_7)
    *(.glue_7t)

    . = ALIGN(4);
    __CORE_INIT_ARRAY_START__ = .;
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array*))
    __CORE_INIT_ARRAY_END__ = .;
  } >RAM_EMU :text

  .data :
  {
    *(.data*)
  } >RAM_EMU :data

  __CORE_CODE_END__ = .;

  .bss (NOLOAD) :
  {
    . = ALIGN(8);
    *(.bss*)
    *(COMMON)
    . = ALIGN(8);
  } >RAM_EMU :data

  __CORE_BSS_END__ = .;

  ASSERT(__CORE_BSS_END__ <= __RAM_EMU_END__,
         "Error: a7800 core RAM_EMU segment (code+data+bss) overflows RAM_EMU")

  /* Hot CODE only — no .data / .bss / .rodata in ITCM. */
  .core_itcm __ITCM_CORE_START__ :
  {
    . = ALIGN(4);
    __CORE_ITCM_CODE_START__ = .;
    build/core/Sally.o(.text*)
    build/core/Maria.o(.text*)
    build/core/Memory.o(.text*)
    build/core/ProSystem.o(.text*)
    build/core/Tia.o(.text*)
    build/core/Pokey.o(.text*)
    build/core/Riot.o(.text*)
    . = ALIGN(4);
    __CORE_ITCM_CODE_END__ = .;
  } >ITCM :itcm

  __CORE_ITCM_BSS_END__ = __CORE_ITCM_CODE_END__;

  ASSERT(__CORE_ITCM_BSS_END__ <= __ITCM_CORE_START__ + __ITCM_CORE_LENGTH__,
         "Error: a7800 core ITCM segment (hot code) overflows the 64K ITCM region")

  __exidx_start = .;
  __exidx_end = .;

  /DISCARD/ :
  {
    *(.fini_array*)
    *(.preinit_array*)
    *(.ARM.exidx*)
    *(.ARM.extab*)
    *(.comment)
    *(.ARM.attributes)
  }
}
