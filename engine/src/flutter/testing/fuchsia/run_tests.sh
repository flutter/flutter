#!/bin/bash

# Any modifications to this script may be applicable to
# https://github.com/flutter/flutter/blob/master/dev/bots/run_fuchsia_tests.sh

# This expects the device to be in zedboot mode, with a zedboot that is
# is compatible with the Fuchsia system image provided.
#
# The first and only parameter should be the path to the Fuchsia system image
# tarball, e.g. `./fuchsia-test.sh generic-x64.tgz`.
#
# This script expects `pm`, `device-finder`, and `fuchsia_ctl` to all be in the
# same directory as the script, as well as the `flutter_aot_runner-0.far` and
# the `flutter_runner_tests-0.far`. It is written to be run from its own
# directory, and will fail if run from other directories or via sym-links.
#
# This script also expects a private key available at:
# "/etc/botanist/keys/id_rsa_infra".

set -Eex

test_timeout_seconds=300

# This is longer than the test timeout as dumping the
# logs can sometimes take longer.
ssh_timeout_seconds=360

# The nodes are named blah-blah--four-word-fuchsia-id
device_name=${SWARMING_BOT_ID#*--}

# Bot key to pave and ssh the device.
pkey="/etc/botanist/keys/id_rsa_infra"

if [ -z "$device_name" ]
then
  echo "No device found. Aborting."
  exit 1
else
  echo "Connecting to device $device_name"
fi

# Wrapper function to pass common args to fuchsia_ctl.
fuchsia_ctl() {
  ./fuchsia_ctl -d $device_name "$@"
}

reboot() {
  # As we are not using recipes we don't have a way to know the location
  # to upload the log to isolated. We are saving the log to a file to avoid dart
  # hanging when running the process and then just using printing the content to
  # the console.
  kill -9 $PID
  cat /tmp/log.txt
  echo "$(date) START:REBOOT ----------------------------------------"
  # note: this will set an exit code of 255, which we can ignore.
  fuchsia_ctl ssh \
      --identity-file $pkey \
      -c "dm reboot-recovery" || true
  echo "$(date) END:REBOOT ------------------------------------------"
}

trap reboot EXIT

echo "$(date) START:PAVING ------------------------------------------"
ssh-keygen -y -f $pkey > key.pub
fuchsia_ctl pave \
      -i $1 \
      --public-key "key.pub"
echo "$(date) END:PAVING --------------------------------------------"

echo "$(date) START:WAIT_DEVICE_READY -------------------------------"
for i in {1..10}; do
  fuchsia_ctl ssh \
      --identity-file $pkey \
      -c "echo up" && break || sleep 15;
done
rm -rf /tmp/log.txt
fuchsia_ctl ssh --timeout-seconds 1800 --identity-file $pkey -c "log_listener" --log-file /tmp/log.txt &
PID=$!
echo "$(date) END:WAIT_DEVICE_READY ---------------------------------"

echo "$(date) START:EXTRACT_PACKAGES  -------------------------------"
mkdir -p packages
tar -xvzf $2 -C packages 1> /dev/null
echo "$(date) END:EXTRACT_PACKAGES  ---------------------------------"

echo "$(date) START:testing_tests -----------------------------------"
fuchsia_ctl test \
   -f testing_tests-0.far  \
   -t testing_tests \
   --identity-file $pkey \
   --timeout-seconds $test_timeout_seconds \
   --packages-directory packages
echo "$(date) DONE:testing_tests ------------------------------------"

# TODO(https://github.com/flutter/flutter/issues/61212): Re-enable ParagraphTest
# once it passes on Fuchsia.
echo "$(date) START:txt_tests ---------------------------------------"
fuchsia_ctl test \
   -f txt_tests-0.far  \
   -t txt_tests \
   -a "--gtest_filter=-ParagraphTest.*" \
   --identity-file $pkey \
   --timeout-seconds $test_timeout_seconds \
   --packages-directory packages
echo "$(date) DONE:txt_tests ----------------------------------------"

# TODO(https://github.com/flutter/flutter/issues/57709): Re-enable FileTest
# once it passes on Fuchsia.
# TODO(https://github.com/flutter/flutter/issues/58211): Re-enable MessageLoop
# test once it passes on Fuchsia.
echo "$(date) START:fml_tests ---------------------------------------"
fuchsia_ctl test \
    -f fml_tests-0.far  \
    -t fml_tests \
    -a "--gtest_filter=-MessageLoop.TimeSensistiveTest_*:FileTest.CanTruncateAndWrite:FileTest.CreateDirectoryStructure" \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages
echo "$(date) DONE:fml_tests ----------------------------------------"


echo "$(date) START:flow_tests --------------------------------------"
fuchsia_ctl test \
   -f flow_tests-0.far  \
   -t flow_tests \
   --identity-file $pkey \
   --timeout-seconds $test_timeout_seconds \
   --packages-directory packages
echo "$(date) DONE:flow_tests ---------------------------------------"


echo "$(date) START:runtime_tests -----------------------------------"
fuchsia_ctl test \
    -f runtime_tests-0.far  \
    -t runtime_tests \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages
echo "$(date) DONE:runtime_tests ------------------------------------"

echo "$(date) START:ui_tests ----------------------------------------"
fuchsia_ctl test \
   -f ui_tests-0.far  \
   -t ui_tests \
   --identity-file $pkey \
   --timeout-seconds $test_timeout_seconds \
   --packages-directory packages
echo "$(date) DONE:ui_tests -----------------------------------------"

echo "$(date) START:shell_tests -------------------------------------"
fuchsia_ctl test \
    -f shell_tests-0.far  \
    -t shell_tests \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages
echo "$(date) DONE:shell_tests --------------------------------------"

echo "$(date) START:embedder_tests -------------------------------------"
fuchsia_ctl test \
    -f embedder_tests-0.far  \
    -t embedder_tests \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages
echo "$(date) DONE:embedder_tests --------------------------------------"

# TODO(gw280): Enable tests using JIT runner
echo "$(date) START:flutter_runner_tests ----------------------------"
fuchsia_ctl test \
    -f flutter_aot_runner-0.far    \
    -f flutter_runner_tests-0.far  \
    -t flutter_runner_tests        \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages

# TODO(https://github.com/flutter/flutter/issues/61768): De-flake and re-enable
# fuchsia_ctl test \
#     -f flutter_aot_runner-0.far    \
#     -f flutter_runner_scenic_tests-0.far  \
#     -t flutter_runner_scenic_tests \
#     --identity-file $pkey \
#     --timeout-seconds $test_timeout_seconds \
#     --packages-directory packages

fuchsia_ctl test \
    -f flutter_aot_runner-0.far    \
    -f flutter_runner_tzdata_tests-0.far  \
    -t flutter_runner_tzdata_tests \
    --identity-file $pkey \
    --timeout-seconds $test_timeout_seconds \
    --packages-directory packages
echo "$(date) DONE:flutter_runner_tests -----------------------------"
