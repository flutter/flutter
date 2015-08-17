#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import subprocess
import xml.etree.ElementTree as ET


MANIFEST_PREFACE = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Copyright 2015 The Chromium Authors. All rights reserved.
     Use of this source code is governed by a BSD-style license that can be
     found in the LICENSE file.
 -->
'''


def increment_version(version):
    pieces = version.split('.')
    pieces[-1] = str(int(pieces[-1]) + 1)
    return '.'.join(pieces)


def prepend_to_file(to_prepend, filepath):
    with open(filepath, 'r+') as f:
        content = f.read()
        f.seek(0, 0)
        f.write(to_prepend + content)


def update_manifest(manifest):
    VERSION_CODE = '{http://schemas.android.com/apk/res/android}versionCode'
    VERSION_NAME = '{http://schemas.android.com/apk/res/android}versionName'
    tree = ET.parse(manifest)
    root = tree.getroot()
    package_name = root.get('package')
    old_code = root.get(VERSION_CODE)
    old_name = root.get(VERSION_NAME)
    root.set(VERSION_CODE, increment_version(old_code))
    root.set(VERSION_NAME, increment_version(old_name))
    print "%20s  %6s (%s) => %6s (%s)" % (package_name, old_name, old_code,
        root.get(VERSION_NAME), root.get(VERSION_CODE))
    # TODO(eseidel): This isn't smart enough to wrap/intent multi-attribute
    # elements like <manifest> as is the typical AndroidManifiest.xml style
    # we could write our own custom prettyprinter to do that?
    tree.write(manifest)
    prepend_to_file(MANIFEST_PREFACE, manifest)
    return root.get(VERSION_NAME)


def main():
    # Should chdir to the root directory.
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest')
    args = parser.parse_args()

    # TODO(eseidel): Without this ET uses 'ns0' for 'android' which is wrong.
    ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')

    new_version = update_manifest(args.manifest)
    notes_dir = os.path.join(os.path.dirname(args.manifest), 'release_notes')
    release_notes = os.path.join(notes_dir, '%s.txt' % new_version)
    # FIXME: We could open an editor for the release notes and prepopulate
    # it with the changes url like how we do for pubspec CHANGELOG.md files.
    print "Please update %s in this commit." % release_notes


if __name__ == '__main__':
    main()
