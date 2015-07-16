#!/bin/sh

# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

BUILDTYPE="${BUILDTYPE:-Debug}"
CHROME_SRC_DIR="${CHROME_SRC_DIR:-$(dirname -- $(readlink -fn -- "$0"))/..}"
CHROME_OUT_DIR="${CHROME_SRC_DIR}/${CHROMIUM_OUT_DIR:-out}/${BUILDTYPE}"
CHROME_SANDBOX_BUILD_PATH="${CHROME_OUT_DIR}/chrome_sandbox"
CHROME_SANDBOX_INST_PATH="/usr/local/sbin/chrome-devel-sandbox"
CHROME_SANDBOX_INST_DIR=$(dirname -- "$CHROME_SANDBOX_INST_PATH")

TARGET_DIR_TYPE=$(stat -f -c %t -- "${CHROME_SANDBOX_INST_DIR}" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Could not get status of ${CHROME_SANDBOX_INST_DIR}"
  exit 1
fi

# Make sure the path is not on NFS.
if [ "${TARGET_DIR_TYPE}" = "6969" ]; then
  echo "Please make sure ${CHROME_SANDBOX_INST_PATH} is not on NFS!"
  exit 1
fi

installsandbox() {
  echo "(using sudo so you may be asked for your password)"
  sudo -- cp "${CHROME_SANDBOX_BUILD_PATH}" \
    "${CHROME_SANDBOX_INST_PATH}" &&
  sudo -- chown root:root "${CHROME_SANDBOX_INST_PATH}" &&
  sudo -- chmod 4755 "${CHROME_SANDBOX_INST_PATH}"
  return $?
}

if [ ! -d "${CHROME_OUT_DIR}" ]; then
  echo -n "${CHROME_OUT_DIR} does not exist. Use \"BUILDTYPE=Release ${0}\" "
  echo "If you are building in Release mode"
  exit 1
fi

if [ ! -f "${CHROME_SANDBOX_BUILD_PATH}" ]; then
  echo -n "Could not find ${CHROME_SANDBOX_BUILD_PATH}, "
  echo "please make sure you build the chrome_sandbox target"
  exit 1
fi

if [ ! -f "${CHROME_SANDBOX_INST_PATH}" ]; then
  echo -n "Could not find ${CHROME_SANDBOX_INST_PATH}, "
  echo "installing it now."
  installsandbox
fi

if [ ! -f "${CHROME_SANDBOX_INST_PATH}" ]; then
  echo "Failed to install ${CHROME_SANDBOX_INST_PATH}"
  exit 1
fi

CURRENT_API=$("${CHROME_SANDBOX_BUILD_PATH}" --get-api)
INSTALLED_API=$("${CHROME_SANDBOX_INST_PATH}" --get-api)

if [ "${CURRENT_API}" != "${INSTALLED_API}" ]; then
  echo "Your installed setuid sandbox is too old, installing it now."
  if ! installsandbox; then
    echo "Failed to install ${CHROME_SANDBOX_INST_PATH}"
    exit 1
  fi
else
  echo "Your setuid sandbox is up to date"
  if [ "${CHROME_DEVEL_SANDBOX}" != "${CHROME_SANDBOX_INST_PATH}" ]; then
    echo -n "Make sure you have \"export "
    echo -n "CHROME_DEVEL_SANDBOX=${CHROME_SANDBOX_INST_PATH}\" "
    echo "somewhere in your .bashrc"
    echo "This variable is currently: ${CHROME_DEVEL_SANDBOX:-empty}"
  fi
fi
