// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';

import './common.dart';

void main() {
  final String flutterRoot = () {
    io.Directory current = io.Directory.current;
    while (!io.File(p.join(current.path, 'DEPS')).existsSync()) {
      if (current.path == current.parent.path) {
        fail(
          'Could not find flutter repository root (${io.Directory.current.path} -> ${current.path})',
        );
      }
      current = current.parent;
    }
    return current.path;
  }();

  /// Verify that the platform specified in the target name matches one of the
  /// platforms defined in the platform_properties section.
  void checkTargetPlatform(String targetName, _CiYaml ciYaml) {
    final String platformName = targetName.split(' ').first.toLowerCase();
    expect(ciYaml.platforms, contains(platformName));
  }

  group('framework', () {
    final _CiYaml ciYaml = _CiYaml.parse(p.join(flutterRoot, '.ci.yaml'));

    for (final _CiYamlTarget target in ciYaml.targets) {
      group(target.name, () {
        setUp(() {
          printOnFailure(target.span.message('One or more errors occurred validating'));
        });

        test('validate platform name', () {
          checkTargetPlatform(target.name, ciYaml);
        });

        if (target.runIf != null && target.runIf!.isNotEmpty) {
          test('must include .ci.yaml', () {
            expect(
              target.runIf,
              contains('.ci.yaml'),
              reason:
                  '.ci.yaml inclusion means changes to the runIfs will trigger presubmit tests.',
            );
          });

          test('must include DEPS', () {
            expect(
              target.runIf,
              contains('DEPS'),
              reason: 'DEPS updates (including the Dart SDK) mean presubmit tests must be run.',
            );
          });

          test('must include the engine sources', () {
            expect(
              target.runIf,
              contains('engine/**'),
              reason: 'Engine updates means framework presubmit tests must be run.',
            );
          });
        }
      });
    }
  });

  group('engine', () {
    final _CiYaml ciYaml = _CiYaml.parse(
      p.join(flutterRoot, 'engine', 'src', 'flutter', '.ci.yaml'),
    );

    for (final _CiYamlTarget target in ciYaml.targets) {
      group(target.name, () {
        setUp(() {
          printOnFailure(target.span.message('One or more errors occurred validating'));
        });

        test('validate platform name', () {
          checkTargetPlatform(target.name, ciYaml);
        });

        if (target.runIf != null && target.runIf!.isNotEmpty) {
          test('must include .ci.yaml', () {
            expect(
              target.runIf,
              contains('engine/src/flutter/.ci.yaml'),
              reason:
                  '.ci.yaml inclusion means changes to the runIfs will trigger presubmit tests.',
            );
          });

          test('must include DEPS', () {
            expect(
              target.runIf,
              contains('DEPS'),
              reason: 'DEPS updates (including the Dart SDK) mean presubmit tests must be run.',
            );
          });
        }
      });
    }
  });
}

/// A minimal representation of an ostensibly well-formatted `.ci.yaml` file.
///
/// Due to the repository setup, it's not possible to reuse the existing
/// specifications of this file, and since the test case is only testing a
/// subset of the encoding, this class exposes only that subset.
///
/// For a discussion leading to this design decision, see
/// <https://github.com/flutter/flutter/issues/160915>.
///
/// See also:
/// - [`scheduler.proto`][1], the schema definition of the file format.
/// - [`CI_YAML.md`][2], a human-authored description of the file format.
/// - [`ci_yaml.dart`][3], where validation is performed (in `flutter/cocoon`).
///
/// [1]: https://github.com/flutter/cocoon/blob/main/app_dart/lib/src/model/proto/internal/scheduler.proto
/// [2]: https://github.com/flutter/cocoon/blob/main/CI_YAML.md
/// [3]: https://github.com/flutter/cocoon/blob/main/app_dart/lib/src/model/ci_yaml/ci_yaml.dart
final class _CiYamlTarget {
  _CiYamlTarget({required this.name, required this.span, required this.runIf});

  factory _CiYamlTarget.fromYamlMap(YamlMap map) {
    return _CiYamlTarget(
      name: map['name'] as String,
      span: map.span,
      runIf: () {
        final runIf = map['runIf'] as YamlList?;
        if (runIf == null) {
          return null;
        }
        return runIf.cast<String>().toList();
      }(),
    );
  }

  /// Name of the target.
  final String name;

  /// Where the target was parsed at in the `.ci.yaml` file.
  final SourceSpan span;

  /// Which lines were present in a `runIf` block, if any.
  final List<String>? runIf;
}

final class _CiYaml {
  _CiYaml({required this.targets, required this.platforms});

  final List<_CiYamlTarget> targets;
  final Set<String> platforms;

  /// Parses a list of targets from the provided `.ci.yaml` file [path].
  static _CiYaml parse(String path) {
    final YamlDocument yamlDoc = loadYamlDocument(
      io.File(path).readAsStringSync(),
      sourceUrl: Uri.parse(path),
    );

    final root = yamlDoc.contents as YamlMap;
    final yamlTargets = root['targets'] as YamlList;
    final List<_CiYamlTarget> targets = yamlTargets.nodes.map((YamlNode node) {
      return _CiYamlTarget.fromYamlMap(node as YamlMap);
    }).toList();

    final yamlPlatforms = root['platform_properties'] as YamlMap;
    final platforms = Set<String>.from(yamlPlatforms.keys.cast<String>());
    return _CiYaml(targets: targets, platforms: platforms);
  }
}
