#!/bin/bash -p

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -eu

# Environment sanitization. Set a known-safe PATH. Clear environment variables
# that might impact the interpreter's operation. The |bash -p| invocation
# on the #! line takes the bite out of BASH_ENV, ENV, and SHELLOPTS (among
# other features), but clearing them here ensures that they won't impact any
# shell scripts used as utility programs. SHELLOPTS is read-only and can't be
# unset, only unexported.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
unset BASH_ENV CDPATH ENV GLOBIGNORE IFS POSIXLY_CORRECT
export -n SHELLOPTS

readonly ScriptDir=$(dirname "$(echo ${0} | sed -e "s,^\([^/]\),$(pwd)/\1,")")
readonly ScriptName=$(basename "${0}")
readonly ThisScript="${ScriptDir}/${ScriptName}"
readonly SimExecutable="${BUILD_DIR}/ninja-iossim/${CONFIGURATION}/iossim"

# Helper to print a line formatted for Xcodes build output parser.
XcodeNote() {
  echo "${ThisScript}:${1}: note: ${2}"
}

# Helper to print a divider to make things stick out in a busy output window.
XcodeHeader() {
  echo "note: _________________________________________________________________"
  echo "note: _________________________________________________________________"
  echo "note: _________________________________________________________________"
  XcodeNote "$1" ">>>>>     $2"
  echo "note: _________________________________________________________________"
  echo "note: _________________________________________________________________"
  echo "note: _________________________________________________________________"
}

# Kills the iPhone Simulator if it is running.
KillSimulator() {
  /usr/bin/killall "iPhone Simulator" 2> /dev/null || true
}

# Runs tests via the iPhone Simulator for multiple devices.
RunTests() {
  local -r appPath="${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app"

  if [[ ! -x "${SimExecutable}" ]]; then
    echo "Unable to run tests: ${SimExecutable} was not found/executable."
    exit 1
  fi

  for device in 'iPhone' 'iPad'; do
    iosVersion="6.1"
    KillSimulator
    local command=(
      "${SimExecutable}" "-d${device}" "-s${iosVersion}" "${appPath}"
    )
    # Pass along any command line flags
    if [[ "$#" -gt 0 ]]; then
      command+=( "--" "${@}" )
    fi
    XcodeHeader ${LINENO} "Launching tests for ${device} (iOS ${iosVersion})"
    "${command[@]}"

    # If the command didn't exit successfully, abort.
    if [[ $? -ne 0 ]]; then
      exit $?;
    fi
  done
}

# Time to get to work.

if [[ "${PLATFORM_NAME}" != "iphonesimulator" ]]; then
  XcodeNote ${LINENO} "Skipping running of unittests for device build."
else
  if [[ "$#" -gt 0 ]]; then
    RunTests "${@}"
  else
    RunTests
  fi
  KillSimulator
fi

exit 0
