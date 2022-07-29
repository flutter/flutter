// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../dart/generate_synthetic_packages.dart';
import '../dart/pub.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand() {
    addSubcommand(PackagesGetCommand('get', false));
    addSubcommand(PackagesInteractiveGetCommand('upgrade', "Upgrade the current package's dependencies to latest versions."));
    addSubcommand(PackagesInteractiveGetCommand('add', 'Add a dependency to pubspec.yaml.'));
    addSubcommand(PackagesInteractiveGetCommand('remove', 'Removes a dependency from the current package.'));
    addSubcommand(PackagesTestCommand());
    addSubcommand(PackagesForwardCommand('publish', 'Publish the current package to pub.dartlang.org.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('downgrade', 'Downgrade packages in a Flutter project.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('deps', 'Print package dependencies.')); // path to package can be specified with --directory argument
    addSubcommand(PackagesForwardCommand('run', 'Run an executable from a package.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('cache', 'Work with the Pub system cache.'));
    addSubcommand(PackagesForwardCommand('version', 'Print Pub version.'));
    addSubcommand(PackagesForwardCommand('uploader', 'Manage uploaders for a package on pub.dev.'));
    addSubcommand(PackagesForwardCommand('login', 'Log into pub.dev.'));
    addSubcommand(PackagesForwardCommand('logout', 'Log out of pub.dev.'));
    addSubcommand(PackagesForwardCommand('global', 'Work with Pub global packages.'));
    addSubcommand(PackagesForwardCommand('outdated', 'Analyze dependencies to find which ones can be upgraded.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('token', 'Manage authentication tokens for hosted pub repositories.'));
    addSubcommand(PackagesPassthroughCommand());
  }

  @override
  final String name = 'pub';

  @override
  List<String> get aliases => const <String>['packages'];

  @override
  final String description = 'Commands for managing Flutter packages.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(this.name, this.upgrade) {
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
    return '${runner!.executableName} pub $name [<target directory>]';
  }

  /// The pub packages usage values are incorrect since these are calculated/sent
  /// before pub get completes. This needs to be performed after dependency resolution.
  @override
  Future<CustomDimensions> get usageValues async {
    final ArgResults argumentResults = argResults!;
    final String? workingDirectory = argumentResults.rest.length == 1 ? argumentResults.rest[0] : null;
    final String? target = findProjectRoot(globals.fs, workingDirectory);
    if (target == null) {
      return const CustomDimensions();
    }

    int numberPlugins;

    final FlutterProject rootProject = FlutterProject.fromDirectory(globals.fs.directory(target));
    // Do not send plugin analytics if pub has not run before.
    final bool hasPlugins = rootProject.flutterPluginsDependenciesFile.existsSync()
      && rootProject.packageConfigFile.existsSync();
    if (hasPlugins) {
      // Do not fail pub get if package config files are invalid before pub has
      // had a chance to run.
      final List<Plugin> plugins = await findPlugins(rootProject, throwOnError: false);
      numberPlugins = plugins.length;
    } else {
      numberPlugins = 0;
    }

    return CustomDimensions(
      commandPackagesNumberPlugins: numberPlugins,
      commandPackagesProjectModule: rootProject.isModule,
      commandPackagesAndroidEmbeddingVersion: rootProject.android.getEmbeddingVersion().toString().split('.').last,
    );
  }

  Future<void> _runPubGet(String directory, FlutterProject flutterProject) async {
    if (flutterProject.manifest.generateSyntheticPackage) {
      final Environment environment = Environment(
        artifacts: globals.artifacts!,
        logger: globals.logger,
        cacheDir: globals.cache.getRoot(),
        engineVersion: globals.flutterVersion.engineRevision,
        fileSystem: globals.fs,
        flutterRootDir: globals.fs.directory(Cache.flutterRoot),
        outputDir: globals.fs.directory(getBuildDirectory()),
        processManager: globals.processManager,
        platform: globals.platform,
        projectDir: flutterProject.directory,
        generateDartPluginRegistry: true,
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
        upgrade: upgrade,
        shouldSkipThirdPartyGenerator: false,
        offline: boolArgDeprecated('offline'),
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
    final ArgResults argumentResults = argResults!;
    if (argumentResults.rest.length > 1) {
      throwToolExit('Too many arguments.\n$usage');
    }

    final String? workingDirectory = argumentResults.rest.length == 1 ? argumentResults.rest[0] : null;
    final String? target = findProjectRoot(globals.fs, workingDirectory);
    if (target == null) {
      throwToolExit(
        'Expected to find project root in '
        '${ workingDirectory ?? "current working directory" }.'
      );
    }
    final FlutterProject rootProject = FlutterProject.fromDirectory(globals.fs.directory(target));

    await _runPubGet(target, rootProject);
    await rootProject.regeneratePlatformSpecificTooling();

    // Get/upgrade packages in example app as well
    if (rootProject.hasExampleApp && rootProject.example.pubspecFile.existsSync()) {
      final FlutterProject exampleProject = rootProject.example;
      await _runPubGet(exampleProject.directory.path, exampleProject);
      await exampleProject.regeneratePlatformSpecificTooling();
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
    return '${runner!.executableName} pub test [<tests...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.batch(<String>['run', 'test', ...argResults!.rest], context: PubContext.runTest, retry: false);
    return FlutterCommandResult.success();
  }
}

class PackagesForwardCommand extends FlutterCommand {
  PackagesForwardCommand(this._commandName, this._description, {bool requiresPubspec = false}) {
    if (requiresPubspec) {
      requiresPubspecYaml();
    }
  }

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final String _commandName;
  final String _description;

  @override
  String get name => _commandName;

  @override
  String get description {
    return '$_description\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} pub $_commandName [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> subArgs = argResults!.rest.toList()
      ..removeWhere((String arg) => arg == '--');
    await pub.interactively(<String>[_commandName, ...subArgs], stdio: globals.stdio);
    return FlutterCommandResult.success();
  }
}

class PackagesPassthroughCommand extends FlutterCommand {
  @override
  ArgParser argParser = ArgParser.allowAnything();

  @override
  String get name => 'pub';

  @override
  String get description {
    return 'Pass the remaining arguments to Dart\'s "pub" tool.\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} packages pub [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.interactively(argResults!.rest, stdio: globals.stdio);
    return FlutterCommandResult.success();
  }
}

class PackagesInteractiveGetCommand extends FlutterCommand {
  PackagesInteractiveGetCommand(this._commandName, this._description);

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final String _commandName;
  final String _description;

  @override
  String get name => _commandName;

  @override
  String get description {
    return '$_description\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} pub $_commandName [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    List<String> rest = argResults!.rest;
    final bool isHelp = rest.contains('-h') || rest.contains('--help');
    String? target;
    if (rest.length == 1 && (rest.single.contains('/') || rest.single.contains(r'\'))) {
      // For historical reasons, if there is one argument to the command and it contains
      // a multiple-component path (i.e. contains a slash) then we use that to determine
      // to which project we're applying the command.
      target = findProjectRoot(globals.fs, rest.single);
      rest = <String>[];
    } else {
      target = findProjectRoot(globals.fs);
    }

    FlutterProject? flutterProject;
    if (!isHelp) {
      if (target == null) {
        throwToolExit('Expected to find project root in current working directory.');
      }
      flutterProject = FlutterProject.fromDirectory(globals.fs.directory(target));

      if (flutterProject.manifest.generateSyntheticPackage) {
        final Environment environment = Environment(
          artifacts: globals.artifacts!,
          logger: globals.logger,
          cacheDir: globals.cache.getRoot(),
          engineVersion: globals.flutterVersion.engineRevision,
          fileSystem: globals.fs,
          flutterRootDir: globals.fs.directory(Cache.flutterRoot),
          outputDir: globals.fs.directory(getBuildDirectory()),
          processManager: globals.processManager,
          platform: globals.platform,
          projectDir: flutterProject.directory,
          generateDartPluginRegistry: true,
        );

        await generateLocalizationsSyntheticPackage(
          environment: environment,
          buildSystem: globals.buildSystem,
        );
      }
    }

    final List<String> subArgs = rest.toList()..removeWhere((String arg) => arg == '--');
    await pub.interactively(
      <String>[name, ...subArgs],
      directory: target,
      stdio: globals.stdio,
      touchesPackageConfig: !isHelp,
      generateSyntheticPackage: flutterProject?.manifest.generateSyntheticPackage ?? false,
    );

    await flutterProject?.regeneratePlatformSpecificTooling();
    return FlutterCommandResult.success();
  }
}
