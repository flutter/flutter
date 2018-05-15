#!/usr/bin/python
# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Pulls down tools required to build flutter."""

import os
import subprocess
import sys

SRC_ROOT = (os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
BUILDTOOLS = os.path.join(SRC_ROOT, 'buildtools')
TOOLS_BUILDTOOLS = os.path.join(SRC_ROOT, 'tools', 'buildtools')

sys.path.insert(0, os.path.join(SRC_ROOT, 'tools'))
import find_depot_tools

DEPOT_PATH = find_depot_tools.add_depot_tools_to_path()


def Update():
    path = os.path.join(BUILDTOOLS, 'update.sh')
    return subprocess.call([
      '/bin/bash', path, '--ninja', '--gn', '--clang'], cwd=SRC_ROOT)


def UpdateOnWindows():
    sha1_file = os.path.join(TOOLS_BUILDTOOLS, 'win', 'gn.exe.sha1')
    output_dir = os.path.join(BUILDTOOLS, 'win', 'gn.exe')
    downloader_script = os.path.join(DEPOT_PATH, 'download_from_google_storage.py')
    download_cmd = [
      'python',
      downloader_script,
      '--no_auth',
      '--no_resume',
      '--quiet',
      '--platform=win*',
      '--bucket',
      'chromium-gn',
      '-s',
      sha1_file,
      '-o',
      output_dir
    ]
    return subprocess.call(download_cmd)


def main(argv):
    if sys.platform.startswith('win'):
        return UpdateOnWindows()
    return Update()


if __name__ == '__main__':
    sys.exit(main(sys.argv))
