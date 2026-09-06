# Changelog

## [v0.0.1]

Initial public ProSystem (Atari 7800) core release.

### Added

- Nothing

### Changed

- Hot code in ITCM (Sally / Maria / Memory / ProSystem / Tia / Pokey / Riot).
- Hot WRAM (`memory_ram`) + POKEY mix buffer in DTCM; no ITCM data.

### Fixed

- Nothing

### Install

- Unzip the release archive onto the SD card root (`cores/prosystem.bin`).
- Place ROMs under `/roms/a7800/` (`.a78` / `.bin`).
- Requires firmware whose ABI matches `SDK_VERSION` in this repository.
