#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Script to download LLVM gold plugin from google storage."""

import json
import os
import shutil
import subprocess
import sys
import zipfile

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
CHROME_SRC = os.path.abspath(os.path.join(SCRIPT_DIR, os.pardir))
sys.path.insert(0, os.path.join(CHROME_SRC, 'tools'))

import find_depot_tools

DEPOT_PATH = find_depot_tools.add_depot_tools_to_path()
GSUTIL_PATH = os.path.join(DEPOT_PATH, 'gsutil.py')

LLVM_BUILD_PATH = os.path.join(CHROME_SRC, 'third_party', 'llvm-build',
                               'Release+Asserts')
CLANG_UPDATE_PY = os.path.join(CHROME_SRC, 'tools', 'clang', 'scripts',
                               'update.py')
CLANG_REVISION = os.popen(CLANG_UPDATE_PY + ' --print-revision').read().rstrip()

CLANG_BUCKET = 'gs://chromium-browser-clang/Linux_x64'

def main():
  targz_name = 'llvmgold-%s.tgz' % CLANG_REVISION
  remote_path = '%s/%s' % (CLANG_BUCKET, targz_name)

  os.chdir(LLVM_BUILD_PATH)

  subprocess.check_call(['python', GSUTIL_PATH,
                         'cp', remote_path, targz_name])
  subprocess.check_call(['tar', 'xzf', targz_name])
  os.remove(targz_name)
  return 0

if __name__ == '__main__':
  sys.exit(main())
