################################################################################
#
# devourer
#
################################################################################

# Feedback-repair build, rollout phase 2: PINNED to notsudogood/devourer branch
# claude/wifi-fpv-link-architecture-1bms9l -- gilankpam/devourer master 56eabe4
# (what the phase-1 images ran) plus per-packet hardware TX queue selection
# (TxMode::hw_queue) -- and to the same commit as the air-unit firmware from
# openipc-builder's same-named branch.
# 3524f4c (2026-10-20, gs10): the batched channel set (FastSetChannel) behind
# the card width switches and full-set hops, 80 MHz on any primary, VHT 1SS
# rates following the HT power diffs.
# 097c527 (2026-10-21, gs11, a data build): LastChannelSetStats -- each
# channel set's time split into lock wait, priming read, write batches,
# single round trips and post-set re-asserts -- and the lean width switch
# (tuning.lean_width, off unless mabur's radio.lean_width).
# Override with `make DEVOURER_VERSION=<sha-or-tag> mabur-rebuild`.
DEVOURER_VERSION = 097c527e8417bc4a1fab0d0818e528a85b5dc724
DEVOURER_SITE = https://github.com/notsudogood/devourer.git
DEVOURER_SITE_METHOD = git
DEVOURER_LICENSE = GPL-2.0
DEVOURER_INSTALL_STAGING = NO
DEVOURER_INSTALL_TARGET = NO

# Nothing is compiled here. mabur's top-level CMakeLists.txt pulls devourer in
# with add_subdirectory(${DEVOURER_DIR} ... EXCLUDE_FROM_ALL), so what mabur
# needs is the *source tree on disk* at its own configure time. This package
# exists to make Buildroot fetch and extract it -- and to define DEVOURER_DIR,
# which the package infrastructure sets to $(BUILD_DIR)/devourer-$(VERSION),
# exactly the cache variable mabur's CMake expects. See package/mabur/mabur.mk.
#
# libusb is still a dependency: devourer's CMake does
# pkg_check_modules(libusb REQUIRED IMPORTED_TARGET libusb-1.0), and that runs
# during *mabur's* configure step, so libusb has to be staged by then.
DEVOURER_DEPENDENCIES = libusb

DEVOURER_CONFIGURE_CMDS =
DEVOURER_BUILD_CMDS =
DEVOURER_INSTALL_TARGET_CMDS =

$(eval $(generic-package))
