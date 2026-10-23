#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Writes a package_config.json over the packages given (pub_package_config, pub.bzl).

Each `--package name=<pubspec to read>=<pubspec's path in the layout>` is a
package whose root is the pubspec's directory; the root URI written is that
directory relative to the configuration's own place in the layout
(`--output-location`), so the file is right where the layout puts it (an
action's execroot or a test's runfiles tree) and nowhere else. The language
version is the lower bound of the pubspec's SDK constraint, as pub derives it
(`environment: sdk: ">=3.6.0 <4.0.0"` or `^3.6.0` gives 3.6).
"""

import argparse
import json
import os
import re
import sys

# A constraint's lower bound: `>=3.6.0`, `^3.6.0-0`, or a bare `3.6.0`.
_LOWER_BOUND = re.compile(r'(?:>=|\^)?\s*(\d+)\.(\d+)')
_SDK_LINE = re.compile(r'^\s*sdk\s*:\s*(.+?)\s*$')

# Pub's default for a pubspec with no SDK constraint (its own fallback).
_DEFAULT_LANGUAGE_VERSION = '2.12'


def language_version(pubspec_path):
  """The language version a pubspec's SDK constraint implies."""
  in_environment = False
  with open(pubspec_path, encoding='utf-8') as f:
    for line in f:
      stripped = line.rstrip('\n')
      if not stripped.strip() or stripped.lstrip().startswith('#'):
        continue
      indent = len(stripped) - len(stripped.lstrip())
      if indent == 0:
        in_environment = stripped.startswith('environment:')
        # `environment: {sdk: ...}` on one line.
        if in_environment and '{' in stripped:
          match = _LOWER_BOUND.search(stripped.split('sdk', 1)[1]) if 'sdk' in stripped else None
          if match:
            return '%s.%s' % (match.group(1), match.group(2))
        continue
      if in_environment:
        match = _SDK_LINE.match(stripped)
        if match:
          value = match.group(1).strip().strip('"').strip("'")
          bound = _LOWER_BOUND.search(value)
          if bound:
            return '%s.%s' % (bound.group(1), bound.group(2))
  return _DEFAULT_LANGUAGE_VERSION


def main():
  parser = argparse.ArgumentParser(description=__doc__.split('\n', maxsplit=1)[0])
  parser.add_argument('--output', required=True)
  parser.add_argument(
      '--output-location', required=True, help="the configuration's path in the layout"
  )
  parser.add_argument('--layout', required=True, choices=['execroot', 'runfiles'])
  parser.add_argument(
      '--package',
      action='append',
      default=[],
      help='name=<pubspec to read>=<pubspec in the layout>'
  )
  options = parser.parse_args()

  config_dir = os.path.dirname(options.output_location)
  packages = []
  seen = set()
  for entry in options.package:
    name, read_path, layout_path = entry.split('=', 2)
    if name in seen:
      sys.exit('package_config.py: package %s given twice' % name)
    seen.add(name)
    root = os.path.dirname(layout_path)
    packages.append({
        'name': name,
        'rootUri': os.path.relpath(root, config_dir) if root else '.',
        'packageUri': 'lib/',
        'languageVersion': language_version(read_path),
    })
  packages.sort(key=lambda p: p['name'])
  with open(options.output, 'w', encoding='utf-8') as f:
    json.dump(
        {
            'configVersion': 2,
            'packages': packages,
            'generator': 'pub_package_config (engine/src/flutter/build/bazel/dart/pub.bzl)',
        },
        f,
        indent=2,
    )
    f.write('\n')
  return 0


if __name__ == '__main__':
  sys.exit(main())
