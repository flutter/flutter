#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import logging
import os
import re
import skypy.paths
import subprocess
import sys

SRC_ROOT = skypy.paths.Paths('ignored').src_root
ADB_PATH = os.path.join(SRC_ROOT,
    'third_party/android_tools/sdk/platform-tools/adb')


# TODO(eseidel): This should be shared with adb_gdb
def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(
        description='Pull all libraries used by a pid on android into a cache.')
    parser.add_argument('cache_root', type=str)
    parser.add_argument('pid', type=int)
    args = parser.parse_args()

    if not os.path.exists(args.cache_root):
        os.makedirs(args.cache_root)

    subprocess.check_call([ADB_PATH, 'root'])

    # TODO(eseidel): Check the build.props, or find some way to avoid
    # re-pulling every library every time.  adb_gdb has code to do this
    # but doesn't seem to notice when the set of needed libraries changed.

    library_regexp = re.compile(r'(?P<library_path>/system/.*\.so)')
    cat_maps_cmd = [ADB_PATH, 'shell', 'cat', '/proc/%s/maps' % args.pid]
    maps_lines = subprocess.check_output(cat_maps_cmd).strip().split('\n')
    # adb shell doesn't return the return code from the shell?
    if not maps_lines or 'No such file or directory' in maps_lines[0]:
        print 'Failed to get maps for pid %s on device.' % args.pid
        sys.exit(1)

    def library_from_line(line):
        result = library_regexp.search(line)
        if not result:
            return None
        return result.group('library_path')

    dev_null = open(os.devnull, 'w')  # Leaking.
    to_pull = set(filter(None, map(library_from_line, maps_lines)))
    to_pull.add('/system/bin/linker')  # Unclear why but adb_gdb pulls this too.
    for library_path in sorted(to_pull):
        # Not using os.path.join since library_path is absolute.
        dest_file = os.path.normpath("%s/%s" % (args.cache_root, library_path))
        dest_dir = os.path.dirname(dest_file)
        if not os.path.exists(dest_dir):
            os.makedirs(dest_dir)
        print '%s -> %s' % (library_path, dest_file)
        pull_cmd = [ADB_PATH, 'pull', library_path, dest_file]
        subprocess.check_call(pull_cmd, stderr=dev_null)


if __name__ == '__main__':
    main()
