// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show ProcessStartMode;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:process_runner/process_runner.dart';

import '../build_utils.dart';
import '../label.dart';
import '../run_utils.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'run' command.
final class RunCommand extends CommandBase {
  /// Constructs the 'run' command.
  RunCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
    super.help = false,
    super.usageLineLength,
  }) {
    // When printing the help/usage for this command, only list all builds
    // when the --verbose flag is supplied.
    final bool includeCiBuilds = environment.verbose || !help;
    builds = runnableBuilds(environment, configs, includeCiBuilds);
    debugCheckBuilds(builds);
    // We default to nothing in order to automatically detect attached devices
    // and select an appropriate target from them.
    addConfigOption(
      environment,
      argParser,
      builds,
      defaultsTo: '',
    );
    addConcurrencyOption(argParser);
    argParser.addFlag(
      rbeFlag,
      defaultsTo: environment.hasRbeConfigInTree(),
      help: 'RBE is enabled by default when available.',
    );
  }

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'run';

  @override
  String get description => '''
Run a Flutter app with a local engine build.
  All arguments after -- are forwarded to flutter run, e.g.:
  et run -- --profile
  et run -- -d macos
See `flutter run --help` for a listing
''';

  Build? _lookup(String configName) {
    final String demangledName = demangleConfigName(environment, configName);
    return builds
        .where((Build build) => build.name == demangledName)
        .firstOrNull;
  }

  Build? _findHostBuild(Build? targetBuild) {
    if (targetBuild == null) {
      return null;
    }
    final String mangledName = mangleConfigName(environment, targetBuild.name);
    if (mangledName.contains('host_')) {
      return targetBuild;
    }
    // TODO(johnmccutchan): This is brittle, it would be better if we encoded
    // the host config name in the target config.
    final String ci =
        mangledName.startsWith('ci') ? mangledName.substring(0, 3) : '';
    if (mangledName.contains('_debug')) {
      return _lookup('${ci}host_debug');
    } else if (mangledName.contains('_profile')) {
      return _lookup('${ci}host_profile');
    } else if (mangledName.contains('_release')) {
      return _lookup('${ci}host_release');
    }
    return null;
  }

  String _getDeviceId() {
    if (argResults!.rest.contains('-d')) {
      final int index = argResults!.rest.indexOf('-d') + 1;
      if (index < argResults!.rest.length) {
        return argResults!.rest[index];
      }
    }
    if (argResults!.rest.contains('--device-id')) {
      final int index = argResults!.rest.indexOf('--device-id') + 1;
      if (index < argResults!.rest.length) {
        return argResults!.rest[index];
      }
    }
    return '';
  }

  String _getMode() {
    // Sniff the build mode from the args that will be passed to flutter run.
    String mode = 'debug';
    if (argResults!.rest.contains('--profile')) {
      mode = 'profile';
    } else if (argResults!.rest.contains('--release')) {
      mode = 'release';
    }
    return mode;
  }

  late final Future<RunTarget?> _runTarget =
      detectAndSelectRunTarget(environment, _getDeviceId());

  Future<String?> _selectTargetConfig() async {
    final String configName = argResults![configFlag] as String;
    if (configName.isNotEmpty) {
      return demangleConfigName(environment, configName);
    }
    final RunTarget? target = await _runTarget;
    if (target == null) {
      return demangleConfigName(environment, 'host_debug');
    }
    environment.logger.status(
        'Building to run on "${target.name}" running ${target.targetPlatform}');
    return target.buildConfigFor(_getMode());
  }

  @override
  Future<int> run() async {
    if (!environment.processRunner.processManager.canRun('flutter')) {
      environment.logger.error('Cannot find the flutter command in your path');
      return 1;
    }
    final String? configName = await _selectTargetConfig();
    if (configName == null) {
      environment.logger.error('Could not find target config');
      return 1;
    }
    final Build? build = _lookup(configName);
    final Build? hostBuild = _findHostBuild(build);
    if (build == null) {
      environment.logger.error('Could not find build $configName');
      return 1;
    }
    if (hostBuild == null) {
      environment.logger.error('Could not find host build for $configName');
      return 1;
    }

    final bool useRbe = argResults![rbeFlag] as bool;
    if (useRbe && !environment.hasRbeConfigInTree()) {
      environment.logger.error('RBE was requested but no RBE config was found');
      return 1;
    }
    final List<String> extraGnArgs = <String>[
      if (!useRbe) '--no-rbe',
    ];
    final RunTarget? target = await _runTarget;
    final List<Label> buildTargetsForShell =
        target?.buildTargetsForShell() ?? <Label>[];

    final String dashJ = argResults![concurrencyFlag] as String;
    final int? concurrency = int.tryParse(dashJ);
    if (concurrency == null || concurrency < 0) {
      environment.logger.error('-j must specify a positive integer.');
      return 1;
    }

    // First build the host.
    int r = await runBuild(
      environment,
      hostBuild,
      concurrency: concurrency,
      extraGnArgs: extraGnArgs,
      enableRbe: useRbe,
    );
    if (r != 0) {
      return r;
    }

    // Now build the target if it isn't the same.
    if (hostBuild.name != build.name) {
      r = await runBuild(
        environment,
        build,
        concurrency: concurrency,
        extraGnArgs: extraGnArgs,
        enableRbe: useRbe,
        targets: buildTargetsForShell,
      );
      if (r != 0) {
        return r;
      }
    }

    final String mangledBuildName = mangleConfigName(environment, build.name);

    final String mangledHostBuildName =
        mangleConfigName(environment, hostBuild.name);

    final List<String> command = <String>[
      'flutter',
      'run',
      '--local-engine-src-path',
      environment.engine.srcDir.path,
      '--local-engine',
      mangledBuildName,
      '--local-engine-host',
      mangledHostBuildName,
      ...argResults!.rest
    ];

    // TODO(johnmccutchan): Be smart and if the user requested a profile
    // config, add the '--profile' flag when invoking flutter run.
    final ProcessRunnerResult result =
        await environment.processRunner.runProcess(
      command,
      runInShell: true,
      startMode: ProcessStartMode.inheritStdio,
    );
    return result.exitCode;
  }
}
