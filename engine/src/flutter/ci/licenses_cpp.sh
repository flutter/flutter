#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---

# Get the absolute path of the directory where this script is located. This is
# crucial for making all other paths relative and predictable.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Default verbosity level
VERBOSITY=1

# Check for QUIET environment variable
if [[ -n "${QUIET}" ]]; then
  VERBOSITY=0
fi

# --- Determine Host Profile Directory ---

HOST_PROFILE_DIR=""

# Check if the first argument ($1) was provided.
if [ -n "$1" ]; then
  # Use the provided argument as the directory name.
  HOST_PROFILE_DIR="$1"
  echo "Using specified host profile directory: $HOST_PROFILE_DIR"
else
  # If no argument is provided, guess based on the machine architecture.
  ARCH=$(uname -m)
  echo "No host profile directory specified. Guessing based on architecture: $ARCH"

  if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    HOST_PROFILE_DIR="host_profile_arm64"
  elif [[ "$ARCH" == "x86_64" ]]; then
    # This is a common directory name for x86-64 builds.
    HOST_PROFILE_DIR="host_profile"
  else
    # If the architecture is not recognized, exit with an error.
    echo "ERROR: Unsupported architecture '$ARCH'."
    echo "Please provide the host profile directory as the first argument."
    echo "Example: $0 host_profile_arm64"
    exit 1
  fi
fi

# --- Define Paths Relative to the Script ---

# Path to the executable to run.
EXECUTABLE="$SCRIPT_DIR/../../out/$HOST_PROFILE_DIR/licenses_cpp"

# The root directory for the license check.
WORKING_DIR="$SCRIPT_DIR/../.."

# The data directory required by the license tool.
DATA_DIR="$SCRIPT_DIR/../tools/licenses_cpp/data"

# The output path for the generated licenses file. This will be created
# in the directory where you *run* the script from (your current working directory).
LICENSES_OUTPUT_PATH="$SCRIPT_DIR/../sky/packages/sky_engine/LICENSE_CPP.new"

LICENSES_PATH="$SCRIPT_DIR/../sky/packages/sky_engine/LICENSE"

# --- Validation ---

# Before running, check that the required executable and directories actually exist.
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Executable not found at the expected path: $EXECUTABLE"
    echo "Please ensure the project has been built and this script is in the correct location."
    exit 1
fi

# --- Run Command ---

"$EXECUTABLE" \
  --working_dir "$WORKING_DIR" \
  --data_dir "$DATA_DIR" \
  --licenses_path "$LICENSES_OUTPUT_PATH" \
  --root_package "flutter" \
  --v $VERBOSITY

if ! git diff \
  --no-index \
  --exit-code \
  --ignore-cr-at-eol \
  --ignore-matching-lines="^You may obtain a copy of this library's Source Code Form from:.*" \
  "$LICENSES_PATH" \
  "$LICENSES_OUTPUT_PATH"; then
  echo "The licenses have changed."
  echo "Please review added licenses and update //engine/src/flutter/sky/packages/sky_engine/LICENSE"
  echo "The license check can be repeated locally with //engine/src/flutter/ci/licenses_cpp.sh"
  echo "Make sure your licenses_cpp executable is built. For example:"
  echo "    et build -c host_profile_arm64 //flutter/tools/licenses_cpp"
  echo "When executed locally the following command can update the licenses after a run:"
  echo "cp $LICENSES_OUTPUT_PATH $LICENSES_PATH"
  exit 1
fi
rm "$LICENSES_OUTPUT_PATH"
