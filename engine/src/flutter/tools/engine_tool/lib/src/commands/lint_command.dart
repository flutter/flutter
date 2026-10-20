// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:path/path.dart' as p;

import '../bazel.dart';
import '../build_plan.dart';
import '../dart_utils.dart';

import '../proc_utils.dart';
import '../worker_pool.dart';
import 'command.dart';
import 'flags.dart';

/// The different kind of linters we support.
enum Linter {
  /// Dart linter
  dart,

  /// Java linter
  java,

  /// C/C++ linter
  c,

  /// Python linter
  python,
}

class _LinterDescription {
  _LinterDescription(this.linter, this.cwd, this.command);

  final Linter linter;
  final Directory cwd;
  final List<String> command;
}

/// The root 'lint' command.
final class LintCommand extends CommandBase {
  /// Constructs the 'lint' command.
  LintCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
    super.help = false,
    super.usageLineLength,
  }) : _configs = configs {
    final String engineFlutterPath = environment.engine.flutterDir.path;
    _linters[Linter.dart] = _LinterDescription(Linter.dart, environment.engine.flutterDir, <String>[
      p.join(engineFlutterPath, 'ci', 'analyze.sh'),
      findDartBinDirectory(environment),
    ]);
    _linters[Linter.java] = _LinterDescription(Linter.java, environment.engine.flutterDir, <String>[
      findDartBinary(environment),
      p.join(engineFlutterPath, 'tools', 'android_lint', 'bin', 'main.dart'),
    ]);
    _linters[Linter.c] = _LinterDescription(Linter.c, environment.engine.flutterDir, <String>[
      p.join(engineFlutterPath, 'ci', 'clang_tidy.sh'),
    ]);
    _linters[Linter.python] = _LinterDescription(
      Linter.python,
      environment.engine.flutterDir,
      <String>[p.join(engineFlutterPath, 'ci', 'pylint.sh')],
    );
    argParser.addFlag(quietFlag, abbr: 'q', help: 'Prints minimal output');
    // The C linter reads a build directory's compile_commands.json:
    // ci/clang_tidy.sh's default (out/host_debug) under GN, the --config's
    // build directory, written first, under the Bazel backend.
    _builds = BuildPlan.addConfigOption(argParser, environment, help: help, configs: configs);
    BuildPlan.addBackendOption(argParser, environment);
  }

  final Map<Linter, _LinterDescription> _linters = <Linter, _LinterDescription>{};
  final Map<String, BuilderConfig> _configs;
  late final List<Build> _builds;

  @override
  String get name => 'lint';

  @override
  String get description => 'Lint the engine repository.';

  @override
  Future<int> run() async {
    // TODO(loic-sharma): Relax this restriction.
    if (environment.platform.isWindows) {
      environment.logger.fatal('lint command is not supported on Windows (for now).');
    }
    if (BuildPlan.backendFromArgResults(argResults!, environment) == BuildBackend.bazel) {
      if (!await _prepareBazelCompileCommands()) {
        return 1;
      }
    }
    final wp = WorkerPool(environment, ProcessTaskProgressReporter(environment));

    final tasks = <ProcessTask>{};
    for (final MapEntry<Linter, _LinterDescription> entry in _linters.entries) {
      tasks.add(ProcessTask(entry.key.name, environment, entry.value.cwd, entry.value.command));
    }
    final bool r = await wp.run(tasks);

    final quiet = argResults![quietFlag] as bool;
    if (!quiet) {
      environment.logger.status('\nDumping failure logs\n');
      for (final pt in tasks) {
        final ProcessArtifacts pa = pt.processArtifacts;
        if (pa.exitCode == 0) {
          continue;
        }
        environment.logger.status('Linter ${pt.name} found issues:');
        environment.logger.status('${pa.stdout}\n');
        environment.logger.status('${pa.stderr}\n');
      }
    }
    return r ? 0 : 1;
  }

  /// Under the Bazel backend: writes the `--config` build's
  /// `compile_commands.json` into its build directory and points the C
  /// linter at it (`ci/clang_tidy.sh --variant <build directory>`); the
  /// other linters read no build. False, the error logged, when the build
  /// has no Bazel configuration or the file cannot be written.
  Future<bool> _prepareBazelCompileCommands() async {
    final Build build = BuildPlan.buildFromArgResults(argResults!, environment, builds: _builds);
    final bazel = Bazel(environment, _configs);
    final String? config = bazel.configFor(build);
    if (config == null) {
      return false;
    }
    if (!await bazel.writeCompileCommands(
      config: config,
      buildDirectory: bazel.buildDirectoryFor(build),
    )) {
      return false;
    }
    final _LinterDescription c = _linters[Linter.c]!;
    _linters[Linter.c] = _LinterDescription(Linter.c, c.cwd, <String>[
      ...c.command,
      '--variant',
      build.ninja.config,
    ]);
    return true;
  }
}
