#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

gradle updateDependencies

version_tag=`date +%Y-%m-%dT%T%z`

cipd create --pkg-def cipd.yaml -tag last_updated:"$version_tag"

echo ""
echo "Update the dependency in the DEPS file:"
echo ""
echo "'src/third_party/android_embedding_dependencies': {"
echo "  'packages': ["
echo "    {"
echo "      'package': 'flutter/android/embedding_bundle',"
echo "      'version': 'last_updated:$version_tag'"
echo "    }"
echo "  ],"
echo "  'condition': 'download_android_deps',"
echo "  'dep_type': 'cipd',"
echo "}"
echo ""
echo "Run gclient sync"
