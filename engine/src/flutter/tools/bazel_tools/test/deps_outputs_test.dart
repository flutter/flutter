// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:bazel_tools/bazel_tools.dart';
import 'package:test/test.dart';

void main() {
  final deps = DepsFile.parse(r'''
vars = {
  'flutter_git': 'https://flutter.googlesource.com',
  'skia_revision': 'abc',
  'download_emsdk': False,
}

gclient_gn_args_file = 'engine/src/flutter/third_party/dart/build/config/gclient_args.gni'
gclient_gn_args = ['download_emsdk']

deps = {
  'engine/src/flutter/third_party/skia': Var('flutter_git') + '/third_party/skia.git@' + Var('skia_revision'),
  'engine/src/flutter/third_party/skia/nested': 'https://example.com/nested.git@1',
  'engine/src/flutter/prebuilts/emsdk': {
    'url': 'https://example.com/emsdk.git@2',
    'condition': 'download_emsdk',
  },
  'engine/src/flutter/prebuilts/linux-x64/dart-sdk': {
    'packages': [
      {'package': 'dart/dart-sdk/${{platform}}', 'version': 'git_revision:def'},
    ],
    'dep_type': 'cipd',
    'condition': 'download_dart_sdk and host_os == "linux"',
  },
  'third_party/ninja': {
    'packages': [{'package': 'infra/3pp/tools/ninja/${{platform}}', 'version': 'version:3@1.12.1'}],
    'dep_type': 'cipd',
  },
}
''');

  group('generateDepsLock', () {
    final String lock = generateDepsLock(deps, generator: 'the-generator');

    test('starts with the license header and a DO NOT EDIT banner', () {
      expect(lock, startsWith(generatedFileLicenseHeader));
      expect(lock, contains('# DO NOT EDIT. Generated from //DEPS by the-generator.'));
    });

    test('emits sorted, buildifier-style Starlark dictionaries', () {
      expect(
        lock,
        contains('''
VARS = {
    "download_emsdk": False,
    "flutter_git": "https://flutter.googlesource.com",
    "skia_revision": "abc",
}
'''),
      );
      expect(
        lock,
        contains('''
GIT_DEPS = {
    "engine/src/flutter/prebuilts/emsdk": {
        "url": "https://example.com/emsdk.git",
        "revision": "2",
        "condition": "download_emsdk",
    },
    "engine/src/flutter/third_party/skia": {
        "url": "https://flutter.googlesource.com/third_party/skia.git",
        "revision": "abc",
    },
    "engine/src/flutter/third_party/skia/nested": {
        "url": "https://example.com/nested.git",
        "revision": "1",
    },
}
'''),
      );
      expect(
        lock,
        contains(r'''
CIPD_DEPS = {
    "engine/src/flutter/prebuilts/linux-x64/dart-sdk": {
        "packages": [
            {
                "package": "dart/dart-sdk/${platform}",
                "version": "git_revision:def",
            },
        ],
        "condition": "download_dart_sdk and host_os == \"linux\"",
    },
    "third_party/ninja": {
        "packages": [
            {
                "package": "infra/3pp/tools/ninja/${platform}",
                "version": "version:3@1.12.1",
            },
        ],
    },
}
'''),
      );
      expect(
        lock,
        contains('''
GCLIENT_GN_ARGS_FILE = "engine/src/flutter/third_party/dart/build/config/gclient_args.gni"

GCLIENT_GN_ARGS = [
    "download_emsdk",
]
'''),
      );
    });

    test('is deterministic', () {
      expect(generateDepsLock(deps, generator: 'the-generator'), lock);
    });
  });

  group('generateBazelignore', () {
    test('lists every dependency and extra directory, pruning nested paths', () {
      final String ignore = generateBazelignore(
        deps,
        generator: 'the-generator',
        extraDirectories: const <String>[
          'engine/src/out',
          'engine/src/flutter/prebuilts',
          'bin/cache',
        ],
      );
      expect(ignore, contains('# DO NOT EDIT. Generated from //DEPS by the-generator.'));
      final List<String> entries = ignore
          .split('\n')
          .where((String line) => line.isNotEmpty && !line.startsWith('#'))
          .toList();
      expect(entries, <String>[
        'bin/cache',
        // Covers prebuilts/emsdk and prebuilts/linux-x64/dart-sdk.
        'engine/src/flutter/prebuilts',
        // Covers third_party/skia/nested.
        'engine/src/flutter/third_party/skia',
        'engine/src/out',
        'third_party/ninja',
      ]);
    });

    test('uses the default extra directories', () {
      final String ignore = generateBazelignore(deps, generator: 'g');
      for (final String directory in defaultIgnoredDirectories) {
        expect(ignore.split('\n'), contains(directory));
      }
    });
  });
}
