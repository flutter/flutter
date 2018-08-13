// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import 'android/gradle.dart' as gradle;
import 'base/common.dart';
import 'base/file_system.dart';
import 'build_info.dart';
import 'bundle.dart' as bundle;
import 'cache.dart';
import 'flutter_manifest.dart';
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
    return new FlutterProject(directory, manifest, exampleManifest);
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

  /// Asynchronously returns the organization names found in this project as
  /// part of iOS product bundle identifier, Android application ID, or
  /// Gradle group ID.
  Future<Set<String>> organizationNames() async {
    final List<String> candidates = await Future.wait(<Future<String>>[
      ios.productBundleIdentifier(),
      android.applicationId(),
      android.group(),
      example.android.applicationId(),
      example.ios.productBundleIdentifier(),
    ]);
    return new Set<String>.from(candidates
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
  IosProject get ios => new IosProject._(this);

  /// The Android sub project of this project.
  AndroidProject get android => new AndroidProject._(this);

  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

  /// The example sub-project of this project.
  FlutterProject get example => new FlutterProject(
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
  static final RegExp _productBundleIdPattern = new RegExp(r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(.*);\s*$');

  IosProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  /// The directory of this project.
  Directory get directory => parent.directory.childDirectory(isModule ? '.ios' : 'ios');

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

  Future<String> productBundleIdentifier() {
    final File projectFile = directory.childDirectory('Runner.xcodeproj').childFile('project.pbxproj');
    return _firstMatchInFile(projectFile, _productBundleIdPattern).then((Match match) => match?.group(1));
  }

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (isModule && _shouldRegenerateFromTemplate()) {
      final Template template = new Template.fromName(fs.path.join('module', 'ios'));
      template.render(directory, <String, dynamic>{}, printStatusWhenWriting: false);
    }
    if (!directory.existsSync())
      return;
    if (Cache.instance.fileOlderThanToolsStamp(generatedXcodePropertiesFile)) {
      await xcode.updateGeneratedXcodeProperties(
        project: parent,
        buildInfo: BuildInfo.debug,
        targetOverride: bundle.defaultMainPath,
        previewDart2: true,
      );
    }
  }

  bool _shouldRegenerateFromTemplate() {
    return Cache.instance.fileOlderThanToolsStamp(directory.childFile('podhelper.rb'));
  }

  File get generatedXcodePropertiesFile => directory.childDirectory('Flutter').childFile('Generated.xcconfig');

  Directory get pluginRegistrantHost {
    return isModule
        ? directory.childDirectory('Flutter').childDirectory('FlutterPluginRegistrant')
        : directory.childDirectory('Runner');
  }
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter modules.
class AndroidProject {
  static final RegExp _applicationIdPattern = new RegExp('^\\s*applicationId\\s+[\'\"](.*)[\'\"]\\s*\$');
  static final RegExp _groupPattern = new RegExp('^\\s*group\\s+[\'\"](.*)[\'\"]\\s*\$');

  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  /// The directory of this project.
  Directory get directory => parent.directory.childDirectory(isModule ? '.android' : 'android');

  /// True, if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  File get gradleManifestFile {
    return isUsingGradle()
        ? fs.file(fs.path.join(directory.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : directory.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return fs.directory(fs.path.join(directory.path, 'app', 'build', 'outputs', 'apk'));
  }

  bool isUsingGradle() {
    return directory.childFile('build.gradle').existsSync();
  }

  Future<String> applicationId() {
    final File gradleFile = directory.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _applicationIdPattern).then((Match match) => match?.group(1));
  }

  Future<String> group() {
    final File gradleFile = directory.childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _groupPattern).then((Match match) => match?.group(1));
  }

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (isModule && _shouldRegenerateFromTemplate()) {
      final Template template = new Template.fromName(fs.path.join('module', 'android'));
      template.render(
        directory,
        <String, dynamic>{
          'androidIdentifier': parent.manifest.androidPackage,
        },
        printStatusWhenWriting: false,
      );
      gradle.injectGradleWrapper(directory);
    }
    if (!directory.existsSync())
      return;
    await gradle.updateLocalProperties(project: parent, requireAndroidSdk: false);
  }

  bool _shouldRegenerateFromTemplate() {
    return Cache.instance.fileOlderThanToolsStamp(directory.childFile('build.gradle'));
  }

  File get localPropertiesFile => directory.childFile('local.properties');

  Directory get pluginRegistrantHost => directory.childDirectory(isModule ? 'Flutter' : 'app');
}

/// Asynchronously returns the first line-based match for [regExp] in [file].
///
/// Assumes UTF8 encoding.
Future<Match> _firstMatchInFile(File file, RegExp regExp) async {
  if (!await file.exists()) {
    return null;
  }
  return file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map(regExp.firstMatch)
      .firstWhere((Match match) => match != null, orElse: () => null);
}
