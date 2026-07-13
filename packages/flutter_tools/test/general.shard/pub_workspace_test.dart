// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../src/common.dart';

void main() {
  const FileSystem fs = LocalFileSystem();
  final String flutterToolsRoot = path.join(getFlutterRoot(), 'packages', 'flutter_tools');
  const expectedWorkspaceMembers = <String>[
    'packages/flutter_tools_core',
    'packages/flutter_tools_extension',
    'packages/flutter_tools_extension_linux_prototype',
  ];

  group('Flutter Tools Pub Workspace', () {
    testWithoutContext('root pubspec.yaml declares all sub-packages in workspace', () {
      final File pubspecFile = fs.file(path.join(flutterToolsRoot, 'pubspec.yaml'));
      expect(pubspecFile.existsSync(), isTrue);

      final Object? yamlContent = loadYaml(pubspecFile.readAsStringSync());
      expect(yamlContent, isA<YamlMap>());
      final yamlMap = yamlContent! as YamlMap;

      expect(yamlMap.containsKey('workspace'), isTrue);
      final List<String> workspaceList = (yamlMap['workspace'] as YamlList).cast<String>().toList();

      for (final member in expectedWorkspaceMembers) {
        expect(
          workspaceList,
          contains(member),
          reason: 'Expected workspace to include $member',
        );
      }
    });

    testWithoutContext('member pubspec.yaml files declare workspace resolution', () {
      for (final member in expectedWorkspaceMembers) {
        final File memberPubspec = fs.file(path.join(flutterToolsRoot, member, 'pubspec.yaml'));
        expect(
          memberPubspec.existsSync(),
          isTrue,
          reason: 'Expected pubspec.yaml to exist for $member',
        );

        final Object? yamlContent = loadYaml(memberPubspec.readAsStringSync());
        expect(yamlContent, isA<YamlMap>());
        final yamlMap = yamlContent! as YamlMap;

        expect(
          yamlMap['resolution'],
          equals('workspace'),
          reason: 'Expected $member to declare resolution: workspace',
        );
      }
    });
  });
}
