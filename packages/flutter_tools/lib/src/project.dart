// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'android/gradle.dart' as gradle;
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'bundle.dart' as bundle;
import 'cache.dart';
import 'flutter_manifest.dart';
import 'ios/ios_workflow.dart';
import 'ios/plist_utils.dart' as plist;
import 'ios/xcodeproj.dart' as xcode;
import 'plugins.dart';
import 'template.dart';

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

  /// Returns a future that completes with a [FlutterProject] view of the given directory
  /// or a ToolExit error, if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static Future<FlutterProject> fromDirectory(Directory directory) async {
    assert(directory != null);
    final FlutterManifest manifest = await _readManifest(
      directory.childFile(bundle.defaultManifestPath).path,
    );
    final FlutterManifest exampleManifest = await _readManifest(
      _exampleDirectory(directory).childFile(bundle.defaultManifestPath).path,
    );
    return FlutterProject(directory, manifest, exampleManifest);
  }

  /// Returns a future that completes with a [FlutterProject] view of the current directory.
  /// or a ToolExit error, if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static Future<FlutterProject> current() => fromDirectory(fs.currentDirectory);

  /// Returns a future that completes with a [FlutterProject] view of the given directory.
  /// or a ToolExit error, if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static Future<FlutterProject> fromPath(String path) => fromDirectory(fs.directory(path));

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
        .map(_organizationNameFromPackageName)
        .where((String name) => name != null));
  }

  String _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.'))
      return packageName.substring(0, packageName.lastIndexOf('.'));
    else
      return null;
  }

  /// The iOS sub project of this project.
  IosProject get ios => IosProject._(this);

  /// The Android sub project of this project.
  AndroidProject get android => AndroidProject._(this);

  /// The `pubspec.yaml` file of this project.
  File get pubspecFile => directory.childFile('pubspec.yaml');

  /// The `.packages` file of this project.
  File get packagesFile => directory.childFile('.packages');

  /// The `.flutter-plugins` file of this project.
  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

  /// The example sub-project of this project.
  FlutterProject get example => FlutterProject(
    _exampleDirectory(directory),
    _exampleManifest,
    FlutterManifest.empty(),
  );

  /// True, if this project is a Flutter module.
  bool get isModule => manifest.isModule;

  /// True, if this project has an example application.
  bool get hasExampleApp => _exampleDirectory(directory).existsSync();

  /// The directory that will contain the example if an example exists.
  static Directory _exampleDirectory(Directory directory) => directory.childDirectory('example');

  /// Reads and validates the `pubspec.yaml` file at [path], asynchronously
  /// returning a [FlutterManifest] representation of the contents.
  ///
  /// Completes with an empty [FlutterManifest], if the file does not exist.
  /// Completes with a ToolExit on validation error.
  static Future<FlutterManifest> _readManifest(String path) async {
    final FlutterManifest manifest = await FlutterManifest.createFromPath(path);
    if (manifest == null)
      throwToolExit('Please correct the pubspec.yaml file at $path');
    return manifest;
  }

  /// Generates project files necessary to make Gradle builds work on Android
  /// and CocoaPods+Xcode work on iOS, for app and module projects only.
  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (!directory.existsSync() || hasExampleApp)
      return;
    refreshPluginsList(this);
    await android.ensureReadyForPlatformSpecificTooling();
    await ios.ensureReadyForPlatformSpecificTooling();
    await injectPlugins(this);
  }
}

/// Represents the iOS sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `ios/` sub-folder of
/// Flutter applications and the `.ios/` sub-folder of Flutter modules.
class IosProject {
  static final RegExp _productBundleIdPattern = RegExp(r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(.*);\s*$');
  static const String _productBundleIdVariable = r'$(PRODUCT_BUNDLE_IDENTIFIER)';
  static const String _hostAppBundleName = 'Runner';

  IosProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  /// The directory of this project.
  Directory get directory => parent.directory.childDirectory(isModule ? '.ios' : 'ios');

  String get hostAppBundleName => '$_hostAppBundleName.app';

  /// True, if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  /// The xcode config file for [mode].
  File xcodeConfigFor(String mode) => directory.childDirectory('Flutter').childFile('$mode.xcconfig');

  /// The 'Podfile'.
  File get podfile => directory.childFile('Podfile');

  /// The 'Podfile.lock'.
  File get podfileLock => directory.childFile('Podfile.lock');

  /// The 'Manifest.lock'.
  File get podManifestLock => directory.childDirectory('Pods').childFile('Manifest.lock');

  /// The 'Info.plist' file of the host app.
  File get hostInfoPlist => directory.childDirectory(_hostAppBundleName).childFile('Info.plist');

  /// '.xcodeproj' folder of the host app.
  Directory get xcodeProject => directory.childDirectory('$_hostAppBundleName.xcodeproj');

  /// The '.pbxproj' file of the host app.
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  /// The product bundle identifier of the host app, or null if not set or if
  /// iOS tooling needed to read it is not installed.
  String get productBundleIdentifier {
    final String fromPlist = iosWorkflow.getPlistValueFromFile(
      hostInfoPlist.path,
      plist.kCFBundleIdentifierKey,
    );
    if (fromPlist != null && !fromPlist.contains('\$')) {
      // Info.plist has no build variables in product bundle ID.
      return fromPlist;
    }
    final String fromPbxproj = _firstMatchInFile(xcodeProjectInfoFile, _productBundleIdPattern)?.group(1);
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

  /// True, if the host app project is using Swift.
  bool get isSwift => buildSettings?.containsKey('SWIFT_VERSION');

  /// The build settings for the host app of this project, as a detached map.
  ///
  /// Returns null, if iOS tooling is unavailable.
  Map<String, String> get buildSettings {
    if (!xcode.xcodeProjectInterpreter.isInstalled)
      return null;
    return xcode.xcodeProjectInterpreter.getBuildSettings(xcodeProject.path, _hostAppBundleName);
  }

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    _regenerateFromTemplateIfNeeded();
    if (!directory.existsSync())
      return;
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
    final bool pubspecChanged = isOlderThanReference(entity: directory, referenceFile: parent.pubspecFile);
    final bool toolingChanged = Cache.instance.isOlderThanToolsStamp(directory);
    if (!pubspecChanged && !toolingChanged)
      return;
    _deleteIfExistsSync(directory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'library'), directory);
    _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral'), directory);
    if (hasPlugins(parent)) {
      _overwriteFromTemplate(fs.path.join('module', 'ios', 'host_app_ephemeral_cocoapods'), directory);
    }
  }

  Future<void> materialize() async {
    throwToolExit('flutter materialize has not yet been implemented for iOS');
  }

  File get generatedXcodePropertiesFile => directory.childDirectory('Flutter').childFile('Generated.xcconfig');

  Directory get pluginRegistrantHost {
    return isModule
        ? directory.childDirectory('Flutter').childDirectory('FlutterPluginRegistrant')
        : directory.childDirectory(_hostAppBundleName);
  }

  void _overwriteFromTemplate(String path, Directory target) {
    final Template template = Template.fromName(path);
    template.render(
      target,
      <String, dynamic>{
        'projectName': parent.manifest.appName,
        'iosIdentifier': parent.manifest.iosBundleIdentifier
      },
      printStatusWhenWriting: false,
      overwriteExisting: true,
    );
  }
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter modules.
class AndroidProject {
  static final RegExp _applicationIdPattern = RegExp('^\\s*applicationId\\s+[\'\"](.*)[\'\"]\\s*\$');
  static final RegExp _groupPattern = RegExp('^\\s*group\\s+[\'\"](.*)[\'\"]\\s*\$');

  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  /// The Gradle root directory of the Android host app. This is the directory
  /// containing the `app/` subdirectory and the `settings.gradle` file that
  /// includes it in the overall Gradle project.
  Directory get hostAppGradleRoot {
    if (!isModule || _materializedDirectory.existsSync())
      return _materializedDirectory;
    return _ephemeralDirectory;
  }

  /// The Gradle root directory of the Android wrapping of Flutter and plugins.
  /// This is the same as [hostAppGradleRoot] except when the project is
  /// a Flutter module with a materialized host app.
  Directory get _flutterLibGradleRoot => isModule ? _ephemeralDirectory : _materializedDirectory;

  Directory get _ephemeralDirectory => parent.directory.childDirectory('.android');
  Directory get _materializedDirectory => parent.directory.childDirectory('android');

  /// True, if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  File get appManifestFile {
    return isUsingGradle
        ? fs.file(fs.path.join(hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return fs.directory(fs.path.join(hostAppGradleRoot.path, 'app', 'build', 'outputs', 'apk'));
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
      // Add ephemeral host app, if a materialized host app does not already exist.
      if (!_materializedDirectory.existsSync()) {
        _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_common'), _ephemeralDirectory);
        _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_ephemeral'), _ephemeralDirectory);
      }
    }
    if (!hostAppGradleRoot.existsSync()) {
      return;
    }
    gradle.updateLocalProperties(project: parent, requireAndroidSdk: false);
  }

  bool _shouldRegenerateFromTemplate() {
    return isOlderThanReference(entity: _ephemeralDirectory, referenceFile: parent.pubspecFile)
        || Cache.instance.isOlderThanToolsStamp(_ephemeralDirectory);
  }

  Future<void> materialize() async {
    assert(isModule);
    if (_materializedDirectory.existsSync())
      throwToolExit('Android host app already materialized. To redo materialization, delete the android/ folder.');
    _regenerateLibrary();
    _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_common'), _materializedDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'host_app_materialized'), _materializedDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'gradle'), _materializedDirectory);
    gradle.injectGradleWrapper(_materializedDirectory);
    gradle.writeLocalProperties(_materializedDirectory.childFile('local.properties'));
    await injectPlugins(parent);
  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost => _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  void _regenerateLibrary() {
    _deleteIfExistsSync(_ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'library'), _ephemeralDirectory);
    _overwriteFromTemplate(fs.path.join('module', 'android', 'gradle'), _ephemeralDirectory);
    gradle.injectGradleWrapper(_ephemeralDirectory);
  }

  void _overwriteFromTemplate(String path, Directory target) {
    final Template template = Template.fromName(path);
    template.render(
      target,
      <String, dynamic>{
        'projectName': parent.manifest.appName,
        'androidIdentifier': parent.manifest.androidPackage,
      },
      printStatusWhenWriting: false,
      overwriteExisting: true,
    );
  }
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
