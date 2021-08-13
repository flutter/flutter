#!/usr/bin/env python3.8
"""Creats a Python zip archive for the input main source."""

# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import shutil
import sys
import zipapp


def main():
    parser = argparse.ArgumentParser(
        'Creates a Python zip archive for the input main source')

    parser.add_argument(
        '--target_name',
        help='Name of the build target',
        required=True,
    )

    parser.add_argument(
        '--main_source',
        help='Path to the source containing the main function',
        required=True,
    )
    parser.add_argument(
        '--main_callable',
        help=
        'Name of the the main callable, that is the entry point of the generated archive',
        required=True,
    )

    parser.add_argument(
        '--gen_dir',
        help='Path to gen directory, used to stage temporary directories',
        required=True,
    )
    parser.add_argument('--output', help='Path to output', required=True)

    parser.add_argument(
        '--sources',
        help='Sources of this target, including main source',
        nargs='*',
    )
    parser.add_argument(
        '--library_infos',
        help='Path to the library infos JSON file',
        type=argparse.FileType('r'),
        required=True,
    )
    parser.add_argument(
        '--depfile',
        help='Path to the depfile to generate',
        type=argparse.FileType('w'),
        required=True,
    )

    args = parser.parse_args()

    infos = json.load(args.library_infos)

    # Temporary directory to stage the source tree for this python binary,
    # including sources of itself and all the libraries it imports.
    #
    # It is possible to have multiple python_binaries in the same directory, so
    # using target name, which should be unique in the same directory, to
    # distinguish between them.
    app_dir = os.path.join(args.gen_dir, args.target_name)
    os.makedirs(app_dir, exist_ok=True)

    # Copy over the sources of this binary.
    for source in args.sources:
        basename = os.path.basename(source)
        if basename == '__main__.py':
            print(
                '__main__.py in sources of python_binary is not supported, see https://fxbug.dev/73576',
                file=sys.stderr,
            )
            return 1
        dest = os.path.join(app_dir, basename)
        shutil.copy2(source, dest)

    # For writing a depfile.
    files_to_copy = []
    # Make sub directories for all libraries and copy over their sources.
    for info in infos:
        dest_lib_root = os.path.join(app_dir, info['library_name'])
        os.makedirs(dest_lib_root, exist_ok=True)

        src_lib_root = info['source_root']
        # Sources are relative to library root.
        for source in info['sources']:
            src = os.path.join(src_lib_root, source)
            dest = os.path.join(dest_lib_root, source)
            # Make sub directories if necessary.
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            files_to_copy.append(src)
            shutil.copy2(src, dest)

    args.depfile.write('{}: {}\n'.format(args.output, ' '.join(files_to_copy)))

    # Main module is the main source without its extension.
    main_module = os.path.splitext(os.path.basename(args.main_source))[0]
    # Manually create a __main__.py file for the archive, instead of using the
    # `main` parameter from `create_archive`. This way we can import everything
    # from the main module (create_archive only `import pkg`), which is
    # necessary for including all test cases for unit tests.
    #
    # TODO(https://fxbug.dev/73576): figure out another way to support unit
    # tests when users need to provide their own custom __main__.py.
    main_file = os.path.join(app_dir, "__main__.py")
    with open(main_file, 'w') as f:
        f.write(
            f'''
import sys
from {main_module} import *

sys.exit({args.main_callable}())
''')

    zipapp.create_archive(
        app_dir,
        target=args.output,
        interpreter='/usr/bin/env python3.8',
        compressed=True,
    )

    # Manually remove the temporary app directory and all the files, instead of
    # using shutil.rmtree. rmtree records reads on directories which throws off
    # the action tracer.
    for root, dirs, files in os.walk(app_dir, topdown=False):
        for file in files:
            os.remove(os.path.join(root, file))
        for dir in dirs:
            os.rmdir(os.path.join(root, dir))
    os.rmdir(app_dir)


if __name__ == '__main__':
    sys.exit(main())
