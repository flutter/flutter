// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:package_config/package_config.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/localizations.dart';
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../package_graph.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand() {
    addSubcommand(
      PackagesGetCommand('get', "Get the current package's dependencies.", PubContext.pubGet),
    );
    addSubcommand(
      PackagesGetCommand(
        'upgrade',
        "Upgrade the current package's dependencies to latest versions.",
        PubContext.pubUpgrade,
      ),
    );
    addSubcommand(
      PackagesGetCommand('add', 'Add a dependency to pubspec.yaml.', PubContext.pubAdd),
    );
    addSubcommand(
      PackagesGetCommand(
        'remove',
        'Removes a dependency from the current package.',
        PubContext.pubRemove,
      ),
    );
    addSubcommand(PackagesTestCommand());
    addSubcommand(
      PackagesForwardCommand(
        'publish',
        'Publish the current package to pub.dartlang.org.',
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand(
        'downgrade',
        'Downgrade packages in a Flutter project.',
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand('deps', 'Print package dependencies.'),
    ); // path to package can be specified with --directory argument
    addSubcommand(
      PackagesForwardCommand('run', 'Run an executable from a package.', requiresPubspec: true),
    );
    addSubcommand(PackagesForwardCommand('cache', 'Work with the Pub system cache.'));
    addSubcommand(PackagesForwardCommand('version', 'Print Pub version.'));
    addSubcommand(PackagesForwardCommand('uploader', 'Manage uploaders for a package on pub.dev.'));
    addSubcommand(PackagesForwardCommand('login', 'Log into pub.dev.'));
    addSubcommand(PackagesForwardCommand('logout', 'Log out of pub.dev.'));
    addSubcommand(PackagesForwardCommand('global', 'Work with Pub global packages.'));
    addSubcommand(
      PackagesForwardCommand(
        'outdated',
        'Analyze dependencies to find which ones can be upgraded.',
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand('token', 'Manage authentication tokens for hosted pub repositories.'),
    );
    addSubcommand(PackagesPassthroughCommand());
  }

  @override
  final name = 'pub';

  @override
  List<String> get aliases => const <String>['packages'];

  @override
  final description = 'Commands for managing Flutter packages.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
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
    await pub.batch(<String>['run', 'test', ...argResults!.rest], context: PubContext.runTest);
    return FlutterCommandResult.success();
  }
}

class PackagesForwardCommand extends FlutterCommand {
  PackagesForwardCommand(this._commandName, this._description, {bool requiresPubspec = false}) {
    if (requiresPubspec) {
      requiresPubspecYaml();
    }
  }

  PubContext context = PubContext.pubForward;

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
    await pub.interactively(
      <String>[_commandName, ...subArgs],
      context: context,
      command: _commandName,
    );
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

  static final PubContext _context = PubContext.pubPassThrough;

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.interactively(command: 'pub', argResults!.rest, context: _context);
    return FlutterCommandResult.success();
  }
}

/// Represents the pub sub-commands that makes package-resolutions.
class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(this._commandName, this._description, this._context);

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final String _commandName;
  final String _description;
  final PubContext _context;

  FlutterProject? _rootProject;

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

  /// An [ArgParser] that accepts all options and flags that the
  ///
  /// `pub get`
  /// `pub upgrade`
  /// `pub downgrade`
  /// `pub add`
  /// `pub remove`
  ///
  /// commands accept.
  ArgParser get _permissiveArgParser {
    final argParser = ArgParser();
    argParser.addOption('directory', abbr: 'C');
    argParser.addFlag('offline');
    argParser.addFlag('dry-run', abbr: 'n');
    argParser.addFlag('help', abbr: 'h');
    argParser.addFlag('enforce-lockfile');
    argParser.addFlag('precompile');
    argParser.addFlag('major-versions');
    argParser.addFlag('example', defaultsTo: true);
    argParser.addOption('sdk');
    argParser.addOption('path');
    argParser.addOption('hosted-url');
    argParser.addOption('git-url');
    argParser.addOption('git-ref');
    argParser.addOption('git-path');
    argParser.addFlag('dev');
    argParser.addFlag('verbose', abbr: 'v');
    return argParser;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> rest = argResults!.rest;
    var isHelp = false;
    var example = true;
    var exampleWasParsed = false;
    String? directoryOption;
    var dryRun = false;
    try {
      final ArgResults results = _permissiveArgParser.parse(rest);
      isHelp = results['help'] as bool;
      directoryOption = results['directory'] as String?;
      example = results['example'] as bool;
      exampleWasParsed = results.wasParsed('example');
      dryRun = results['dry-run'] as bool;
    } on ArgParserException {
      // Let pub give the error message.
    }
    String? target;
    FlutterProject? rootProject;

    if (!isHelp) {
      target = findProjectRoot(globals.fs, directoryOption);
      if (target == null) {
        if (directoryOption == null) {
          throwToolExit('Expected to find project root in current working directory.');
        } else {
          throwToolExit('Expected to find project root in $directoryOption.');
        }
      }

      rootProject = FlutterProject.fromDirectory(globals.fs.directory(target));
      _rootProject = rootProject;
    }
    final String? relativeTarget = target == null ? null : globals.fs.path.relative(target);

    final List<String> subArgs = rest.toList()..removeWhere((String arg) => arg == '--');
    final timer = Stopwatch()..start();
    try {
      await pub.interactively(
        <String>[
          name,
          ...subArgs,
          // `dart pub get` and friends defaults to `--no-example`.
          if (!exampleWasParsed && target != null) '--example',
          if (directoryOption == null && relativeTarget != null) ...<String>[
            '--directory',
            relativeTarget,
          ],
        ],
        project: rootProject,
        context: _context,
        command: name,
        touchesPackageConfig: !(isHelp || dryRun),
      );
      final Duration elapsedDuration = timer.elapsed;
      analytics.send(
        Event.timing(
          workflow: 'pub',
          variableName: 'get',
          elapsedMilliseconds: elapsedDuration.inMilliseconds,
          label: 'success',
        ),
      );
      // Not limiting to catching Exception because the exception is rethrown.
    } catch (_) {
      final Duration elapsedDuration = timer.elapsed;
      analytics.send(
        Event.timing(
          workflow: 'pub',
          variableName: 'get',
          elapsedMilliseconds: elapsedDuration.inMilliseconds,
          label: 'failure',
        ),
      );
      rethrow;
    }

    if (rootProject != null) {
      // Walk through all workspace projects,and generate platform specific
      // tooling if needed.
      final PackageConfig packageConfig = await loadPackageConfigWithLogging(
        rootProject.packageConfig,
        logger: globals.logger,
      );
      final PackageGraph graph = PackageGraph.load(rootProject);
      // Iterate all root packages in the pub workspace to do Flutter specific
      // generation.
      for (final String workspaceRootName in graph.roots) {
        final Package? rootPackage = packageConfig[workspaceRootName];
        assert(rootPackage != null);
        final Uri rootUri = rootPackage!.root;

        final FlutterProject project = FlutterProject.fromDirectory(globals.fs.directory(rootUri));

        final environment = Environment(
          artifacts: globals.artifacts!,
          logger: globals.logger,
          cacheDir: globals.cache.getRoot(),
          engineVersion: globals.flutterVersion.engineRevision,
          fileSystem: globals.fs,
          flutterRootDir: globals.fs.directory(Cache.flutterRoot),
          outputDir: globals.fs.directory(getBuildDirectory()),
          processManager: globals.processManager,
          platform: globals.platform,
          analytics: analytics,
          projectDir: project.directory,
          packageConfigPath: packageConfigPath(),
          generateDartPluginRegistry: true,
        );
        if (project.manifest.generateLocalizations) {
          // If localizations were enabled, but we are not using synthetic packages.
          final BuildResult result = await globals.buildSystem.build(
            const GenerateLocalizationsTarget(),
            environment,
          );
          if (result.hasException) {
            throwToolExit(
              'Generating synthetic localizations package failed with ${result.exceptions.length} ${pluralize('error', result.exceptions.length)}:'
              '\n\n'
              '${result.exceptions.values.map<Object?>((ExceptionMeasurement e) => e.exception).join('\n\n')}',
            );
          }
        }

        // TODO(matanlurey): https://github.com/flutter/flutter/issues/163774.
        //
        // `flutter packages get` inherently is neither a debug or release build,
        // and since a future build (`flutter build apk`) will regenerate tooling
        // anyway, we assume this is fine.
        //
        // It won't be if they do `flutter build --no-pub`, though.
        const ignoreReleaseModeSinceItsNotABuildAndHopeItWorks = false;

        // We need to regenerate the platform specific tooling for both the project
        // itself and example(if present).
        await project.regeneratePlatformSpecificTooling(
          releaseMode: ignoreReleaseModeSinceItsNotABuildAndHopeItWorks,
        );
        if (example && project.hasExampleApp && project.example.pubspecFile.existsSync()) {
          final FlutterProject exampleProject = project.example;
          await exampleProject.regeneratePlatformSpecificTooling(
            releaseMode: ignoreReleaseModeSinceItsNotABuildAndHopeItWorks,
          );
        }
      }
    }

    return FlutterCommandResult.success();
  }

  late final Future<List<Plugin>> _pluginsFound = (() async {
    final FlutterProject? rootProject = _rootProject;
    if (rootProject == null) {
      return <Plugin>[];
    }

    return findPlugins(rootProject, throwOnError: false);
  })();

  late final String? _androidEmbeddingVersion = _rootProject?.android
      .getEmbeddingVersion()
      .toString()
      .split('.')
      .last;

  /// The pub packages usage values are incorrect since these are calculated/sent
  /// before pub get completes. This needs to be performed after dependency resolution.
  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    final FlutterProject? rootProject = _rootProject;
    if (rootProject == null) {
      return Event.commandUsageValues(workflow: commandPath, commandHasTerminal: hasTerminal);
    }

    final int numberPlugins;
    // Do not send plugin analytics if pub has not run before.
    final bool hasPlugins =
        rootProject.flutterPluginsDependenciesFile.existsSync() &&
        findPackageConfigFile(rootProject.directory) != null;
    if (hasPlugins) {
      // Do not fail pub get if package config files are invalid before pub has
      // had a chance to run.
      final List<Plugin> plugins = await _pluginsFound;
      numberPlugins = plugins.length;
    } else {
      numberPlugins = 0;
    }

    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      packagesNumberPlugins: numberPlugins,
      packagesProjectModule: rootProject.isModule,
      packagesAndroidEmbeddingVersion: _androidEmbeddingVersion,
    );
  }
}
