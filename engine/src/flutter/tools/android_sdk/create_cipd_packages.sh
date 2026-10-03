#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script requires depot_tools to be on path.

print_usage () {
  echo "Usage:"
  echo "  ./create_cipd_packages.sh [FLAGS] <VERSION_TAG> [PATH_TO_SDK_DIR]"
  echo "    Downloads, packages, and uploads Android SDK packages where:"
  echo "      - VERSION_TAG is the tag of the cipd packages, e.g. 28r6, 31v1 or baklava_v1."
  echo "                    Must contain only lowercase letters, numbers and underscores."
  echo "      - PATH_TO_SDK_DIR is the path to the sdk folder. If omitted, this defaults to"
  echo "                      your ANDROID_SDK_ROOT environment variable."
  echo "  ./create_cipd_packages.sh [FLAGS] list"
  echo "    Lists the available packages for use in 'packages.txt'"
  echo ""
  echo "Flags:"
  echo "  --packages-file=<path>     The file listing the packages to upload. Defaults to"
  echo "                             'packages.txt' in the same directory as this script."
  echo "  --dry-run                  Download and stage all packages, but print the 'cipd create'"
  echo "                             commands instead of running them. The staged upload"
  echo "                             directories are kept for inspection."
  echo "  -h, --help                 Print this message."
  echo ""
  echo "This script downloads the packages specified in the packages file and uploads"
  echo "them to CIPD for linux, mac, and windows."
  echo "To confirm you have write permissions run 'cipd acl-check flutter/android/sdk/all/ -writer'."
  echo ""
  echo "Manage the packages to download in 'packages.txt'. You can use"
  echo "'sdkmanager --list --include_obsolete' in cmdline-tools to list all available packages."
  echo "Packages should be listed in the format of <package-name>:<directory-to-upload>."
  echo "For example, build-tools;31.0.0:build-tools"
  echo "Multiple directories to upload can be specified by delimiting by additional ':'"
  echo ""
  echo "To upload an Android preview SDK, use 'preview_packages.txt'. For example:"
  echo "  ./create_cipd_packages.sh --packages-file=preview_packages.txt --dry-run \\"
  echo "    cinnamonbun_v1 \$ANDROID_SDK_ROOT"
  echo ""
  echo "This script expects the cmdline-tools to be installed in your specified PATH_TO_SDK_DIR"
  echo "and should only be run on linux or macos hosts."
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

packages_file="$script_dir/packages.txt"
dry_run=false
positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --packages-file=*)
      packages_file="${1#*=}"
      ;;
    --dry-run)
      dry_run=true
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --*)
      echo "Unknown flag: $1"
      print_usage
      exit 1
      ;;
    *)
      positional+=("$1")
      ;;
  esac
  shift
done

first_argument="${positional[0]}"
# Validate version or argument is provided.
if [[ $first_argument == "" ]]; then
  print_usage
  exit 1
fi

# Validate version contains only lower case letters, numbers and underscores.
if [[ $first_argument != "list" ]] && ! [[ $first_argument =~ ^[[:lower:][:digit:]_]+$ ]]; then
  echo "Version tag can only consist of lower case letters, digits and underscores.";
  print_usage
  exit 1
fi

# Validate the packages file exists. Relative paths are resolved against the
# current directory first, then against the directory of this script.
if [[ ! -f "$packages_file" && -f "$script_dir/$packages_file" ]]; then
  packages_file="$script_dir/$packages_file"
fi
if [[ ! -f "$packages_file" ]]; then
  echo "Packages file '$packages_file' not found."
  print_usage
  exit 1
fi

# Validate environment has cipd installed.
if [[ `which cipd` == "" ]]; then
  echo "'cipd' command not found. depot_tools should be on the path."
  exit 1
fi

sdk_path=${positional[1]:-$ANDROID_SDK_ROOT}

# Validate directory contains all SDK packages
if [[ ! -d "$sdk_path" ]]; then
  echo "Android SDK at '$sdk_path' not found."
  print_usage
  exit 1
fi

# Validate caller has cipd.
if [[ ! -d "$sdk_path/cmdline-tools" ]]; then
  echo "SDK directory does not contain $sdk_path/cmdline-tools."
  print_usage
  exit 1
fi

platforms=("linux" "macosx" "windows")

# Find the sdkmanager in cmdline-tools. We default to using latest if available.
sdkmanager_path="$sdk_path/cmdline-tools/latest/bin/sdkmanager"
find_results=()
while IFS= read -r line; do
  find_results+=("$line")
done < <(find "$sdk_path/cmdline-tools" -name sdkmanager)
i=0
while [ ! -f "$sdkmanager_path" ]; do
  if [ $i -ge ${#find_results[@]} ]; then
    echo "Unable to find sdkmanager in the SDK directory. Please ensure cmdline-tools is installed."
    exit 1
  fi
  sdkmanager_path="${find_results[$i]}"
  echo $sdkmanager_path
  ((i++))
done

# list available packages
if [ $first_argument == "list" ]; then
  "$sdkmanager_path" --list --include_obsolete
  exit 0
fi

# Returns the CIPD package name suffixes (e.g. mac-arm64) for a given sdkmanager platform.
cipd_names_for_platform () {
  case "$1" in
    macosx)
      # Upload an arm64 version for M1 macs. Mac uses a different sdkmanager
      # name than the platform name used in gn.
      echo "mac-amd64 mac-arm64"
      ;;
    *)
      echo "$1-amd64"
      ;;
  esac
}

# CIPD tags are immutable. Verify the tag is unused for every package before
# downloading anything, so a collision does not leave a partial upload.
for platform in "${platforms[@]}"; do
  for cipd_name in $(cipd_names_for_platform "$platform"); do
    if describe_output=$(cipd describe "flutter/android/sdk/all/$cipd_name" -version "version:$first_argument" 2>&1); then
      echo "Tag version:$first_argument already exists for flutter/android/sdk/all/$cipd_name."
      echo "CIPD tags are immutable. Please choose a new version tag."
      exit 1
    elif [[ $describe_output != *"no such tag"* ]]; then
      echo "Failed to check tag version:$first_argument for flutter/android/sdk/all/$cipd_name:"
      echo "$describe_output"
      exit 1
    fi
  done
done
echo "Tag version:$first_argument is unused."

# We create a new temporary SDK directory because the default working directory
# tends to not update/re-download packages if they are being used. This guarantees
# a clean install of Android SDK.
temp_dir=`mktemp -d -t android_sdkXXXX`

for platform in "${platforms[@]}"; do
  sdk_root="$temp_dir/sdk_$platform"
  upload_dir="$temp_dir/upload_$platform"
  echo "Creating temporary working directory for $platform: $sdk_root"
  mkdir "$sdk_root"
  mkdir "$upload_dir"
  mkdir "$upload_dir/sdk"
  export REPO_OS_OVERRIDE=$platform

  # Download all the packages with sdkmanager.
  for package in $(< "$packages_file"); do
    echo $package
    split=(${package//:/ })
    IFS=',' read -ra ADDR <<< "${split[0]}"
    for i in "${ADDR[@]}"; do
      echo "Installing $i"
      yes "y" | "$sdkmanager_path" --sdk_root="$sdk_root" "$i"
    done

    # We copy only the relevant directories to a temporary dir
    # for upload. sdkmanager creates extra files that we don't need.
    array_length=${#split[@]}
    for (( i=1; i<${array_length}; i++ )); do
      cp -a "$sdk_root/${split[$i]}" "$upload_dir/sdk"
    done
  done

  # Accept all licenses to ensure they are generated and uploaded.
  yes "y" | "$sdkmanager_path" --licenses --sdk_root="$sdk_root"
  cp -a "$sdk_root/licenses" "$upload_dir/sdk"

  for cipd_name in $(cipd_names_for_platform "$platform"); do
    cipd_command=(cipd create -in "$upload_dir" -name "flutter/android/sdk/all/$cipd_name" -install-mode copy -tag "version:$first_argument" -ref "$first_argument")

    if $dry_run; then
      echo "[dry-run] ${cipd_command[*]}"
    else
      echo "Uploading $upload_dir as $cipd_name to CIPD"
      "${cipd_command[@]}"
    fi
  done

  rm -rf "$sdk_root"
  if ! $dry_run; then
    rm -rf "$upload_dir"
  fi

  # This variable changes the behvaior of sdkmanager.
  # Unset to clean up after script.
  unset REPO_OS_OVERRIDE
done

if $dry_run; then
  echo ""
  echo "[dry-run] No packages were uploaded. Staged upload directories:"
  for platform in "${platforms[@]}"; do
    du -sh "$temp_dir/upload_$platform/sdk"/*
  done
  echo "[dry-run] Delete $temp_dir when done inspecting."
else
  rm -rf "$temp_dir"
fi
