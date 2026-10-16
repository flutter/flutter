// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('HostPlatform', () {
    test('cliName and fromName round-trip', () {
      for (final HostPlatform platform in HostPlatform.values) {
        expect(HostPlatform.fromName(platform.cliName), platform);
        expect(HostPlatform.fromName(platform.name), platform);
        expect(HostPlatform.tryFromName(platform.cliName), platform);
      }
      expect(HostPlatform.linux_x64.cliName, 'linux-x64');
      expect(HostPlatform.darwin_arm64.platformName, 'arm64');
      expect(HostPlatform.linux_riscv64.platformName, 'riscv64');
      expect(HostPlatform.tryFromName('invalid-platform'), isNull);
      expect(() => HostPlatform.fromName('invalid-platform'), throwsArgumentError);
    });
  });

  group('ArtifactDependency', () {
    test('serializes and deserializes correctly with all fields', () {
      final dep = ArtifactDependency(
        name: 'custom-engine-bin',
        sha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        url: Uri.parse('https://example.com/artifacts/engine.zip'),
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> json = dep.toMap();
      expect(json, <String, Object?>{
        'name': 'custom-engine-bin',
        'url': 'https://example.com/artifacts/engine.zip',
        'sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'hostPlatform': 'linux-x64',
        'targetPlatform': 'linux-x64',
      });

      final deserialized = ArtifactDependency.fromJson(json);
      expect(deserialized, equals(dep));
      expect(deserialized.hashCode, equals(dep.hashCode));
      expect(
        deserialized.toString(),
        'ArtifactDependency(name: custom-engine-bin, '
        'url: https://example.com/artifacts/engine.zip, '
        'sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855, '
        'hostPlatform: HostPlatform.linux_x64, targetPlatform: linux-x64)',
      );
    });

    test('serializes and deserializes without optional platforms', () {
      final dep = ArtifactDependency(
        name: 'common-data',
        sha256: 'abc123456',
        url: Uri.parse('https://example.com/data.bin'),
      );

      final Map<String, Object?> json = dep.toMap();
      expect(json.containsKey('hostPlatform'), isFalse);
      expect(json.containsKey('targetPlatform'), isFalse);

      final deserialized = ArtifactDependency.fromJson(json);
      expect(deserialized, equals(dep));
      expect(deserialized.hostPlatform, isNull);
      expect(deserialized.targetPlatform, isNull);
    });

    test('listFromJson parses valid entries and returns empty list on non-list', () {
      final List<ArtifactDependency> list = ArtifactDependency.listFromJson(<Object?>[
        <String, Object?>{'name': 'a', 'url': 'https://example.com/a.zip', 'sha256': '111'},
      ]);
      expect(list, hasLength(1));
      expect(list.first.name, 'a');
      expect(ArtifactDependency.listFromJson(null), isEmpty);
    });

    test('throws ArgumentError on invalid JSON', () {
      expect(() => ArtifactDependency.fromJson(const <String, Object?>{}), throwsArgumentError);
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': ':::not_a_valid_uri:::',
          'sha256': '123',
        }),
        throwsArgumentError,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'relative/path/without/scheme.zip',
          'sha256': '123',
        }),
        throwsArgumentError,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': '123',
          'hostPlatform': 'invalid-host',
        }),
        throwsArgumentError,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': '123',
          'targetPlatform': 42,
        }),
        throwsArgumentError,
      );
    });
  });
}
