// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import './common.dart';

enum _Section { devicelab, firebase, frameworkHostOnly, other, shards }

class _TestOwnersRegistry {
  _TestOwnersRegistry({required this.owners, required this.shardOwners});

  final Map<String, String> owners;
  final Map<String, String> shardOwners;

  String? getOwner(
    String targetName,
    String recipe,
    Map<dynamic, dynamic> properties,
    List<String>? tags,
  ) {
    final String testName =
        properties['task_name'] as String? ?? _getTestNameFromTargetName(targetName);

    final bool isShard =
        (tags != null && tags.contains('shard')) ||
        properties['shard'] != null ||
        recipe == 'flutter/flutter_drone';

    // Broad shard suites resolve via substring matching ('targetName.contains(shard_name)').
    // Non-shard jobs resolve via direct 1:1 key lookups to prevent substring false positives.
    if (isShard) {
      for (final MapEntry<String, String> entry in shardOwners.entries) {
        if (testName.contains(entry.key)) {
          return entry.value;
        }
      }
      return null;
    }

    return owners[testName] ?? owners[targetName];
  }
}

List<String>? _parseTags(dynamic tagsProperty) {
  if (tagsProperty == null) {
    return null;
  }
  if (tagsProperty is YamlList) {
    return tagsProperty.cast<String>().toList();
  }
  if (tagsProperty is String) {
    try {
      final dynamic decoded = loadYaml(tagsProperty);
      if (decoded is YamlList) {
        return decoded.cast<String>().toList();
      }
      if (decoded is List) {
        return decoded.cast<String>().toList();
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _getTestNameFromTargetName(String targetName) {
  final List<String> words = targetName.split(RegExp(r'\s+'));
  return words.length < 2 ? words[0] : words.sublist(1).join(' ');
}

String? _extractOwner(String line) {
  final List<String> words = line.split(RegExp(r'\s+'));
  for (final word in words) {
    if (word.startsWith('@') && word.length > 1) {
      return word.substring(1);
    }
  }
  return null;
}

_TestOwnersRegistry _parseTestOwners(String content) {
  final owners = <String, String>{};
  final shardOwners = <String, String>{};

  _Section currentSection = _Section.other;
  final pendingFrameworkTargets = <String>[];

  final List<String> lines = content.split('\n');
  for (final rawLine in lines) {
    final String line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    if (line.startsWith('## ')) {
      pendingFrameworkTargets.clear();
      if (line.contains('DeviceLab tests')) {
        currentSection = _Section.devicelab;
      } else if (line.contains('Host only framework tests')) {
        currentSection = _Section.frameworkHostOnly;
      } else if (line.contains('Firebase tests')) {
        currentSection = _Section.firebase;
      } else if (line.contains('Shards tests')) {
        currentSection = _Section.shards;
      } else {
        currentSection = _Section.other;
      }
      continue;
    }

    switch (currentSection) {
      case _Section.devicelab:
        // DeviceLab CI targets reference tasks by script basename (e.g. 'analyzer_benchmark')
        // rather than full file paths ('/dev/devicelab/bin/tasks/analyzer_benchmark.dart').
        if (line.startsWith('#')) {
          continue;
        }
        final String? owner = _extractOwner(line);
        if (owner != null) {
          final String path = line.split(RegExp(r'\s+')).first;
          final String taskName = p.basenameWithoutExtension(path);
          owners[taskName] = owner;
        }
      case _Section.frameworkHostOnly:
        // Host-only framework tests in TESTOWNERS are grouped under comment headers
        // (e.g. '# Linux analyze' or multiple headers sharing a script).
        // We collect pending target names from comments and map them when we hit an @owner line.
        if (line.startsWith('#')) {
          final List<String> words = line.split(RegExp(r'\s+'));
          if (words.length > 2) {
            final String name = words.sublist(2).join(' ');
            pendingFrameworkTargets.add(name);
            pendingFrameworkTargets.add(name.replaceAll(' ', '_'));
          } else if (words.length == 2) {
            pendingFrameworkTargets.add(words[1]);
          }
        } else {
          final String? owner = _extractOwner(line);
          if (owner != null) {
            for (final target in pendingFrameworkTargets) {
              owners[target] = owner;
            }
            pendingFrameworkTargets.clear();
          }
        }
      case _Section.firebase:
        // Firebase CI targets reference suites by their directory name (e.g. 'release_smoke_test')
        // rather than full directory paths ('/dev/integration_tests/release_smoke_test').
        if (line.startsWith('#')) {
          continue;
        }
        final String? owner = _extractOwner(line);
        if (owner != null) {
          final String path = line.split(RegExp(r'\s+')).first;
          final String testName = path.split('/').last;
          owners[testName] = owner;
        }
      case _Section.shards:
        // Shard suites in TESTOWNERS are defined as comment lines with owners ('# framework_tests @Piinks').
        if (!line.startsWith('#') || !line.contains('@')) {
          continue;
        }
        final String? owner = _extractOwner(line);
        if (owner != null) {
          final List<String> parts = line.split(RegExp(r'\s+'));
          if (parts.length > 1) {
            shardOwners[parts[1]] = owner;
          }
        }
      case _Section.other:
        continue;
    }
  }

  return _TestOwnersRegistry(owners: owners, shardOwners: shardOwners);
}

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

  final String testOwnersContent = io.File(p.join(flutterRoot, 'TESTOWNERS')).readAsStringSync();
  final _TestOwnersRegistry registry = _parseTestOwners(testOwnersContent);

  group('TESTOWNERS validation', () {
    final YamlDocument ciYamlDoc = loadYamlDocument(
      io.File(p.join(flutterRoot, '.ci.yaml')).readAsStringSync(),
      sourceUrl: Uri.parse(p.join(flutterRoot, '.ci.yaml')),
    );
    final root = ciYamlDoc.contents as YamlMap;
    final targets = root['targets'] as YamlList;

    for (final YamlNode node in targets.nodes) {
      final targetMap = node as YamlMap;
      final targetName = targetMap['name'] as String;
      final String recipe = targetMap['recipe'] as String? ?? '';
      final Map<dynamic, dynamic> properties =
          targetMap['properties'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{};
      final List<String>? tags = _parseTags(properties['tags']);

      test('target "$targetName" must have an owner in TESTOWNERS', () {
        final String? owner = registry.getOwner(targetName, recipe, properties, tags);
        expect(owner, isNotNull, reason: 'No owner found in TESTOWNERS for target "$targetName".');
      });
    }
  });
}
