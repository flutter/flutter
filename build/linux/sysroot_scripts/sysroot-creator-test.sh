#!/bin/sh
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Rudimentry test suite for sysroot-creator.

SCRIPT_DIR=$(dirname $0)

set -o errexit

TestUpdateAllLists() {
  echo "[ RUN      ] TestUpdateAllLists"
  "$SCRIPT_DIR/sysroot-creator-trusty.sh" UpdatePackageListsAmd64
  "$SCRIPT_DIR/sysroot-creator-trusty.sh" UpdatePackageListsI386
  "$SCRIPT_DIR/sysroot-creator-trusty.sh" UpdatePackageListsARM
  "$SCRIPT_DIR/sysroot-creator-wheezy.sh" UpdatePackageListsAmd64
  "$SCRIPT_DIR/sysroot-creator-wheezy.sh" UpdatePackageListsI386
  "$SCRIPT_DIR/sysroot-creator-wheezy.sh" UpdatePackageListsARM
  echo "[      OK  ]"
}

TestUpdateAllLists
