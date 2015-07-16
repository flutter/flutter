#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import logging
import os
import sys
import subprocess
import json
import platform


def library_paths(build_dir):
    for name in os.listdir(build_dir):
        path = os.path.realpath(os.path.join(build_dir, name))
        if not os.path.isfile(path):
            continue

        # Only include suffixes we care about:
        basename, ext = os.path.splitext(name)
        if ext not in ('', '.mojo', '.so'):
            continue

        # Ignore ninja's dot-files.
        if basename.startswith('.'):
            continue
        yield path


def get_cached_app_id(path, cache, cache_mtime):
    if not cache_mtime:
        return None
    try:
        if os.path.getmtime(path) > cache_mtime:
            return None
    except:
        return None
    return cache.get(path)


def compute_path_to_app_id_map(paths, cache, cache_mtime):
    path_to_app_id_map = {}
    for path in paths:
        app_id = get_cached_app_id(path, cache, cache_mtime)
        if not app_id:
            if platform.system() == 'Darwin':
                logging.info('shasum -a 256 %s' % path)
                output = subprocess.check_output(['shasum', '-a', '256', path])
            else:
                logging.info('sha256sum %s' % path)
                output = subprocess.check_output(['sha256sum', path])
            # Example output:
            # f82a3551478a9a0e010adccd675053b9 png_viewer.mojo
            app_id = output.strip().split()[0]
        path_to_app_id_map[path] = app_id
    return path_to_app_id_map


def read_app_id_cache(cache_path):
    try:
        with open(cache_path, 'r') as cache_file:
            return json.load(cache_file), os.path.getmtime(cache_path)
    except:
        logging.warn('Failed to read file: %s' % cache_path)
        return {}, None


def write_app_id_cache(cache_path, cache):
    try:
        with open(cache_path, 'w') as cache_file:
            json.dump(cache, cache_file, indent=2, sort_keys=True)
    except:
        logging.warn('Failed to write file: %s' % cache_path)


# TODO(eseidel): Share logic with tools/android_stack_parser/stack
def main():
    logging.basicConfig(level=logging.WARN)
    parser = argparse.ArgumentParser(
        description='Builds a directory of app_id symlinks to symbols'
        ' to match expected dlopen names from mojo_shell\'s NetworkLoader.')
    parser.add_argument('links_dir', type=str)
    parser.add_argument('build_dir', type=str)
    parser.add_argument('-f', '--force', action='store_true')
    parser.add_argument('-v', '--verbose', action='store_true')
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.INFO)

    if not os.path.isdir(args.links_dir):
        logging.fatal('links_dir: %s is not a directory' % args.links_dir)
        sys.exit(1)

    # Some of the .so files are 100s of megabytes.  Cache the md5s to save time.
    cache_path = os.path.join(args.build_dir, '.app_id_cache')
    cache, cache_mtime = read_app_id_cache(cache_path)
    if args.force:
        cache_mtime = None

    paths = library_paths(args.build_dir)
    path_to_app_id_map = compute_path_to_app_id_map(list(paths),
        cache, cache_mtime)

    # The cache contains unmodified app-ids.
    write_app_id_cache(cache_path, path_to_app_id_map)

    for path, app_id in path_to_app_id_map.items():
        basename = os.path.basename(path)
        root_name, ext = os.path.splitext(basename)

        # On android foo.mojo is stripped, but libfoo_library.so is not.
        if ext == '.mojo':
            symboled_name = 'lib%s_library.so' % root_name
            symboled_path = os.path.realpath(
                os.path.join(args.build_dir, symboled_name))
            if os.path.exists(symboled_path):
                path = symboled_path

        link_path = os.path.join(args.links_dir, '%s.mojo' % app_id)

        logging.info("%s -> %s" % (link_path, path))

        if os.path.lexists(link_path):
            logging.debug('link already exists %s, replacing' % path)
            os.unlink(link_path)

        os.symlink(path, link_path)


if __name__ == '__main__':
    main()
