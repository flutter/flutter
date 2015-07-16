#!/bin/bash
#
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# A collection of functions useful for maintaining android devices


# Run an adb command on all connected device in parallel.
# Usage: adb_all command line to eval.  Quoting is optional.
#
# Examples:
#  adb_all install Chrome.apk
#  adb_all 'shell cat /path/to/file'
#
adb_all() {
  if [[ $# == 0 ]]; then
    echo "Usage: adb_all <adb command>.  Quoting is optional."
    echo "Example: adb_all install Chrome.apk"
    return 1
  fi
  local DEVICES=$(adb_get_devices -b)
  local NUM_DEVICES=$(echo $DEVICES | wc -w)
  if (( $NUM_DEVICES > 1 )); then
    echo "Looping over $NUM_DEVICES devices"
  fi
  _adb_multi "$DEVICES" "$*"
}


# Run a command on each connected device.  Quoting the command is suggested but
# not required.  The script setups up variable DEVICE to correspond to the
# current serial number.  Intended for complex one_liners that don't work in
# adb_all
# Usage: adb_device_loop 'command line to eval'
adb_device_loop() {
  if [[ $# == 0 ]]; then
    echo "Intended for more complex one-liners that cannot be done with" \
        "adb_all."
    echo 'Usage: adb_device_loop "echo $DEVICE: $(adb root &&' \
        'adb shell cat /data/local.prop)"'
    return 1
  fi
  local DEVICES=$(adb_get_devices)
  if [[ -z $DEVICES ]]; then
    return
  fi
  # Do not change DEVICE variable name - part of api
  for DEVICE in $DEVICES; do
    DEV_TYPE=$(adb -s $DEVICE shell getprop ro.product.device | sed 's/\r//')
    echo "Running on $DEVICE ($DEV_TYPE)"
    ANDROID_SERIAL=$DEVICE eval "$*"
  done
}

# Erases data from any devices visible on adb.  To preserve a device,
# disconnect it or:
#  1) Reboot it into fastboot with 'adb reboot bootloader'
#  2) Run wipe_all_devices to wipe remaining devices
#  3) Restore device it with 'fastboot reboot'
#
#  Usage: wipe_all_devices [-f]
#
wipe_all_devices() {
  if [[ -z $(which adb) || -z $(which fastboot) ]]; then
    echo "aborting: adb and fastboot not in path"
    return 1
  elif ! $(groups | grep -q 'plugdev'); then
    echo "If fastboot fails, run: 'sudo adduser $(whoami) plugdev'"
  fi

  local DEVICES=$(adb_get_devices -b)

  if [[ $1 != '-f' ]]; then
    echo "This will ERASE ALL DATA from $(echo $DEVICES | wc -w) device."
    read -p "Hit enter to continue"
  fi

  _adb_multi "$DEVICES" "reboot bootloader"
  # Subshell to isolate job list
  (
  for DEVICE in $DEVICES; do
    fastboot_erase $DEVICE &
  done
  wait
  )

  # Reboot devices together
  for DEVICE in $DEVICES; do
    fastboot -s $DEVICE reboot
  done
}

# Wipe a device in fastboot.
# Usage fastboot_erase [serial]
fastboot_erase() {
  if [[ -n $1 ]]; then
    echo "Wiping $1"
    local SERIAL="-s $1"
  else
    if [ -z $(fastboot devices) ]; then
      echo "No devices in fastboot, aborting."
      echo "Check out wipe_all_devices to see if sufficient"
      echo "You can put a device in fastboot using adb reboot bootloader"
      return 1
    fi
    local SERIAL=""
  fi
  fastboot $SERIAL erase cache
  fastboot $SERIAL erase userdata
}

# Get list of devices connected via adb
# Args: -b block until adb detects a device
adb_get_devices() {
  local DEVICES="$(adb devices | grep 'device$')"
  if [[ -z $DEVICES && $1 == '-b' ]]; then
    echo '- waiting for device -' >&2
    local DEVICES="$(adb wait-for-device devices | grep 'device$')"
  fi
  echo "$DEVICES" | awk -vORS=' ' '{print $1}' | sed 's/ $/\n/'
}

###################################################
## HELPER FUNCTIONS
###################################################

# Run an adb command in parallel over a device list
_adb_multi() {
  local DEVICES=$1
  local ADB_ARGS=$2
  (
    for DEVICE in $DEVICES; do
      adb -s $DEVICE $ADB_ARGS &
    done
    wait
  )
}
