// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'base/file_system.dart';
import 'ios/xcodeproj.dart';
import 'plugins.dart';


/// Represents the contents of a Flutter project at the specified [directory].
class FlutterProject {
  FlutterProject(this.directory);

  /// The location of this project.
  final Directory directory;

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

  /// Returns true if this project is a plugin project.
  bool get isPluginProject => directory.childDirectory('example').childFile('pubspec.yaml').existsSync();

  /// The example sub project of this (plugin) project.
  FlutterProject get example => new FlutterProject(directory.childDirectory('example'));

  /// Generates project files necessary to make Gradle builds work on Android
  /// and CocoaPods+Xcode work on iOS.
  void ensureReadyForPlatformSpecificTooling() {
    if (!directory.existsSync() || isPluginProject) {
      return;
    }
    injectPlugins(directory: directory.path);
    generateXcodeProperties(directory.path);
  }
}

/// Represents the contents of the ios/ folder of a Flutter project.
class IosProject {
  static final RegExp _productBundleIdPattern = new RegExp(r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(.*);\s*$');
  IosProject(this.directory);

  final Directory directory;

  Future<String> productBundleIdentifier() {
    final File projectFile = directory.childDirectory('Runner.xcodeproj').childFile('project.pbxproj');
    return _firstMatchInFile(projectFile, _productBundleIdPattern).then((Match match) => match?.group(1));
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
