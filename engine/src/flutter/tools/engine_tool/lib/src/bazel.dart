// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:gn_to_bazel/gn_to_bazel.dart' as gn_to_bazel;
import 'package:path/path.dart' as p;
import 'package:process_runner/process_runner.dart';

import 'environment.dart';
import 'label.dart';

/// Which build system a command drives.
enum BuildBackend {
  /// GN and ninja, through the builder configuration's `gn` and `ninja`
  /// blocks: the engine's build.
  gn,

  /// Bazel, through the configuration the converter generates for the same
  /// build (`ci/builders/configs.bazelrc`: `--config=<name>`) and the Bazel
  /// counterparts of its targets. Experimental, opt-in; see
  /// flutter/build/bazel/README.md.
  bazel;

  /// The backend named by `ET_BACKEND` in [environment], or GN.
  static BuildBackend fromEnvironment(Environment environment) {
    final String? name;
    try {
      name = environment.platform.environment['ET_BACKEND'];
    } on StateError {
      // A platform without an environment (a test's fake): GN.
      return BuildBackend.gn;
    }
    return BuildBackend.values.firstWhere(
      (BuildBackend b) => b.name == name,
      orElse: () => BuildBackend.gn,
    );
  }
}

/// The Bazel build of the engine, as `et` drives it: the configuration a
/// builder file's build corresponds to, the Bazel spelling of GN labels, and
/// the `bazel` process itself (bazelisk, run from `engine/src`).
///
/// The Bazel side of a build is what tools/gn_to_bazel generates from the
/// builder files (`builders.dart`): a `--config=<name>` for every Linux x64
/// host build whose `tools/gn` flags the Bazel build can express, an install
/// target laying the build's outputs into its build directory, and a test
/// suite over its `run_tests.py` types. This class asks that code, so that
/// `et` and the generated files cannot disagree on a name.
final class Bazel {
  /// The Bazel side of the builds of [configs] (the builder files), for
  /// commands run in [environment].
  Bazel(this._environment, Map<String, BuilderConfig> configs)
    : _builds = gn_to_bazel.linuxHostBuilds(configs);

  final Environment _environment;
  final List<gn_to_bazel.BuilderBuild> _builds;

  /// The root Bazel package of the engine's sources (the GN root, `//`,
  /// lives at `engine/src` of the repository).
  static const String rootPackage = '//engine/src';

  /// The install target of the whole tree (GN's default target).
  static const String installTarget = '$rootPackage/flutter:install';

  /// What the converter made of [build]: its configuration name, or null
  /// with the reasons it has none.
  gn_to_bazel.BuilderBuild? _builderBuild(Build build) {
    for (final gn_to_bazel.BuilderBuild b in _builds) {
      if (b.name == build.name) {
        return b;
      }
    }
    return null;
  }

  /// The configuration name for [build] (`--config=<name>`), or null, the
  /// reason logged, when the Bazel build has none for it.
  String? configFor(Build build) {
    final gn_to_bazel.BuilderBuild? builderBuild = _builderBuild(build);
    if (builderBuild == null) {
      _environment.logger.error(
        'The Bazel build has no configuration for ${build.name}: only the Linux x64 '
        'host builds of ci/builders have one (tools/gn_to_bazel generates them).',
      );
      return null;
    }
    if (builderBuild.unsupported.isNotEmpty) {
      _environment.logger.error(
        'The Bazel build cannot express ${build.name} yet '
        '(see flutter/ci/builders/configs.bazelrc):\n'
        '  ${builderBuild.unsupported.join('\n  ')}',
      );
      return null;
    }
    return builderBuild.configName;
  }

  /// The install target of [build]: the builder's own
  /// (`//engine/src/flutter/ci/builders:<name>`, over its ninja targets) when
  /// it names ninja targets, the whole tree's otherwise.
  String installTargetFor(Build build) {
    final gn_to_bazel.BuilderBuild? builderBuild = _builderBuild(build);
    if (builderBuild == null || builderBuild.ninjaTargets.isEmpty) {
      return installTarget;
    }
    return '$rootPackage/flutter/ci/builders:${builderBuild.configName}';
  }

  /// The test suite of [build] (`//engine/src/flutter/ci/builders:<name>_tests`,
  /// over the Bazel suites of its `run_tests.py` types), or null when the
  /// build runs no `run_tests.py` step.
  String? testSuiteFor(Build build) {
    final gn_to_bazel.BuilderBuild? builderBuild = _builderBuild(build);
    if (builderBuild == null || builderBuild.testTypes.isEmpty) {
      return null;
    }
    return '$rootPackage/flutter/ci/builders:${builderBuild.configName}_tests';
  }

  /// GN's build directory for [build], where its install target lays the
  /// outputs: `engine/src/out/<ninja config>`.
  String buildDirectoryFor(Build build) {
    return p.join(_environment.engine.outDir.path, build.ninja.config);
  }

  /// The Bazel spelling of a GN label or pattern: `//flutter/fml:fml_unittests`
  /// is `//engine/src/flutter/fml:fml_unittests`, `//flutter/fml/...` is
  /// `//engine/src/flutter/fml/...`, `//flutter/fml:all` is
  /// `//engine/src/flutter/fml:all`. A GN directory that the converter sends
  /// elsewhere (Skia's `//flutter/skia` is `@skia`) follows the converter's
  /// table; a directory it has not converted is left to Bazel to report.
  static String labelFor(TargetPattern pattern) {
    if (pattern.package == '//...') {
      return '$rootPackage/...';
    }
    // A subtree pattern's package is the directory with `...` appended
    // (TargetPattern keeps `//flutter/shell/...` as `//flutter/shell...`).
    final bool subtree = pattern.package.endsWith('...');
    final String directory = subtree
        ? pattern.package.substring(0, pattern.package.length - '...'.length)
        : pattern.package;
    final String? target = pattern.target;
    if (!subtree && target != null && target != 'all') {
      // The whole label through the converter's table: a target it sends to
      // another repository (`//flutter/third_party/icu:icuuc` is
      // `@icu//:icuuc`) goes where it sends it.
      return gn_to_bazel.bazelLabel('$directory:$target', package: directory);
    }
    // The directory alone, read as `<repository>//<package>`.
    String mapped = gn_to_bazel.bazelLabel(directory, package: directory);
    if (mapped.startsWith('@') && !mapped.contains('//')) {
      mapped = '$mapped//';
    }
    final int root = mapped.indexOf('//') + 2;
    final String rest = mapped.substring(root);
    final int colon = rest.indexOf(':');
    final String package =
        mapped.substring(0, root) + (colon < 0 ? rest : rest.substring(0, colon));
    if (subtree) {
      return package.endsWith('//') ? '$package...' : '$package/...';
    }
    return '$package:all';
  }

  /// Runs `bazel <arguments>` from `engine/src`, the output going straight to
  /// the terminal; returns the exit code. Uses bazelisk when it is on PATH, as
  /// the engine's `.bazelversion` expects, else `bazel`.
  Future<int> run(List<String> arguments) async {
    final String? executable = _executable();
    if (executable == null) {
      _environment.logger.error(_noBazel);
      return 1;
    }
    final command = <String>[executable, ...arguments];
    _environment.logger.info('Running: ${command.join(' ')}');
    final io.Process process = await _environment.processRunner.processManager.start(
      command,
      workingDirectory: _environment.engine.srcDir.path,
      mode: io.ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  }

  /// Runs `bazel query <expression>` from `engine/src` and returns the
  /// labels it prints, or null (the error logged) when the query fails.
  Future<List<String>?> query(String expression) async {
    final String? executable = _executable();
    if (executable == null) {
      _environment.logger.error(_noBazel);
      return null;
    }
    final command = <String>[executable, 'query', '--output=label', expression];
    _environment.logger.info('Running: ${command.join(' ')}');
    final ProcessRunnerResult result = await _environment.processRunner.runProcess(
      command,
      workingDirectory: _environment.engine.srcDir,
      failOk: true,
    );
    if (result.exitCode != 0) {
      _environment.logger.error('bazel query failed:\n${result.stderr}');
      return null;
    }
    return <String>[
      for (final String line in result.stdout.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
  }

  /// The GN spelling of a Bazel label of the main repository
  /// (`//engine/src/flutter/fml:fml` is `//flutter/fml:fml`), or null for a
  /// label of another repository or outside the GN root.
  static String? gnLabelFor(String bazelLabel) {
    const root = '$rootPackage/';
    if (!bazelLabel.startsWith(root)) {
      return null;
    }
    return '//${bazelLabel.substring(root.length)}';
  }

  /// Writes [buildDirectory]'s `compile_commands.json` for the Bazel build
  /// under configuration [config], through
  /// `tools/gn_to_bazel/tool/compile_commands.py` (`bazel aquery` over the
  /// engine's compiles); false, the error logged, when it fails.
  ///
  /// GN writes the file at `gn gen`; Bazel has no such step, so the tool
  /// runs when something is about to read the file (`et lint`'s clang-tidy).
  /// It is Python, as `tools/gn` is, and runs under the `python3` on PATH.
  Future<bool> writeCompileCommands({
    required String config,
    required String buildDirectory,
  }) async {
    final String? executable = _executable();
    if (executable == null) {
      _environment.logger.error(_noBazel);
      return false;
    }
    if (!_environment.processRunner.processManager.canRun('python3')) {
      _environment.logger.error('No python3 on PATH; compile_commands.py needs it.');
      return false;
    }
    final command = <String>[
      'python3',
      p.join(
        _environment.engine.flutterDir.path,
        'tools',
        'gn_to_bazel',
        'tool',
        'compile_commands.py',
      ),
      '--out=$buildDirectory',
      '--config=$config',
      '--bazel=$executable',
    ];
    _environment.logger.info('Running: ${command.join(' ')}');
    final ProcessRunnerResult result = await _environment.processRunner.runProcess(
      command,
      workingDirectory: _environment.engine.srcDir,
      failOk: true,
    );
    if (result.exitCode != 0) {
      _environment.logger.error('compile_commands.py failed:\n${result.stdout}\n${result.stderr}');
      return false;
    }
    _environment.logger.status(result.stdout.trim());
    return true;
  }

  static const String _noBazel =
      'Neither bazelisk nor bazel is on PATH. Install bazelisk '
      '(https://github.com/bazelbuild/bazelisk); the engine pins its Bazel version in '
      '.bazelversion.';

  String? _executable() {
    for (final name in <String>['bazelisk', 'bazel']) {
      if (_environment.processRunner.processManager.canRun(name)) {
        return name;
      }
    }
    return null;
  }
}
