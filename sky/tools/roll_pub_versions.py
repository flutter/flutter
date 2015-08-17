#!/usr/bin/env python
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import yaml


PUBSPECS = [
    'sky/packages/sky/pubspec.yaml',
    'sky/packages/sky_engine/pubspec.yaml',
    'sky/packages/sky_services/pubspec.yaml',
]

def increment_version(version):
    pieces = version.split('.')
    pieces[-1] = str(int(pieces[-1]) + 1)
    return '.'.join(pieces)


def sort_dict(unsorted):
    sorted_dict = collections.OrderedDict()
    for key in sorted(unsorted.keys()):
        sorted_dict[key] = unsorted[key]
    return sorted_dict


def count_commits(start, end):
    return subprocess.check_output([
        'git', 'rev-list', '%s...%s' % (start, end)]).count('\n')


def last_commit_to(file_path):
    return subprocess.check_output(['git', 'log', '-1', '--format=%h', file_path]).strip()


def update_pubspec(pubspec):
    # TODO(eseidel): This does not prserve any manual sort-order of the yaml.
    with open(pubspec, 'r') as stream:
        spec = yaml.load(stream)
        old_version = spec['version']
        spec['version'] = increment_version(old_version)
        print "%20s  %6s => %6s" % (spec['name'], old_version, spec['version'])

    with open(pubspec, 'w') as stream:
        yaml.dump(spec, stream=stream, default_flow_style=False)
    return spec['version']


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


def main():
    # Should chdir to the root directory.

    print 'Pub packages:'
    for pubspec in PUBSPECS:
        new_version = update_pubspec(pubspec)
        changelog = os.path.join(os.path.dirname(pubspec), 'CHANGELOG.md')
        update_changelog(changelog, pubspec, new_version)


if __name__ == '__main__':
    main()
