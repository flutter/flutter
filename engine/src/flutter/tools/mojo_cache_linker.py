#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import logging
import os
import re
import sys

# TODO(eseidel): This should be shared with tools/android_stack_parser/stack
# TODO(eseidel): This could be replaced by using build-ids on Android
# TODO(eseidel): mojo_shell should write out a cache mapping file.
def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(
        description='Watches mojo_shell logcat output and builds a directory '
        'of symlinks to symboled binaries for seen cache names.')
    parser.add_argument('links_dir', type=str)
    parser.add_argument('symbols_dir', type=str)
    parser.add_argument('base_url', type=str)
    args = parser.parse_args()

    regex = re.compile('Caching mojo app (?P<url>\S+) at (?P<path>\S+)')

    if not os.path.isdir(args.links_dir):
        logging.fatal('links_dir: %s is not a directory' % args.links_dir)
        sys.exit(1)

    for line in sys.stdin:
        result = regex.search(line)
        if not result:
            continue

        url = result.group('url')
        if not url.startswith(args.base_url):
            logging.debug('%s does not match base %s' % (url, args.base_url))
            continue
        full_name = os.path.basename(url)
        name, ext = os.path.splitext(full_name)
        if ext != '.mojo':
            logging.debug('%s is not a .mojo library' % url)
            continue

        symboled_name = 'lib%s_library.so' % name
        cache_link_path = os.path.join(args.links_dir,
            os.path.basename(result.group('path')))
        symboled_path = os.path.realpath(
            os.path.join(args.symbols_dir, symboled_name))
        if not os.path.isfile(symboled_path):
            logging.warn('symboled path %s does not exist' % symboled_path)
            continue

        print "%s -> %s" % (cache_link_path, symboled_path)

        if os.path.lexists(cache_link_path):
            logging.debug('link already exists %s, replacing' % symboled_path)
            os.unlink(cache_link_path)

        os.symlink(symboled_path, cache_link_path)

if __name__ == '__main__':
    main()
