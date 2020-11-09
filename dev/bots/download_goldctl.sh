#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git ./depot_tools
cd depot_tools
echo -e '# Ensure File\n$ServiceURL https://chrome-infra-packages.appspot.com\n\n# Skia Gold Client goldctl\nskia/tools/goldctl/${platform} git_revision:b57f561ad4ad624bd399b8b7b500aa1955276d41' > ensure.txt
./cipd ensure -ensure-file ./ensure.txt -root .
