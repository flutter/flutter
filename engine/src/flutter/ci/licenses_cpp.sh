#!/usr/bin/env bash

# A script to run the C++ license checker for the Flutter engine.
#
# This script makes the command easier to run by:
# 1. Accepting the host profile directory (e.g., host_profile_arm64) as an argument.
# 2. Guessing the host profile directory based on the CPU architecture if not provided.
# 3. Automatically resolving all paths relative to the script's location.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---

# Get the absolute path of the directory where this script is located. This is
# crucial for making all other paths relative and predictable.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

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

# Based on the original command, we can infer the project's directory structure
# relative to this script's location.
#
# Assumed structure:
# .../engine/
# ├── out/
# │   └── [host_profile_arm64]/
# │       └── licenses_cpp      <-- The executable
# └── src/
#     └── flutter/
#         ├── ...
#         └── tools/
#             └── licenses_cpp/
#                 ├── data/     <-- The data directory
#                 └── run.sh    <-- This script

# Path to the executable to run.
EXECUTABLE="$SCRIPT_DIR/../../out/$HOST_PROFILE_DIR/licenses_cpp"

# The root directory for the license check.
WORKING_DIR="$SCRIPT_DIR/.."

# The data directory required by the license tool.
DATA_DIR="$SCRIPT_DIR/../tools/licenses_cpp/data"

# The output path for the generated licenses file. This will be created
# in the directory where you *run* the script from (your current working directory).
LICENSES_OUTPUT_PATH="licenses.txt"


# --- Validation ---

# Before running, check that the required executable and directories actually exist.
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERROR: Executable not found at the expected path: $EXECUTABLE"
    echo "Please ensure the project has been built and this script is in the correct location."
    exit 1
fi

# --- Run Command ---

echo "--------------------------------------------------"
echo "Host Profile:   $HOST_PROFILE_DIR"
echo "Executable:     $EXECUTABLE"
echo "Working Dir:    $WORKING_DIR"
echo "Data Dir:       $DATA_DIR"
echo "Output File:    $(pwd)/$LICENSES_OUTPUT_PATH"
echo "--------------------------------------------------"
echo "Running license check..."

# Use "exec" to replace the shell process with the command. This is slightly
# more efficient as it avoids creating an unnecessary child process.
exec "$EXECUTABLE" \
  --working_dir "$WORKING_DIR" \
  --data_dir "$DATA_DIR" \
  --licenses_path "$LICENSES_OUTPUT_PATH"

echo "License check complete. Output written to $LICENSES_OUTPUT_PATH"
