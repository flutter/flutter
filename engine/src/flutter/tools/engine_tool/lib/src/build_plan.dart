// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:meta/meta.dart';

import 'build_utils.dart';
import 'environment.dart';
import 'logger.dart';

const _flagConfig = 'config';
const _flagConcurrency = 'concurrency';
const _flagStrategy = 'build-strategy';
const _flagRbe = 'rbe';
const _flagLto = 'lto';

/// Describes what (platform, targets) and how (strategy, options) to build.
///
/// Multiple commands in `et` are used to indirectly run builds, which often
/// means running some combination of `gn`, `ninja`, and RBE bootstrap scripts;
/// this class encapsulates the information needed to do so.
@immutable
final class BuildPlan {
  /// Creates a new build plan from parsed command-line arguments.
  ///
  /// The [ArgParser] that produced [args] must have been configured with
  /// [configureArgParser].
  factory BuildPlan.fromArgResults(
    ArgResults args,
    Environment environment, {
    required List<Build> builds,
    String? Function() defaultBuild = _defaultHostDebug,
  }) {
    final build = () {
      final name = args.option(_flagConfig) ?? defaultBuild();
      final config = builds.firstWhereOrNull(
        (b) => mangleConfigName(environment, b.name) == name,
      );
      if (config == null) {
        if (name == null) {
          throw FatalError('No build configuration specified.');
        }
        throw FatalError('Unknown build configuration: $name');
      }
      return config;
    }();
    return BuildPlan._(
      build: build,
      strategy: BuildStrategy.values.byName(args.option(_flagStrategy)!),
      useRbe: () {
        final useRbe = args.flag(_flagRbe);
        if (useRbe && !environment.hasRbeConfigInTree()) {
          throw FatalError(
            'RBE requested but configuration not found.\n\n$_rbeInstructions',
          );
        }
        return useRbe;
      }(),
      useLto: () {
        if (args.wasParsed(_flagLto)) {
          return args.flag(_flagLto);
        }
        return !build.gn.contains('--no-lto');
      }(),
      concurrency: () {
        final value = args.option(_flagConcurrency);
        if (value == null) {
          return null;
        }
        if (int.tryParse(value) case final value? when value >= 0) {
          return value;
        }
        throw FatalError('Invalid value for --$_flagConcurrency: $value');
      }(),
    );
  }

  BuildPlan._({
    required this.build,
    required this.strategy,
    required this.useRbe,
    required this.useLto,
    required this.concurrency,
  }) {
    if (!useRbe && strategy == BuildStrategy.remote) {
      throw FatalError(
        'Cannot use remote builds without RBE enabled.\n\n$_rbeInstructions',
      );
    }
  }

  static String _defaultHostDebug() {
    return 'host_debug';
  }

  /// Adds options to [parser] for configuring a [BuildPlan].
  ///
  /// Returns the list of builds that can be configured.
  @useResult
  static List<Build> configureArgParser(
    ArgParser parser,
    Environment environment, {
    required bool help,
    required Map<String, BuilderConfig> configs,
  }) {
    // Add --config.
    final builds = runnableBuilds(
      environment,
      configs,
      environment.verbose || !help,
    );
    debugCheckBuilds(builds);
    parser.addOption(
      _flagConfig,
      abbr: 'c',
      defaultsTo: () {
        if (builds.any((b) => b.name == 'host_debug')) {
          return 'host_debug';
        }
        return null;
      }(),
      allowed: [
        for (final config in builds) mangleConfigName(environment, config.name),
      ],
      allowedHelp: {
        for (final config in builds)
          mangleConfigName(environment, config.name): config.description,
      },
    );

    // Add --lto.
    parser.addFlag(
      _flagLto,
      help: ''
          'Whether LTO should be enabled for a build.\n'
          "If omitted, defaults to the configuration's specified value, "
          'which is typically (but not always) --no-lto.',
      defaultsTo: null,
      hide: !environment.verbose,
    );

    // Add --rbe.
    final hasRbeConfigInTree = environment.hasRbeConfigInTree();
    parser.addFlag(
      _flagRbe,
      defaultsTo: hasRbeConfigInTree,
      help: () {
        var rbeHelp = 'Enable pre-configured remote build execution.';
        if (!hasRbeConfigInTree || environment.verbose) {
          rbeHelp += '\n\n$_rbeInstructions';
        }
        return rbeHelp;
      }(),
    );

    // Add --build-strategy.
    parser.addOption(
      _flagStrategy,
      defaultsTo: _defaultStrategy.name,
      allowed: BuildStrategy.values.map((e) => e.name),
      allowedHelp: {
        for (final e in BuildStrategy.values) e.name: e._help,
      },
      help: 'How to prefer remote or local builds.',
      hide: !hasRbeConfigInTree && !environment.verbose,
    );

    // Add --concurrency.
    parser.addOption(
      _flagConcurrency,
      abbr: 'j',
      help: 'How many jobs to run in parallel.',
    );

    return builds;
  }

  /// The build configuration to use.
  final Build build;

  /// How to prefer remote or local builds.
  final BuildStrategy strategy;
  static const _defaultStrategy = BuildStrategy.auto;

  /// Whether to configure the build plan to use RBE (remote build execution).
  final bool useRbe;
  static const _rbeInstructions = ''
      'Google employees can follow the instructions at '
      'https://flutter.dev/to/engine-rbe to enable RBE, which can '
      'parallelize builds and reduce build times on faster internet '
      'connections.';

  /// How many jobs to run in parallel.
  ///
  /// If `null`, the build system will use the default number of jobs.
  final int? concurrency;

  /// Whether to build with LTO (link-time optimization).
  final bool useLto;

  @override
  bool operator ==(Object other) {
    return other is BuildPlan &&
        build.name == other.build.name &&
        strategy == other.strategy &&
        useRbe == other.useRbe &&
        useLto == other.useLto &&
        concurrency == other.concurrency;
  }

  @override
  int get hashCode {
    return Object.hash(build.name, strategy, useRbe, useLto, concurrency);
  }

  /// Converts this build plan to its equivalent [RbeConfig].
  RbeConfig toRbeConfig() {
    switch (strategy) {
      case BuildStrategy.auto:
        return const RbeConfig();
      case BuildStrategy.local:
        return const RbeConfig(
          execStrategy: RbeExecStrategy.local,
          remoteDisabled: true,
        );
      case BuildStrategy.remote:
        return const RbeConfig(execStrategy: RbeExecStrategy.remote);
    }
  }

  /// Converts this build plan into extra GN arguments to pass to the build.
  List<String> toGnArgs() {
    return [
      if (!useRbe) '--no-rbe',
      if (useLto) '--lto' else '--no-lto',
    ];
  }

  @override
  String toString() {
    final buffer = StringBuffer('BuildPlan <');
    buffer.writeln();
    buffer.writeln('  build: ${build.name}');
    buffer.writeln('  useLto: $useLto');
    buffer.writeln('  useRbe: $useRbe');
    buffer.writeln('  strategy: $strategy');
    buffer.writeln('  concurrency: $concurrency');
    buffer.write('>');
    return buffer.toString();
  }
}

/// User-specified strategy for executing a build.
enum BuildStrategy {
  /// Automatically determine the best build strategy.
  auto(
    'Prefer remote builds and fallback silently to local builds.',
  ),

  /// Build locally.
  local(
    'Use local builds.'
    '\n'
    'No internet connection is required.',
  ),

  /// Build remotely.
  remote(
    'Use remote builds.'
    '\n'
    'If --$_flagStrategy is not specified, the build will fail.',
  );

  const BuildStrategy(this._help);
  final String _help;
}
