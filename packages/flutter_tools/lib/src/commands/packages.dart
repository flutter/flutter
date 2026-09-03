// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:args/args.dart';
import 'package:package_config/package_config.dart';
import 'package:pool/pool.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/localizations.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../flutter_plugins.dart';
import '../package_graph.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class PackagesCommand extends FlutterCommand {
  PackagesCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    super.verboseHelp,
  }) : _buildSystem = buildSystem,
       _toolContext = toolContext,
       super(toolContext: toolContext) {
    addSubcommand(
      PackagesGetCommand(
        'get',
        "Get the current package's dependencies.",
        PubContext.pubGet,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
      ),
    );
    addSubcommand(
      PackagesGetCommand(
        'upgrade',
        "Upgrade the current package's dependencies to latest versions.",
        PubContext.pubUpgrade,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
      ),
    );
    addSubcommand(
      PackagesGetCommand(
        'add',
        'Add a dependency to pubspec.yaml.',
        PubContext.pubAdd,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
      ),
    );
    addSubcommand(
      PackagesGetCommand(
        'remove',
        'Removes a dependency from the current package.',
        PubContext.pubRemove,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
      ),
    );
    addSubcommand(PackagesTestCommand(toolContext: _toolContext));
    addSubcommand(
      PackagesForwardCommand(
        'publish',
        'Publish the current package to pub.dartlang.org.',
        toolContext: _toolContext,
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand(
        'downgrade',
        'Downgrade packages in a Flutter project.',
        toolContext: _toolContext,
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand('deps', 'Print package dependencies.', toolContext: _toolContext),
    ); // path to package can be specified with --directory argument
    addSubcommand(
      PackagesForwardCommand(
        'run',
        'Run an executable from a package.',
        toolContext: _toolContext,
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand('cache', 'Work with the Pub system cache.', toolContext: _toolContext),
    );
    addSubcommand(
      PackagesForwardCommand('version', 'Print Pub version.', toolContext: _toolContext),
    );
    addSubcommand(
      PackagesForwardCommand(
        'uploader',
        'Manage uploaders for a package on pub.dev.',
        toolContext: _toolContext,
      ),
    );
    addSubcommand(PackagesForwardCommand('login', 'Log into pub.dev.', toolContext: _toolContext));
    addSubcommand(
      PackagesForwardCommand('logout', 'Log out of pub.dev.', toolContext: _toolContext),
    );
    addSubcommand(
      PackagesForwardCommand('global', 'Work with Pub global packages.', toolContext: _toolContext),
    );
    addSubcommand(
      PackagesForwardCommand(
        'outdated',
        'Analyze dependencies to find which ones can be upgraded.',
        toolContext: _toolContext,
        requiresPubspec: true,
      ),
    );
    addSubcommand(
      PackagesForwardCommand(
        'token',
        'Manage authentication tokens for hosted pub repositories.',
        toolContext: _toolContext,
      ),
    );
    addSubcommand(PackagesPassthroughCommand(toolContext: _toolContext));
  }

  final ToolContext _toolContext;
  final BuildSystem _buildSystem;

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
  PackagesTestCommand({required ToolContext toolContext})
    : _toolContext = toolContext,
      super(toolContext: toolContext) {
    requiresPubspecYaml();
  }

  final ToolContext _toolContext;

  late final Pub _pub = _createPub(_toolContext);

  @override
  String get name => 'test';

  @override
  final description = 'Run the test runner for the current package.';

  @override
  ArgParser argParser = ArgParser.allowAnything();

  @override
  String get invocation {
    return '${runner!.executableName} pub test [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await _pub.batch(<String>['run', 'test', ...argResults!.rest], context: PubContext.runTest);
    return FlutterCommandResult.success();
  }
}

class PackagesForwardCommand extends FlutterCommand {
  PackagesForwardCommand(
    this._commandName,
    this._description, {
    required ToolContext toolContext,
    bool requiresPubspec = false,
  }) : _toolContext = toolContext,
       super(toolContext: toolContext) {
    if (requiresPubspec) {
      requiresPubspecYaml();
    }
  }

  final ToolContext _toolContext;

  late final Pub _pub = _createPub(_toolContext);

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
    await _pub.interactively(
      <String>[_commandName, ...subArgs],
      command: _commandName,
      context: PubContext.pubForward,
    );
    return FlutterCommandResult.success();
  }
}

class PackagesPassthroughCommand extends FlutterCommand {
  PackagesPassthroughCommand({required ToolContext toolContext})
    : _toolContext = toolContext,
      super(toolContext: toolContext);

  final ToolContext _toolContext;

  @override
  ArgParser argParser = ArgParser.allowAnything();

  late final Pub _pub = _createPub(_toolContext);

  @override
  String get name => 'pub';

  @override
  final description = 'Pass remaining arguments to Pub.';

  @override
  String get invocation {
    return '${runner!.executableName} packages pub [<arguments...>]';
  }

  static final PubContext _context = PubContext.pubPassThrough;

  @override
  Future<FlutterCommandResult> runCommand() async {
    await _pub.interactively(command: 'pub', argResults!.rest, context: _context);
    return FlutterCommandResult.success();
  }
}

/// Represents the pub sub-commands that makes package-resolutions.
class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(
    this._commandName,
    this._description,
    this._context, {
    required BuildSystem buildSystem,
    required ToolContext toolContext,
  }) : _buildSystem = buildSystem,
       _toolContext = toolContext,
       super(toolContext: toolContext);

  final ToolContext _toolContext;
  final BuildSystem _buildSystem;

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

  late final Pub _pub = _createPub(_toolContext);

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
    final FileSystem fs = _toolContext.fs;
    final Logger logger = _toolContext.logger;
    final FlutterProjectFactory projectFactory = _toolContext.projectFactory;

    String? target;
    FlutterProject? rootProject;

    if (!isHelp) {
      target = findProjectRoot(fs, directoryOption);
      if (target == null) {
        if (directoryOption == null) {
          throwToolExit('Expected to find project root in current working directory.');
        } else {
          throwToolExit('Expected to find project root in $directoryOption.');
        }
      }

      rootProject = projectFactory.fromDirectory(fs.directory(target));
      _rootProject = rootProject;
    }
    final String? relativeTarget = target == null ? null : fs.path.relative(target);

    final List<String> subArgs = rest.toList()..removeWhere((String arg) => arg == '--');
    final timer = Stopwatch()..start();
    try {
      await _pub.interactively(
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
        logger: logger,
      );
      final PackageGraph graph = PackageGraph.load(rootProject);

      // Build a cache of all pubspec.yaml contents once, keyed by package root
      // URI. This avoids re-reading the same files for every workspace package
      // during post-processing.
      final PubspecCache pubspecCache = await buildPubspecCache(packageConfig, fileSystem: fs);
      // Process workspace root packages concurrently, capped to 64 to
      // saturate I/O without exhausting file descriptors or system resources.
      await Pool(64).forEach<String, void>(graph.roots, (String workspaceRootName) async {
        final Package? rootPackage = packageConfig[workspaceRootName];
        assert(rootPackage != null);
        final Uri rootUri = rootPackage!.root;

        final FlutterProject project = projectFactory.fromDirectory(fs.directory(rootUri));

        if (project.manifest.generateLocalizations) {
          final environment = Environment(
            artifacts: _toolContext.artifacts,
            logger: logger,
            cacheDir: _toolContext.cache.getRoot(),
            engineVersion: _toolContext.flutterVersion.engineRevision,
            fileSystem: fs,
            flutterRootDir: fs.directory(Cache.flutterRoot),
            outputDir: fs.directory(getBuildDirectory(_toolContext.config, fs)),
            processManager: _toolContext.processManager,
            platform: _toolContext.platform,
            analytics: analytics,
            projectDir: project.directory,
            packageConfigPath: packageConfigPath(),
            generateDartPluginRegistry: true,
          );
          // If localizations were enabled, but we are not using synthetic packages.
          final BuildResult result = await _buildSystem.build(
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
        // We need to regenerate the platform specific tooling for both the
        // project itself and example (if present).
        //
        // Workspace packages that do not depend on Flutter (such as a pub
        // workspace root that is a plain Dart package) are skipped, so that a
        // stray ios/ or android/ directory in one of them is not populated
        // with Flutter project files.
        // See https://github.com/flutter/flutter/issues/189550.
        if (_dependsOnFlutter(graph, workspaceRootName)) {
          await project.regeneratePlatformSpecificTooling(
            releaseMode: ignoreReleaseModeSinceItsNotABuildAndHopeItWorks,
            pubspecCache: pubspecCache,
            packageGraph: graph,
            packageConfig: packageConfig,
          );
        }
        if (example && project.hasExampleApp && project.example.pubspecFile.existsSync()) {
          final FlutterProject exampleProject = project.example;
          // Skip if the example is already a workspace root — it will be
          // (or has already been) processed in the main loop, avoiding
          // double post-processing.
          if (!graph.roots.contains(exampleProject.manifest.appName)) {
            await exampleProject.regeneratePlatformSpecificTooling(
              releaseMode: ignoreReleaseModeSinceItsNotABuildAndHopeItWorks,
              pubspecCache: pubspecCache,
              packageGraph: graph,
              packageConfig: packageConfig,
            );
          }
        }
      }).drain<void>();
    }

    return FlutterCommandResult.success();
  }

  /// Whether [packageName] depends on the `flutter` package, directly or
  /// transitively, according to the resolved package [graph].
  static bool _dependsOnFlutter(PackageGraph graph, String packageName) {
    final visited = <String>{};
    final toVisit = Queue<String>.of(<String>[packageName]);
    while (toVisit.isNotEmpty) {
      final String current = toVisit.removeFirst();
      if (!visited.add(current)) {
        continue;
      }
      if (current == 'flutter') {
        return true;
      }
      final List<String>? dependencies = graph.dependencies[current];
      if (dependencies != null) {
        toVisit.addAll(dependencies);
      }
    }
    return false;
  }

  late final Future<List<Plugin>> _pluginsFound = (() async {
    final FlutterProject? rootProject = _rootProject;
    if (rootProject == null) {
      return <Plugin>[];
    }

    return findPlugins(rootProject, logger: _toolContext.logger, throwOnError: false);
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

Pub _createPub(ToolContext toolContext) => Pub(
  botDetector: toolContext.botDetector,
  fileSystem: toolContext.fs,
  logger: toolContext.logger,
  platform: toolContext.platform,
  processManager: toolContext.processManager,
  stdio: toolContext.stdio,
);
