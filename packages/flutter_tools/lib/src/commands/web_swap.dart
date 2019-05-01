// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../cache.dart';
import '../runner/flutter_command.dart';

class WebSwapCommand extends FlutterCommand {
  WebSwapCommand() {
    argParser.addFlag('ui', help: 'Swap to dart:ui from web_ui', defaultsTo: false);
  }

  @override
  String get description => '(DANGEROUS) Swap dart:ui imports with web_ui for local development.';

  @override
  String get name => 'web-swap';

  @override
  bool get hidden => true;

  @override
  bool get isExperimental => true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  bool get swapToUi => argResults['ui'];

  @override
  Future<FlutterCommandResult> runCommand() {
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
          contents = swapToUi
              ? contents.replaceAll(patterns.last, patterns.first)
              : contents.replaceAll(patterns.first, patterns.last);
        }
        file.writeAsStringSync(contents);
      }
    }

    return null;
  }
}
