// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import 'android/gradle.dart' as gradle;
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'bundle.dart' as bundle;
import 'cache.dart';
import 'features.dart';
import 'flutter_manifest.dart';
import 'globals.dart';
import 'ios/plist_parser.dart';
import 'ios/xcodeproj.dart' as xcode;
import 'plugins.dart';
import 'template.dart';

FlutterProjectFactory get projectFactory => context.get<FlutterProjectFactory>() ?? FlutterProjectFactory();

class FlutterProjectFactory {
  FlutterProjectFactory();

  final Map<String, FlutterProject> _projects =
      <String, FlutterProject>{};

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject fromDirectory(Directory directory) {
    assert(directory != null);
    return _projects.putIfAbsent(directory.path, /* ifAbsent */ () {
      final FlutterManifest manifest = FlutterProject._readManifest(
        directory.childFile(bundle.defaultManifestPath).path,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory)
            .childFile(bundle.defaultManifestPath)
            .path,
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
  static FlutterProject fromDirectory(Directory directory) => projectFactory.fromDirectory(directory);

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject current() => fromDirectory(fs.currentDirectory);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromPath(String path) => fromDirectory(fs.directory(path));

  /// The location of this project.
  final Directory directory;

  /// The manifest of this project.
  final FlutterManifest manifest;

  /// The manifest of the example sub-project of this project.
  final FlutterManifest _exampleManifest;

  /// The set of organization names found in this project as
  /// part of iOS product bundle identifier, Android application ID, or
  /// Gradle group ID.
  Set<String> get organizationNames {
    final List<String> candidates = <String>[
      ios.productBundleIdentifier,
      android.applicationId,
      android.group,
      example.android.applicationId,
      example.ios.productBundleIdentifier,
    ];
    return Set<String>.from(candidates
        .map<String>(_organizationNameFromPackageName)
        .where((String name) => name != null));
  }

  String _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.'))
      return packageName.substring(0, packageName.lastIndexOf('.'));
    else
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

  /// The `.flutter-plugins` file of this project.
  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

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
    FlutterManifest.empty(),
  );

  /// True if this project is a Flutter module project.
  bool get isModule => manifest.isModule;

  /// True if the Flutter project is using the AndroidX support library
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
  static FlutterManifest _readManifest(String path) {
    FlutterManifest manifest;
    try {
      manifest = FlutterManifest.createFromPath(path);
    } on YamlException catch (e) {
      printStatus('Error detected in pubspec.yaml:', emphasis: true);
      printError('$e');
    }
    if (manifest == null) {
      throwToolExit('Please correct the pubspec.yaml file at $path');
    }
    return manifest;
  }

  /// Generates project files necessary to make Gradle builds work on Android
  /// and CocoaPods+Xcode work on iOS, for app and module projects only.
  Future<void> ensureReadyForPlatformSpecificTooling({bool checkProjects = false}) async {
    if (!directory.existsSync() || hasExampleApp) {
      return;
    }
    refreshPluginsList(this);
    if ((android.existsSync() && checkProjects) || !checkProjects) {
      await android.ensureReadyForPlatformSpecificTooling();
    }
    if ((ios.existsSync() && checkProjects) || !checkProjects) {
      await ios.ensureReadyForPlatformSpecificTooling();
    }
    // TODO(stuartmorgan): Add checkProjects logic once a create workflow exists
    // for macOS. For now, always treat checkProjects as true for macOS.
    if (featureFlags.isMacOSEnabled && macos.existsSync()) {
      await macos.ensureReadyForPlatformSpecificTooling();
    }
    if (featureFlags.isWebEnabled && web.existsSync()) {
      await web.ensureReadyForPlatformSpecificTooling();
    }
    await injectPlugins(this, checkProjects: checkProjects);
  }

  /// Return the set of builders used by this package.
  YamlMap get builders {
    if (!pubspecFile.existsSync()) {
      return null;
    }
    final YamlMap pubspec = loadYaml(pubspecFile.readAsStringSync());
    // If the pubspec file is empty, this will be null.
    if (pubspec == null) {
      return null;
    }
    return pubspec['builders'];
  }

  /// Whether there are any builders used by this package.
  bool get hasBuilders {
    final YamlMap result = builders;
    return result != null && result.isNotEmpty;
  }
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

  /// True if the host app project is using Swift.
  bool get isSwift;
}

/// Represents the iOS sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `ios/` sub-folder of
/// Flutter applications and the `.ios/` sub-folder of Flutter module projects.
class IosProject implements XcodeBasedProject {
  IosProject.fromFlutter(this.parent);

  @override
  final FlutterProject parent;

  static final RegExp _productBundleIdPattern = RegExp(r'''^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(["']?)(.*?)\1;\s*$''');
  static const String _productBundleIdVariable = r'$(PRODUCT_BUNDLE_IDENTIFIER)';
  static const String _hostAppBundleName = 'Runner';

  Directory get ephemeralDirectory => parent.directory.childDirectory('.ios');
  Directory get _editableDirectory => parent.directory.childDirectory('ios');

  /// This parent folder of `Runner.xcodeproj`.
  Directory get hostAppRoot {
    if (!isModule || _editableDirectory.existsSync())
      return _editableDirectory;
    return ephemeralDirectory;
  }

  /// The root directory of the iOS wrapping of Flutter and plugins. This is the
  /// parent of the `Flutter/` folder into which Flutter artifacts are written
  /// during build.
  ///
  /// This is the same as [hostAppRoot] except when the project is
  /// a Flutter module with an editable host app.
  Directory get _flutterLibRoot => isModule ? ephemeralDirectory : _editableDirectory;

  /// The bundle name of the host app, `Runner.app`.
  String get hostAppBundleName => '$_hostAppBundleName.app';

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

  /// The 'Info.plist' file of the host app.
  File get hostInfoPlist => hostAppRoot.childDirectory(_hostAppBundleName).childFile('Info.plist');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('$_hostAppBundleName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  Directory get xcodeWorkspace => hostAppRoot.childDirectory('$_hostAppBundleName.xcworkspace');

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
  String get productBundleIdentifier {
    String fromPlist;
    try {
      fromPlist = PlistParser.instance.getValueFromFile(
        hostInfoPlist.path,
        PlistParser.kCFBundleIdentifierKey,
      );
    } on FileNotFoundException {
      // iOS tooling not found; likely not running OSX; let [fromPlist] be null
    }
    if (fromPlist != null && !fromPlist.contains('\$')) {
      // Info.plist has no build variables in product bundle ID.
      return fromPlist;
    }
    final String fromPbxproj = _firstMatchInFile(xcodeProjectInfoFile, _productBundleIdPattern)?.group(2);
    if (fromPbxproj != null && (fromPlist == null || fromPlist == _productBundleIdVariable)) {
      // Common case. Avoids parsing build settings.
      return fromPbxproj;
    }
    if (fromPlist != null && xcode.xcodeProjectInterpreter.isInstalled) {
      // General case: perform variable substitution using build settings.
      return xcode.substituteXcodeVariables(fromPlist, buildSettings);
    }
    return null;
  }

  @override
  bool get isSwift => buildSettings?.containsKey('SWIFT_VERSION') ?? false;

  /// The build settings for the host app of this project, as a detached map.
  ///
  /// Returns null, if iOS tooling is unavailable.
  Map<String, String> get buildSettings {
    if (!xcode.xcodeProjectInterpreter.isInstalled)
      return null;
    _buildSettings ??=
        xcode.xcodeProjectInterpreter.getBuildSettings(xcodeProject.path,
                                                       _hostAppBundleName);
    return _buildSettings;
  }

  Map<String, String> _buildSettings;

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    _regenerateFromTemplateIfNeeded();
    if (!_flutterLibRoot.existsSync())
      return;
    await _updateGeneratedXcodeConfigIfNeeded();
  }

  Future<void> _updateGeneratedXcodeConfigIfNeeded() async {
    if (Cache.instance.isOlderThanToolsStamp(generatedXcodePropertiesFile)) {
      await xcode.updateGeneratedXcodeProperties(
        project: parent,
        buildInfo: BuildInfo.debug,
        targetOverride: bundle.defaultMainPath,
      );
    }
  }

  void _regenerateFromTemplateIfNeeded() {
    if (!isModule)
      return;
    final bool pubspecChanged = isOlderThanReference(entity: ephemeralDirectory, referenceFile: parent.pubspecFile);
    final bool toolingChanged = Cache.instance.isOlderThanToolsStamp(ephemeralDirectory);
    if (!pubspecChanged && !toolingChanged)
      return;
    _deleteIfExistsSync(ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'library'), ephemeralDirectory);
    // Add ephemeral host app, if a editable host app does not already exist.
    if (!_editableDirectory.existsSync()) {
      _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral'), ephemeralDirectory);
      if (hasPlugins(parent)) {
        _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral_cocoapods'), ephemeralDirectory);
      }
    }
  }

  Future<void> makeHostAppEditable() async {
    assert(isModule);
    if (_editableDirectory.existsSync())
      throwToolExit('iOS host app is already editable. To start fresh, delete the ios/ folder.');
    _deleteIfExistsSync(ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'library'), ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral'), _editableDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral_cocoapods'), _editableDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_editable_cocoapods'), _editableDirectory);
    await _updateGeneratedXcodeConfigIfNeeded();
    await injectPlugins(parent);
  }

  @override
  File get generatedXcodePropertiesFile => _flutterLibRoot.childDirectory('Flutter').childFile('Generated.xcconfig');

  Directory get pluginRegistrantHost {
    return isModule
        ? _flutterLibRoot.childDirectory('Flutter').childDirectory('FlutterPluginRegistrant')
        : hostAppRoot.childDirectory(_hostAppBundleName);
  }

  void _overwriteFromTemplate(String path, Directory target) {
    final Template template = Template.fromName(path);
    template.render(
      target,
      <String, dynamic>{
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
class AndroidProject {
  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  static final RegExp _applicationIdPattern = RegExp('^\\s*applicationId\\s+[\'\"](.*)[\'\"]\\s*\$');
  static final RegExp _kotlinPluginPattern = RegExp('^\\s*apply plugin\:\\s+[\'\"]kotlin-android[\'\"]\\s*\$');
  static final RegExp _groupPattern = RegExp('^\\s*group\\s+[\'\"](.*)[\'\"]\\s*\$');

  /// The Gradle root directory of the Android host app. This is the directory
  /// containing the `app/` subdirectory and the `settings.gradle` file that
  /// includes it in the overall Gradle project.
  Directory get hostAppGradleRoot {
    if (!isModule || _editableHostAppDirectory.existsSync())
      return _editableHostAppDirectory;
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

  /// True if the Flutter project is using the AndroidX support library
  bool get usesAndroidX => parent.usesAndroidX;

  /// True, if the app project is using Kotlin.
  bool get isKotlin {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _kotlinPluginPattern) != null;
  }

  File get appManifestFile {
    return isUsingGradle
        ? fs.file(fs.path.join(hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return fs.directory(fs.path.join(hostAppGradleRoot.path, 'app', 'build', 'outputs', 'apk'));
  }

  /// Whether the current flutter project has an Android sub-project.
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

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (isModule && _shouldRegenerateFromTemplate()) {
      _regenerateLibrary();
      // Add ephemeral host app, if an editable host app does not already exist.
      if (!_editableHostAppDirectory.existsSync()) {
        _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_common'), ephemeralDirectory);
        _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_ephemeral'), ephemeralDirectory);
      }
    }
    if (!hostAppGradleRoot.existsSync()) {
      return;
    }
    gradle.updateLocalProperties(project: parent, requireAndroidSdk: false);
  }

  bool _shouldRegenerateFromTemplate() {
    return isOlderThanReference(entity: ephemeralDirectory, referenceFile: parent.pubspecFile)
        || Cache.instance.isOlderThanToolsStamp(ephemeralDirectory);
  }

  Future<void> makeHostAppEditable() async {
    assert(isModule);
    if (_editableHostAppDirectory.existsSync())
      throwToolExit('Android host app is already editable. To start fresh, delete the android/ folder.');
    _regenerateLibrary();
    _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_common'), _editableHostAppDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_editable'), _editableHostAppDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'gradle'), _editableHostAppDirectory);
    gradle.injectGradleWrapperIfNeeded(_editableHostAppDirectory);
    gradle.writeLocalProperties(_editableHostAppDirectory.childFile('local.properties'));
    await injectPlugins(parent);
  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost => _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  void _regenerateLibrary() {
    _deleteIfExistsSync(ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'library'), ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'gradle'), ephemeralDirectory);
    gradle.injectGradleWrapperIfNeeded(ephemeralDirectory);
  }

  void _overwriteFromTemplate(String path, Directory target) {
    final Template template = Template.fromName(path);
    template.render(
      target,
      <String, dynamic>{
        'projectName': parent.manifest.appName,
        'androidIdentifier': parent.manifest.androidPackage,
        'androidX': usesAndroidX,
      },
      printStatusWhenWriting: false,
      overwriteExisting: true,
    );
  }
}

/// Represents the web sub-project of a Flutter project.
class WebProject {
  WebProject._(this.parent);

  final FlutterProject parent;

  /// Whether this flutter project has a web sub-project.
  bool existsSync() {
    return parent.directory.childDirectory('web').existsSync()
      && indexFile.existsSync();
  }

  /// The 'lib' directory for the application.
  Directory get libDirectory => parent.directory.childDirectory('lib');

  /// The html file used to host the flutter web application.
  File get indexFile => parent.directory
      .childDirectory('web')
      .childFile('index.html');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// Deletes [directory] with all content.
void _deleteIfExistsSync(Directory directory) {
  if (directory.existsSync())
    directory.deleteSync(recursive: true);
}


/// Returns the first line-based match for [regExp] in [file].
///
/// Assumes UTF8 encoding.
Match _firstMatchInFile(File file, RegExp regExp) {
  if (!file.existsSync()) {
    return null;
  }
  for (String line in file.readAsLinesSync()) {
    final Match match = regExp.firstMatch(line);
    if (match != null) {
      return match;
    }
  }
  return null;
}

/// The macOS sub project.
class MacOSProject implements XcodeBasedProject {
  MacOSProject._(this.parent);

  @override
  final FlutterProject parent;

  static const String _hostAppBundleName = 'Runner';

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
  Directory get xcodeProject => _macOSDirectory.childDirectory('$_hostAppBundleName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  Directory get xcodeWorkspace => _macOSDirectory.childDirectory('$_hostAppBundleName.xcworkspace');

  @override
  bool get isSwift => true;

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
    if (Cache.instance.isOlderThanToolsStamp(generatedXcodePropertiesFile)) {
      await xcode.updateGeneratedXcodeProperties(
        project: parent,
        buildInfo: BuildInfo.debug,
        useMacOSConfig: true,
        setSymroot: false,
      );
    }
  }
}

/// The Windows sub project
class WindowsProject {
  WindowsProject._(this.project);

  final FlutterProject project;

  bool existsSync() => _editableDirectory.existsSync();

  Directory get _editableDirectory => project.directory.childDirectory('windows');

  /// The directory in the project that is managed by Flutter. As much as
  /// possible, files that are edited by Flutter tooling after initial project
  /// creation should live here.
  Directory get managedDirectory => _editableDirectory.childDirectory('flutter');

  /// The subdirectory of [managedDirectory] that contains files that are
  /// generated on the fly. All generated files that are not intended to be
  /// checked in should live here.
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  /// Contains definitions for FLUTTER_ROOT, LOCAL_ENGINE, and more flags for
  /// the build.
  File get generatedPropertySheetFile => ephemeralDirectory.childFile('Generated.props');

  // The MSBuild project file.
  File get vcprojFile => _editableDirectory.childFile('Runner.vcxproj');

  // The MSBuild solution file.
  File get solutionFile => _editableDirectory.childFile('Runner.sln');

  /// The file where the VS build will write the name of the built app.
  ///
  /// Ideally this will be replaced in the future with inspection of the project.
  File get nameFile => ephemeralDirectory.childFile('exe_filename');
}

/// The Linux sub project.
class LinuxProject {
  LinuxProject._(this.project);

  final FlutterProject project;

  Directory get editableHostAppDirectory => project.directory.childDirectory('linux');

  // TODO(stuartmorgan): Move to using an ephemeralDirectory to match the other
  // desktop projects.
  Directory get cacheDirectory => editableHostAppDirectory.childDirectory('flutter');

  bool existsSync() => editableHostAppDirectory.existsSync();

  /// The Linux project makefile.
  File get makeFile => editableHostAppDirectory.childFile('Makefile');
}

/// The Fuchisa sub project
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
