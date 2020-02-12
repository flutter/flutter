#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

if [[ -z $OPEN_JDK_URL ]]; then
  exit 0
fi

mkdir -p $HOME/Java
pushd $HOME/Java
curl -L $OPEN_JDK_URL --output open_jdk.tar.gz
tar -xvf open_jdk.tar.gz
rm open_jdk.tar.gz
popd
