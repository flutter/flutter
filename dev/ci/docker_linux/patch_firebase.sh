#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

FIREBASE_CMD_LOC=$(which firebase)
NODE_DIR=$(dirname $(dirname $FIREBASE_CMD_LOC))
echo "Node directory is located at $NODE_DIR"

UPLOADER_FILE="$NODE_DIR""/lib/node_modules/firebase-tools/lib/deploy/hosting/uploader.js"
echo "File to modify is $UPLOADER_FILE"

REPLACE='s#populateBatchSize || 1000;#populateBatchSize || 100;#'
echo "Going to replace with $REPLACE"
sed -i "$REPLACE" "$UPLOADER_FILE"
