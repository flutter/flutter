// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  const validSha256 = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  group('HostPlatform', () {
    test('round-trips canonical built-in platforms', () {
      for (final HostPlatform platform in HostPlatform.values) {
        expect(HostPlatform.fromName(platform.cliName), same(platform));
        expect(HostPlatform.fromName(platform.name), same(platform));
        expect(HostPlatform.tryFromName(platform.cliName), same(platform));
      }
      expect(HostPlatform.linux_x64.cliName, 'linux-x64');
      expect(HostPlatform.linux_x64.name, 'linux_x64');
      expect(HostPlatform.darwin_arm64.platformName, 'arm64');
      expect(HostPlatform.linux_riscv64.platformName, 'riscv64');
      expect(HostPlatform.linux_x64.toString(), 'HostPlatform.linux_x64');
      expect(HostPlatform.fromOsAndArch('macos', 'arm64'), HostPlatform.darwin_arm64);
      expect(HostPlatform.fromOsAndArch('linux', 'riscv64'), HostPlatform.linux_riscv64);
      expect(HostPlatform.fromOsAndArch('freebsd', 'x64'), isNull);
    });

    test('parses and compares custom <os>-<arch> platforms', () {
      const customHost = HostPlatform('freebsd-x64', 'x64');
      expect(customHost.cliName, 'freebsd-x64');
      expect(customHost.name, 'freebsd_x64');
      expect(customHost.platformName, 'x64');
      expect(HostPlatform.fromName('freebsd-x64'), equals(customHost));
      expect(HostPlatform.fromName('freebsd_x64'), equals(customHost));
      expect(HostPlatform.fromName('freebsd-x64').hashCode, equals(customHost.hashCode));
    });

    test('rejects malformed host platform strings', () {
      for (final invalid in <String>[
        '',
        '   ',
        'invalid',
        'linux-x86_64',
        'FreeBSD-x64',
        ' linux-x64 ',
        'invalid/platform',
        'invalid platform',
      ]) {
        expect(HostPlatform.tryFromName(invalid), isNull, reason: 'Expected "$invalid" to be null');
        expect(() => HostPlatform.fromName(invalid), throwsFormatException);
      }
    });
  });

  group('ArtifactDependency', () {
    test('serializes and deserializes correctly with all fields', () {
      final dep = ArtifactDependency(
        name: 'custom-engine-bin',
        sha256: validSha256,
        url: Uri.parse('https://example.com/artifacts/engine.zip'),
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> json = dep.toMap();
      expect(json, <String, Object?>{
        'name': 'custom-engine-bin',
        'url': 'https://example.com/artifacts/engine.zip',
        'sha256': validSha256,
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
        'sha256: $validSha256, '
        'sha256Url: null, '
        'hostPlatform: HostPlatform.linux_x64, targetPlatform: linux-x64)',
      );

      final customHostDep = ArtifactDependency(
        name: 'custom-bsd-bin',
        sha256: validSha256,
        url: Uri.parse('https://example.com/artifacts/bsd.zip'),
        hostPlatform: const HostPlatform('freebsd-x64', 'x64'),
        targetPlatform: 'freebsd-x64',
      );
      expect(ArtifactDependency.fromJson(customHostDep.toMap()), equals(customHostDep));
    });

    test('serializes and deserializes correctly with sha256Url instead of sha256', () {
      final dep = ArtifactDependency(
        name: 'custom-engine-bin',
        sha256Url: Uri.parse('https://example.com/artifacts/engine.zip.sha256sum'),
        url: Uri.parse('https://example.com/artifacts/engine.zip'),
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux-x64',
      );

      final Map<String, Object?> json = dep.toMap();
      expect(json, <String, Object?>{
        'name': 'custom-engine-bin',
        'url': 'https://example.com/artifacts/engine.zip',
        'sha256Url': 'https://example.com/artifacts/engine.zip.sha256sum',
        'hostPlatform': 'linux-x64',
        'targetPlatform': 'linux-x64',
      });

      final deserialized = ArtifactDependency.fromJson(json);
      expect(deserialized, equals(dep));
      expect(deserialized.sha256, isNull);
      expect(
        deserialized.sha256Url,
        Uri.parse('https://example.com/artifacts/engine.zip.sha256sum'),
      );
      expect(deserialized.hashCode, equals(dep.hashCode));
    });

    test('isValidSha256 validates 64-character hex strings', () {
      expect(ArtifactDependency.isValidSha256(validSha256), isTrue);
      expect(ArtifactDependency.isValidSha256(validSha256.toUpperCase()), isTrue);
      expect(ArtifactDependency.isValidSha256('deadbeef'), isFalse);
      expect(ArtifactDependency.isValidSha256(''), isFalse);
      expect(
        ArtifactDependency.isValidSha256(
          'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
        ),
        isFalse,
      );
    });

    test('serializes and deserializes without optional platforms', () {
      final dep = ArtifactDependency(
        name: 'common-data',
        sha256: validSha256,
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
        <String, Object?>{'name': 'a', 'url': 'https://example.com/a.zip', 'sha256': validSha256},
      ]);
      expect(list, hasLength(1));
      expect(list.first.name, 'a');
      expect(ArtifactDependency.listFromJson(null), isEmpty);
    });

    test('matchesPlatforms matches exact targetPlatform and OS prefix', () {
      final dep = ArtifactDependency(
        name: 'linux-bin',
        sha256: validSha256,
        url: Uri.parse('https://example.com/linux.zip'),
        hostPlatform: HostPlatform.linux_x64,
        targetPlatform: 'linux-x64',
      );

      expect(
        dep.matchesPlatforms(
          currentHostPlatform: HostPlatform.linux_x64,
          targetPlatforms: const <String>{'linux-x64'},
        ),
        isTrue,
      );
      expect(
        dep.matchesPlatforms(
          currentHostPlatform: HostPlatform.linux_x64,
          targetPlatforms: const <String>{'linux'},
        ),
        isTrue,
      );
      expect(
        dep.matchesPlatforms(
          currentHostPlatform: HostPlatform.darwin_arm64,
          targetPlatforms: const <String>{'linux-x64'},
        ),
        isFalse,
      );
      expect(
        dep.matchesPlatforms(
          currentHostPlatform: HostPlatform.linux_x64,
          targetPlatforms: const <String>{'android'},
        ),
        isFalse,
      );
    });

    test('throws FormatException on invalid JSON', () {
      expect(() => ArtifactDependency.fromJson(const <String, Object?>{}), throwsFormatException);
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': ':::not_a_valid_uri:::',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'relative/path/without/scheme.zip',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'file:///etc/passwd',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': validSha256,
          'hostPlatform': 'invalid/host',
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': validSha256,
          'targetPlatform': 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': '',
          'url': 'https://example.com/a.zip',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': '../evil',
          'url': 'https://example.com/a.zip',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'sub/bin',
          'url': 'https://example.com/a.zip',
          'sha256': validSha256,
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': '../badsha',
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256': 'deadbeef',
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
        }),
        throwsFormatException,
      );
      expect(
        () => ArtifactDependency.fromJson(const <String, Object?>{
          'name': 'test',
          'url': 'https://example.com/a.zip',
          'sha256Url': 'file:///etc/passwd',
        }),
        throwsFormatException,
      );
    });
  });
}
