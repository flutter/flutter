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
/// builder files (`builders.dart`): a `--config=<name>` for every Linux build
/// (the x64 host's own, the web's, the Linux arm64 cross builds' and
/// Android's, `local_engine.json`'s `linux/` ones included) whose `tools/gn`
/// flags the Bazel build can express, an install target laying a CI build's
/// ninja targets into its build directory, and a test suite over its
/// `run_tests.py` types. A build of everything (GN's default target: the
/// developer's builds) has no install; the flutter tool reads it where Bazel
/// builds it, through [localEngineTarget]'s manifest. This class asks that
/// code, so that `et` and the generated files cannot disagree on a name.
///
/// A build is named as `et` names it elsewhere: `-c ci/android_debug_x64`
/// for CI's, `-c android_debug_unopt_x64` for the developer's
/// (`linux/android_debug_unopt_x64`).
final class Bazel {
  /// The Bazel side of the builds of [configs] (the builder files), for
  /// commands run in [environment].
  Bazel(this._environment, Map<String, BuilderConfig> configs)
    : _builds = gn_to_bazel.linuxBuilds(configs);

  final Environment _environment;
  final List<gn_to_bazel.BuilderBuild> _builds;

  /// The root Bazel package of the engine's sources (the GN root, `//`,
  /// lives at `engine/src` of the repository).
  static const String rootPackage = '//engine/src';

  /// The local engine target of the whole tree: the build's artifacts where
  /// Bazel builds them and `local_engine.json` beside them, which the flutter
  /// tool reads through `--local-engine` (build_defs/dist/local_engine.bzl).
  static const String localEngineTarget = '$rootPackage/flutter:local_engine';

  /// The manifest [localEngineTarget] writes.
  static const String localEngineManifest = 'local_engine.json';

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
        'The Bazel build has no configuration for ${build.name}: only the Linux '
        "builds of ci/builders (the x64 host's, the web's, the Linux arm64 cross "
        "builds' and Android's, local_engine.json's linux/ ones included) have "
        'one (tools/gn_to_bazel generates them).',
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

  /// The install target of [build]
  /// (`//engine/src/flutter/ci/builders:<name>`, over its ninja targets), or
  /// null for a build of everything, which has none: the flutter tool reads
  /// such a build where Bazel builds it, through [localEngineTarget]'s
  /// manifest ([buildLocalEngine]) -- its own platform's directly, Android's
  /// through its Gradle plugin, which takes the manifest's directory as
  /// `-Plocal-engine-out`. A CI build names ninja targets, and its install
  /// lays what its recipe uploads, so it keeps its install target.
  String? installTargetFor(Build build) {
    final gn_to_bazel.BuilderBuild? builderBuild = _builderBuild(build);
    if (builderBuild == null || builderBuild.ninjaTargets.isEmpty) {
      return null;
    }
    return '$rootPackage/flutter/ci/builders:${builderBuild.configName}';
  }

  /// Whether [build] is of the host's own platform (no `--platforms`), as
  /// against another's (Android's, the web's, Linux arm64's), whose local
  /// engine the flutter tool pairs with a host build's (`--local-engine-host`).
  bool isHostBuild(Build build) {
    final gn_to_bazel.BuilderBuild? builderBuild = _builderBuild(build);
    return builderBuild != null && builderBuild.platform == null;
  }

  /// Builds [localEngineTarget] under [config] and returns the directory
  /// holding its manifest -- the value for `--local-engine` and
  /// `--local-engine-host` -- or null, the error logged, when a step fails.
  ///
  /// The directory is the configuration's own under `bazel-out`
  /// (`<execroot>/bazel-out/k8-dbg/bin/engine/src/flutter` for the host's
  /// `-c dbg`, `bazel-out/android_arm64-opt/bin/engine/src/flutter` for
  /// Android's: a cross build's directory is named after its platform, the
  /// root `.bazelrc`'s `--experimental_platform_in_output_dir`, so that it
  /// and the host build it pairs with are both on disk), found from
  /// `bazel info output_path` and the manifest's path among the target's
  /// outputs (`bazel cquery --output=files`), rather than the `bazel-bin`
  /// convenience symlink, which follows the last build of any configuration.
  Future<String?> buildLocalEngine(String config) async {
    final int exitCode = await run(<String>['build', '--config=$config', localEngineTarget]);
    if (exitCode != 0) {
      return null;
    }
    final List<String>? outputPath = await _lines(<String>[
      'info',
      '--config=$config',
      'output_path',
    ]);
    if (outputPath == null || outputPath.length != 1) {
      _environment.logger.error('bazel info output_path did not name the output directory.');
      return null;
    }
    final List<String>? files = await _lines(<String>[
      'cquery',
      '--config=$config',
      '--output=files',
      localEngineTarget,
    ]);
    if (files == null) {
      return null;
    }
    const manifestSuffix = '/$localEngineManifest';
    for (final String file in files) {
      if (file.endsWith(manifestSuffix)) {
        // `bazel-out/<configuration>/bin/...`, relative to the execution
        // root, which output_path is `bazel-out` of.
        final String executionRoot = p.dirname(outputPath.single);
        return p.normalize(p.join(executionRoot, p.dirname(file)));
      }
    }
    _environment.logger.error('$localEngineTarget has no $localEngineManifest among its outputs.');
    return null;
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
  Future<List<String>?> query(String expression) {
    return _lines(<String>['query', '--output=label', expression]);
  }

  /// Runs `bazel <arguments>` from `engine/src`, capturing its output, and
  /// returns the non-empty lines it prints, or null (the error logged) when
  /// it fails.
  Future<List<String>?> _lines(List<String> arguments) async {
    final String? executable = _executable();
    if (executable == null) {
      _environment.logger.error(_noBazel);
      return null;
    }
    final command = <String>[executable, ...arguments];
    _environment.logger.info('Running: ${command.join(' ')}');
    final ProcessRunnerResult result = await _environment.processRunner.runProcess(
      command,
      workingDirectory: _environment.engine.srcDir,
      failOk: true,
    );
    if (result.exitCode != 0) {
      _environment.logger.error('bazel ${arguments.first} failed:\n${result.stderr}');
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
