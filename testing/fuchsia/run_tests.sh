#!/bin/bash

# This expects the device to be in zedboot mode, with a zedboot that is
# is compatible with the Fuchsia system image provided.
#
# The first and only parameter should be the path to the Fuchsia system image
# tarball, e.g. `./fuchsia-test.sh generic-x64.tgz`.
#
# This script expects `pm`, `dev_finder`, and `fuchsia_ctl` to all be in the
# same directory as the script, as well as the `flutter_aot_runner-0.far` and
# the `flutter_runner_tests-0.far`. It is written to be run from its own
# directory, and will fail if run from other directories or via sym-links.

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
  echo "Dumping system logs..."

  ./fuchsia_ctl -d $device_name ssh \
      -c "log_listener --dump_logs yes"

  # note: this will set an exit code of 255, which we can ignore.
  ./fuchsia_ctl -d $device_name ssh -c "dm reboot-recovery" || true
}

trap reboot EXIT

./fuchsia_ctl -d $device_name pave  -i $1

for i in {1..10}; do
  ./fuchsia_ctl -d $device_name ssh -c "echo up" && break || sleep 15;
done

# TODO(gw280): Enable tests using JIT runner

./fuchsia_ctl -d $device_name test \
    -f flutter_aot_runner-0.far    \
    -f flutter_runner_tests-0.far  \
    -t flutter_runner_tests

# TODO(https://bugs.fuchsia.dev/p/fuchsia/issues/detail?id=47081)
# Re-enable once the crash is resolved
#./fuchsia_ctl -d $device_name test \
#    -f flutter_aot_runner-0.far    \
#    -f flutter_runner_scenic_tests-0.far  \
#    -t flutter_runner_scenic_tests

# TODO(https://github.com/flutter/flutter/issues/50032) Enable after the
# Fuchsia message loop migration is complete.
./fuchsia_ctl -d $device_name test \
    -f fml_tests-0.far  \
    -t fml_tests \
    -a "--gtest_filter=-MessageLoop*:Message*:FileTest*"

./fuchsia_ctl -d $device_name test \
    -f flow_tests-0.far  \
    -t flow_tests

./fuchsia_ctl -d $device_name test \
    -f runtime_tests-0.far  \
    -t runtime_tests

./fuchsia_ctl -d $device_name test \
    -f shell_tests-0.far  \
    -t shell_tests \
    -a "--gtest_filter=-ShellTest.CacheSkSLWorks:ShellTest.SetResourceCacheSize*"

