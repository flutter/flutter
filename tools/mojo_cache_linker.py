#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import logging
import os
import sys
import subprocess

# TODO(eseidel): Share logic with tools/android_stack_parser/stack
def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(
        description='Builds a directory of app_id symlinks to symbols'
        ' to match expected dlopen names from mojo_shell\'s NetworkLoader.')
    parser.add_argument('links_dir', type=str)
    parser.add_argument('build_dir', type=str)
    args = parser.parse_args()

    if not os.path.isdir(args.links_dir):
        logging.fatal('links_dir: %s is not a directory' % args.links_dir)
        sys.exit(1)

    for name in os.listdir(args.build_dir):
        path = os.path.join(args.build_dir, name)
        if not os.path.isfile(path):
            continue

        # md5sum is slow, so only bother for suffixes we care about:
        basename, ext = os.path.splitext(name)
        if ext not in ('', '.mojo', '.so'):
            continue

        # Ignore ninja's dot-files.
        if basename.startswith('.'):
            continue

        # Example output:
        # f82a3551478a9a0e010adccd675053b9 png_viewer.mojo
        md5 = subprocess.check_output(['md5sum', path]).strip().split()[0]
        link_path = os.path.join(args.links_dir, '%s.mojo' % md5)

        lib_path = os.path.realpath(os.path.join(args.build_dir, name))

        # On android foo.mojo is stripped, but libfoo_library.so is not.
        if ext == '.mojo':
            symboled_name = 'lib%s_library.so' % basename
            symboled_path = os.path.realpath(
                os.path.join(args.build_dir, symboled_name))
            if os.path.exists(symboled_path):
                lib_path = symboled_path

        print "%s -> %s" % (link_path, lib_path)

        if os.path.lexists(link_path):
            logging.debug('link already exists %s, replacing' % lib_path)
            os.unlink(link_path)

        os.symlink(lib_path, link_path)

if __name__ == '__main__':
    main()
