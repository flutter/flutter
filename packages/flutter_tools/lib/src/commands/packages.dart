// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../dart/generate_synthetic_packages.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand() {
    addSubcommand(PackagesGetCommand('get', false));
    addSubcommand(PackagesGetCommand('upgrade', true));
    addSubcommand(PackagesTestCommand());
    addSubcommand(PackagesPublishCommand());
    addSubcommand(PackagesForwardCommand('downgrade', 'Downgrade packages in a Flutter project', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('deps', 'Print package dependencies', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('run', 'Run an executable from a package', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('cache', 'Work with the Pub system cache'));
    addSubcommand(PackagesForwardCommand('version', 'Print Pub version'));
    addSubcommand(PackagesForwardCommand('uploader', 'Manage uploaders for a package on pub.dev'));
    addSubcommand(PackagesForwardCommand('global', 'Work with Pub global packages'));
    addSubcommand(PackagesForwardCommand('outdated', 'Analyze dependencies to find which ones can be upgraded', requiresPubspec: true));
    addSubcommand(PackagesPassthroughCommand());
  }

  @override
  final String name = 'pub';

  @override
  List<String> get aliases => const <String>['packages'];

  @override
  final String description = 'Commands for managing Flutter packages.';

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(this.name, this.upgrade) {
    requiresPubspecYaml();
    argParser.addFlag('offline',
      negatable: false,
      help: 'Use cached packages instead of accessing the network.',
    );
  }

  @override
  final String name;

  final bool upgrade;

  @override
  String get description {
    return '${ upgrade ? "Upgrade" : "Get" } packages in a Flutter project.';
  }

  @override
  String get invocation {
    return '${runner.executableName} pub $name [<target directory>]';
  }

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usageValues = <CustomDimensions, String>{};
    final String workingDirectory = argResults.rest.length == 1 ? argResults.rest[0] : null;
    final String target = findProjectRoot(workingDirectory);
    if (target == null) {
      return usageValues;
    }
    final FlutterProject rootProject = FlutterProject.fromPath(target);
    final bool hasPlugins = rootProject.flutterPluginsFile.existsSync();
    if (hasPlugins) {
      final int numberOfPlugins = (rootProject.flutterPluginsFile.readAsLinesSync()).length;
      usageValues[CustomDimensions.commandPackagesNumberPlugins] = '$numberOfPlugins';
    } else {
      usageValues[CustomDimensions.commandPackagesNumberPlugins] = '0';
    }
    usageValues[CustomDimensions.commandPackagesProjectModule] = '${rootProject.isModule}';
    usageValues[CustomDimensions.commandPackagesAndroidEmbeddingVersion] =
        rootProject.android.getEmbeddingVersion().toString().split('.').last;
    return usageValues;
  }

  Future<void> _runPubGet(String directory, FlutterProject flutterProject) async {
    if (flutterProject.manifest.generateSyntheticPackage) {
      final Environment environment = Environment(
        artifacts: globals.artifacts,
        logger: globals.logger,
        cacheDir: globals.cache.getRoot(),
        engineVersion: globals.flutterVersion.engineRevision,
        fileSystem: globals.fs,
        flutterRootDir: globals.fs.directory(Cache.flutterRoot),
        outputDir: globals.fs.directory(getBuildDirectory()),
        processManager: globals.processManager,
        projectDir: flutterProject.directory,
      );

      await generateLocalizationsSyntheticPackage(
        environment: environment,
        buildSystem: globals.buildSystem,
      );
    }

    final Stopwatch pubGetTimer = Stopwatch()..start();
    try {
      await pub.get(
        context: PubContext.pubGet,
        directory: directory,
        upgrade: upgrade ,
        offline: boolArg('offline'),
        checkLastModified: false,
        generateSyntheticPackage: flutterProject.manifest.generateSyntheticPackage,
      );
      pubGetTimer.stop();
      globals.flutterUsage.sendTiming('pub', 'get', pubGetTimer.elapsed, label: 'success');
    // Not limiting to catching Exception because the exception is rethrown.
    } catch (_) { // ignore: avoid_catches_without_on_clauses
      pubGetTimer.stop();
      globals.flutterUsage.sendTiming('pub', 'get', pubGetTimer.elapsed, label: 'failure');
      rethrow;
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.length > 1) {
      throwToolExit('Too many arguments.\n$usage');
    }

    final String workingDirectory = argResults.rest.length == 1 ? argResults.rest[0] : null;
    final String target = findProjectRoot(workingDirectory);
    if (target == null) {
      throwToolExit(
       'Expected to find project root in '
       '${ workingDirectory ?? "current working directory" }.'
      );
    }
    final FlutterProject rootProject = FlutterProject.fromPath(target);

    await _runPubGet(target, rootProject);
    await rootProject.ensureReadyForPlatformSpecificTooling(checkProjects: true);

    // Get/upgrade packages in example app as well
    if (rootProject.hasExampleApp) {
      final FlutterProject exampleProject = rootProject.example;
      await _runPubGet(exampleProject.directory.path, exampleProject);
      await exampleProject.ensureReadyForPlatformSpecificTooling(checkProjects: true);
    }

    return FlutterCommandResult.success();
  }
}

class PackagesTestCommand extends FlutterCommand {
  PackagesTestCommand() {
    requiresPubspecYaml();
  }

  @override
  String get name => 'test';

  @override
  String get description {
    return 'Run the "test" package.\n'
           'This is similar to "flutter test", but instead of hosting the tests in the '
           'flutter environment it hosts the tests in a pure Dart environment. The main '
           'differences are that the "dart:ui" library is not available and that tests '
           'run faster. This is helpful for testing libraries that do not depend on any '
           'packages from the Flutter SDK. It is equivalent to "pub run test".';
  }

  @override
  String get invocation {
    return '${runner.executableName} pub test [<tests...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.batch(<String>['run', 'test', ...argResults.rest], context: PubContext.runTest, retry: false);
    return FlutterCommandResult.success();
  }
}

class PackagesPublishCommand extends FlutterCommand {
  PackagesPublishCommand() {
    requiresPubspecYaml();
    argParser.addFlag('dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Validate but do not publish the package.',
    );
    argParser.addFlag('force',
      abbr: 'f',
      negatable: false,
      help: 'Publish without confirmation if there are no errors.',
    );
  }

  @override
  String get name => 'publish';

  @override
  String get description {
    return 'Publish the current package to pub.dev';
  }

  @override
  String get invocation {
    return '${runner.executableName} pub publish [--dry-run]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> args = <String>[
      ...argResults.rest,
      if (boolArg('dry-run')) '--dry-run',
      if (boolArg('force')) '--force',
    ];
    await pub.interactively(<String>['publish', ...args], stdio: globals.stdio);
    return FlutterCommandResult.success();
  }
}

class PackagesForwardCommand extends FlutterCommand {
  PackagesForwardCommand(this._commandName, this._description, {bool requiresPubspec = false}) {
    if (requiresPubspec) {
      requiresPubspecYaml();
    }
  }
  final String _commandName;
  final String _description;

  @override
  String get name => _commandName;

  @override
  String get description {
    return '$_description.\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner.executableName} pub $_commandName [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.interactively(<String>[_commandName, ...argResults.rest], stdio: globals.stdio);
    return FlutterCommandResult.success();
  }

}

class PackagesPassthroughCommand extends FlutterCommand {
  PackagesPassthroughCommand() {
    requiresPubspecYaml();
  }

  @override
  String get name => 'pub';

  @override
  String get description {
    return 'Pass the remaining arguments to Dart\'s "pub" tool.\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner.executableName} packages pub [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.interactively(argResults.rest, stdio: globals.stdio);
    return FlutterCommandResult.success();
  }
}
