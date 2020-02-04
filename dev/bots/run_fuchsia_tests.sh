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
# This script expects `pm`, `device-finder`, and `fuchsia_ctl` to all be in the
# same directory as the script.

set -Eex

script_dir=$(dirname "$(readlink -f "$0")")

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
  $script_dir/fuchsia_ctl -d $device_name --dev-finder-path $script_dir/dev_finder ssh --identity-file $script_dir/.ssh/pkey -c "dm reboot-recovery" || true
}

trap reboot EXIT

$script_dir/fuchsia_ctl -d $device_name pave  -i $1
$script_dir/fuchsia_ctl push-packages -d $device_name --repoArchive generic-x64.tar.gz -p tiles -p tiles_ctl

# set fuchsia ssh config
export FUCHSIA_SSH_PKEY=$script_dir/.ssh/pkey
cat > $script_dir/fuchsia_ssh_config << EOF
Host *
  CheckHostIP no
  StrictHostKeyChecking no
  ForwardAgent no
  ForwardX11 no
  GSSAPIDelegateCredentials no
  UserKnownHostsFile /dev/null
  User fuchsia
  IdentitiesOnly yes
  IdentityFile $FUCHSIA_SSH_PKEY
  ControlPersist yes
  ControlMaster auto
  ControlPath /tmp/fuchsia--%r@%h:%p
  ConnectTimeout 10
  ServerAliveInterval 1
  ServerAliveCountMax 10
  LogLevel ERROR
EOF

export FUCHSIA_SSH_CONFIG=$script_dir/fuchsia_ssh_config

# Run the driver test
flutter_dir=$script_dir/flutter
flutter_bin=$flutter_dir/bin/flutter

# remove all out dated .packages references
find $flutter_dir -name ".packages" | xargs rm

cd $flutter_dir/dev/benchmarks/test_apps/stocks/

$flutter_bin precache --fuchsia
$flutter_bin precache --flutter_runner

$flutter_bin pub get
$flutter_bin drive -v --target=test_driver/stock_view.dart
