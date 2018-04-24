// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/buildconfig_generator.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('BuildConfig class generator', () {
    Directory temp;

    setUp(() {
      Cache.disableLocking();
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<String> createMinimalProject(String manifest) async {
      final Directory directory = temp.childDirectory('simple_project');

      final Directory libDirectory = directory.childDirectory('lib');
      libDirectory.createSync(recursive: true);

      final File manifestFile = directory.childFile('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);

      return directory.path;
    }

    Future<void> checkGenerator({
      String manifest,
      BuildInfo buildInfo,
      List<String> expectedLines,
    }) async {
      final String projectPath = await createMinimalProject(manifest);

      await generateBuildConfigClassAtPath(buildInfo: buildInfo, projectPath: projectPath);

      final String srcFile = fs.path.join(projectPath, 'lib', 'build_config.g.dart');
      final CompilationUnit unit = parseDartFile(srcFile);
      final ClassDeclaration classDeclaration = unit.declarations.first;
      final NodeList<ClassMember> members = classDeclaration.members;

      for (String line in expectedLines) {
        expect(
          members.any((ClassMember field) => field.toString() == line),
          isTrue,
          reason: '\'$line\' not found in generated build_config.g.dart file',
        );
      }
    }

    testUsingContext('generate simple BuildConfig', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const BuildInfo buildInfo = const BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: 3);
      final List<String> expected = <String>[
        'static const bool kDebug = false;',
        'static const String kModeName = \'release\';',
        'static const String kVersionName = \'1.0.2\';',
        'static const int kVersionNumber = 3;'
      ];
      await checkGenerator(manifest: manifest, buildInfo: buildInfo, expectedLines: expected);
    });
  });
}
