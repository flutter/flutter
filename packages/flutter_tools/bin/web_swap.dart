// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

final ArgParser argParser = ArgParser()
  ..addFlag('back', help: 'Swap back to dart:ui from web_ui', defaultsTo: false);

/// Swap the dart:ui imports with web_ui for local development.
///
/// This is only intended as a temporary bridge to the new development
/// workflow and will be removed at a later time.
Future<void> main(List<String> arguments) async {
  final ArgResults results = argParser.parse(arguments);
  await runInContext(() {
    // Normally this is initialized by the command runner.
    Cache.flutterRoot = FlutterCommandRunner.defaultFlutterRoot;
    printError(
      'WARNING: This is only intended for use by flutter contributors.'
      ' Running this command will alter the code in your flutter checkout.'
    );
    final String engineDirectory = fs.path.join(Cache.flutterRoot, '..', 'engine', 'src', 'flutter', 'lib', 'stub_ui');
    final String flutterPath = fs.path.join(Cache.flutterRoot, 'packages', 'flutter');
    final String flutterTestPath = fs.path.join(Cache.flutterRoot, 'packages', 'flutter_test');
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

    final Iterable<File> searchFiles = <Directory>[
      fs.directory(fs.path.join(Cache.flutterRoot, 'packages')),
      fs.directory(fs.path.join(Cache.flutterRoot, 'examples')),
    ].expand((Directory directory) => directory.listSync(recursive: true))
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart') || file.path.endsWith('pubspec.yaml'));

    for (File file in searchFiles) {
      String contents = file.readAsStringSync();
      final List<List<Pattern>> patterns = file.path.endsWith('.dart')
          ? codePatterns
          : configPatterns;
      if (file.path.endsWith('.dart')) {
        for (List<Pattern> patterns in patterns) {
          contents = results['back']
              ? contents.replaceAll(patterns.last, patterns.first)
              : contents.replaceAll(patterns.first, patterns.last);
        }
        file.writeAsStringSync(contents);
      }
    }
  });
}