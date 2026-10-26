// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// felt's configuration (lib/web_ui/test/felt_config.yaml) as a Starlark
/// table, for lib/web_ui/BUILD.bazel's one `web_ui_tests` call
/// (build_defs/web/web_ui_tests.bzl).
///
/// felt_config.yaml is the web team's source of truth for the web engine's
/// unit tests: the compile configurations (compiler and renderer), the test
/// sets (a directory of test files each), the test bundles (a test set
/// compiled under one or more compile configurations), the run
/// configurations (a browser with its flags and variant) and the test suites
/// (a bundle run under a run configuration). Bazel cannot read YAML, so the
/// converter writes the same tables into `felt_config.bzl` beside the BUILD
/// file -- the names and the references among them, which is all the macro
/// needs; a run configuration's flags and variant stay felt's own, read from
/// the YAML by suite name at run time -- and `--check` holds the two files
/// together.
library;

import 'package:yaml/yaml.dart';

/// felt_config.yaml, parsed as felt's own dev/felt_config.dart parses it
/// (the same required fields and references).
final class FeltConfig {
  FeltConfig._({
    required this.compileConfigs,
    required this.testSets,
    required this.testBundles,
    required this.runConfigs,
    required this.testSuites,
  });

  /// Parses the text of felt_config.yaml. Throws a [FormatException] on a
  /// missing field or a dangling reference, naming the entry.
  factory FeltConfig.parse(String yaml) {
    final Object? document = loadYaml(yaml);
    if (document is! YamlMap) {
      throw const FormatException('felt_config.yaml is not a mapping');
    }
    final compileConfigs = <String, FeltCompileConfig>{};
    for (final YamlMap node in _list(document, 'compile-configs')) {
      final String name = _string(node, 'name', 'a compile config');
      _unique(compileConfigs, name, 'compile config');
      compileConfigs[name] = FeltCompileConfig(
        compiler: _string(node, 'compiler', 'compile config $name'),
        renderer: _string(node, 'renderer', 'compile config $name'),
      );
    }
    final testSets = <String, String>{};
    for (final YamlMap node in _list(document, 'test-sets')) {
      final String name = _string(node, 'name', 'a test set');
      _unique(testSets, name, 'test set');
      testSets[name] = _string(node, 'directory', 'test set $name');
    }
    final testBundles = <String, FeltTestBundle>{};
    for (final YamlMap node in _list(document, 'test-bundles')) {
      final String name = _string(node, 'name', 'a test bundle');
      _unique(testBundles, name, 'test bundle');
      final String testSet = _string(node, 'test-set', 'test bundle $name');
      if (!testSets.containsKey(testSet)) {
        throw FormatException('test bundle $name names an unknown test set: $testSet');
      }
      final Object? configs = node['compile-configs'];
      final List<String> compileConfigs = switch (configs) {
        final String one => <String>[one],
        final YamlList many => many.cast<String>().toList(),
        _ => throw FormatException('test bundle $name has no compile-configs'),
      };
      testBundles[name] = FeltTestBundle(testSet: testSet, compileConfigs: compileConfigs);
    }
    final runConfigs = <String, String>{};
    for (final YamlMap node in _list(document, 'run-configs')) {
      final String name = _string(node, 'name', 'a run config');
      _unique(runConfigs, name, 'run config');
      runConfigs[name] = _string(node, 'browser', 'run config $name');
    }
    final testSuites = <String, FeltTestSuite>{};
    for (final YamlMap node in _list(document, 'test-suites')) {
      final String name = _string(node, 'name', 'a test suite');
      _unique(testSuites, name, 'test suite');
      final String bundle = _string(node, 'test-bundle', 'test suite $name');
      if (!testBundles.containsKey(bundle)) {
        throw FormatException('test suite $name names an unknown test bundle: $bundle');
      }
      final String runConfig = _string(node, 'run-config', 'test suite $name');
      if (!runConfigs.containsKey(runConfig)) {
        throw FormatException('test suite $name names an unknown run config: $runConfig');
      }
      final Object? deps = node['artifact-deps'];
      testSuites[name] = FeltTestSuite(
        testBundle: bundle,
        runConfig: runConfig,
        artifactDeps: deps is YamlList ? deps.cast<String>().toList() : const <String>[],
      );
    }
    for (final MapEntry<String, FeltTestBundle> bundle in testBundles.entries) {
      for (final String config in bundle.value.compileConfigs) {
        if (!compileConfigs.containsKey(config)) {
          throw FormatException(
            'test bundle ${bundle.key} names an unknown compile config: $config',
          );
        }
      }
    }
    return FeltConfig._(
      compileConfigs: compileConfigs,
      testSets: testSets,
      testBundles: testBundles,
      runConfigs: runConfigs,
      testSuites: testSuites,
    );
  }

  /// The compile configurations by name.
  final Map<String, FeltCompileConfig> compileConfigs;

  /// The test sets: name to directory under lib/web_ui/test.
  final Map<String, String> testSets;

  /// The test bundles by name.
  final Map<String, FeltTestBundle> testBundles;

  /// The run configurations: name to browser.
  final Map<String, String> runConfigs;

  /// The test suites by name.
  final Map<String, FeltTestSuite> testSuites;

  /// The Starlark file: `FELT_CONFIG`, a dict of the five tables, keys
  /// sorted (buildifier's order for the file's literals).
  String toStarlark() {
    final out = StringBuffer()
      ..writeln('# GENERATED by tools/gn_to_bazel from lib/web_ui/test/felt_config.yaml; do not')
      ..writeln('# edit. Run `dart bin/gn_to_bazel.dart` in tools/gn_to_bazel after changing the')
      ..writeln('# YAML; `--check` compares the two.')
      ..writeln()
      ..writeln("\"\"\"felt's configuration (test/felt_config.yaml) as a Starlark table.")
      ..writeln()
      ..writeln('The names and the references among them, which is what the `web_ui_tests`')
      ..writeln('macro (build_defs/web/web_ui_tests.bzl) needs to declare one test per test')
      ..writeln("file and suite; a run configuration's browser flags and variant stay felt's")
      ..writeln('own, read from the YAML by suite name when the test runs.')
      ..writeln('"""')
      ..writeln()
      ..writeln('FELT_CONFIG = {')
      ..writeln('    "compile_configs": {');
    for (final String name in compileConfigs.keys.toList()..sort()) {
      final FeltCompileConfig config = compileConfigs[name]!;
      out.writeln(
        '        "$name": {"compiler": "${config.compiler}", "renderer": "${config.renderer}"},',
      );
    }
    out
      ..writeln('    },')
      ..writeln('    "run_configs": {');
    for (final String name in runConfigs.keys.toList()..sort()) {
      out.writeln('        "$name": {"browser": "${runConfigs[name]}"},');
    }
    out
      ..writeln('    },')
      ..writeln('    "test_bundles": {');
    for (final String name in testBundles.keys.toList()..sort()) {
      final FeltTestBundle bundle = testBundles[name]!;
      out
        ..writeln('        "$name": {')
        ..writeln('            "compile_configs": [${_quoted(bundle.compileConfigs)}],')
        ..writeln('            "test_set": "${bundle.testSet}",')
        ..writeln('        },');
    }
    out
      ..writeln('    },')
      ..writeln('    "test_sets": {');
    for (final String name in testSets.keys.toList()..sort()) {
      out.writeln('        "$name": "${testSets[name]}",');
    }
    out
      ..writeln('    },')
      ..writeln('    "test_suites": {');
    for (final String name in testSuites.keys.toList()..sort()) {
      final FeltTestSuite suite = testSuites[name]!;
      out
        ..writeln('        "$name": {')
        ..writeln('            "artifact_deps": [${_quoted(suite.artifactDeps)}],')
        ..writeln('            "run_config": "${suite.runConfig}",')
        ..writeln('            "test_bundle": "${suite.testBundle}",')
        ..writeln('        },');
    }
    out
      ..writeln('    },')
      ..writeln('}');
    return out.toString();
  }

  static String _quoted(List<String> values) => values.map((String v) => '"$v"').join(', ');

  static Iterable<YamlMap> _list(YamlMap document, String key) {
    final Object? value = document[key];
    if (value is! YamlList) {
      throw FormatException('felt_config.yaml has no $key list');
    }
    return value.map((Object? node) {
      if (node is! YamlMap) {
        throw FormatException('an entry of $key is not a mapping: $node');
      }
      return node;
    });
  }

  static String _string(YamlMap node, String key, String what) {
    final Object? value = node[key];
    if (value is! String) {
      throw FormatException('$what has no $key');
    }
    return value;
  }

  static void _unique(Map<String, Object?> seen, String name, String what) {
    if (seen.containsKey(name)) {
      throw FormatException('duplicate $what name: $name');
    }
  }
}

/// A compile configuration: the compiler (dart2js, dart2wasm) and the
/// renderer (canvaskit, skwasm).
final class FeltCompileConfig {
  const FeltCompileConfig({required this.compiler, required this.renderer});

  final String compiler;
  final String renderer;
}

/// A test bundle: a test set compiled under its compile configurations.
final class FeltTestBundle {
  const FeltTestBundle({required this.testSet, required this.compileConfigs});

  final String testSet;
  final List<String> compileConfigs;
}

/// A test suite: a bundle run under a run configuration, with the artifacts
/// it needs (felt's artifact-deps: canvaskit, canvaskit_chromium, skwasm, ...).
final class FeltTestSuite {
  const FeltTestSuite({
    required this.testBundle,
    required this.runConfig,
    required this.artifactDeps,
  });

  final String testBundle;
  final String runConfig;
  final List<String> artifactDeps;
}
