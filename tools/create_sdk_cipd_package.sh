#!/bin/bash

# This script requires depot_tools to be on path.

print_usage () {
  echo "Usage: create_ndk_cipd_package.sh <PACKAGE_TYPE> <PATH_TO_ASSETS> <PLATFORM_NAME> <VERSION_TAG>"
  echo "  where:"
  echo "    - PACKAGE_TYPE is one of build-tools, platform-tools, platforms, or tools"
  echo "    - PATH_TO_ASSETS is the path to the unzipped asset folder"
  echo "    - PLATFORM_NAME is one of linux-amd64, mac-amd64, or windows-amd64"
  echo "    - VERSION_TAG is the version of the package, e.g. 28r6 or 28.0.3"
}

if [[ $4 == "" ]]; then
  print_usage
  exit 1
fi

if [[ $1 != "build-tools" && $1 != "platform-tools" && $1 != "platforms" && $1 != "tools" ]]; then
  echo "Unrecognized paackage type $1."
  print_usage
  exit 1
fi

if [[ ! -d "$2" ]]; then
  echo "Directory $1 not found."
  print_usage
  exit 1
fi

if [[ $1 != "platforms" && $3 != "linux-amd64" && $3 != "mac-amd64" && $3 != "windows-amd64" ]]; then
  echo "Unsupported platform $3."
  echo "Valid options are linux-amd64, mac-amd64, windows-amd64."
  print_usage
  exit 1
fi

if [[ $1 == "platforms" ]]; then
  echo "Ignoring PLATFORM_NAME - this package is cross-platform."
  cipd create -in $2 -name flutter/android/sdk/$1 -install-mode copy -tag version:$4
else
  cipd create -in $2 -name flutter/android/sdk/$1/$3 -install-mode copy -tag version:$4
fi
