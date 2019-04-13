// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

final ArgParser argParser = ArgParser()..addFlag('ui', defaultsTo: false);

final String flutterRoot = Platform.environment['FLUTTER_ROOT'];
final String engineDirectory = path.join(flutterRoot, '..', 'engine', 'src', 'flutter', 'lib', 'stub_ui');
final String flutterPath = path.join(flutterRoot, 'packages', 'flutter');
final String flutterTestPath = path.join(flutterRoot, 'packages', 'flutter_test');
final String flutterDrivePath = path.join(flutterRoot, 'packages', 'flutter_drive');

final List<List<Pattern>> codePatterns = <List<Pattern>>[
  <Pattern>['import \'dart:ui\'', 'import \'package:flutter_web_ui/ui.dart\''],
  <Pattern>['export \'dart:ui\'', 'export \'package:flutter_web_ui/ui.dart\''],
  <Pattern>[
    'export \'bitfield.dart\' if (dart.library.html) \'bitfield_unsupported.dart\';',
    'export \'bitfield_unsupported.dart\';'
  ]
];

final List<List<Pattern>> configPatterns = <List<Pattern>>[
  <Pattern>[
'''
  sky_engine:
    sdk: flutter
''',
'''
  flutter_web_ui:
    path: $engineDirectory
'''
  ],
  <Pattern>[
'''
  flutter:
    sdk: flutter
''',
'''
  flutter:
    path: $flutterPath
'''
  ],
  <Pattern>[
'''
  flutter_driver:
    sdk: flutter
''',
'''
#  flutter_driver:
#    sdk: flutter
'''
  ],
  <Pattern>[
'''
  flutter_test:
    sdk: flutter
''',
'''
  flutter_test:
    path: $flutterTestPath
  build_runner: '>=0.8.10 <2.0.0'
  build_web_compilers: '>=0.3.6 <2.0.0'
'''
  ],
  <Pattern>[
r'''
  flutter_goldens:
    sdk: flutter
''',
r'''
#  flutter_goldens:
#    sdk: flutter
'''
  ],
];

void main(List<String> args) {
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw StateError('FLUTTER_ROOT must be set');
  }
  final ArgResults results = argParser.parse(args);
  final bool toUi = results['ui'];
  for (FileSystemEntity entity in Directory.current.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (toUi) {
        String contents = entity.readAsStringSync();
        for (List<Pattern> patterns in codePatterns) {
          contents = contents.replaceAll(patterns.last, patterns.first);
        }
        entity.writeAsStringSync(contents);
      } else {
        String contents = entity.readAsStringSync();
        for (List<Pattern> patterns in codePatterns) {
          contents = contents.replaceAll(patterns.first, patterns.last);
        }
        entity.writeAsStringSync(contents);
      }
    } else if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      if (toUi) {
        String contents = entity.readAsStringSync();
        for (List<Pattern> patterns in configPatterns) {
          contents = contents.replaceAll(patterns.last, patterns.first);
        }
        entity.writeAsStringSync(contents);
      } else {
        String contents = entity.readAsStringSync();
        for (List<Pattern> patterns in configPatterns) {
          contents = contents.replaceAll(patterns.first, patterns.last);
        }
        entity.writeAsStringSync(contents);
      }
    }
  }
}
