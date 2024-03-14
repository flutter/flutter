// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show ProcessStartMode;

import 'package:engine_build_configs/engine_build_configs.dart';
import 'package:process_runner/process_runner.dart';

import '../build_utils.dart';
import '../run_utils.dart';
import 'command.dart';
import 'flags.dart';

/// The root 'run' command.
final class RunCommand extends CommandBase {
  /// Constructs the 'run' command.
  RunCommand({
    required super.environment,
    required Map<String, BuilderConfig> configs,
  }) {
    builds = runnableBuilds(environment, configs);
    debugCheckBuilds(builds);

    argParser.addOption(
      configFlag,
      abbr: 'c',
      defaultsTo: '',
      help:
          'Specify the build config to use for the target build (usually auto detected)',
      allowed: <String>[
        for (final Build build in runnableBuilds(environment, configs))
          build.name,
      ],
      allowedHelp: <String, String>{
        for (final Build build in runnableBuilds(environment, configs))
          build.name: build.gn.join(' '),
      },
    );
    argParser.addFlag(
      rbeFlag,
      defaultsTo: true,
      help: 'RBE is enabled by default when available. Use --no-rbe to '
            'disable it.',
    );
  }

  /// List of compatible builds.
  late final List<Build> builds;

  @override
  String get name => 'run';

  @override
  String get description => 'Run a Flutter app with a local engine build. '
      'All arguments after -- are forwarded to flutter run, e.g.: '
      'et run -- --profile '
      'et run -- -d macos '
      'See `flutter run --help` for a listing';

  Build? _lookup(String configName) {
    return builds.where((Build build) => build.name == configName).firstOrNull;
  }

  Build? _findHostBuild(Build? targetBuild) {
    if (targetBuild == null) {
      return null;
    }

    final String name = targetBuild.name;
    if (name.startsWith('host_')) {
      return targetBuild;
    }
    // TODO(johnmccutchan): This is brittle, it would be better if we encoded
    // the host config name in the target config.
    if (name.contains('_debug')) {
      return _lookup('host_debug');
    } else if (name.contains('_profile')) {
      return _lookup('host_profile');
    } else if (name.contains('_release')) {
      return _lookup('host_release');
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

  Future<String?> _selectTargetConfig() async {
    final String configName = argResults![configFlag] as String;
    if (configName.isNotEmpty) {
      return configName;
    }
    final String deviceId = _getDeviceId();
    final RunTarget? target =
        await detectAndSelectRunTarget(environment, deviceId);
    if (target == null) {
      return 'host_debug';
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
    final List<String> extraGnArgs = <String>[
      if (!useRbe) '--no-rbe',
    ];

    // First build the host.
    int r = await runBuild(environment, hostBuild, extraGnArgs: extraGnArgs);
    if (r != 0) {
      return r;
    }

    // Now build the target if it isn't the same.
    if (hostBuild.name != build.name) {
      r = await runBuild(environment, build, extraGnArgs: extraGnArgs);
      if (r != 0) {
        return r;
      }
    }

    // TODO(johnmccutchan): Be smart and if the user requested a profile
    // config, add the '--profile' flag when invoking flutter run.
    final ProcessRunnerResult result =
        await environment.processRunner.runProcess(
      <String>[
        'flutter',
        'run',
        '--local-engine-src-path',
        environment.engine.srcDir.path,
        '--local-engine',
        build.name,
        '--local-engine-host',
        hostBuild.name,
        ...argResults!.rest,
      ],
      runInShell: true,
      startMode: ProcessStartMode.inheritStdio,
    );
    return result.exitCode;
  }
}
