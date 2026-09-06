# Atari 7800 (ProSystem) — standalone Retro-Go SD core
#
#   make                  — build + pack → prosystem.bin
#   make host             — Linux/macOS SDL binary (prosystem_host)
#   make docker           — Docker builder image
#
# BUILD_DIR=build/core must match ld/a7800_core.ld ITCM object paths.
# SD ROM dirname stays a7800 (firmware launcher convention).

#######################################
# Project identity
#######################################
PROJECT_KIND ?= core

CORE_NAME  := prosystem
CORE_ENTRY := app_main

CORE_C_SOURCES := \
src/prosystem/Bios.c \
src/prosystem/Cartridge.c \
src/prosystem/Database.c \
src/prosystem/Hash.c \
src/prosystem/Maria.c \
src/prosystem/Memory.c \
src/prosystem/Palette.c \
src/prosystem/Pokey.c \
src/prosystem/ProSystem.c \
src/prosystem/Region.c \
src/prosystem/Riot.c \
src/prosystem/Sally.c \
src/prosystem/Tia.c \
src/main.c

CORE_C_INCLUDES := \
-Isrc/prosystem

# Relative path so Docker bind-mounts work (do NOT use $(abspath)).
GNW_CORE_SDK ?= sdk
BUILD_DIR ?= build/$(PROJECT_KIND)

CORE_LDSCRIPT := ld/a7800_core.ld
CORE_EXTRA_SEGMENTS := itcm:core_itcm

#######################################
# Kind-specific compile defs + packing
#######################################
ifeq ($(PROJECT_KIND),core)
CORE_C_DEFS := \
-DPROJECT_KIND_CORE=1 \
-DCOVERFLOW=1 \
-DCHEAT_CODES=1 \
-DMAX_CHEAT_CODES=13 \
-DGNW_DISABLE_COMPRESSION \
-DTARGET_GNW

PACKED_BIN  := $(CORE_NAME).bin
PAD_LOGO    := src/assets/pad.bmp
HEADER_LOGO := src/assets/header.bmp

else
$(error PROJECT_KIND must be 'core' (got '$(PROJECT_KIND)'))
endif

include $(GNW_CORE_SDK)/Makefile

PACK_CORE := $(GNW_CORE_SDK)/tools/pack_core.py

#######################################
# Packed header version
#######################################
CORE_VERSION ?= $(shell git describe --tags --dirty 2>/dev/null || echo NOTAG)

#######################################
# Pack
#######################################
.PHONY: pack

pack: $(TARGET_BIN) $(BUILD_DIR)/$(CORE_NAME)_core_itcm.bin $(PAD_LOGO) $(HEADER_LOGO)
	$(V)$(ECHO) [ PACK CORE ] $(PACKED_BIN) version=$(CORE_VERSION)
	$(V)python3 $(PACK_CORE) \
		--elf $(TARGET_ELF) --bin $(TARGET_BIN) \
		--system-name "Atari 7800" --dirname a7800 \
		--extensions "a78 bin" \
		--core-name "ProSystem" \
		--version "$(CORE_VERSION)" \
		--pad-logo $(PAD_LOGO) \
		--header-logo $(HEADER_LOGO) \
		--logo-invert \
		--segment itcm:__ITCM_CORE_START__:__CORE_ITCM_CODE_END__:__CORE_ITCM_BSS_END__:$(BUILD_DIR)/$(CORE_NAME)_core_itcm.bin \
		--out $(PACKED_BIN)

all: pack

.PHONY: print-PROJECT_KIND print-PACKED_BIN print-CORE_NAME print-DOCKER_IMAGE \
	print-TARGET_ELF print-TARGET_MAP print-CORE_VERSION
print-PROJECT_KIND:
	@echo $(PROJECT_KIND)
print-PACKED_BIN:
	@echo $(PACKED_BIN)
print-CORE_NAME:
	@echo $(CORE_NAME)
print-DOCKER_IMAGE:
	@echo $(DOCKER_IMAGE)
print-TARGET_ELF:
	@echo $(TARGET_ELF)
print-TARGET_MAP:
	@echo $(BUILD_DIR)/$(CORE_NAME)_core.map
print-CORE_VERSION:
	@echo $(CORE_VERSION)

clean::
	$(V)rm -f $(PACKED_BIN)

#######################################
# Docker (same image as firmware repo)
#######################################
.PHONY: docker docker_pull docker_shell

RELEASE_VERSION ?= v1.5
DOCKER_REPOSITORY ?= sylverb/retro-go-sd-builder
DOCKER_IMAGE ?= $(DOCKER_REPOSITORY):$(RELEASE_VERSION)

DOCKER_TTY_FLAG := $(shell if [ -t 0 ]; then echo -it; else echo; fi)
DOCKER_USER := $(shell id -u):$(shell id -g)
DOCKER_RUN := docker run --rm $(DOCKER_TTY_FLAG) \
	--user $(DOCKER_USER) \
	-v "$(CURDIR):/opt/workdir" \
	-w /opt/workdir \
	$(DOCKER_IMAGE)

docker:
	$(V)$(ECHO) "[ DOCKER ]" $(DOCKER_IMAGE) "PROJECT_KIND=$(PROJECT_KIND)"
	$(V)$(DOCKER_RUN) make --no-print-directory -j$$(nproc) PROJECT_KIND=$(PROJECT_KIND)

docker_pull:
	$(V)$(ECHO) "[ PULL ]" $(DOCKER_IMAGE)
	$(V)docker pull $(DOCKER_IMAGE)

docker_shell:
	$(DOCKER_RUN) bash

#######################################
# Host SDL (Linux / macOS)
#######################################
include host/Makefile.host
