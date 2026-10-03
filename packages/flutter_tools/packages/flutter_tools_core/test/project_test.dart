// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionFlutterProject', () {
    test('serializes and deserializes correctly with all fields', () {
      final project = ExtensionFlutterProject(
        appName: 'my_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.2.3+4',
        dependencies: const <String>{'flutter', 'http'},
        isEmpty: true,
        isModule: true,
        isPlugin: true,
        workspace: const <String>['packages/pkg_a', 'packages/pkg_b'],
      );

      final Map<String, Object?> map = project.toMap();
      expect(map[ExtensionFlutterProject.appNameKey], 'my_app');
      expect(map[ExtensionFlutterProject.appVersionKey], '1.2.3+4');
      expect(map[ExtensionFlutterProject.buildDirectoryKey], 'file:///path/to/my_app/build/');
      expect(map[ExtensionFlutterProject.dependenciesKey], <String>['flutter', 'http']);
      expect(map[ExtensionFlutterProject.directoryKey], 'file:///path/to/my_app/');
      expect(map[ExtensionFlutterProject.isEmptyKey], isTrue);
      expect(map[ExtensionFlutterProject.isModuleKey], isTrue);
      expect(map[ExtensionFlutterProject.isPluginKey], isTrue);
      expect(map[ExtensionFlutterProject.workspaceKey], <String>[
        'packages/pkg_a',
        'packages/pkg_b',
      ]);

      final parsed = ExtensionFlutterProject.fromJson(map);
      expect(parsed, equals(project));
      expect(parsed.hashCode, equals(project.hashCode));
      expect(parsed.toString(), contains('my_app'));
      expect(parsed.toString(), contains('1.2.3+4'));
    });

    test('deserializes correctly with minimal fields and default values', () {
      final minimalJson = <String, Object?>{
        ExtensionFlutterProject.appNameKey: 'minimal_app',
        ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/minimal_app/build/',
        ExtensionFlutterProject.directoryKey: 'file:///tmp/minimal_app/',
      };

      final project = ExtensionFlutterProject.fromJson(minimalJson);
      expect(project.appName, 'minimal_app');
      expect(project.appVersion, isNull);
      expect(project.buildDirectory, Uri.parse('file:///tmp/minimal_app/build/'));
      expect(project.dependencies, isEmpty);
      expect(project.directory, Uri.parse('file:///tmp/minimal_app/'));
      expect(project.isEmpty, isFalse);
      expect(project.isModule, isFalse);
      expect(project.isPlugin, isFalse);
      expect(project.workspace, isEmpty);

      final Map<String, Object?> map = project.toMap();
      expect(map.containsKey(ExtensionFlutterProject.appVersionKey), isFalse);
      expect(map[ExtensionFlutterProject.dependenciesKey], isEmpty);
      expect(map[ExtensionFlutterProject.workspaceKey], isEmpty);
    });

    test('handles missing or malformed JSON fields gracefully', () {
      final malformedJson = <String, Object?>{
        ExtensionFlutterProject.appNameKey: 123,
        ExtensionFlutterProject.appVersionKey: 456,
        ExtensionFlutterProject.buildDirectoryKey: null,
        ExtensionFlutterProject.dependenciesKey: <Object?>['valid_dep', 99, null],
        ExtensionFlutterProject.directoryKey: 789,
        ExtensionFlutterProject.isEmptyKey: 'true',
        ExtensionFlutterProject.isModuleKey: 1,
        ExtensionFlutterProject.isPluginKey: null,
        ExtensionFlutterProject.workspaceKey: <Object?>['packages/a', false, null],
      };

      final project = ExtensionFlutterProject.fromJson(malformedJson);
      expect(project.appName, '');
      expect(project.appVersion, isNull);
      expect(project.buildDirectory, Uri());
      expect(project.dependencies, <String>{'valid_dep'});
      expect(project.directory, Uri());
      expect(project.isEmpty, isFalse);
      expect(project.isModule, isFalse);
      expect(project.isPlugin, isFalse);
      expect(project.workspace, <String>['packages/a']);
    });

    test('equality and hashCode compare Set and List contents properly', () {
      final base = ExtensionFlutterProject(
        appName: 'my_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.0.0',
        dependencies: const <String>{'a', 'b'},
        workspace: const <String>['pkg1', 'pkg2'],
      );
      final sameWithReorderedSet = ExtensionFlutterProject(
        appName: 'my_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.0.0',
        dependencies: const <String>{'b', 'a'},
        workspace: const <String>['pkg1', 'pkg2'],
      );
      final differentWorkspaceOrder = ExtensionFlutterProject(
        appName: 'my_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.0.0',
        dependencies: const <String>{'a', 'b'},
        workspace: const <String>['pkg2', 'pkg1'],
      );
      final differentDependencies = ExtensionFlutterProject(
        appName: 'my_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.0.0',
        dependencies: const <String>{'a', 'c'},
        workspace: const <String>['pkg1', 'pkg2'],
      );
      final differentAppName = ExtensionFlutterProject(
        appName: 'other_app',
        buildDirectory: Uri.directory('/path/to/my_app/build'),
        directory: Uri.directory('/path/to/my_app'),
        appVersion: '1.0.0',
        dependencies: const <String>{'a', 'b'},
        workspace: const <String>['pkg1', 'pkg2'],
      );

      expect(base, equals(sameWithReorderedSet));
      expect(base.hashCode, equals(sameWithReorderedSet.hashCode));
      expect(base, isNot(equals(differentWorkspaceOrder)));
      expect(base, isNot(equals(differentDependencies)));
      expect(base, isNot(equals(differentAppName)));
      expect(base.hashCode, isNot(equals(differentAppName.hashCode)));
    });
  });
}
