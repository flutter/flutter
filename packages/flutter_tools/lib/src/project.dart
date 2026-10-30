// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import 'android/android_builder.dart';
import 'android/gradle_utils.dart' as gradle;
import 'base/common.dart';
import 'base/config.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/project_migrator.dart';
import 'base/utils.dart';
import 'base/version.dart';
import 'base/yaml.dart';
import 'build_info.dart';
import 'bundle.dart' as bundle;
import 'cache.dart';
import 'cmake_project.dart';
import 'context/tool_context.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'features.dart';
import 'flutter_manifest.dart';
import 'flutter_plugins.dart';
import 'globals.dart' as globals;
import 'ios/plist_parser.dart';
import 'ios/xcodeproj.dart';
import 'macos/xcode.dart';
import 'migrations/analysis_options_migration.dart';
import 'package_graph.dart';
import 'platform_plugins.dart';
import 'project_validator_result.dart';
import 'template.dart';
import 'xcode_project.dart';

export 'cmake_project.dart';
export 'xcode_project.dart';

/// Enum for each officially supported platform.
enum SupportedPlatform {
  android,
  ios,
  linux,
  macos,
  web,
  windows,
  fuchsia,
  root, // Special platform to represent the root project directory
}

class FlutterProjectFactory {
  FlutterProjectFactory({
    required this._fileSystem,
    required this._logger,
    this._config,
    this._featureFlags,
    this._featureFlagsBuilder,
    this._plistParser,
    this._xcode,
    this._xcodeBuilder,
    this._xcodeProjectInterpreter,
    this._xcodeProjectInterpreterBuilder,
  });

  final Config? _config;
  final FeatureFlags? _featureFlags;
  final FeatureFlags Function()? _featureFlagsBuilder;
  final FileSystem _fileSystem;
  final Logger _logger;
  final PlistParser? _plistParser;
  final Xcode? _xcode;
  final Xcode? Function()? _xcodeBuilder;
  final XcodeProjectInterpreter? _xcodeProjectInterpreter;
  final XcodeProjectInterpreter? Function()? _xcodeProjectInterpreterBuilder;

  @visibleForTesting
  final projects = <String, FlutterProject>{};

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject fromDirectory(Directory directory) {
    final Config? config = _config;
    final Directory? buildDirectory = config != null
        ? directory.childDirectory(getBuildDirectory(config, directory.fileSystem))
        : null;
    final FeatureFlags? resolvedFeatureFlags = _featureFlags ?? _featureFlagsBuilder?.call();
    final Xcode? resolvedXcode = _xcode ?? _xcodeBuilder?.call();
    final XcodeProjectInterpreter? resolvedXcodeProjectInterpreter =
        _xcodeProjectInterpreter ?? _xcodeProjectInterpreterBuilder?.call();
    final File pubspec = directory.childFile(bundle.defaultManifestPath);
    if (!pubspec.existsSync()) {
      final FlutterManifest manifest = FlutterProject._readManifest(
        pubspec.path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory).childFile(bundle.defaultManifestPath).path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      return FlutterProject(
        directory,
        manifest,
        exampleManifest,
        buildDirectory: buildDirectory,
        featureFlags: resolvedFeatureFlags,
        plistParser: _plistParser,
        projectFactory: this,
        xcode: resolvedXcode,
        xcodeProjectInterpreter: resolvedXcodeProjectInterpreter,
      );
    }
    return projects.putIfAbsent(directory.path, () {
      final FlutterManifest manifest = FlutterProject._readManifest(
        pubspec.path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory).childFile(bundle.defaultManifestPath).path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      return FlutterProject(
        directory,
        manifest,
        exampleManifest,
        buildDirectory: buildDirectory,
        featureFlags: resolvedFeatureFlags,
        plistParser: _plistParser,
        projectFactory: this,
        xcode: resolvedXcode,
        xcodeProjectInterpreter: resolvedXcodeProjectInterpreter,
      );
    });
  }

  /// Invalidate any cached [FlutterProject] for the given [directory].
  void invalidate(Directory directory) {
    projects.remove(directory.path);
  }
}

/// Represents the contents of a Flutter project at the specified [directory].
///
/// [FlutterManifest] information is read from `pubspec.yaml` and
/// `example/pubspec.yaml` files on construction of a [FlutterProject] instance.
/// The constructed instance carries an immutable snapshot representation of the
/// presence and content of those files. Accordingly, [FlutterProject] instances
/// should be discarded upon changes to the `pubspec.yaml` files, but can be
/// used across changes to other files, as no other file-level information is
/// cached.
class FlutterProject {
  @visibleForTesting
  FlutterProject(
    this.directory,
    FlutterManifest manifest,
    this._exampleManifest, {
    this._buildDirectory,
    this._featureFlags,
    this._plistParser,
    this._projectFactory,
    this._xcode,
    this._xcodeProjectInterpreter,
  }) {
    _setManifest(manifest);
  }

  final FeatureFlags? _featureFlags;
  final PlistParser? _plistParser;
  final FlutterProjectFactory? _projectFactory;
  final Xcode? _xcode;
  final XcodeProjectInterpreter? _xcodeProjectInterpreter;

  FlutterProject? _workspaceRoot;
  bool _searchedForWorkspaceRoot = false;

  /// Returns the workspace root project if this project is a member of a workspace.
  ///
  /// Returns null if this project is not part of a workspace or is itself the workspace root.
  FlutterProject? get workspaceRoot {
    if (_searchedForWorkspaceRoot) {
      return _workspaceRoot;
    }
    _searchedForWorkspaceRoot = true;
    _workspaceRoot = _findWorkspaceRoot();
    return _workspaceRoot;
  }

  FlutterProject? _findWorkspaceRoot() {
    final FileSystem fileSystem = directory.fileSystem;
    final String normalizedPath = fileSystem.path.normalize(directory.absolute.path);
    Directory candidate = fileSystem.directory(normalizedPath);

    while (true) {
      final Directory parent = candidate.parent;
      if (fileSystem.path.equals(parent.path, candidate.path)) {
        break;
      }
      candidate = parent;
      final File pubspec = candidate.childFile('pubspec.yaml');
      if (!pubspec.existsSync()) {
        continue;
      }
      try {
        final FlutterManifest manifest = FlutterProject._readManifest(
          pubspec.path,
          logger: globals.logger,
          fileSystem: fileSystem,
        );
        if (manifest.workspace.isNotEmpty) {
          final String relativePath = fileSystem.path.relative(
            normalizedPath,
            from: candidate.path,
          );
          final bool isMember = manifest.workspace.any((String entry) {
            final glob = Glob(entry, context: fileSystem.path);
            return glob.matches(relativePath);
          });
          if (isMember) {
            return _projectFactory?.fromDirectory(candidate) ??
                FlutterProject.fromDirectory(candidate);
          }
        }
      } on Exception catch (_) {
        // Ignore manifest reading errors.
      }
    }
    return null;
  }

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromDirectory(Directory directory) =>
      globals.projectFactory.fromDirectory(directory);

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject current() =>
      globals.projectFactory.fromDirectory(globals.fs.currentDirectory);

  /// Create a [FlutterProject] and bypass the project caching.
  @visibleForTesting
  static FlutterProject fromDirectoryTest(
    Directory directory, [
    Logger? logger,
    Directory? buildDirectory,
  ]) {
    final FileSystem fileSystem = directory.fileSystem;
    final Logger manifestLogger = logger ?? BufferLogger.test();
    final FlutterManifest manifest = FlutterProject._readManifest(
      directory.childFile(bundle.defaultManifestPath).path,
      logger: manifestLogger,
      fileSystem: fileSystem,
    );
    final FlutterManifest exampleManifest = FlutterProject._readManifest(
      FlutterProject._exampleDirectory(directory).childFile(bundle.defaultManifestPath).path,
      logger: manifestLogger,
      fileSystem: fileSystem,
    );
    return FlutterProject(
      directory,
      manifest,
      exampleManifest,
      buildDirectory: buildDirectory ?? directory.childDirectory('build'),
    );
  }

  /// The location of this project.
  final Directory directory;

  final Directory? _buildDirectory;

  /// The location of the build folder.
  Directory get buildDirectory => _buildDirectory ?? directory.childDirectory('build');

  /// The manifest of this project.
  FlutterManifest get manifest => _manifest;
  late FlutterManifest _manifest;

  /// The manifest of the example sub-project of this project.
  final FlutterManifest _exampleManifest;

  /// List of [FlutterProject]s corresponding to the workspace entries.
  List<FlutterProject> get workspaceProjects => _workspaceProjects;
  late List<FlutterProject> _workspaceProjects;

  void _setManifest(FlutterManifest manifest) {
    _manifest = manifest;
    _searchedForWorkspaceRoot = false;
    _workspaceRoot = null;

    // Update the workspace projects based on the new manifest.
    _workspaceProjects = <FlutterProject>[];
    if (!directory.existsSync()) {
      return;
    }
    for (final String entry in manifest.workspace) {
      for (final Directory entity in _resolveWorkspacePattern(directory, entry)) {
        if (entity.childFile('pubspec.yaml').existsSync()) {
          try {
            _workspaceProjects.add(
              _projectFactory?.fromDirectory(entity) ?? FlutterProject.fromDirectory(entity),
            );
          } on Exception catch (_) {
            // Ignore child projects with invalid manifests.
          }
        }
      }
    }
  }

  /// Resolves the given workspace [pattern] relative to [root] to find all
  /// matching package root directories.
  ///
  /// Evaluates the pattern segment-by-segment using shallow directory listings
  /// to avoid deep recursive tree traversal into build artifacts or caches
  /// (such as Gradle `.transforms/...`) that can exceed Windows `MAX_PATH`
  /// limits. Hidden directories (starting with `.`) and `build/` directories
  /// are ignored during matching.
  ///
  /// Supports exact relative paths, single-level glob patterns (e.g. `packages/*`),
  /// and recursive multi-level directory descent (`**`).
  static List<Directory> _resolveWorkspacePattern(Directory root, String pattern) {
    final List<String> segments = pattern
        .replaceAll(r'\', '/')
        .split('/')
        .where((String s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return const <Directory>[];
    }

    var currentDirs = <Directory>[root];

    for (final segment in segments) {
      if (segment == '**') {
        final nextDirs = <Directory>[];
        final visited = <String>{};
        for (final dir in currentDirs) {
          if (!dir.existsSync()) {
            continue;
          }
          if (visited.add(dir.path)) {
            nextDirs.add(dir);
            _collectSubdirectories(dir, nextDirs, visited);
          }
        }
        currentDirs = nextDirs;
      } else {
        final glob = Glob(segment, context: root.fileSystem.path);
        currentDirs = currentDirs.expand((Directory dir) {
          if (!dir.existsSync()) {
            return const <Directory>[];
          }
          try {
            return dir.listSync(followLinks: false).whereType<Directory>().where((Directory d) {
              final String name = d.basename;
              return !name.startsWith('.') && name != 'build' && glob.matches(name);
            });
          } on FileSystemException {
            return const <Directory>[];
          }
        }).toList();
      }
    }

    return currentDirs;
  }

  /// Recursively collects all subdirectories under [dir], excluding hidden
  /// directories (starting with `.`) and `build/` directories.
  ///
  /// Tracks [visited] paths to prevent infinite loops from cyclic directory
  /// structures or overlapping search roots.
  static void _collectSubdirectories(Directory dir, List<Directory> results, Set<String> visited) {
    try {
      for (final FileSystemEntity entity in dir.listSync(followLinks: false)) {
        if (entity is Directory) {
          final String name = entity.basename;
          if (!name.startsWith('.') && name != 'build') {
            if (visited.add(entity.path)) {
              results.add(entity);
              _collectSubdirectories(entity, results, visited);
            }
          }
        }
      }
    } on FileSystemException {
      // Ignore unreadable or transient directories.
    }
  }

  /// The set of organization names found in this project as
  /// part of iOS product bundle identifier, Android application ID, or
  /// Gradle group ID.
  Future<Set<String>> get organizationNames async {
    final candidates = <String>[];

    if (ios.existsSync()) {
      // Don't require iOS build info, this method is only
      // used during create as best-effort, use the
      // default target bundle identifier.
      try {
        final String? bundleIdentifier = await ios.productBundleIdentifier(null);
        if (bundleIdentifier != null) {
          candidates.add(bundleIdentifier);
        }
      } on ToolExit {
        // It's possible that while parsing the build info for the ios project
        // that the bundleIdentifier can't be resolve. However, we would like
        // skip parsing that id in favor of searching in other place. We can
        // consider a tool exit in this case to be non fatal for the program.
      }
    }
    if (android.existsSync()) {
      final String? applicationId = android.applicationId;
      final String? group = android.group;
      candidates.addAll(<String>[?applicationId, ?group]);
    }
    if (example.android.existsSync()) {
      final String? applicationId = example.android.applicationId;
      if (applicationId != null) {
        candidates.add(applicationId);
      }
    }
    if (example.ios.existsSync()) {
      final String? bundleIdentifier = await example.ios.productBundleIdentifier(null);
      if (bundleIdentifier != null) {
        candidates.add(bundleIdentifier);
      }
    }
    return Set<String>.of(
      candidates.map<String?>(_organizationNameFromPackageName).whereType<String>(),
    );
  }

  String? _organizationNameFromPackageName(String packageName) {
    if (0 <= packageName.lastIndexOf('.')) {
      return packageName.substring(0, packageName.lastIndexOf('.'));
    }
    return null;
  }

  /// The iOS sub project of this project.
  late final ios = IosProject.fromFlutter(
    this,
    featureFlags: _featureFlags,
    plistParser: _plistParser,
    xcode: _xcode,
    xcodeProjectInterpreter: _xcodeProjectInterpreter,
  );

  /// The Android sub project of this project.
  late final android = AndroidProject._(this);

  /// The web sub project of this project.
  late final web = WebProject._(this);

  /// The MacOS sub project of this project.
  late final macos = MacOSProject.fromFlutter(
    this,
    featureFlags: _featureFlags,
    xcode: _xcode,
    xcodeProjectInterpreter: _xcodeProjectInterpreter,
  );

  /// The Linux sub project of this project.
  late final linux = LinuxProject.fromFlutter(this);

  /// The Windows sub project of this project.
  late final windows = WindowsProject.fromFlutter(this);

  /// The Fuchsia sub project of this project.
  late final fuchsia = FuchsiaProject._(this);

  /// The `pubspec.yaml` file of this project.
  File get pubspecFile => directory.childFile('pubspec.yaml');

  /// The `.metadata` file of this project.
  File get metadataFile => directory.childFile('.metadata');

  /// The `.flutter-plugins-dependencies` file of this project.
  ///
  /// Contains the dependencies each plugin depends on.
  File get flutterPluginsDependenciesFile => directory.childFile('.flutter-plugins-dependencies');

  /// The `.gitignore` file of this project.
  File get gitignoreFile => directory.childFile('.gitignore');

  File get packageConfig => findPackageConfigFileOrDefault(directory);

  /// The `.dart-tool` directory of this project.
  Directory get dartTool => directory.childDirectory('.dart_tool');

  /// The location of the generated scaffolding project for hosting widget
  /// previews from this project.
  late final Directory widgetPreviewScaffold = directory.childDirectory('.widget_preview');

  /// The directory containing the generated code for this project.
  Directory get generated => directory.absolute
      .childDirectory('.dart_tool')
      .childDirectory('build')
      .childDirectory('generated')
      .childDirectory(manifest.appName);

  /// The set of directories created by the tool containing ephemeral state.
  // TODO(bkonyi): provide getters for each project type that returns the set
  // of known ephemeral files / directories.
  Set<Directory> get ephemeralDirectories => UnmodifiableSetView(_ephemeralDirectories);
  late final _ephemeralDirectories = <Directory>{
    buildDirectory,
    android.ephemeralDirectory,
    ios.ephemeralDirectory,
    ios.ephemeralModuleDirectory,
    ios.symlinks,
    linux.ephemeralDirectory,
    macos.ephemeralDirectory,
    windows.ephemeralDirectory,
  };

  /// The generated Dart plugin registrant for non-web platforms.
  File get dartPluginRegistrant =>
      dartTool.childDirectory('flutter_build').childFile('dart_plugin_registrant.dart');

  /// The example sub-project of this project.
  FlutterProject get example => FlutterProject(
    _exampleDirectory(directory),
    _exampleManifest,
    FlutterManifest.empty(logger: _manifest.logger),
    featureFlags: _featureFlags,
    plistParser: _plistParser,
    projectFactory: _projectFactory,
    xcode: _xcode,
    xcodeProjectInterpreter: _xcodeProjectInterpreter,
  );

  /// The generated scaffolding project for hosting widget previews from this
  /// project.
  late final FlutterProject widgetPreviewScaffoldProject = FlutterProject.fromDirectory(
    widgetPreviewScaffold,
  );

  /// True if this project is a Flutter module project.
  bool get isModule => manifest.isModule;

  /// True if this project is a Flutter plugin project.
  bool get isPlugin => manifest.isPlugin;

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => manifest.usesAndroidX;

  /// True if this project has an example application.
  bool get hasExampleApp => _exampleDirectory(directory).existsSync();

  /// Converts this project into a serializable [ExtensionFlutterProject] representation
  /// for tool extensions.
  ExtensionFlutterProject toExtensionProject() {
    return ExtensionFlutterProject(
      appName: manifest.appName,
      buildDirectory: buildDirectory.uri,
      directory: directory.uri,
      appVersion: manifest.appVersion,
      dependencies: <String>{...manifest.dependencies},
      isEmpty: manifest.isEmpty,
      isModule: isModule,
      isPlugin: isPlugin,
      workspace: <String>[...manifest.workspace],
    );
  }

  /// Returns a list of platform names that are supported by the project.
  List<SupportedPlatform> getSupportedPlatforms({bool includeRoot = false}) {
    return <SupportedPlatform>[
      if (includeRoot) SupportedPlatform.root,
      if (android.existsSync()) SupportedPlatform.android,
      if (ios.exists) SupportedPlatform.ios,
      if (web.existsSync()) SupportedPlatform.web,
      if (macos.existsSync()) SupportedPlatform.macos,
      if (linux.existsSync()) SupportedPlatform.linux,
      if (windows.existsSync()) SupportedPlatform.windows,
      if (fuchsia.existsSync()) SupportedPlatform.fuchsia,
    ];
  }

  /// The directory that will contain the example if an example exists.
  static Directory _exampleDirectory(Directory directory) => directory.childDirectory('example');

  /// Reads and validates the `pubspec.yaml` file at [path], asynchronously
  /// returning a [FlutterManifest] representation of the contents.
  ///
  /// Completes with an empty [FlutterManifest], if the file does not exist.
  /// Completes with a ToolExit on validation error.
  static FlutterManifest _readManifest(
    String path, {
    required Logger logger,
    required FileSystem fileSystem,
  }) {
    FlutterManifest? manifest;
    try {
      manifest = FlutterManifest.createFromPath(path, logger: logger, fileSystem: fileSystem);
    } on YamlException catch (e) {
      logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    } on FormatException catch (e) {
      logger.printError('Error detected while parsing pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    } on FileSystemException catch (e) {
      logger.printError('Error detected while reading pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    }
    if (manifest == null) {
      throwToolExit('Please correct the pubspec.yaml file at $path');
    }
    return manifest;
  }

  /// Reloads the content of [pubspecFile] and updates the contents of [manifest].
  void reloadManifest({required Logger logger, required FileSystem fs}) {
    _setManifest(_readManifest(pubspecFile.path, logger: logger, fileSystem: fs));
  }

  /// Returns the MD5 hash of the contents of [manifest], ensuring [manifest] is up to date before
  /// calculating the hash.
  String computeManifestMD5Hash({required Logger logger, required FileSystem fs}) {
    reloadManifest(logger: logger, fs: fs);
    return _manifest.computeMD5Hash();
  }

  /// Replaces the content of [pubspecFile] with the contents of [updated] and
  /// sets [manifest] to the [updated] manifest.
  void replacePubspec(FlutterManifest updated) {
    final YamlMap updatedPubspecContents = updated.toYaml();
    pubspecFile.writeAsStringSync(encodeYamlAsString(updatedPubspecContents));
    _setManifest(updated);
  }

  /// Reapplies template files and regenerates project files and plugin
  /// registrants for app and module projects only.
  ///
  /// Will not create project platform directories if they do not already exist.
  ///
  /// If [releaseMode] is `true`, platform-specific tooling and metadata generated
  /// may apply optimizations or changes that are only specific to release builds,
  /// such as not including dev-only dependencies.
  Future<void> regeneratePlatformSpecificTooling({
    required ToolContext toolContext,
    required bool releaseMode,
    DeprecationBehavior deprecationBehavior = DeprecationBehavior.none,
    PubspecCache? pubspecCache,
    PackageGraph? packageGraph,
    PackageConfig? packageConfig,
  }) async {
    return ensureReadyForPlatformSpecificTooling(
      toolContext: toolContext,
      androidPlatform: android.existsSync(),
      iosPlatform: ios.existsSync(),
      // TODO(stuartmorgan): Revisit the conditions here once the plans for handling
      // desktop in existing projects are in place.
      linuxPlatform: featureFlags.isLinuxEnabled && linux.existsSync(),
      macOSPlatform: featureFlags.isMacOSEnabled && macos.existsSync(),
      windowsPlatform: featureFlags.isWindowsEnabled && windows.existsSync(),
      webPlatform: featureFlags.isWebEnabled && web.existsSync(),
      deprecationBehavior: deprecationBehavior,
      releaseMode: releaseMode,
      pubspecCache: pubspecCache,
      packageGraph: packageGraph,
      packageConfig: packageConfig,
    );
  }

  /// Applies template files and generates project files and plugin
  /// registrants for app and module projects only for the specified platforms.
  ///
  /// If [releaseMode] is `true`, platform-specific tooling and metadata generated
  /// may apply optimizations or changes that are only specific to release builds,
  /// such as not including dev-only dependencies.
  Future<void> ensureReadyForPlatformSpecificTooling({
    required ToolContext toolContext,
    required bool releaseMode,
    bool androidPlatform = false,
    bool iosPlatform = false,
    bool linuxPlatform = false,
    bool macOSPlatform = false,
    bool windowsPlatform = false,
    bool webPlatform = false,
    DeprecationBehavior deprecationBehavior = DeprecationBehavior.none,
    PubspecCache? pubspecCache,
    PackageGraph? packageGraph,
    PackageConfig? packageConfig,
  }) async {
    if (!directory.existsSync()) {
      return;
    }

    final ToolContext(:Cache cache, :Logger logger) = toolContext;
    final migration = ProjectMigration(<ProjectMigrator>[
      AnalysisOptionsMigration(this, logger, packageConfig: packageConfig),
    ]);
    await migration.run();

    // When no platforms are enabled, nothing reads the plugin list or the
    // injected per-platform files.
    final bool anyPlatformEnabled =
        androidPlatform ||
        iosPlatform ||
        linuxPlatform ||
        macOSPlatform ||
        windowsPlatform ||
        webPlatform;
    if (isPlugin || !anyPlatformEnabled) {
      return;
    }
    await refreshPluginsList(
      this,
      cocoaPods: globals.cocoaPods,
      featureFlags: featureFlags,
      toolContext: toolContext,
      iosPlatform: iosPlatform,
      macOSPlatform: macOSPlatform,
      pubspecCache: pubspecCache,
      packageGraph: packageGraph,
      packageConfig: packageConfig,
    );
    if (androidPlatform) {
      await android.ensureReadyForPlatformSpecificTooling(
        cache: cache,
        deprecationBehavior: deprecationBehavior,
      );
    }
    if (iosPlatform) {
      await ios.ensureReadyForPlatformSpecificTooling(
        plistParser: _plistParser ?? globals.plistParser,
        templateRenderer: globals.templateRenderer,
        toolContext: toolContext,
      );
    }
    if (linuxPlatform) {
      await linux.ensureReadyForPlatformSpecificTooling();
    }
    if (macOSPlatform) {
      await macos.ensureReadyForPlatformSpecificTooling(toolContext: toolContext);
    }
    if (windowsPlatform) {
      await windows.ensureReadyForPlatformSpecificTooling();
    }
    if (webPlatform) {
      await web.ensureReadyForPlatformSpecificTooling();
    }
    await injectPlugins(
      this,
      analytics: globals.analytics,
      androidPlatform: androidPlatform,
      cocoaPods: globals.cocoaPods,
      featureFlags: featureFlags,
      iosPlatform: iosPlatform,
      linuxPlatform: linuxPlatform,
      macOSPlatform: macOSPlatform,
      releaseMode: releaseMode,
      templateRenderer: globals.templateRenderer,
      toolContext: toolContext,
      windowsPlatform: windowsPlatform,
      pubspecCache: pubspecCache,
      packageGraph: packageGraph,
      packageConfig: packageConfig,
    );
  }

  void checkForDeprecation({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) {
    if (android.existsSync() && pubspecFile.existsSync()) {
      android.checkForDeprecation(deprecationBehavior: deprecationBehavior);
    }
  }

  /// A JSON encoded string containing the [FlutterManifest.appName],
  /// [FlutterManifest.buildName] (version), and [FlutterManifest.buildNumber]
  /// that are used to generate `version.json`.
  String getVersionInfo() {
    final String? buildName = manifest.buildName;
    final String? buildNumber = manifest.buildNumber;
    final versionFileJson = <String, String>{
      'app_name': manifest.appName,
      'version': ?buildName,
      'build_number': ?buildNumber,
      'package_name': manifest.appName,
    };
    return jsonEncode(versionFileJson);
  }
}

/// Base class for projects per platform.
abstract class FlutterProjectPlatform {
  /// Plugin's platform config key, e.g., "macos", "ios".
  String get pluginConfigKey;

  /// Whether the platform exists in the project.
  bool existsSync();
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter module projects.
class AndroidProject extends FlutterProjectPlatform {
  AndroidProject._(this.parent);

  // User facing string when java/gradle/agp/kgp versions are compatible.
  @visibleForTesting
  static const validJavaGradleAgpKgpString = 'compatible java/gradle/agp/kgp';

  // User facing link that describes compatibility between gradle and
  // android gradle plugin.
  static const gradleAgpCompatUrl =
      'https://developer.android.com/studio/releases/gradle-plugin#updating-gradle';

  // User facing link that describes compatibility between java and the first
  // version of gradle to support it.
  static const javaGradleCompatUrl =
      'https://docs.gradle.org/current/userguide/compatibility.html#java';

  // User facing link that describes compatibility between KGP and Gradle
  // and AGP.
  static const kgpCompatUrl =
      'https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin';

  // User facing link that describes instructions for downloading
  // the latest version of Android Studio.
  static const installAndroidStudioUrl = 'https://developer.android.com/studio/install';

  /// The parent of this project.
  final FlutterProject parent;

  @override
  String get pluginConfigKey => AndroidPlugin.kConfigKey;

  static final _androidNamespacePattern = RegExp(
    'android {[\\S\\s]+namespace\\s*=?\\s*[\'"](.+)[\'"]',
  );
  static final _applicationIdPattern = RegExp('^\\s*applicationId\\s*=?\\s*[\'"](.*)[\'"]\\s*\$');
  static final _imperativeKotlinPluginPattern = RegExp(
    '^\\s*apply plugin\\:\\s+[\'"]kotlin-android[\'"]\\s*\$',
  );

  static final _kotlinCompilerOptionsPattern = RegExp(
    r'kotlin\s*\{[\s\S]*?compilerOptions\s*\{[^}]*\}',
  );

  /// Examples of strings that this regex matches:
  /// - `id "kotlin-android"`
  /// - `id("kotlin-android")`
  /// - `id ( "kotlin-android" ) `
  /// - `id "org.jetbrains.kotlin.android"`
  /// - `id("org.jetbrains.kotlin.android")`
  /// - `id ( "org.jetbrains.kotlin.android" )`
  /// - `kotlin("android")`
  /// - any of the above followed by `version "..."`
  /// - `alias(libs.plugins.kotlin.android)` or
  ///   `alias(libs.plugins.jetbrains.kotlin.android)`, the catalog names that
  ///   Android Studio project templates use
  static final _declarativeKotlinPluginPatterns = <RegExp>[
    RegExp('^\\s*id\\s*\\(?\\s*[\'"]kotlin-android[\'"]\\s*\\)?$_versionSuffix\\s*\$'),
    RegExp(
      '^\\s*id\\s*\\(?\\s*[\'"]org.jetbrains.kotlin.android[\'"]\\s*\\)?$_versionSuffix\\s*\$',
    ),
    RegExp('^\\s*kotlin\\s*\\(\\s*"android"\\s*\\)$_versionSuffix\\s*\$'),
    RegExp(r'^\s*alias\s*\(\s*libs\.plugins\.(?:jetbrains\.)?kotlin\.android\s*\)\s*$'),
  ];

  /// An optional plugin version, as in `id("org.jetbrains.kotlin.android") version "2.4.20"`.
  static const _versionSuffix = '(?:\\s+version\\s*\\(?\\s*[\'"][^\'"]*[\'"]\\s*\\)?)?';

  /// Pattern used to find the assignment of the "group" property in Gradle.
  /// Expected example: `group "dev.flutter.plugin"`
  /// Regex is used in both Groovy and Kotlin Gradle files.
  static final _groupPattern = RegExp('^\\s*group\\s*=?\\s*[\'"](.*)[\'"]\\s*\$');

  /// The Gradle root directory of the Android host app. This is the directory
  /// containing the `app/` subdirectory and the `settings.gradle` file that
  /// includes it in the overall Gradle project.
  Directory get hostAppGradleRoot {
    if (!isModule || _editableHostAppDirectory.existsSync()) {
      return _editableHostAppDirectory;
    }
    return ephemeralDirectory;
  }

  /// The Gradle root directory of the Android wrapping of Flutter and plugins.
  /// This is the same as [hostAppGradleRoot] except when the project is
  /// a Flutter module with an editable host app.
  Directory get _flutterLibGradleRoot => isModule ? ephemeralDirectory : _editableHostAppDirectory;

  Directory get ephemeralDirectory => parent.directory.childDirectory('.android');
  Directory get _editableHostAppDirectory => parent.directory.childDirectory('android');

  /// True if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  /// True if the parent Flutter project is a plugin.
  bool get isPlugin => parent.isPlugin;

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => parent.usesAndroidX;

  /// Returns true if the current version of the Gradle plugin is supported.
  late final bool isSupportedVersion = _computeSupportedVersion();

  /// Gets all build variants of this project.
  Future<List<String>> getBuildVariants() async {
    if (!existsSync() || androidBuilder == null) {
      return const <String>[];
    }
    return androidBuilder!.getBuildVariants(project: parent);
  }

  /// Outputs app link related settings into a json file.
  ///
  /// The return future resolves to the path of the json file.
  ///
  /// The future resolves to null if it fails to retrieve app link settings.
  Future<String> outputsAppLinkSettings({required String variant}) async {
    if (!existsSync() || androidBuilder == null) {
      throwToolExit('Target directory $hostAppGradleRoot is not an Android project');
    }
    return androidBuilder!.outputsAppLinkSettings(variant, project: parent);
  }

  bool _computeSupportedVersion() {
    final FileSystem fileSystem = hostAppGradleRoot.fileSystem;
    final File plugin = hostAppGradleRoot.childFile(
      fileSystem.path.join('buildSrc', 'src', 'main', 'groovy', 'FlutterPlugin.groovy'),
    );
    if (plugin.existsSync()) {
      return false;
    }
    try {
      for (final String line in appGradleFile.readAsLinesSync()) {
        // This syntax corresponds to applying the Flutter Gradle Plugin with a
        // script.
        // See https://docs.gradle.org/current/userguide/plugins.html#sec:script_plugins.
        final bool fileBasedApply = line.contains(RegExp(r'apply from: .*/flutter.gradle'));

        // This syntax corresponds to applying the Flutter Gradle Plugin using
        // the declarative "plugins {}" block after including it in the
        // pluginManagement block of the settings.gradle file.
        // See https://docs.gradle.org/current/userguide/composite_builds.html#included_plugin_builds,
        // as well as the settings.gradle and build.gradle templates.
        final bool declarativeApply = line.contains(
          RegExp(r'dev\.flutter\.(?:(?:flutter-gradle-plugin)|(?:`flutter-gradle-plugin`))'),
        );

        // This case allows for flutter run/build to work for modules. It does
        // not guarantee the Flutter Gradle Plugin is applied.
        final bool managed = line.contains(RegExp('def flutterPluginVersion = [\'"]managed[\'"]'));
        if (fileBasedApply || declarativeApply || managed) {
          return true;
        }
      }
    } on FileSystemException {
      return false;
    }
    return false;
  }

  /// Whether the app module's Gradle build file applies the `kotlin-android`
  /// (`org.jetbrains.kotlin.android`) plugin. Other modules, such as plugins,
  /// are not checked.
  bool get appliesKotlinAndroidPlugin {
    if (!appGradleFile.existsSync()) {
      return false;
    }
    if (firstMatchInFile(appGradleFile, _imperativeKotlinPluginPattern) != null) {
      return true;
    }
    for (final RegExp pattern in _declarativeKotlinPluginPatterns) {
      if (firstMatchInFile(appGradleFile, pattern) != null) {
        return true;
      }
    }
    return false;
  }

  /// Paths of Gradle build files that prevent the project from building with
  /// `android.newDsl` enabled.
  ///
  /// Scans the app module's build file and the `android/build.gradle(.kts)`
  /// file of each Android plugin listed in `.flutter-plugins-dependencies`.
  /// A build file blocks `android.newDsl` when the build file uses:
  /// - the legacy variant API (`applicationVariants`, `libraryVariants`,
  ///   `testVariants`, `unitTestVariants`, `variantFilter`),
  /// - a legacy extension type (`BaseExtension`, `AppExtension`,
  ///   `TestedExtension`, or `LibraryExtension` unless imported or qualified
  ///   from `com.android.build.api.dsl`), or
  /// - an unguarded `kotlin-android` plugin application (imperative
  ///   applications inside an `if` or `else` branch in files that check the
  ///   AGP version or `android.builtInKotlin`, reactive callbacks such as
  ///   `plugins.withId`, and `apply false` declarations do not block).
  ///
  /// Returns null when `.flutter-plugins-dependencies` is missing or unreadable
  /// because the project's Android plugins are unknown.
  ///
  /// Because only the app and plugin `build.gradle(.kts)` files are scanned,
  /// logic in `buildSrc`, convention plugins, or included builds is covered by
  /// the Gradle error handlers in `gradle_errors.dart`.
  List<String>? get newDslBlockingBuildFiles {
    final File dependenciesFile = parent.flutterPluginsDependenciesFile;
    final buildFiles = <File>[if (appGradleFile.existsSync()) appGradleFile];
    try {
      if (!dependenciesFile.existsSync()) {
        return null;
      }
      final Object? decoded = json.decode(dependenciesFile.readAsStringSync());
      final Object? plugins = decoded is Map<String, Object?> ? decoded['plugins'] : null;
      final Object? androidPlugins = plugins is Map<String, Object?>
          ? plugins[AndroidPlugin.kConfigKey]
          : null;
      if (androidPlugins != null && androidPlugins is! List<Object?>) {
        return null;
      }
      for (final Object? plugin in androidPlugins as List<Object?>? ?? const <Object?>[]) {
        final Object? path = plugin is Map<String, Object?> ? plugin['path'] : null;
        if (path is! String) {
          return null;
        }
        final Directory pluginAndroidDir = hostAppGradleRoot.fileSystem
            .directory(path)
            .childDirectory('android');
        final File buildFile = getGroovyOrKotlin(pluginAndroidDir, 'build.gradle');
        if (buildFile.existsSync()) {
          buildFiles.add(buildFile);
        }
      }
      final blocking = <String>[];
      for (final buildFile in buildFiles) {
        final bool isKotlinDsl = buildFile.path.endsWith('.kts');
        if (_GradleNewDslScanner.blocksNewDsl(
          buildFile.readAsStringSync(),
          isKotlinDsl: isKotlinDsl,
        )) {
          blocking.add(buildFile.path);
        }
      }
      return blocking;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  /// True, if the app project is using Kotlin.
  bool get isKotlin {
    if (appliesKotlinAndroidPlugin) {
      return true;
    }
    if (appGradleFile.existsSync()) {
      try {
        final String content = appGradleFile.readAsStringSync();
        if (_kotlinCompilerOptionsPattern.hasMatch(content)) {
          return true;
        }
      } on FileSystemException {
        // Ignore and continue with other checks.
      }
    }
    final Directory kotlinSrc = hostAppGradleRoot
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('kotlin');
    return kotlinSrc.existsSync();
  }

  /// Gets top-level Gradle build file.
  /// See https://developer.android.com/build#top-level.
  ///
  /// The file must exist and it must be written in either Groovy (build.gradle)
  /// or Kotlin (build.gradle.kts).
  File get hostAppGradleFile {
    return getGroovyOrKotlin(hostAppGradleRoot, 'build.gradle');
  }

  /// Gets the project root level Gradle settings file.
  ///
  /// The file must exist and it must be written in either Groovy (settings.gradle)
  /// or Kotlin (settings.gradle.kts).
  File get settingsGradleFile {
    return getGroovyOrKotlin(hostAppGradleRoot, 'settings.gradle');
  }

  File getGroovyOrKotlin(Directory directory, String baseFilename) {
    final File groovyFile = directory.childFile(baseFilename);
    final File kotlinFile = directory.childFile('$baseFilename.kts');

    if (groovyFile.existsSync()) {
      // We mimic Gradle's behavior of preferring Groovy over Kotlin when both files exist.
      return groovyFile;
    }
    if (kotlinFile.existsSync()) {
      return kotlinFile;
    }

    // TODO(bartekpacia): An exception should be thrown when neither
    // the Groovy or Kotlin file exists, instead of falling back to the
    // Groovy file. See #141180.
    return groovyFile;
  }

  /// Gets the module-level build.gradle file.
  /// See https://developer.android.com/build#module-level.
  ///
  /// The file must exist and it must be written in either Groovy (build.gradle)
  /// or Kotlin (build.gradle.kts).
  File get appGradleFile {
    final Directory appDir = hostAppGradleRoot.childDirectory('app');
    return getGroovyOrKotlin(appDir, 'build.gradle');
  }

  File get appManifestFile {
    if (isUsingGradle) {
      return hostAppGradleRoot
          .childDirectory('app')
          .childDirectory('src')
          .childDirectory('main')
          .childFile('AndroidManifest.xml');
    }

    return hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  /// Gets the Gradle wrapper properties file.
  ///
  /// This file is located under `gradle/wrapper/gradle-wrapper.properties`
  /// in the host app's Gradle root directory. It defines the distribution
  /// settings for the Gradle wrapper.
  File get gradleWrapperPropertiesFile {
    return hostAppGradleRoot
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties');
  }

  File get generatedPluginRegistrantFile {
    return hostAppGradleRoot
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childDirectory('java')
        .childDirectory('io')
        .childDirectory('flutter')
        .childDirectory('plugins')
        .childFile('GeneratedPluginRegistrant.java');
  }

  /// Whether the current flutter project has an Android sub-project.
  @override
  bool existsSync() {
    return parent.isModule || _editableHostAppDirectory.existsSync();
  }

  /// Check if the versions of Java, Gradle and AGP are compatible.
  ///
  /// This is expected to be called from
  /// flutter_tools/lib/src/project_validator.dart.
  Future<ProjectValidatorResult> validateJavaAndGradleAgpVersions() async {
    // Constructing ProjectValidatorResult happens here and not in
    // flutter_tools/lib/src/project_validator.dart because of the additional
    // Complexity of variable status values and error string formatting.
    const visibleName = 'Java/Gradle/KGP/Android Gradle Plugin';
    final CompatibilityResult validJavaGradleAgpVersions = await hasValidJavaGradleAgpVersions();

    return ProjectValidatorResult(
      name: visibleName,
      value: validJavaGradleAgpVersions.description,
      status: validJavaGradleAgpVersions.success
          ? StatusProjectValidator.success
          : StatusProjectValidator.error,
    );
  }

  /// Ensures Java SDK is compatible with the project's Gradle version and
  /// the project's Gradle version is compatible with the AGP version and
  /// kotlin version used in build.gradle.
  Future<CompatibilityResult> hasValidJavaGradleAgpVersions() async {
    final String? gradleVersion = await gradle.getGradleVersion(
      hostAppGradleRoot,
      globals.logger,
      globals.processManager,
    );
    final String? agpVersion = gradle.getAgpVersion(hostAppGradleRoot, globals.logger);
    final String? javaVersion = versionToParsableString(globals.java?.version);
    final String? kgpVersion = await gradle.getKgpVersion(
      hostAppGradleRoot,
      globals.logger,
      globals.processManager,
    );

    // Assume valid configuration.
    String description = validJavaGradleAgpKgpString;

    final bool compatibleGradleAgp = gradle.validateGradleAndAgp(
      globals.logger,
      gradleV: gradleVersion,
      agpV: agpVersion,
    );

    final bool compatibleJavaGradle = gradle.validateJavaAndGradle(
      globals.logger,
      javaVersion: javaVersion,
      gradleVersion: gradleVersion,
    );

    final bool compatibleKgpGradle = gradle.validateGradleAndKGP(
      globals.logger,
      gradleV: gradleVersion,
      kgpV: kgpVersion,
    );

    final bool compatibleAgpKgp = gradle.validateAgpAndKgp(
      globals.logger,
      agpV: agpVersion,
      kgpV: kgpVersion,
    );

    // Begin description formatting.
    if (!compatibleGradleAgp) {
      final gradleDescription = agpVersion != null
          ? 'Update Gradle to at least "${gradle.getGradleVersionFor(agpVersion)}".'
          : '';
      description =
          '''
Incompatible Gradle/AGP versions. \n
Gradle Version: $gradleVersion, AGP Version: $agpVersion
$gradleDescription\n
See the link below for more information:
$gradleAgpCompatUrl
''';
    }
    if (!compatibleJavaGradle) {
      // Should contain the agp error (if present) but not the valid String.
      description =
          '''
${compatibleGradleAgp ? '' : description}
Incompatible Java/Gradle versions.
Java Version: $javaVersion, Gradle Version: $gradleVersion\n
See the link below for more information:
$javaGradleCompatUrl
''';
    }
    if (!compatibleKgpGradle) {
      description =
          '''
${compatibleGradleAgp ? '' : description}
Incompatible KGP/Gradle versions.
Gradle Version: $gradleVersion, Kotlin Version: $kgpVersion\n
See the link below for more information:
  $kgpCompatUrl
''';
    }
    if (!compatibleAgpKgp) {
      description =
          '''
${compatibleGradleAgp ? '' : description}
Incompatible AGP/KGP versions.
AGP Version: $agpVersion, KGP Version: $kgpVersion\n
See the link below for more information:
  $kgpCompatUrl
''';
    }
    return CompatibilityResult(
      compatibleJavaGradle && compatibleGradleAgp && compatibleKgpGradle && compatibleAgpKgp,
      description,
    );
  }

  bool get isUsingGradle {
    return hostAppGradleFile.existsSync();
  }

  String? get applicationId {
    return firstMatchInFile(appGradleFile, _applicationIdPattern)?.group(1);
  }

  /// Get the namespace for newer Android projects,
  /// which replaces the `package` attribute in the Manifest.xml.
  String? get namespace {
    try {
      // firstMatchInFile() reads per line but `_androidNamespacePattern` matches a multiline pattern.
      return _androidNamespacePattern.firstMatch(appGradleFile.readAsStringSync())?.group(1);
    } on FileSystemException {
      return null;
    }
  }

  String? get group {
    return firstMatchInFile(hostAppGradleFile, _groupPattern)?.group(1);
  }

  /// The build directory where the Android artifacts are placed.
  Directory get buildDirectory {
    return parent.buildDirectory;
  }

  Future<void> ensureReadyForPlatformSpecificTooling({
    required Cache cache,
    DeprecationBehavior deprecationBehavior = DeprecationBehavior.none,
  }) async {
    if (isModule && _shouldRegenerateFromTemplate(cache)) {
      await _regenerateLibrary();
      // Add ephemeral host app, if an editable host app does not already exist.
      if (!_editableHostAppDirectory.existsSync()) {
        await _overwriteFromTemplate(
          globals.fs.path.join('module', 'android', 'host_app_common'),
          ephemeralDirectory,
        );
        await _overwriteFromTemplate(
          globals.fs.path.join('module', 'android', 'host_app_ephemeral'),
          ephemeralDirectory,
        );
      }
    }
    if (!hostAppGradleRoot.existsSync()) {
      return;
    }
    gradle.updateLocalProperties(project: parent, requireAndroidSdk: false, cache: cache);
  }

  bool _shouldRegenerateFromTemplate(Cache cache) {
    return globals.fsUtils.isOlderThanReference(
          entity: ephemeralDirectory,
          referenceFile: parent.pubspecFile,
        ) ||
        cache.isOlderThanToolsStamp(ephemeralDirectory);
  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost =>
      _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  Future<void> _regenerateLibrary() async {
    ErrorHandlingFileSystem.deleteIfExists(ephemeralDirectory, recursive: true);
    await _overwriteFromTemplate(
      globals.fs.path.join('module', 'android', 'library_new_embedding'),
      ephemeralDirectory,
    );
    await _overwriteFromTemplate(
      globals.fs.path.join('module', 'android', 'gradle'),
      ephemeralDirectory,
    );
    globals.gradleUtils?.injectGradleWrapperIfNeeded(ephemeralDirectory);
  }

  Future<void> _overwriteFromTemplate(String path, Directory target) async {
    final Template template = await Template.fromName(
      path,
      fileSystem: globals.fs,
      templateManifest: null,
      logger: globals.logger,
      templateRenderer: globals.templateRenderer,
    );
    final String androidIdentifier =
        parent.manifest.androidPackage ?? 'com.example.${parent.manifest.appName}';
    template.render(target, <String, Object>{
      'android': true,
      'projectName': parent.manifest.appName,
      'androidIdentifier': androidIdentifier,
      'androidX': usesAndroidX,
      'agpVersion': gradle.templateAndroidGradlePluginVersion,
      'agpVersionForModule': gradle.templateAndroidGradlePluginVersionForModule,
      'kotlinVersion': gradle.templateKotlinGradlePluginVersion,
      'gradleVersion': gradle.templateDefaultGradleVersion,
      'compileSdkVersion': gradle.compileSdkVersion,
      'minSdkVersion': gradle.minSdkVersion,
      'ndkVersion': gradle.ndkVersion,
      'targetSdkVersion': gradle.targetSdkVersion,
    }, printStatusWhenWriting: false);
  }

  void checkForDeprecation({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) {
    if (deprecationBehavior == DeprecationBehavior.none) {
      return;
    }
    final AndroidEmbeddingVersionResult result = computeEmbeddingVersion();
    if (result.version != AndroidEmbeddingVersion.v1) {
      return;
    }
    // The v1 android embedding has been deleted.
    throwToolExit('Build failed due to use of deleted Android v1 embedding.', exitCode: 1);
  }

  AndroidEmbeddingVersion getEmbeddingVersion() {
    final AndroidEmbeddingVersion androidEmbeddingVersion = computeEmbeddingVersion().version;
    if (androidEmbeddingVersion == AndroidEmbeddingVersion.v1) {
      throwToolExit('Build failed due to use of deleted Android v1 embedding.', exitCode: 1);
    }

    return androidEmbeddingVersion;
  }

  AndroidEmbeddingVersionResult computeEmbeddingVersion() {
    if (isModule) {
      // A module type's Android project is used in add-to-app scenarios and
      // only supports the V2 embedding.
      return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v2, 'Is add-to-app module');
    }
    if (isPlugin) {
      // Plugins do not use an appManifest, so we stop here.
      //
      // TODO(garyq): This method does not currently check for code references to
      // the v1 embedding, we should check for this once removal is further along.
      return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v2, 'Is plugin');
    }
    if (!appManifestFile.existsSync()) {
      return AndroidEmbeddingVersionResult(
        AndroidEmbeddingVersion.v1,
        'No `${appManifestFile.absolute.path}` file',
      );
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlException {
      throwToolExit(
        'Error parsing $appManifestFile '
        'Please ensure that the android manifest is a valid XML document and try again.',
      );
    } on FileSystemException {
      throwToolExit(
        'Error reading $appManifestFile even though it exists. '
        'Please ensure that you have read permission to this file and try again.',
      );
    }
    for (final XmlElement application in document.findAllElements('application')) {
      final String? applicationName = application.getAttribute('android:name');
      if (applicationName == 'io.flutter.app.FlutterApplication') {
        return AndroidEmbeddingVersionResult(
          AndroidEmbeddingVersion.v1,
          '${appManifestFile.absolute.path} uses `android:name="io.flutter.app.FlutterApplication"`',
        );
      }
    }
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String? name = metaData.getAttribute('android:name');
      // External code checks for this string to identify flutter android apps.
      // See cl/667760684 as an example.
      if (name == 'flutterEmbedding') {
        final String? embeddingVersionString = metaData.getAttribute('android:value');
        if (embeddingVersionString == '1') {
          return AndroidEmbeddingVersionResult(
            AndroidEmbeddingVersion.v1,
            '${appManifestFile.absolute.path} `<meta-data android:name="flutterEmbedding"` has value 1',
          );
        }
        if (embeddingVersionString == '2') {
          return AndroidEmbeddingVersionResult(
            AndroidEmbeddingVersion.v2,
            '${appManifestFile.absolute.path} `<meta-data android:name="flutterEmbedding"` has value 2',
          );
        }
      }
    }
    return AndroidEmbeddingVersionResult(
      AndroidEmbeddingVersion.v1,
      'No `<meta-data android:name="flutterEmbedding" android:value="2"/>` in ${appManifestFile.absolute.path}',
    );
  }

  static const _impellerEnabledByDefault = true;

  /// Returns the `io.flutter.embedding.android.EnableImpeller` manifest value.
  ///
  /// If there is no manifest file, or the key is not present, returns [_impellerEnabledByDefault].
  bool computeImpellerEnabled() {
    return _computeManifestMetadataBoolValue(
      'io.flutter.embedding.android.EnableImpeller',
      _impellerEnabledByDefault,
    );
  }

  /// Returns the `io.flutter.embedding.android.EnableHcpp` manifest value.
  ///
  /// If there is no manifest file, or the key is not present, returns
  /// [ifAbsent]. Callers should pass the value the build injects into the
  /// manifest when the key is not explicitly set, so that the result reflects
  /// what is actually packaged.
  ///
  /// This reads the app's primary source manifest, so it is an estimate of the
  /// packaged value: it does not account for contributions from build
  /// type/flavor overlay manifests or library manifests merged in at build
  /// time. Intended for analytics, not for correctness-sensitive decisions.
  bool computeHcppEnabled({bool ifAbsent = false}) {
    return _computeManifestMetadataBoolValueOrNull('io.flutter.embedding.android.EnableHcpp') ??
        ifAbsent;
  }

  bool _computeManifestMetadataBoolValue(String metadataKey, bool defaultValue) {
    return _computeManifestMetadataBoolValueOrNull(metadataKey) ?? defaultValue;
  }

  bool? _computeManifestMetadataBoolValueOrNull(String metadataKey) {
    if (!appManifestFile.existsSync()) {
      return null;
    }
    final XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlException {
      throwToolExit(
        'Error parsing $appManifestFile '
        'Please ensure that the android manifest is a valid XML document and try again.',
      );
    } on FileSystemException {
      throwToolExit(
        'Error reading $appManifestFile even though it exists. '
        'Please ensure that you have read permission to this file and try again.',
      );
    }
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String? name = metaData.getAttribute('android:name');
      if (name == metadataKey) {
        final String? value = metaData.getAttribute('android:value');
        if (value == null) {
          continue;
        }
        if (value.toLowerCase() == 'true') {
          return true;
        }
        if (value.toLowerCase() == 'false') {
          return false;
        }
      }
    }
    return null;
  }
}

/// Iteration of the embedding Java API in the engine used by the Android project.
enum AndroidEmbeddingVersion {
  /// V1 APIs based on io.flutter.app.FlutterActivity.
  v1,

  /// V2 APIs based on io.flutter.embedding.android.FlutterActivity.
  v2,
}

/// Data class that holds the results of checking for embedding version.
///
/// This class includes the reason why a particular embedding was selected.
class AndroidEmbeddingVersionResult {
  AndroidEmbeddingVersionResult(this.version, this.reason);

  /// The embedding version.
  AndroidEmbeddingVersion version;

  /// The reason why the embedding version was selected.
  String reason;
}

// What the tool should do when encountering deprecated API in applications.
enum DeprecationBehavior {
  // The command being run does not care about deprecation status.
  none,
  // The command should continue and ignore the deprecation warning.
  ignore,
  // The command should exit the tool.
  exit,
}

/// Represents the web sub-project of a Flutter project.
class WebProject extends FlutterProjectPlatform {
  WebProject._(this.parent);

  final FlutterProject parent;

  @override
  String get pluginConfigKey => WebPlugin.kConfigKey;

  /// Whether this flutter project has a web sub-project.
  @override
  bool existsSync() {
    return parent.directory.childDirectory('web').existsSync() && indexFile.existsSync();
  }

  /// The 'lib' directory for the application.
  Directory get libDirectory => parent.directory.childDirectory('lib');

  /// The directory containing additional files for the application.
  Directory get directory => parent.directory.childDirectory('web');

  /// The html file used to host the flutter web application.
  File get indexFile => parent.directory.childDirectory('web').childFile('index.html');

  /// The .dart_tool/dartpad directory
  Directory get dartpadToolDirectory =>
      parent.directory.childDirectory('.dart_tool').childDirectory('dartpad');

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    /// Create .dart_tool/dartpad/web_plugin_registrant.dart.
    /// See: https://github.com/dart-lang/dart-services/pull/874
    await injectBuildTimePluginFilesForWebPlatform(
      parent,
      destination: dartpadToolDirectory,
      logger: globals.logger,
      templateRenderer: globals.templateRenderer,
    );
  }
}

/// The Fuchsia sub project.
class FuchsiaProject {
  FuchsiaProject._(this.project);

  final FlutterProject project;

  Directory? _editableHostAppDirectory;
  Directory get editableHostAppDirectory =>
      _editableHostAppDirectory ??= project.directory.childDirectory('fuchsia');

  bool existsSync() => editableHostAppDirectory.existsSync();

  Directory? _meta;
  Directory get meta => _meta ??= editableHostAppDirectory.childDirectory('meta');
}

// Combines success and a description into one object that can be returned
// together.
@visibleForTesting
class CompatibilityResult {
  CompatibilityResult(this.success, this.description);
  final bool success;
  final String description;
}

/// Converts a [Version] to a string that can be parsed by [Version.parse].
String? versionToParsableString(Version? version) {
  if (version == null) {
    return null;
  }

  return '${version.major}.${version.minor}.${version.patch}';
}

enum _GradleTokenKind {
  ident,
  string,
  lBrace,
  rBrace,
  lParen,
  rParen,
  lBracket,
  rBracket,
  dot,
  colon,
  equals,
  semicolon,
  star,
  other,
}

final class _GradleToken {
  const _GradleToken(this.kind, this.text, this.line);

  final _GradleTokenKind kind;
  final String text;
  final int line;
}

final class _StringLexState {
  _StringLexState({required this.quote, required this.triple});

  final int quote;
  final bool triple;
  final StringBuffer buffer = StringBuffer();
  int? interpolationBraceDepth;
}

/// Lexical scanner for Groovy and Kotlin Gradle build files used by
/// [AndroidProject.newDslBlockingBuildFiles].
abstract final class _GradleNewDslScanner {
  static const _unconditionalLegacyIdentifiers = <String>{
    'applicationVariants',
    'libraryVariants',
    'testVariants',
    'unitTestVariants',
    'variantFilter',
    'BaseExtension',
    'AppExtension',
    'TestedExtension',
  };

  static const _legacyGradlePackage = <String>['com', 'android', 'build', 'gradle'];
  static const _newApiDslPackage = <String>['com', 'android', 'build', 'api', 'dsl'];

  static final _kotlinAndroidCatalogPattern = RegExp(r'kotlin.*android', caseSensitive: false);

  /// Returns true when [contents] uses a legacy AGP DSL or variant API or
  /// applies the `kotlin-android` plugin without an AGP-version or
  /// `android.builtInKotlin` guard, using [isKotlinDsl] to apply Kotlin raw
  /// string and nested block comment rules.
  static bool blocksNewDsl(String contents, {required bool isKotlinDsl}) {
    final List<_GradleToken> tokens = _tokenize(contents, isKotlinDsl: isKotlinDsl);
    if (tokens.isEmpty) {
      return false;
    }

    final List<int?> matchingClose = _computeMatchingDelimiters(tokens);
    final inPluginsBlock = List<bool>.filled(tokens.length, false);
    if (_hasBlockingPluginsBlockDeclaration(tokens, matchingClose, inPluginsBlock)) {
      return true;
    }
    if (_hasBlockingLegacyApiReference(tokens)) {
      return true;
    }
    return _hasUnguardedImperativeKotlinAndroidApply(tokens, matchingClose, inPluginsBlock);
  }

  static List<_GradleToken> _tokenize(String source, {required bool isKotlinDsl}) {
    final tokens = <_GradleToken>[];
    final stringStack = <_StringLexState>[];
    final int length = source.length;
    var i = 0;
    var line = 1;

    while (i < length) {
      final _StringLexState? activeString = stringStack.isNotEmpty ? stringStack.last : null;
      if (activeString != null && activeString.interpolationBraceDepth == null) {
        final int ch = source.codeUnitAt(i);
        if (ch == 0x5C /* \ */ && !(isKotlinDsl && activeString.triple)) {
          if (i + 1 < length) {
            if (source.codeUnitAt(i + 1) == 0x0A /* \n */ ) {
              line++;
            }
            activeString.buffer.writeCharCode(source.codeUnitAt(i + 1));
            i += 2;
            continue;
          }
          i++;
          continue;
        }
        if (activeString.quote == 0x22 /* " */ &&
            ch == 0x24 /* $ */ &&
            i + 1 < length &&
            source.codeUnitAt(i + 1) == 0x7B /* { */ ) {
          activeString.interpolationBraceDepth = 0;
          i += 2;
          continue;
        }
        if (activeString.triple) {
          if (ch == activeString.quote &&
              i + 2 < length &&
              source.codeUnitAt(i + 1) == activeString.quote &&
              source.codeUnitAt(i + 2) == activeString.quote) {
            while (i + 3 < length && source.codeUnitAt(i + 3) == activeString.quote) {
              activeString.buffer.writeCharCode(activeString.quote);
              i++;
            }
            tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
            stringStack.removeLast();
            i += 3;
            continue;
          }
          if (ch == 0x0A /* \n */ ) {
            line++;
          }
          activeString.buffer.writeCharCode(ch);
          i++;
          continue;
        }
        if (ch == activeString.quote) {
          tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
          stringStack.removeLast();
          i++;
          continue;
        }
        if (ch == 0x0A /* \n */ ) {
          tokens.add(_GradleToken(_GradleTokenKind.string, activeString.buffer.toString(), line));
          stringStack.removeLast();
          line++;
          i++;
          continue;
        }
        activeString.buffer.writeCharCode(ch);
        i++;
        continue;
      }

      final int ch = source.codeUnitAt(i);
      if (ch == 0x0A /* \n */ ) {
        line++;
        i++;
        continue;
      }
      if (ch <= 0x20) {
        i++;
        continue;
      }

      // Line comment `// ...`
      if (ch == 0x2F /* / */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x2F /* / */ ) {
        i += 2;
        while (i < length && source.codeUnitAt(i) != 0x0A /* \n */ ) {
          i++;
        }
        continue;
      }

      // Block comment `/* ... */`
      if (ch == 0x2F /* / */ && i + 1 < length && source.codeUnitAt(i + 1) == 0x2A /* * */ ) {
        i += 2;
        var depth = 1;
        while (i < length && depth > 0) {
          final int c = source.codeUnitAt(i);
          if (c == 0x0A /* \n */ ) {
            line++;
            i++;
          } else if (isKotlinDsl &&
              c == 0x2F /* / */ &&
              i + 1 < length &&
              source.codeUnitAt(i + 1) == 0x2A /* * */ ) {
            depth++;
            i += 2;
          } else if (c == 0x2A /* * */ &&
              i + 1 < length &&
              source.codeUnitAt(i + 1) == 0x2F /* / */ ) {
            depth--;
            i += 2;
          } else {
            i++;
          }
        }
        continue;
      }

      // String and character literals
      if (ch == 0x22 /* " */ || ch == 0x27 /* ' */ ) {
        final bool isTriple =
            i + 2 < length &&
            source.codeUnitAt(i + 1) == ch &&
            source.codeUnitAt(i + 2) == ch &&
            (!isKotlinDsl || ch == 0x22 /* " */ );
        stringStack.add(_StringLexState(quote: ch, triple: isTriple));
        i += isTriple ? 3 : 1;
        continue;
      }

      // Backticked Kotlin identifier
      if (ch == 0x60 /* ` */ ) {
        final int start = i + 1;
        i++;
        while (i < length && source.codeUnitAt(i) != 0x60 && source.codeUnitAt(i) != 0x0A) {
          i++;
        }
        tokens.add(_GradleToken(_GradleTokenKind.ident, source.substring(start, i), line));
        if (i < length && source.codeUnitAt(i) == 0x60) {
          i++;
        }
        continue;
      }

      // Identifiers
      if (_isIdentStart(ch)) {
        final start = i;
        i++;
        while (i < length && _isIdentPart(source.codeUnitAt(i))) {
          i++;
        }
        tokens.add(_GradleToken(_GradleTokenKind.ident, source.substring(start, i), line));
        continue;
      }

      if (ch == 0x7B /* { */ ) {
        if (activeString != null && activeString.interpolationBraceDepth != null) {
          activeString.interpolationBraceDepth = activeString.interpolationBraceDepth! + 1;
        }
        tokens.add(_GradleToken(_GradleTokenKind.lBrace, '{', line));
        i++;
        continue;
      }
      if (ch == 0x7D /* } */ ) {
        if (activeString != null && activeString.interpolationBraceDepth != null) {
          if (activeString.interpolationBraceDepth == 0) {
            activeString.interpolationBraceDepth = null;
            i++;
            continue;
          }
          activeString.interpolationBraceDepth = activeString.interpolationBraceDepth! - 1;
        }
        tokens.add(_GradleToken(_GradleTokenKind.rBrace, '}', line));
        i++;
        continue;
      }

      final _GradleTokenKind kind = switch (ch) {
        0x28 /* ( */ => _GradleTokenKind.lParen,
        0x29 /* ) */ => _GradleTokenKind.rParen,
        0x5B /* [ */ => _GradleTokenKind.lBracket,
        0x5D /* ] */ => _GradleTokenKind.rBracket,
        0x2E /* . */ => _GradleTokenKind.dot,
        0x3A /* : */ => _GradleTokenKind.colon,
        0x3D /* = */ => _GradleTokenKind.equals,
        0x3B /* ; */ => _GradleTokenKind.semicolon,
        0x2A /* * */ => _GradleTokenKind.star,
        _ => _GradleTokenKind.other,
      };
      tokens.add(_GradleToken(kind, String.fromCharCode(ch), line));
      i++;
    }

    while (stringStack.isNotEmpty) {
      final _StringLexState unclosed = stringStack.removeLast();
      tokens.add(_GradleToken(_GradleTokenKind.string, unclosed.buffer.toString(), line));
    }

    return tokens;
  }

  static bool _isIdentStart(int ch) =>
      (ch >= 0x41 && ch <= 0x5A) ||
      (ch >= 0x61 && ch <= 0x7A) ||
      ch == 0x5F /* _ */ ||
      ch == 0x24 /* $ */;

  static bool _isIdentPart(int ch) => _isIdentStart(ch) || (ch >= 0x30 && ch <= 0x39);

  static List<int?> _computeMatchingDelimiters(List<_GradleToken> tokens) {
    final matching = List<int?>.filled(tokens.length, null);
    final braceStack = <int>[];
    final parenStack = <int>[];
    final bracketStack = <int>[];
    for (var i = 0; i < tokens.length; i++) {
      switch (tokens[i].kind) {
        case _GradleTokenKind.lBrace:
          braceStack.add(i);
        case _GradleTokenKind.rBrace:
          if (braceStack.isNotEmpty) {
            matching[braceStack.removeLast()] = i;
          }
        case _GradleTokenKind.lParen:
          parenStack.add(i);
        case _GradleTokenKind.rParen:
          if (parenStack.isNotEmpty) {
            matching[parenStack.removeLast()] = i;
          }
        case _GradleTokenKind.lBracket:
          bracketStack.add(i);
        case _GradleTokenKind.rBracket:
          if (bracketStack.isNotEmpty) {
            matching[bracketStack.removeLast()] = i;
          }
        case _GradleTokenKind.ident ||
            _GradleTokenKind.string ||
            _GradleTokenKind.dot ||
            _GradleTokenKind.colon ||
            _GradleTokenKind.equals ||
            _GradleTokenKind.semicolon ||
            _GradleTokenKind.star ||
            _GradleTokenKind.other:
          break;
      }
    }
    return matching;
  }

  static bool _hasBlockingPluginsBlockDeclaration(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    List<bool> inPluginsBlock,
  ) {
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident ||
          tokens[i].text != 'plugins' ||
          (i > 0 && tokens[i - 1].kind == _GradleTokenKind.dot) ||
          tokens[i + 1].kind != _GradleTokenKind.lBrace) {
        continue;
      }
      final int blockEnd = matchingClose[i + 1] ?? tokens.length;
      for (var k = i; k < blockEnd && k < tokens.length; k++) {
        inPluginsBlock[k] = true;
      }

      for (int j = i + 2; j < blockEnd; j++) {
        final int? afterSpec = _matchDeclarativeKotlinAndroidSpec(
          tokens,
          matchingClose,
          j,
          blockEnd,
        );
        if (afterSpec == null) {
          continue;
        }
        if (!_hasApplyFalseModifier(tokens, afterSpec, blockEnd)) {
          return true;
        }
      }
      i = blockEnd;
    }
    return false;
  }

  static int? _matchDeclarativeKotlinAndroidSpec(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    int index,
    int blockEnd,
  ) {
    final _GradleToken token = tokens[index];
    if (token.kind != _GradleTokenKind.ident ||
        (index > 0 && tokens[index - 1].kind == _GradleTokenKind.dot)) {
      return null;
    }
    if (token.text == 'id') {
      if (index + 1 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[index + 1].text)) {
        return index + 2;
      }
      if (index + 3 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.lParen &&
          tokens[index + 2].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[index + 2].text) &&
          tokens[index + 3].kind == _GradleTokenKind.rParen) {
        return index + 4;
      }
      return null;
    }
    if (token.text == 'kotlin') {
      if (index + 1 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.string &&
          tokens[index + 1].text == 'android') {
        return index + 2;
      }
      if (index + 3 < blockEnd &&
          tokens[index + 1].kind == _GradleTokenKind.lParen &&
          tokens[index + 2].kind == _GradleTokenKind.string &&
          tokens[index + 2].text == 'android' &&
          tokens[index + 3].kind == _GradleTokenKind.rParen) {
        return index + 4;
      }
      return null;
    }
    if (token.text == 'alias' &&
        index + 1 < blockEnd &&
        tokens[index + 1].kind == _GradleTokenKind.lParen) {
      final int? closeParen = matchingClose[index + 1];
      if (closeParen == null || closeParen > blockEnd) {
        return null;
      }
      // Match `alias(libs.plugins.<...kotlin...android...>)`.
      if (index + 6 < closeParen &&
          tokens[index + 2].kind == _GradleTokenKind.ident &&
          tokens[index + 2].text == 'libs' &&
          tokens[index + 3].kind == _GradleTokenKind.dot &&
          tokens[index + 4].kind == _GradleTokenKind.ident &&
          tokens[index + 4].text == 'plugins' &&
          tokens[index + 5].kind == _GradleTokenKind.dot) {
        final segments = <String>[];
        var validChain = true;
        for (int k = index + 6; k < closeParen; k += 2) {
          if (tokens[k].kind != _GradleTokenKind.ident) {
            validChain = false;
            break;
          }
          segments.add(tokens[k].text);
          if (k + 1 < closeParen && tokens[k + 1].kind != _GradleTokenKind.dot) {
            validChain = false;
            break;
          }
        }
        if (validChain && _kotlinAndroidCatalogPattern.hasMatch(segments.join('.'))) {
          return closeParen + 1;
        }
      }
    }
    return null;
  }

  static bool _hasApplyFalseModifier(List<_GradleToken> tokens, int start, int blockEnd) {
    var parenDepth = 0;
    for (var k = start; k < blockEnd; k++) {
      final _GradleToken token = tokens[k];
      if (parenDepth == 0) {
        if (token.kind == _GradleTokenKind.semicolon ||
            token.kind == _GradleTokenKind.lBrace ||
            token.kind == _GradleTokenKind.rBrace) {
          return false;
        }
        final bool startsNextPluginSpec =
            token.kind == _GradleTokenKind.ident &&
            (k == 0 || tokens[k - 1].kind != _GradleTokenKind.dot) &&
            (token.text == 'id' || token.text == 'kotlin' || token.text == 'alias') &&
            k + 1 < blockEnd &&
            (tokens[k + 1].kind == _GradleTokenKind.lParen ||
                tokens[k + 1].kind == _GradleTokenKind.string);
        if (startsNextPluginSpec) {
          return false;
        }
        if (token.kind == _GradleTokenKind.ident && token.text == 'apply') {
          if (k + 1 < blockEnd &&
              tokens[k + 1].kind == _GradleTokenKind.ident &&
              tokens[k + 1].text == 'false') {
            return true;
          }
          if (k + 3 < blockEnd &&
              tokens[k + 1].kind == _GradleTokenKind.lParen &&
              tokens[k + 2].kind == _GradleTokenKind.ident &&
              tokens[k + 2].text == 'false' &&
              tokens[k + 3].kind == _GradleTokenKind.rParen) {
            return true;
          }
        }
      }
      if (token.kind == _GradleTokenKind.lParen) {
        parenDepth++;
      } else if (token.kind == _GradleTokenKind.rParen && parenDepth > 0) {
        parenDepth--;
      }
    }
    return false;
  }

  static bool _hasBlockingLegacyApiReference(List<_GradleToken> tokens) {
    var importsNewLibraryExtension = false;
    var importsLegacyGradleWildcard = false;

    for (var i = 0; i < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident || tokens[i].text != 'import') {
        continue;
      }
      final int? targetEnd = _consumeImportPath(tokens, i + 1);
      if (targetEnd == null) {
        continue;
      }
      final _GradleToken lastSegment = tokens[targetEnd - 1];
      if (lastSegment.kind == _GradleTokenKind.star) {
        if (_hasDottedPrefix(tokens, targetEnd - 1, _legacyGradlePackage)) {
          importsLegacyGradleWildcard = true;
        } else if (_hasDottedPrefix(tokens, targetEnd - 1, _newApiDslPackage)) {
          importsNewLibraryExtension = true;
        }
      } else if (lastSegment.kind == _GradleTokenKind.ident &&
          lastSegment.text == 'LibraryExtension') {
        if (_hasDottedPrefix(tokens, targetEnd - 1, _legacyGradlePackage)) {
          return true;
        }
        final bool hasDifferentAlias =
            targetEnd + 1 < tokens.length &&
            tokens[targetEnd].kind == _GradleTokenKind.ident &&
            tokens[targetEnd].text == 'as' &&
            tokens[targetEnd + 1].kind == _GradleTokenKind.ident &&
            tokens[targetEnd + 1].text != 'LibraryExtension';
        if (!hasDifferentAlias && _hasDottedPrefix(tokens, targetEnd - 1, _newApiDslPackage)) {
          importsNewLibraryExtension = true;
        }
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      final _GradleToken token = tokens[i];
      if (token.kind != _GradleTokenKind.ident) {
        continue;
      }
      if (_unconditionalLegacyIdentifiers.contains(token.text)) {
        return true;
      }
      if (token.text == 'LibraryExtension') {
        if (_hasDottedPrefix(tokens, i, _legacyGradlePackage)) {
          return true;
        }
        if (_hasDottedPrefix(tokens, i, _newApiDslPackage)) {
          continue;
        }
        if (!importsNewLibraryExtension || importsLegacyGradleWildcard) {
          return true;
        }
      }
    }
    return false;
  }

  static int? _consumeImportPath(List<_GradleToken> tokens, int start) {
    var index = start;
    if (index < tokens.length &&
        tokens[index].kind == _GradleTokenKind.ident &&
        tokens[index].text == 'static') {
      index++;
    }
    if (index >= tokens.length || tokens[index].kind != _GradleTokenKind.ident) {
      return null;
    }
    index++;
    while (index + 1 < tokens.length && tokens[index].kind == _GradleTokenKind.dot) {
      final _GradleToken next = tokens[index + 1];
      if (next.kind == _GradleTokenKind.star) {
        return index + 2;
      }
      if (next.kind != _GradleTokenKind.ident) {
        break;
      }
      index += 2;
    }
    return index;
  }

  static bool _hasDottedPrefix(List<_GradleToken> tokens, int targetIndex, List<String> prefix) {
    final int requiredTokens = prefix.length * 2;
    if (targetIndex < requiredTokens) {
      return false;
    }
    final int start = targetIndex - requiredTokens;
    if (start > 0 && tokens[start - 1].kind == _GradleTokenKind.dot) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      final _GradleToken segment = tokens[start + i * 2];
      final _GradleToken separator = tokens[start + i * 2 + 1];
      if (segment.kind != _GradleTokenKind.ident ||
          segment.text != prefix[i] ||
          separator.kind != _GradleTokenKind.dot) {
        return false;
      }
    }
    return true;
  }

  static bool _hasUnguardedImperativeKotlinAndroidApply(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    List<bool> inPluginsBlock,
  ) {
    final bool hasGuardSignal = tokens.any(
      (_GradleToken token) =>
          (token.kind == _GradleTokenKind.ident &&
              (token.text == 'ANDROID_GRADLE_PLUGIN_VERSION' ||
                  token.text == 'AndroidPluginVersion')) ||
          (token.kind == _GradleTokenKind.string && token.text == 'android.builtInKotlin'),
    );

    final inConditionalBody = List<bool>.filled(tokens.length, false);
    for (var i = 0; i + 1 < tokens.length; i++) {
      if (tokens[i].kind != _GradleTokenKind.ident ||
          tokens[i].text != 'if' ||
          (i > 0 && tokens[i - 1].kind == _GradleTokenKind.dot) ||
          tokens[i + 1].kind != _GradleTokenKind.lParen) {
        continue;
      }
      final int? condClose = matchingClose[i + 1];
      if (condClose == null || condClose + 1 >= tokens.length) {
        continue;
      }
      final int? thenEnd = _markConditionalBranch(
        tokens,
        matchingClose,
        inConditionalBody,
        condClose + 1,
      );
      if (thenEnd != null &&
          thenEnd + 1 < tokens.length &&
          tokens[thenEnd].kind == _GradleTokenKind.ident &&
          tokens[thenEnd].text == 'else') {
        _markConditionalBranch(tokens, matchingClose, inConditionalBody, thenEnd + 1);
      }
    }

    final kotlinPluginVariables = <String>{};
    for (var i = 0; i + 2 < tokens.length; i++) {
      if (tokens[i].kind == _GradleTokenKind.ident &&
          tokens[i].text != 'plugin' &&
          tokens[i + 1].kind == _GradleTokenKind.equals &&
          tokens[i + 2].kind == _GradleTokenKind.string &&
          _isKotlinAndroidPluginId(tokens[i + 2].text)) {
        kotlinPluginVariables.add(tokens[i].text);
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (inPluginsBlock[i] ||
          tokens[i].kind != _GradleTokenKind.ident ||
          tokens[i].text != 'apply') {
        continue;
      }
      if (i + 1 >= tokens.length) {
        continue;
      }
      final _GradleToken next = tokens[i + 1];
      if (next.kind == _GradleTokenKind.lParen) {
        final int closeParen = matchingClose[i + 1] ?? tokens.length;
        final bool appliesViaNamedArg = _rangeHasPluginKeyTarget(
          tokens,
          i + 2,
          closeParen,
          kotlinPluginVariables,
          allowEquals: true,
        );
        final bool appliesViaContainer =
            _hasPluginContainerReceiver(tokens, i) &&
            i + 2 < closeParen &&
            _isKotlinAndroidTarget(tokens[i + 2], kotlinPluginVariables);
        if ((appliesViaNamedArg || appliesViaContainer) &&
            (!hasGuardSignal || !inConditionalBody[i])) {
          return true;
        }
      } else if (next.kind == _GradleTokenKind.lBrace) {
        final int closeBrace = matchingClose[i + 1] ?? tokens.length;
        for (int k = i + 2; k < closeBrace; k++) {
          if (tokens[k].kind != _GradleTokenKind.ident || tokens[k].text != 'plugin') {
            continue;
          }
          final bool parenCall =
              k + 2 < closeBrace &&
              tokens[k + 1].kind == _GradleTokenKind.lParen &&
              _isKotlinAndroidTarget(tokens[k + 2], kotlinPluginVariables);
          final bool bareCall =
              k + 1 < closeBrace &&
              tokens[k + 1].line == tokens[k].line &&
              _isKotlinAndroidTarget(tokens[k + 1], kotlinPluginVariables);
          if ((parenCall || bareCall) && (!hasGuardSignal || !inConditionalBody[k])) {
            return true;
          }
        }
      } else {
        final int stmtEnd = _findSingleStatementEnd(tokens, matchingClose, i);
        final bool appliesViaMap = _rangeHasPluginKeyTarget(
          tokens,
          i + 1,
          stmtEnd,
          kotlinPluginVariables,
          allowEquals: false,
        );
        final bool appliesViaContainer =
            _hasPluginContainerReceiver(tokens, i) &&
            i + 1 < stmtEnd &&
            tokens[i + 1].line == tokens[i].line &&
            _isKotlinAndroidTarget(tokens[i + 1], kotlinPluginVariables);
        if ((appliesViaMap || appliesViaContainer) && (!hasGuardSignal || !inConditionalBody[i])) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _rangeHasPluginKeyTarget(
    List<_GradleToken> tokens,
    int start,
    int end,
    Set<String> kotlinPluginVariables, {
    required bool allowEquals,
  }) {
    for (var k = start; k + 2 < end; k++) {
      final _GradleToken key = tokens[k];
      final bool isPluginKey =
          (key.kind == _GradleTokenKind.ident || key.kind == _GradleTokenKind.string) &&
          key.text == 'plugin';
      final _GradleToken sep = tokens[k + 1];
      final bool validSep =
          sep.kind == _GradleTokenKind.colon ||
          (allowEquals && sep.kind == _GradleTokenKind.equals) ||
          (sep.kind == _GradleTokenKind.ident && sep.text == 'to');
      if (isPluginKey && validSep && _isKotlinAndroidTarget(tokens[k + 2], kotlinPluginVariables)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasPluginContainerReceiver(List<_GradleToken> tokens, int applyIndex) {
    if (applyIndex < 2 || tokens[applyIndex - 1].kind != _GradleTokenKind.dot) {
      return false;
    }
    final _GradleToken receiver = tokens[applyIndex - 2];
    if (receiver.kind == _GradleTokenKind.ident &&
        (receiver.text == 'pluginManager' || receiver.text == 'plugins')) {
      return true;
    }
    if (applyIndex >= 4 &&
        receiver.kind == _GradleTokenKind.rParen &&
        tokens[applyIndex - 3].kind == _GradleTokenKind.lParen &&
        tokens[applyIndex - 4].kind == _GradleTokenKind.ident &&
        (tokens[applyIndex - 4].text == 'getPluginManager' ||
            tokens[applyIndex - 4].text == 'getPlugins')) {
      return true;
    }
    return false;
  }

  static int? _markConditionalBranch(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    List<bool> inConditionalBody,
    int start,
  ) {
    if (start >= tokens.length) {
      return null;
    }
    if (tokens[start].kind == _GradleTokenKind.lBrace) {
      final int? closeBrace = matchingClose[start];
      if (closeBrace == null) {
        return null;
      }
      for (int k = start + 1; k < closeBrace; k++) {
        inConditionalBody[k] = true;
      }
      return closeBrace + 1;
    }
    if (tokens[start].kind == _GradleTokenKind.ident && tokens[start].text == 'if') {
      if (start + 1 >= tokens.length || tokens[start + 1].kind != _GradleTokenKind.lParen) {
        return null;
      }
      final int? condClose = matchingClose[start + 1];
      if (condClose == null || condClose + 1 >= tokens.length) {
        return null;
      }
      final int? nestedThenEnd = _markConditionalBranch(
        tokens,
        matchingClose,
        inConditionalBody,
        condClose + 1,
      );
      if (nestedThenEnd != null &&
          nestedThenEnd + 1 < tokens.length &&
          tokens[nestedThenEnd].kind == _GradleTokenKind.ident &&
          tokens[nestedThenEnd].text == 'else') {
        return _markConditionalBranch(tokens, matchingClose, inConditionalBody, nestedThenEnd + 1);
      }
      return nestedThenEnd;
    }
    final int stmtEnd = _findSingleStatementEnd(tokens, matchingClose, start);
    for (var k = start; k < stmtEnd; k++) {
      inConditionalBody[k] = true;
    }
    return stmtEnd;
  }

  static int _findSingleStatementEnd(
    List<_GradleToken> tokens,
    List<int?> matchingClose,
    int start,
  ) {
    var j = start;
    while (j < tokens.length) {
      final _GradleToken token = tokens[j];
      if (token.kind == _GradleTokenKind.semicolon ||
          token.kind == _GradleTokenKind.rBrace ||
          token.kind == _GradleTokenKind.rParen ||
          token.kind == _GradleTokenKind.rBracket ||
          (token.kind == _GradleTokenKind.ident && token.text == 'else')) {
        return j;
      }
      if (token.kind == _GradleTokenKind.lParen ||
          token.kind == _GradleTokenKind.lBrace ||
          token.kind == _GradleTokenKind.lBracket) {
        final int? close = matchingClose[j];
        if (close == null) {
          return start;
        }
        final wasBrace = token.kind == _GradleTokenKind.lBrace;
        j = close + 1;
        if (j >= tokens.length) {
          return j;
        }
        if (wasBrace && tokens[j].kind != _GradleTokenKind.dot) {
          return j;
        }
        if (tokens[j].line > tokens[close].line &&
            tokens[j].kind != _GradleTokenKind.dot &&
            tokens[j].kind != _GradleTokenKind.lBrace) {
          return j;
        }
        continue;
      }
      if (j + 1 >= tokens.length) {
        return j + 1;
      }
      final _GradleToken next = tokens[j + 1];
      if (next.line > token.line &&
          token.kind != _GradleTokenKind.dot &&
          next.kind != _GradleTokenKind.dot) {
        return j + 1;
      }
      j++;
    }
    return j;
  }

  static bool _isKotlinAndroidTarget(_GradleToken token, Set<String> kotlinPluginVariables) =>
      (token.kind == _GradleTokenKind.string && _isKotlinAndroidPluginId(token.text)) ||
      (token.kind == _GradleTokenKind.ident && kotlinPluginVariables.contains(token.text));

  static bool _isKotlinAndroidPluginId(String value) =>
      value == 'kotlin-android' || value == 'org.jetbrains.kotlin.android';
}
