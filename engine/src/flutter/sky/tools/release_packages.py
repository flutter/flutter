#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# See https://github.com/domokit/sky_engine/wiki/Release-process

import os
import subprocess
import sys


def main():
    engine_root = os.path.abspath('.')
    if not os.path.exists(os.path.join(engine_root, 'sky')):
        print "Cannot find //sky. Is %s the Flutter engine repository?" % engine_root
        return 1

    pub_path = os.path.join(engine_root, 'third_party/dart-sdk/dart-sdk/bin/pub')

    if args.publish:
        subprocess.check_call([pub_path, 'publish', '--force'], cwd=os.path.join(engine_root, 'sky/packages/sky'))
        subprocess.check_call([pub_path, 'publish', '--force'], cwd=os.path.join(engine_root, 'sky/packages/flx'))
        subprocess.check_call([pub_path, 'publish', '--force'], cwd=os.path.join(engine_root, 'skysprites'))


if __name__ == '__main__':
    sys.exit(main())
