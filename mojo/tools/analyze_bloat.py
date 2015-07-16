#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import logging
import os
import re
import subprocess
import sys

from mopy.paths import Paths

ANDROID_TOOLS_DIR = ('third_party/android_tools/ndk/toolchains/' +
    'arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin')

def binaries(path):
    for item in os.listdir(path):
        match = re.match(r'^(\w+)\.mojo$', item)
        if match:
            name = match.group(1)
            if name.endswith('apptests'):
                continue
            binary = os.path.join(path, 'lib%s_library.so' % name)
            if os.path.exists(binary):
                yield name, binary

def check_deps():
    success = True
    if not os.path.exists('bloat'):
        print ("Can't find bloat.py. Did you " +
            "'git clone https://github.com/martine/bloat.git' ?")
        success = False
    if not os.path.exists('webtreemap'):
        print ("Can't find webtreemap. Did you " +
            "'git clone https://github.com/martine/webtreemap.git' ?")
        success = False
    if not success:
        sys.exit(1)

def main():
    logging.basicConfig(level=logging.WARN)
    parser = argparse.ArgumentParser(description='Dump bloat treeview.')
    args = parser.parse_args()
    check_deps()

    # Always use android release?
    rel_build_dir = os.path.join('out', 'android_Release')
    src_root = Paths().src_root
    build_dir = os.path.join(src_root, rel_build_dir)

    tools_dir = os.path.join(src_root, ANDROID_TOOLS_DIR)
    tools_prefix = 'arm-linux-androideabi-'

    nm = os.path.join(tools_dir, tools_prefix + 'nm')
    objdump = os.path.join(tools_dir, tools_prefix + 'objdump')

    for name, binary in binaries(build_dir):
        print 'Analyzing', name

        nm_path = name + '.nm'
        objdump_path = name + '.objdump'
        json_path = name + '.json'
        html_path = name + '.html'

        with open(nm_path, 'w') as nm_file:
            args = [nm, '-C', '-S', '-l', binary]
            subprocess.check_call(args, stdout=nm_file)

        with open(objdump_path, 'w') as objdump_file:
            subprocess.check_call([objdump, '-h', binary], stdout=objdump_file)

        with open(json_path, 'w') as json_file:
            subprocess.check_call([
                sys.executable,
                'bloat/bloat.py',
                '--nm-output=' + nm_path,
                '--objdump-output=' + objdump_path,
                '--strip-prefix=' + src_root + '/',
                'syms'
            ], stdout=json_file)

        source = None
        with open('bloat/index.html', 'r') as source_file:
            source = source_file.read().replace('bloat.json', json_path)

        with open(html_path, 'w') as html_file:
            html_file.write(source)


if __name__ == '__main__':
    main()
