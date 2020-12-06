// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import 'android/gradle_utils.dart' as gradle;
import 'artifacts.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'build_info.dart';
import 'bundle.dart' as bundle;
import 'dart/pub.dart';
import 'features.dart';
import 'flutter_manifest.dart';
import 'globals.dart' as globals;
import 'ios/plist_parser.dart';
import 'ios/xcodeproj.dart' as xcode;
import 'ios/xcodeproj.dart';
import 'platform_plugins.dart';
import 'plugins.dart';
import 'template.dart';

class FlutterProjectFactory {
  FlutterProjectFactory({
    @required Logger logger,
    @required FileSystem fileSystem,
  }) : _logger = logger,
       _fileSystem = fileSystem;

  final Logger _logger;
  final FileSystem _fileSystem;

  @visibleForTesting
  final Map<String, FlutterProject> projects =
      <String, FlutterProject>{};

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject fromDirectory(Directory directory) {
    assert(directory != null);
    return projects.putIfAbsent(directory.path, () {
      final FlutterManifest manifest = FlutterProject._readManifest(
        directory.childFile(bundle.defaultManifestPath).path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory)
            .childFile(bundle.defaultManifestPath)
            .path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      return FlutterProject(directory, manifest, exampleManifest);
    });
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
  FlutterProject(this.directory, this.manifest, this._exampleManifest)
    : assert(directory != null),
      assert(manifest != null),
      assert(_exampleManifest != null);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromDirectory(Directory directory) => globals.projectFactory.fromDirectory(directory);

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject current() => globals.projectFactory.fromDirectory(globals.fs.currentDirectory);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromPath(String path) => globals.projectFactory.fromDirectory(globals.fs.directory(path));

  /// The location of this project.
  final Directory directory;

  /// The manifest of this project.
  final FlutterManifest manifest;

  /// The manifest of the example sub-project of this project.
  final FlutterManifest _exampleManifest;

  /// The set of organization names found in this project as
  /// part of iOS product bundle identifier, Android application ID, or
  /// Gradle group ID.
  Future<Set<String>> get organizationNames async {
    final List<String> candidates = <String>[
      // Don't require iOS build info, this method is only
      // used during create as best-effort, use the
      // default target bundle identifier.
      if (ios.existsSync())
        await ios.productBundleIdentifier(null),
      if (android.existsSync()) ...<String>[
        android.applicationId,
        android.group,
      ],
      if (example.android.existsSync())
        example.android.applicationId,
      if (example.ios.existsSync())
        await example.ios.productBundleIdentifier(null),
    ];
    return Set<String>.of(candidates
        .map<String>(_organizationNameFromPackageName)
        .where((String name) => name != null));
  }

  String _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.')) {
      return packageName.substring(0, packageName.lastIndexOf('.'));
    }
    return null;
  }

  /// The iOS sub project of this project.
  IosProject _ios;
  IosProject get ios => _ios ??= IosProject.fromFlutter(this);

  /// The Android sub project of this project.
  AndroidProject _android;
  AndroidProject get android => _android ??= AndroidProject._(this);

  /// The web sub project of this project.
  WebProject _web;
  WebProject get web => _web ??= WebProject._(this);

  /// The MacOS sub project of this project.
  MacOSProject _macos;
  MacOSProject get macos => _macos ??= MacOSProject._(this);

  /// The Linux sub project of this project.
  LinuxProject _linux;
  LinuxProject get linux => _linux ??= LinuxProject._(this);

  /// The Windows sub project of this project.
  WindowsProject _windows;
  WindowsProject get windows => _windows ??= WindowsProject._(this);

  /// The Fuchsia sub project of this project.
  FuchsiaProject _fuchsia;
  FuchsiaProject get fuchsia => _fuchsia ??= FuchsiaProject._(this);

  /// The `pubspec.yaml` file of this project.
  File get pubspecFile => directory.childFile('pubspec.yaml');

  /// The `.packages` file of this project.
  File get packagesFile => directory.childFile('.packages');

  /// The `.metadata` file of this project.
  File get metadataFile => directory.childFile('.metadata');

  /// The `.flutter-plugins` file of this project.
  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

  /// The `.flutter-plugins-dependencies` file of this project,
  /// which contains the dependencies each plugin depends on.
  File get flutterPluginsDependenciesFile => directory.childFile('.flutter-plugins-dependencies');

  /// The `.dart-tool` directory of this project.
  Directory get dartTool => directory.childDirectory('.dart_tool');

  /// The directory containing the generated code for this project.
  Directory get generated => directory
    .absolute
    .childDirectory('.dart_tool')
    .childDirectory('build')
    .childDirectory('generated')
    .childDirectory(manifest.appName);

  /// The example sub-project of this project.
  FlutterProject get example => FlutterProject(
    _exampleDirectory(directory),
    _exampleManifest,
    FlutterManifest.empty(logger: globals.logger),
  );

  /// True if this project is a Flutter module project.
  bool get isModule => manifest.isModule;

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => manifest.usesAndroidX;

  /// True if this project has an example application.
  bool get hasExampleApp => _exampleDirectory(directory).existsSync();

  /// The directory that will contain the example if an example exists.
  static Directory _exampleDirectory(Directory directory) => directory.childDirectory('example');

  /// Reads and validates the `pubspec.yaml` file at [path], asynchronously
  /// returning a [FlutterManifest] representation of the contents.
  ///
  /// Completes with an empty [FlutterManifest], if the file does not exist.
  /// Completes with a ToolExit on validation error.
  static FlutterManifest _readManifest(String path, {
    @required Logger logger,
    @required FileSystem fileSystem,
  }) {
    FlutterManifest manifest;
    try {
      manifest = FlutterManifest.createFromPath(
        path,
        logger: logger,
        fileSystem: fileSystem,
      );
    } on YamlException catch (e) {
      logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    }
    if (manifest == null) {
      throwToolExit('Please correct the pubspec.yaml file at $path');
    }
    return manifest;
  }

  /// Generates project files necessary to make Gradle builds work on Android
  /// and CocoaPods+Xcode work on iOS, for app and module projects only.
  // TODO(cyanglaz): The param `checkProjects` is confusing. We should give it a better name
  // or add some documentation explaining what it does, or both.
  // https://github.com/flutter/flutter/issues/60023
  Future<void> ensureReadyForPlatformSpecificTooling({bool checkProjects = false}) async {
    if (!directory.existsSync() || hasExampleApp) {
      return;
    }
    await refreshPluginsList(this);
    if ((android.existsSync() && checkProjects) || !checkProjects) {
      await android.ensureReadyForPlatformSpecificTooling();
    }
    if ((ios.existsSync() && checkProjects) || !checkProjects) {
      await ios.ensureReadyForPlatformSpecificTooling();
    }
    // TODO(stuartmorgan): Revisit conditions once there is a plan for handling
    // non-default platform projects. For now, always treat checkProjects as
    // true for desktop.
    if (featureFlags.isLinuxEnabled && linux.existsSync()) {
      await linux.ensureReadyForPlatformSpecificTooling();
    }
    if (featureFlags.isMacOSEnabled && macos.existsSync()) {
      await macos.ensureReadyForPlatformSpecificTooling();
    }
    if (featureFlags.isWindowsEnabled && windows.existsSync()) {
      await windows.ensureReadyForPlatformSpecificTooling();
    }
    if (featureFlags.isWebEnabled && web.existsSync()) {
      await web.ensureReadyForPlatformSpecificTooling();
    }
    await injectPlugins(this, checkProjects: checkProjects);
  }
}

/// Base class for projects per platform.
abstract class FlutterProjectPlatform {

  /// Plugin's platform config key, e.g., "macos", "ios".
  String get pluginConfigKey;

  /// Whether the platform exists in the project.
  bool existsSync();
}

/// Represents an Xcode-based sub-project.
///
/// This defines interfaces common to iOS and macOS projects.
abstract class XcodeBasedProject {
  /// The parent of this project.
  FlutterProject get parent;

  /// Whether the subproject (either iOS or macOS) exists in the Flutter project.
  bool existsSync();

  /// The Xcode project (.xcodeproj directory) of the host app.
  Directory get xcodeProject;

  /// The 'project.pbxproj' file of [xcodeProject].
  File get xcodeProjectInfoFile;

  /// The Xcode workspace (.xcworkspace directory) of the host app.
  Directory get xcodeWorkspace;

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the Xcode build.
  File get generatedXcodePropertiesFile;

  /// The Flutter-managed Xcode config file for [mode].
  File xcodeConfigFor(String mode);

  /// The script that exports environment variables needed for Flutter tools.
  /// Can be run first in a Xcode Script build phase to make FLUTTER_ROOT,
  /// LOCAL_ENGINE, and other Flutter variables available to any flutter
  /// tooling (`flutter build`, etc) to convert into flags.
  File get generatedEnvironmentVariableExportScript;

  /// The CocoaPods 'Podfile'.
  File get podfile;

  /// The CocoaPods 'Podfile.lock'.
  File get podfileLock;

  /// The CocoaPods 'Manifest.lock'.
  File get podManifestLock;
}

/// Represents a CMake-based sub-project.
///
/// This defines interfaces common to Windows and Linux projects.
abstract class CmakeBasedProject {
  /// The parent of this project.
  FlutterProject get parent;

  /// Whether the subproject (either Windows or Linux) exists in the Flutter project.
  bool existsSync();

  /// The native project CMake specification.
  File get cmakeFile;

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the build.
  File get generatedCmakeConfigFile;

  /// Includable CMake with rules and variables for plugin builds.
  File get generatedPluginCmakeFile;

  /// The directory to write plugin symlinks.
  Directory get pluginSymlinkDirectory;
}

/// Represents the iOS sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `ios/` sub-folder of
/// Flutter applications and the `.ios/` sub-folder of Flutter module projects.
class IosProject extends FlutterProjectPlatform implements XcodeBasedProject {
  IosProject.fromFlutter(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => IOSPlugin.kConfigKey;

  static final RegExp _productBundleIdPattern = RegExp(r'''^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(["']?)(.*?)\1;\s*$''');
  static const String _productBundleIdVariable = r'$(PRODUCT_BUNDLE_IDENTIFIER)';
  static const String _hostAppProjectName = 'Runner';

  Directory get ephemeralDirectory => parent.directory.childDirectory('.ios');
  Directory get _editableDirectory => parent.directory.childDirectory('ios');

  /// This parent folder of `Runner.xcodeproj`.
  Directory get hostAppRoot {
    if (!isModule || _editableDirectory.existsSync()) {
      return _editableDirectory;
    }
    return ephemeralDirectory;
  }

  /// The root directory of the iOS wrapping of Flutter and plugins. This is the
  /// parent of the `Flutter/` folder into which Flutter artifacts are written
  /// during build.
  ///
  /// This is the same as [hostAppRoot] except when the project is
  /// a Flutter module with an editable host app.
  Directory get _flutterLibRoot => isModule ? ephemeralDirectory : _editableDirectory;

  /// True, if the parent Flutter project is a module project.
  bool get isModule => parent.isModule;

  /// Whether the flutter application has an iOS project.
  bool get exists => hostAppRoot.existsSync();

  @override
  File xcodeConfigFor(String mode) => _flutterLibRoot.childDirectory('Flutter').childFile('$mode.xcconfig');

  @override
  File get generatedEnvironmentVariableExportScript => _flutterLibRoot.childDirectory('Flutter').childFile('flutter_export_environment.sh');

  @override
  File get podfile => hostAppRoot.childFile('Podfile');

  @override
  File get podfileLock => hostAppRoot.childFile('Podfile.lock');

  @override
  File get podManifestLock => hostAppRoot.childDirectory('Pods').childFile('Manifest.lock');

  /// The default 'Info.plist' file of the host app. The developer can change this location in Xcode.
  File get defaultHostInfoPlist => hostAppRoot.childDirectory(_hostAppProjectName).childFile('Info.plist');

  Directory get symlinks => _flutterLibRoot.childDirectory('.symlinks');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('$_hostAppProjectName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  Directory get xcodeWorkspace => hostAppRoot.childDirectory('$_hostAppProjectName.xcworkspace');

  /// Xcode workspace shared data directory for the host app.
  Directory get xcodeWorkspaceSharedData => xcodeWorkspace.childDirectory('xcshareddata');

  /// Xcode workspace shared workspace settings file for the host app.
  File get xcodeWorkspaceSharedSettings => xcodeWorkspaceSharedData.childFile('WorkspaceSettings.xcsettings');

  @override
  bool existsSync()  {
    return parent.isModule || _editableDirectory.existsSync();
  }

  /// The product bundle identifier of the host app, or null if not set or if
  /// iOS tooling needed to read it is not installed.
  Future<String> productBundleIdentifier(BuildInfo buildInfo) async {
    if (!existsSync()) {
      return null;
    }
    return _productBundleIdentifier ??= await _parseProductBundleIdentifier(buildInfo);
  }
  String _productBundleIdentifier;

  Future<String> _parseProductBundleIdentifier(BuildInfo buildInfo) async {
    String fromPlist;
    final File defaultInfoPlist = defaultHostInfoPlist;
    // Users can change the location of the Info.plist.
    // Try parsing the default, first.
    if (defaultInfoPlist.existsSync()) {
      try {
        fromPlist = globals.plistParser.getValueFromFile(
          defaultHostInfoPlist.path,
          PlistParser.kCFBundleIdentifierKey,
        );
      } on FileNotFoundException {
        // iOS tooling not found; likely not running OSX; let [fromPlist] be null
      }
      if (fromPlist != null && !fromPlist.contains(r'$')) {
        // Info.plist has no build variables in product bundle ID.
        return fromPlist;
      }
    }
    final Map<String, String> allBuildSettings = await buildSettingsForBuildInfo(buildInfo);
    if (allBuildSettings != null) {
      if (fromPlist != null) {
        // Perform variable substitution using build settings.
        return xcode.substituteXcodeVariables(fromPlist, allBuildSettings);
      }
      return allBuildSettings['PRODUCT_BUNDLE_IDENTIFIER'];
    }

    // On non-macOS platforms, parse the first PRODUCT_BUNDLE_IDENTIFIER from
    // the project file. This can return the wrong bundle identifier if additional
    // bundles have been added to the project and are found first, like frameworks
    // or companion watchOS projects. However, on non-macOS platforms this is
    // only used for display purposes and to regenerate organization names, so
    // best-effort is probably fine.
    final String fromPbxproj = _firstMatchInFile(xcodeProjectInfoFile, _productBundleIdPattern)?.group(2);
    if (fromPbxproj != null && (fromPlist == null || fromPlist == _productBundleIdVariable)) {
      return fromPbxproj;
    }

    return null;
  }

  /// The bundle name of the host app, `My App.app`.
  Future<String> hostAppBundleName(BuildInfo buildInfo) async {
    if (!existsSync()) {
      return null;
    }
    return _hostAppBundleName ??= await _parseHostAppBundleName(buildInfo);
  }
  String _hostAppBundleName;

  Future<String> _parseHostAppBundleName(BuildInfo buildInfo) async {
    // The product name and bundle name are derived from the display name, which the user
    // is instructed to change in Xcode as part of deploying to the App Store.
    // https://flutter.dev/docs/deployment/ios#review-xcode-project-settings
    // The only source of truth for the name is Xcode's interpretation of the build settings.
    String productName;
    if (globals.xcodeProjectInterpreter.isInstalled) {
      final Map<String, String> xcodeBuildSettings = await buildSettingsForBuildInfo(buildInfo);
      if (xcodeBuildSettings != null) {
        productName = xcodeBuildSettings['FULL_PRODUCT_NAME'];
      }
    }
    if (productName == null) {
      globals.printTrace('FULL_PRODUCT_NAME not present, defaulting to $_hostAppProjectName');
    }
    return productName ?? '$_hostAppProjectName.app';
  }

  /// The build settings for the host app of this project, as a detached map.
  ///
  /// Returns null, if iOS tooling is unavailable.
  Future<Map<String, String>> buildSettingsForBuildInfo(BuildInfo buildInfo) async {
    if (!existsSync()) {
      return null;
    }
    _buildSettingsByScheme ??= <String, Map<String, String>>{};
    final XcodeProjectInfo info = await projectInfo();
    if (info == null) {
      return null;
    }

    final String scheme = info.schemeFor(buildInfo);
    if (scheme == null) {
      info.reportFlavorNotFoundAndExit();
    }

    return _buildSettingsByScheme[scheme] ??= await _xcodeProjectBuildSettings(scheme);
  }
  Map<String, Map<String, String>> _buildSettingsByScheme;

  Future<XcodeProjectInfo> projectInfo() async {
    if (!xcodeProject.existsSync() || !globals.xcodeProjectInterpreter.isInstalled) {
      return null;
    }
    return _projectInfo ??= await globals.xcodeProjectInterpreter.getInfo(hostAppRoot.path);
  }
  XcodeProjectInfo _projectInfo;

  Future<Map<String, String>> _xcodeProjectBuildSettings(String scheme) async {
    if (!globals.xcodeProjectInterpreter.isInstalled) {
      return null;
    }
    final Map<String, String> buildSettings = await globals.xcodeProjectInterpreter.getBuildSettings(
      xcodeProject.path,
      scheme: scheme,
    );
    if (buildSettings != null && buildSettings.isNotEmpty) {
      // No timeouts, flakes, or errors.
      return buildSettings;
    }
    return null;
  }

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    await _regenerateFromTemplateIfNeeded();
    if (!_flutterLibRoot.existsSync()) {
      return;
    }
    await _updateGeneratedXcodeConfigIfNeeded();
  }

  /// Check if one the [targets] of the project is a watchOS companion app target.
  Future<bool> containsWatchCompanion(List<String> targets, BuildInfo buildInfo) async {
    final String bundleIdentifier = await productBundleIdentifier(buildInfo);
    // A bundle identifier is required for a companion app.
    if (bundleIdentifier == null) {
      return false;
    }
    for (final String target in targets) {
      // Create Info.plist file of the target.
      final File infoFile = hostAppRoot.childDirectory(target).childFile('Info.plist');
      // The Info.plist file of a target contains the key WKCompanionAppBundleIdentifier,
      // if it is a watchOS companion app.
      if (infoFile.existsSync() && globals.plistParser.getValueFromFile(infoFile.path, 'WKCompanionAppBundleIdentifier') == bundleIdentifier) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateGeneratedXcodeConfigIfNeeded() async {
    if (globals.cache.isOlderThanToolsStamp(generatedXcodePropertiesFile)) {
      await xcode.updateGeneratedXcodeProperties(
        project: parent,
        buildInfo: BuildInfo.debug,
        targetOverride: bundle.defaultMainPath,
      );
    }
  }

  Future<void> _regenerateFromTemplateIfNeeded() async {
    if (!isModule) {
      return;
    }
    final bool pubspecChanged = globals.fsUtils.isOlderThanReference(
      entity: ephemeralDirectory,
      referenceFile: parent.pubspecFile,
    );
    final bool toolingChanged = globals.cache.isOlderThanToolsStamp(ephemeralDirectory);
    if (!pubspecChanged && !toolingChanged) {
      return;
    }

    _deleteIfExistsSync(ephemeralDirectory);
    await _overwriteFromTemplate(
      globals.fs.path.join('module', 'ios', 'library'),
      ephemeralDirectory,
    );
    // Add ephemeral host app, if a editable host app does not already exist.
    if (!_editableDirectory.existsSync()) {
      await _overwriteFromTemplate(
        globals.fs.path.join('module', 'ios', 'host_app_ephemeral'),
        ephemeralDirectory,
      );
      if (hasPlugins(parent)) {
        await _overwriteFromTemplate(
          globals.fs.path.join('module', 'ios', 'host_app_ephemeral_cocoapods'),
          ephemeralDirectory,
        );
      }
      copyEngineArtifactToProject(BuildMode.debug);
    }
  }

  void copyEngineArtifactToProject(BuildMode mode) {
    // Copy podspec and framework from engine cache. The actual build mode
    // doesn't actually matter as it will be overwritten by xcode_backend.sh.
    // However, cocoapods will run before that script and requires something
    // to be in this location.
    final Directory framework = globals.fs.directory(
      globals.artifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: TargetPlatform.ios,
        mode: mode,
      )
    );
    if (framework.existsSync()) {
      final Directory engineDest = ephemeralDirectory
          .childDirectory('Flutter')
          .childDirectory('engine');
      final File podspec = framework.parent.childFile('Flutter.podspec');
      globals.fsUtils.copyDirectorySync(
        framework,
        engineDest.childDirectory('Flutter.framework'),
      );
      podspec.copySync(engineDest.childFile('Flutter.podspec').path);
    }
  }

  @override
  File get generatedXcodePropertiesFile => _flutterLibRoot
    .childDirectory('Flutter')
    .childFile('Generated.xcconfig');

  Directory get compiledDartFramework => _flutterLibRoot
      .childDirectory('Flutter')
      .childDirectory('App.framework');

  Directory get pluginRegistrantHost {
    return isModule
        ? _flutterLibRoot
            .childDirectory('Flutter')
            .childDirectory('FlutterPluginRegistrant')
        : hostAppRoot.childDirectory(_hostAppProjectName);
  }

  Future<void> _overwriteFromTemplate(String path, Directory target) async {
    final Template template = await Template.fromName(
      path,
      fileSystem: globals.fs,
      templateManifest: null,
      logger: globals.logger,
      templateRenderer: globals.templateRenderer,
      pub: pub,
    );
    template.render(
      target,
      <String, dynamic>{
        'ios': true,
        'projectName': parent.manifest.appName,
        'iosIdentifier': parent.manifest.iosBundleIdentifier,
      },
      printStatusWhenWriting: false,
      overwriteExisting: true,
    );
  }
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter module projects.
class AndroidProject extends FlutterProjectPlatform {
  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  @override
  String get pluginConfigKey => AndroidPlugin.kConfigKey;

  static final RegExp _applicationIdPattern = RegExp('^\\s*applicationId\\s+[\'"](.*)[\'"]\\s*\$');
  static final RegExp _kotlinPluginPattern = RegExp('^\\s*apply plugin\\:\\s+[\'"]kotlin-android[\'"]\\s*\$');
  static final RegExp _groupPattern = RegExp('^\\s*group\\s+[\'"](.*)[\'"]\\s*\$');

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

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => parent.usesAndroidX;

  /// True, if the app project is using Kotlin.
  bool get isKotlin {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _kotlinPluginPattern) != null;
  }

  File get appManifestFile {
    return isUsingGradle
        ? globals.fs.file(globals.fs.path.join(hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return globals.fs.directory(globals.fs.path.join(hostAppGradleRoot.path, 'app', 'build', 'outputs', 'apk'));
  }

  /// Whether the current flutter project has an Android sub-project.
  @override
  bool existsSync() {
    return parent.isModule || _editableHostAppDirectory.existsSync();
  }

  bool get isUsingGradle {
    return hostAppGradleRoot.childFile('build.gradle').existsSync();
  }

  String get applicationId {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _applicationIdPattern)?.group(1);
  }

  String get group {
    final File gradleFile = hostAppGradleRoot.childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _groupPattern)?.group(1);
  }

  /// The build directory where the Android artifacts are placed.
  Directory get buildDirectory {
    return parent.directory.childDirectory('build');
  }

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (getEmbeddingVersion() == AndroidEmbeddingVersion.v1) {
      globals.printStatus(
"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Warning
──────────────────────────────────────────────────────────────────────────────
Your Flutter application is created using an older version of the Android
embedding. It's being deprecated in favor of Android embedding v2. Follow the
steps at

https://flutter.dev/go/android-project-migration

to migrate your project.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
      );
    }
    if (isModule && _shouldRegenerateFromTemplate()) {
      await _regenerateLibrary();
      // Add ephemeral host app, if an editable host app does not already exist.
      if (!_editableHostAppDirectory.existsSync()) {
        await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'host_app_common'), ephemeralDirectory);
        await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'host_app_ephemeral'), ephemeralDirectory);
      }
    }
    if (!hostAppGradleRoot.existsSync()) {
      return;
    }
    gradle.updateLocalProperties(project: parent, requireAndroidSdk: false);
  }

  bool _shouldRegenerateFromTemplate() {
    return globals.fsUtils.isOlderThanReference(
      entity: ephemeralDirectory,
      referenceFile: parent.pubspecFile,
    ) || globals.cache.isOlderThanToolsStamp(ephemeralDirectory);
  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost => _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  Future<void> _regenerateLibrary() async {
    _deleteIfExistsSync(ephemeralDirectory);
    await _overwriteFromTemplate(globals.fs.path.join(
      'module',
      'android',
      'library_new_embedding',
    ), ephemeralDirectory);
    await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'gradle'), ephemeralDirectory);
    gradle.gradleUtils.injectGradleWrapperIfNeeded(ephemeralDirectory);
  }

  Future<void> _overwriteFromTemplate(String path, Directory target) async {
    final Template template = await Template.fromName(
      path,
      fileSystem: globals.fs,
      templateManifest: null,
      logger: globals.logger,
      templateRenderer: globals.templateRenderer,
      pub: pub,
    );
    template.render(
      target,
      <String, dynamic>{
        'android': true,
        'projectName': parent.manifest.appName,
        'androidIdentifier': parent.manifest.androidPackage,
        'androidX': usesAndroidX,
      },
      printStatusWhenWriting: false,
      overwriteExisting: true,
    );
  }

  AndroidEmbeddingVersion getEmbeddingVersion() {
    if (isModule) {
      // A module type's Android project is used in add-to-app scenarios and
      // only supports the V2 embedding.
      return AndroidEmbeddingVersion.v2;
    }
    if (appManifestFile == null || !appManifestFile.existsSync()) {
      return AndroidEmbeddingVersion.v1;
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlParserException {
      throwToolExit('Error parsing $appManifestFile '
                    'Please ensure that the android manifest is a valid XML document and try again.');
    } on FileSystemException {
      throwToolExit('Error reading $appManifestFile even though it exists. '
                    'Please ensure that you have read permission to this file and try again.');
    }
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String name = metaData.getAttribute('android:name');
      if (name == 'flutterEmbedding') {
        final String embeddingVersionString = metaData.getAttribute('android:value');
        if (embeddingVersionString == '1') {
          return AndroidEmbeddingVersion.v1;
        }
        if (embeddingVersionString == '2') {
          return AndroidEmbeddingVersion.v2;
        }
      }
    }
    return AndroidEmbeddingVersion.v1;
  }
}

/// Iteration of the embedding Java API in the engine used by the Android project.
enum AndroidEmbeddingVersion {
  /// V1 APIs based on io.flutter.app.FlutterActivity.
  v1,
  /// V2 APIs based on io.flutter.embedding.android.FlutterActivity.
  v2,
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
    return parent.directory.childDirectory('web').existsSync()
      && indexFile.existsSync();
  }

  /// The 'lib' directory for the application.
  Directory get libDirectory => parent.directory.childDirectory('lib');

  /// The directory containing additional files for the application.
  Directory get directory => parent.directory.childDirectory('web');

  /// The html file used to host the flutter web application.
  File get indexFile => parent.directory
      .childDirectory('web')
      .childFile('index.html');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// Deletes [directory] with all content.
void _deleteIfExistsSync(Directory directory) {
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}


/// Returns the first line-based match for [regExp] in [file].
///
/// Assumes UTF8 encoding.
Match _firstMatchInFile(File file, RegExp regExp) {
  if (!file.existsSync()) {
    return null;
  }
  for (final String line in file.readAsLinesSync()) {
    final Match match = regExp.firstMatch(line);
    if (match != null) {
      return match;
    }
  }
  return null;
}

/// The macOS sub project.
class MacOSProject extends FlutterProjectPlatform implements XcodeBasedProject {
  MacOSProject._(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => MacOSPlugin.kConfigKey;

  static const String _hostAppProjectName = 'Runner';

  @override
  bool existsSync() => _macOSDirectory.existsSync();

  Directory get _macOSDirectory => parent.directory.childDirectory('macos');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _macOSDirectory.childDirectory('Flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  /// The xcfilelist used to track the inputs for the Flutter script phase in
  /// the Xcode build.
  File get inputFileList => ephemeralDirectory.childFile('FlutterInputs.xcfilelist');

  /// The xcfilelist used to track the outputs for the Flutter script phase in
  /// the Xcode build.
  File get outputFileList => ephemeralDirectory.childFile('FlutterOutputs.xcfilelist');

  @override
  File get generatedXcodePropertiesFile => ephemeralDirectory.childFile('Flutter-Generated.xcconfig');

  @override
  File xcodeConfigFor(String mode) => managedDirectory.childFile('Flutter-$mode.xcconfig');

  @override
  File get generatedEnvironmentVariableExportScript => ephemeralDirectory.childFile('flutter_export_environment.sh');

  @override
  File get podfile => _macOSDirectory.childFile('Podfile');

  @override
  File get podfileLock => _macOSDirectory.childFile('Podfile.lock');

  @override
  File get podManifestLock => _macOSDirectory.childDirectory('Pods').childFile('Manifest.lock');

  @override
  Directory get xcodeProject => _macOSDirectory.childDirectory('$_hostAppProjectName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  Directory get xcodeWorkspace => _macOSDirectory.childDirectory('$_hostAppProjectName.xcworkspace');

  /// The file where the Xcode build will write the name of the built app.
  ///
  /// Ideally this will be replaced in the future with inspection of the Runner
  /// scheme's target.
  File get nameFile => ephemeralDirectory.childFile('.app_filename');

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    // TODO(stuartmorgan): Add create-from-template logic here.
    await _updateGeneratedXcodeConfigIfNeeded();
  }

  Future<void> _updateGeneratedXcodeConfigIfNeeded() async {
    if (globals.cache.isOlderThanToolsStamp(generatedXcodePropertiesFile)) {
      await xcode.updateGeneratedXcodeProperties(
        project: parent,
        buildInfo: BuildInfo.debug,
        useMacOSConfig: true,
        setSymroot: false,
      );
    }
  }
}

/// The Windows sub project.
class WindowsProject extends FlutterProjectPlatform implements CmakeBasedProject {
  WindowsProject._(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => WindowsPlugin.kConfigKey;

  @override
  bool existsSync() => _editableDirectory.existsSync() && cmakeFile.existsSync();

  @override
  File get cmakeFile => _editableDirectory.childFile('CMakeLists.txt');

  @override
  File get generatedCmakeConfigFile => ephemeralDirectory.childFile('generated_config.cmake');

  @override
  File get generatedPluginCmakeFile => managedDirectory.childFile('generated_plugins.cmake');

  @override
  Directory get pluginSymlinkDirectory => ephemeralDirectory.childDirectory('.plugin_symlinks');

  Directory get _editableDirectory => parent.directory.childDirectory('windows');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// The Linux sub project.
class LinuxProject extends FlutterProjectPlatform implements CmakeBasedProject {
  LinuxProject._(this.parent);

  @override
  final FlutterProject parent;

  @override
  String get pluginConfigKey => LinuxPlugin.kConfigKey;

  static final RegExp _applicationIdPattern = RegExp(r'''^\s*set\s*\(\s*APPLICATION_ID\s*"(.*)"\s*\)\s*$''');

  Directory get _editableDirectory => parent.directory.childDirectory('linux');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  @override
  bool existsSync() => _editableDirectory.existsSync();

  @override
  File get cmakeFile => _editableDirectory.childFile('CMakeLists.txt');

  @override
  File get generatedCmakeConfigFile => ephemeralDirectory.childFile('generated_config.cmake');

  @override
  File get generatedPluginCmakeFile => managedDirectory.childFile('generated_plugins.cmake');

  @override
  Directory get pluginSymlinkDirectory => ephemeralDirectory.childDirectory('.plugin_symlinks');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}

  String get applicationId {
    return _firstMatchInFile(cmakeFile, _applicationIdPattern)?.group(1);
  }
}

/// The Fuchsia sub project.
class FuchsiaProject {
  FuchsiaProject._(this.project);

  final FlutterProject project;

  Directory _editableHostAppDirectory;
  Directory get editableHostAppDirectory =>
      _editableHostAppDirectory ??= project.directory.childDirectory('fuchsia');

  bool existsSync() => editableHostAppDirectory.existsSync();

  Directory _meta;
  Directory get meta =>
      _meta ??= editableHostAppDirectory.childDirectory('meta');
}
