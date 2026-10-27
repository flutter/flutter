// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
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

      final String encoded = jsonEncode(map);
      final parsed = ExtensionFlutterProject.fromJson(
        (jsonDecode(encoded) as Map<Object?, Object?>).cast<String, Object?>(),
      );
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

    test('constructor validates file:// directory URIs ending with slash', () {
      expect(Uri.directory('/path/to/my_app').isValidDirectoryUri, isTrue);
      expect(
        () => ExtensionFlutterProject(
          appName: 'my_app',
          buildDirectory: Uri.parse('https://example.com/my_app/build/'),
          directory: Uri.directory('/path/to/my_app'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExtensionFlutterProject(
          appName: 'my_app',
          buildDirectory: Uri.directory('/path/to/my_app/build'),
          directory: Uri.parse('https://example.com/my_app/'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExtensionFlutterProject(
          appName: 'my_app',
          buildDirectory: Uri.parse('file:///path/to/my_app/build'),
          directory: Uri.directory('/path/to/my_app'),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExtensionFlutterProject(
          appName: 'my_app',
          buildDirectory: Uri.directory('/path/to/my_app/build'),
          directory: Uri.parse('file:///path/to/my_app'),
        ),
        throwsArgumentError,
      );
    });

    test('throws FormatException on missing or invalid fields and non-directory URIs', () {
      const validBase = <String, Object?>{
        ExtensionFlutterProject.appNameKey: 'my_app',
        ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
        ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
      };

      for (final invalidJson in const <Map<String, Object?>>[
        <String, Object?>{},
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 123,
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'relative/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'https://example.com/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app/',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'relative/project/',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'file:///tmp/my_app',
        },
        <String, Object?>{
          ExtensionFlutterProject.appNameKey: 'my_app',
          ExtensionFlutterProject.buildDirectoryKey: 'file:///tmp/my_app/build/',
          ExtensionFlutterProject.directoryKey: 'https://example.com/my_app/',
        },
        <String, Object?>{...validBase, ExtensionFlutterProject.appVersionKey: 456},
        <String, Object?>{...validBase, ExtensionFlutterProject.dependenciesKey: 'not_a_list'},
        <String, Object?>{
          ...validBase,
          ExtensionFlutterProject.dependenciesKey: <Object?>['valid_dep', 99],
        },
        <String, Object?>{...validBase, ExtensionFlutterProject.isEmptyKey: 'true'},
        <String, Object?>{...validBase, ExtensionFlutterProject.isModuleKey: 1},
        <String, Object?>{...validBase, ExtensionFlutterProject.isPluginKey: 0},
        <String, Object?>{...validBase, ExtensionFlutterProject.workspaceKey: 'not_a_list'},
        <String, Object?>{
          ...validBase,
          ExtensionFlutterProject.workspaceKey: <Object?>['packages/a', false],
        },
      ]) {
        expect(() => ExtensionFlutterProject.fromJson(invalidJson), throwsFormatException);
      }
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
