// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';


import 'android/android_sdk.dart';
import 'android/gradle.dart' as gradle;
import 'base/file_system.dart';
import 'bundle.dart' as bundle;
import 'cache.dart';
import 'flutter_manifest.dart';
import 'ios/xcodeproj.dart' as xcode;
import 'plugins.dart';
import 'template.dart';

/// Represents the contents of a Flutter project at the specified [directory].
class FlutterProject {

  FlutterProject(this.directory);
  FlutterProject.fromPath(String projectPath) : directory = fs.directory(projectPath);

  /// The location of this project.
  final Directory directory;

  Future<FlutterManifest> get manifest {
    return _manifest ??= FlutterManifest.createFromPath(
      directory.childFile(bundle.defaultManifestPath).path,
    );
  }
  Future<FlutterManifest> _manifest;

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
    return new Set<String>.from(
      candidates.map(_organizationNameFromPackageName)
                .where((String name) => name != null)
    );
  }

  String _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.'))
      return packageName.substring(0, packageName.lastIndexOf('.'));
    else
      return null;
  }

  /// The iOS sub project of this project.
  IosProject get ios => new IosProject(directory.childDirectory('ios'));

  /// The Android sub project of this project.
  AndroidProject get android => new AndroidProject(directory.childDirectory('android'));

  /// The generated AndroidModule sub project of this module project.
  AndroidModuleProject get androidModule => new AndroidModuleProject(directory.childDirectory('.android'));

  /// The generated IosModule sub project of this module project.
  IosModuleProject get iosModule => new IosModuleProject(directory.childDirectory('.ios'));

  Future<File> get androidLocalPropertiesFile {
    return _androidLocalPropertiesFile ??= manifest.then<File>((FlutterManifest manifest) {
      return directory.childDirectory(manifest.isModule ? '.android' : 'android')
          .childFile('local.properties');
    });
  }
  Future<File> _androidLocalPropertiesFile;

  Future<File> get generatedXcodePropertiesFile {
    return _generatedXcodeProperties ??= manifest.then<File>((FlutterManifest manifest) {
      return directory.childDirectory(manifest.isModule ? '.ios' : 'ios')
          .childDirectory('Flutter')
          .childFile('Generated.xcconfig');
    });
  }
  Future<File> _generatedXcodeProperties;

  File get flutterPluginsFile {
    return _flutterPluginsFile ??= directory.childFile('.flutter-plugins');
  }
  File _flutterPluginsFile;

  Future<Directory> get androidPluginRegistrantHost async {
    return _androidPluginRegistrantHost ??= manifest.then((FlutterManifest manifest) {
      if (manifest.isModule) {
        return directory.childDirectory('.android').childDirectory('Flutter');
      } else {
        return directory.childDirectory('android').childDirectory('app');
      }
    });
  }
  Future<Directory> _androidPluginRegistrantHost;

  Future<Directory> get iosPluginRegistrantHost async {
    return _iosPluginRegistrantHost ??= manifest.then((FlutterManifest manifest) {
      if (manifest.isModule) {
        // In a module create the GeneratedPluginRegistrant as a pod to be included
        // from a hosting app.
        return directory
            .childDirectory('.ios')
            .childDirectory('Flutter')
            .childDirectory('FlutterPluginRegistrant');
      } else {
        // For a non-module create the GeneratedPluginRegistrant as source files
        // directly in the iOS project.
        return directory.childDirectory('ios').childDirectory('Runner');
      }
    });
  }
  Future<Directory> _iosPluginRegistrantHost;

  /// Returns true if this project has an example application
  bool get hasExampleApp => _exampleDirectory.childFile('pubspec.yaml').existsSync();

  /// The example sub project of this (package or plugin) project.
  FlutterProject get example => new FlutterProject(_exampleDirectory);

  /// The directory that will contain the example if an example exists.
  Directory get _exampleDirectory => directory.childDirectory('example');

  /// Generates project files necessary to make Gradle builds work on Android
  /// and CocoaPods+Xcode work on iOS, for app and module projects only.
  ///
  /// Returns the number of files written.
  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (!directory.existsSync() || hasExampleApp) {
      return 0;
    }
    final FlutterManifest manifest = await this.manifest;
    if (manifest.isModule) {
      await androidModule.ensureReadyForPlatformSpecificTooling(this);
      await iosModule.ensureReadyForPlatformSpecificTooling();
    }
    await xcode.generateXcodeProperties(project: this);
    await injectPlugins(this);
  }
}

/// Represents the contents of the ios/ folder of a Flutter project.
class IosProject {
  static final RegExp _productBundleIdPattern = new RegExp(r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(.*);\s*$');
  IosProject(this.directory);

  final Directory directory;

  /// The xcode config file for [mode].
  File xcodeConfigFor(String mode) {
    return directory.childDirectory('Flutter').childFile('$mode.xcconfig');
  }

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
}

/// Represents the contents of the .ios/ folder of a Flutter module
/// project.
class IosModuleProject {
  IosModuleProject(this.directory);

  final Directory directory;

  Future<void> ensureReadyForPlatformSpecificTooling() async {
    if (_shouldRegenerate()) {
      final Template template = new Template.fromName(fs.path.join('module', 'ios'));
      template.render(directory, <String, dynamic>{}, printStatusWhenWriting: false);
    }
  }

  bool _shouldRegenerate() {
    return Cache.instance.fileOlderThanToolsStamp(directory.childFile('podhelper.rb'));
  }
}

/// Represents the contents of the android/ folder of a Flutter project.
class AndroidProject {
  static final RegExp _applicationIdPattern = new RegExp('^\\s*applicationId\\s+[\'\"](.*)[\'\"]\\s*\$');
  static final RegExp _groupPattern = new RegExp('^\\s*group\\s+[\'\"](.*)[\'\"]\\s*\$');

  AndroidProject(this.directory);

  final Directory directory;

  Future<String> applicationId() {
    final File gradleFile = directory.childDirectory('app').childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _applicationIdPattern).then((Match match) => match?.group(1));
  }

  Future<String> group() {
    final File gradleFile = directory.childFile('build.gradle');
    return _firstMatchInFile(gradleFile, _groupPattern).then((Match match) => match?.group(1));
  }
}

/// Represents the contents of the .android-generated/ folder of a Flutter module
/// project.
class AndroidModuleProject {
  AndroidModuleProject(this.directory);

  final Directory directory;

  Future<void> ensureReadyForPlatformSpecificTooling(FlutterProject project) async {
    if (_shouldRegenerate()) {
      final Template template = new Template.fromName(fs.path.join('module', 'android'));
      template.render(directory, <String, dynamic>{
        'androidIdentifier': (await project.manifest).moduleDescriptor['androidPackage'],
      }, printStatusWhenWriting: false);
      gradle.injectGradleWrapper(directory);
    }
    if (androidSdk != null)
      await gradle.updateLocalProperties(project: project);
  }

  bool _shouldRegenerate() {
    return Cache.instance.fileOlderThanToolsStamp(directory.childFile('build.gradle'));
  }
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
