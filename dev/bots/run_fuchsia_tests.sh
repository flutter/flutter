#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script has been adapted from:
# https://github.com/flutter/engine/blob/master/testing/fuchsia/run_tests.sh
# Any modifications made to this file might be applicable there as well.

# This expects the device to be in zedboot mode, with a zedboot that is
# is compatible with the Fuchsia system image provided.
#
# The first and only parameter should be the path to the Fuchsia system image
# tarball, e.g. `./run_fuchsia_tests.sh generic-x64.tgz`.
#
# This script expects `pm`, `dev_finder`, and `fuchsia_ctl` to all be in the
# same directory as the script.

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
