#!/usr/bin/env python
# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import json
import os
import sys

SDK_EXTRAS_JSON_FILE = os.path.join(os.path.dirname(__file__),
                                    'android_sdk_extras.json')

def main():
  with open(SDK_EXTRAS_JSON_FILE) as json_file:
    packages = json.load(json_file)

  out = []
  for package in packages:
    out.append(package['package_id'])

  print ','.join(out)

if __name__ == '__main__':
  sys.exit(main())
