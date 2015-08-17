#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import xml.etree.ElementTree as ET
import argparse


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


def count_commits(start, end):
    return subprocess.check_output([
        'git', 'rev-list', '%s...%s' % (start, end)]).count('\n')


def last_commit_to(file_path):
    return subprocess.check_output(['git', 'log', '-1', '--format=%h', file_path]).strip()


def update_changelog(changelog, pubspec, version):
    old = last_commit_to(pubspec)
    new = last_commit_to('.')
    url = "https://github.com/domokit/mojo/compare/%s...%s" % (old, new)
    count = count_commits(old, new)
    message = """## %s

  - %s changes: %s

""" % (version, count, url)
    prepend_to_file(message, changelog)


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


def main():
    # Should chdir to the root directory.
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest')
    args = parser.parse_args()

    # TODO(eseidel): Without this ET uses 'ns0' for 'android' which is wrong.
    ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')

    update_manifest(args.manifest)


if __name__ == '__main__':
    main()
