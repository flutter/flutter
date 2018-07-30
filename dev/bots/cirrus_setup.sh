#!/bin/bash
set -e

# This script is only meant to be run by the Cirrus CI system, not locally.
# It must be run from the root of the Flutter repo.

# Collects log output in a tmpfile, but only prints it if the command fails.
function log_on_fail() {
  local COMMAND="$@"
  local TMPDIR="$(mktemp -d)"
  local TMPFILE="$TMPDIR/command.log"
  local EXIT=0
  if ("$@" > "$TMPFILE" 2>&1); then
    echo "'$COMMAND' succeeded."
  else
    EXIT=$?
    cat "$TMPFILE" 1>&2
    echo "FAIL: '$COMMAND' exited with code $EXIT" 1>&2
  fi
  rm -rf "$TMPDIR"
  return "$EXIT"
}

function run_sdkmanager() {
  echo "y" | sdkmanager "$@"
}

function setup_android() {
  echo "Installing Android SDK so the Gallery app can built and/or deployed for $CIRRUS_BRANCH."
  set -x
  wget --progress=dot:giga https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
  mkdir android-sdk
  unzip -qq sdk-tools-linux-3859397.zip -d android-sdk
  export ANDROID_HOME="$PWD/android-sdk"
  export PATH="$PWD/android-sdk/tools/bin:$PATH"
  mkdir -p "$HOME/.android" # silence sdkmanager warning
  # Make sure we don't print our secrets to the logs!
  set +x
  if [ -n "$ANDROID_GALLERY_UPLOAD_KEY" ]; then
    echo "$ANDROID_GALLERY_UPLOAD_KEY" | base64 --decode > "$HOME/.android/debug.keystore"
  fi
  echo 'count=0' > "$HOME/.android/repositories.cfg" # silence sdkmanager warning
  local SDKS=(
    "tools"
    "platform-tools"
    "build-tools;27.0.3"
    "platforms;android-27"
    "extras;android;m2repository"
    "extras;google;m2repository"
    "patcher;v4"
  )
  for SDK in "${SDKS[@]}"; do
    echo "Installing '$SDK' with sdkmanager"
    log_on_fail run_sdkmanager "$SDK"
  done
  set -x
  sdkmanager --list
  wget --progress=dot:giga http://services.gradle.org/distributions/gradle-4.4-bin.zip
  unzip -qq gradle-4.4-bin.zip
  export GRADLE_HOME="$PWD/gradle-4.4"
  export PATH="$GRADLE_HOME/bin:$PATH"
  gradle -v
  set +x
}

echo "Flutter SDK directory is: $PWD"

if [[ -n "$CIRRUS_CI" && "$OS_NAME" == "linux" && "$SHARD" == "deploy_gallery" ]]; then
  setup_android
fi

# Run flutter to download dependencies and precompile things, and to disable
# analytics on the bots.
echo "Downloading build dependencies and pre-compiling Flutter snapshot"
log_on_fail ./bin/flutter config --no-analytics

# Run doctor, to print it to the log for debugging purposes.
./bin/flutter doctor -v

# Run pub get in all the repo packages.
echo "Updating packages for Flutter."
log_on_fail ./bin/flutter update-packages

# Make sure the master branch has been fetched so we can determine a branch
# point for PRs.
git fetch origin master
