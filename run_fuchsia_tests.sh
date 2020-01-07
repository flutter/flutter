#!/bin/bash

# This expects the device to be in zedboot mode, with a zedboot that is
# is compatible with the Fuchsia system image provided.

set -Ee

# The nodes are named blah-blah--four-word-fuchsia-id
device_name=${SWARMING_BOT_ID#*--}

if [ -z "$device_name" ]
then
  echo "No device found. Aborting."
  exit 1
else
  echo "Connecting to device $device_name"
fi

reboot() {
  # note: this will set an exit code of 255, which we can ignore.
  ./fuchsia_ctl -d $device_name ssh -c "dm reboot-recovery" || true
}

trap reboot EXIT

./fuchsia_ctl -d $device_name pave  -i $1

