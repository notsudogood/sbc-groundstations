#!/bin/sh
# Host-side test for S00config's once-per-image refresh of maburgs.toml /
# maburplay.toml (board/common/overlay/etc/init.d/S00config refresh).
#
#   sh tests/config-refresh.test.sh
cd "$(dirname "$0")/.." || exit 1
S00=$PWD/board/common/overlay/etc/init.d/S00config
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export CONFIG_DIR=$T/config DEFAULTS_DIR=$T/defaults MENU_FILE=$T/maburgs.menu
mkdir -p "$CONFIG_DIR" "$DEFAULTS_DIR"
fail=0
ko() { fail=$((fail + 1)); echo "FAIL $*"; }
run() { sh "$S00" refresh >"$T/out" 2>&1; }
image() { printf 'channels = [%s]\n' "$1" >"$DEFAULTS_DIR/maburgs.toml"; printf 'phase_lock = %s\n' "$2" >"$DEFAULTS_DIR/maburplay.toml"; printf 'mode = "ap"\n' >"$DEFAULTS_DIR/wifi.toml"; }

# First boot: seeded, stamped.
image "36, 132" false
run
cmp -s "$DEFAULTS_DIR/maburgs.toml" "$CONFIG_DIR/maburgs.toml" || ko "not seeded"
cmp -s "$DEFAULTS_DIR/maburgs.toml" "$CONFIG_DIR/.image-defaults/maburgs.toml" || ko "not stamped"
# Edited on this image (and the menu used): kept on the next boot.
printf 'channels = [132]\n' >"$CONFIG_DIR/maburgs.toml"
printf 'hop=off\n' >"$MENU_FILE"
printf 'mode = "client"\n' >"$CONFIG_DIR/wifi.toml"
run
grep -q '\[132\]' "$CONFIG_DIR/maburgs.toml" || ko "same-image edit lost"
[ -f "$MENU_FILE" ] || ko "menu choice dropped on the same image"
# New image, maburgs default changed: reset, backup, menu cleared; maburplay
# unedited -> replaced without a backup; wifi.toml untouched.
image "36, 100, 116, 132" true
run
cmp -s "$DEFAULTS_DIR/maburgs.toml" "$CONFIG_DIR/maburgs.toml" || ko "maburgs not reset"
grep -q '\[132\]' "$CONFIG_DIR/old/maburgs.toml.old1" || ko "maburgs not backed up"
[ ! -f "$MENU_FILE" ] && [ -f "$CONFIG_DIR/old/maburgs.menu.old" ] || ko "menu choice not cleared"
grep -q 'phase_lock = true' "$CONFIG_DIR/maburplay.toml" || ko "maburplay not updated"
[ ! -e "$CONFIG_DIR/old/maburplay.toml.old1" ] || ko "unedited maburplay backed up"
grep -q client "$CONFIG_DIR/wifi.toml" || ko "wifi.toml touched"
grep -q "reset to the new default" "$T/out" || ko "no console line"
# Next image with the same maburgs default: an edit made since survives.
printf 'channels = [100]\n' >"$CONFIG_DIR/maburgs.toml"
run
grep -q '\[100\]' "$CONFIG_DIR/maburgs.toml" || ko "edit under unchanged default lost"
# keep-config: a changed default leaves the edited file alone.
touch "$CONFIG_DIR/keep-config"
image "36, 104" true
run
grep -q '\[100\]' "$CONFIG_DIR/maburgs.toml" || ko "keep-config ignored"

[ "$fail" = 0 ] && echo "config refresh: OK" || { echo "$fail failure(s)"; exit 1; }
