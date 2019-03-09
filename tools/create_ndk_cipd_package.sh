#!/bin/bash

# This script requires depot_tools to be on path.

print_usage () {
  echo "Usage: create_ndk_cipd_package.sh <PATH_TO_NDK_ASSETS> <PLATFORM_NAME> <VERSION_TAG>"
  echo "  where:"
  echo "    - PATH_TO_NDK_ASSETS is the path to the unzipped NDK folder"
  echo "    - PLATFORM_NAME is one of linux-amd64, mac-amd64, or windows-amd64"
  echo "    - VERSION_TAG is the version of the NDK, e.g. r19b"
}

if [[ $3 == "" ]]; then
  print_usage
  exit 1
fi

if [[ ! -d "$1" ]]; then
  echo "Directory $1 not found."
  print_usage
  exit 1
fi

if [[ $2 != "linux-amd64" && $2 != "mac-amd64" && $2 != "windows-amd64" ]]; then
  echo "Unsupported platform $2."
  echo "Valid options are linux-amd64, mac-amd64, windows-amd64."
  print_usage
  exit 1
fi

cipd create -in $1 -name flutter/android/ndk/$2 -install-mode copy -tag version:$3
