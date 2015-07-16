#!/bin/sh

# Copyright (c) 2008 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This is a wrapper for fetching values from the BRANDING files.  Pass the
# value of GYP's branding variable followed by the key you want and the right
# file is checked.
#
#  branding_value.sh Chromium COPYRIGHT
#  branding_value.sh Chromium PRODUCT_FULLNAME
#

set -e

if [ $# -ne 2 ] ;  then
  echo "error: expect two arguments, branding and key" >&2
  exit 1
fi

BUILD_BRANDING=$1
THE_KEY=$2

pushd $(dirname "${0}") > /dev/null
BUILD_DIR=$(pwd)
popd > /dev/null

TOP="${BUILD_DIR}/.."

case ${BUILD_BRANDING} in
  Chromium)
    BRANDING_FILE="${TOP}/chrome/app/theme/chromium/BRANDING"
    ;;
  Chrome)
    BRANDING_FILE="${TOP}/chrome/app/theme/google_chrome/BRANDING"
    ;;
  *)
    echo "error: unknown branding: ${BUILD_BRANDING}" >&2
    exit 1
    ;;
esac

BRANDING_VALUE=$(sed -n -e "s/^${THE_KEY}=\(.*\)\$/\1/p" "${BRANDING_FILE}")

if [ -z "${BRANDING_VALUE}" ] ; then
  echo "error: failed to find key '${THE_KEY}'" >&2
  exit 1
fi

echo "${BRANDING_VALUE}"
