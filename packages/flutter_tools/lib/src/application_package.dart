// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart' as xml;

import 'build_info.dart';
import 'ios/plist_utils.dart';

abstract class ApplicationPackage {
  /// Path to the package's root folder.
  final String rootPath;

  /// Path to the actual apk or bundle.
  final String localPath;

  /// Package ID from the Android Manifest or equivalent.
  final String id;

  /// File name of the apk or bundle.
  final String name;

  ApplicationPackage({String rootPath, String localPath, this.id})
      : rootPath = rootPath,
        localPath = localPath,
        name = path.basename(localPath) {
    assert(rootPath != null);
    assert(localPath != null);
    assert(id != null);
  }

  String get displayName => name;

  @override
  String toString() => displayName;
}

class AndroidApk extends ApplicationPackage {
  /// The path to the activity that should be launched.
  final String launchActivity;

  AndroidApk({
    String androidBuildDir,
    String androidApkPath,
    String id,
    this.launchActivity
  }) : super(rootPath: androidBuildDir, localPath: androidApkPath, id: id) {
    assert(launchActivity != null);
  }

  /// Creates a new AndroidApk based on the information in the Android manifest.
  factory AndroidApk.fromCurrentDirectory() {
    String manifestPath = path.join('android', 'AndroidManifest.xml');
    if (!FileSystemEntity.isFileSync(manifestPath))
      return null;
    String manifestString = new File(manifestPath).readAsStringSync();
    xml.XmlDocument document = xml.parse(manifestString);

    Iterable<xml.XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty)
      return null;
    String id = manifests.first.getAttribute('package');

    String launchActivity;
    for (xml.XmlElement category in document.findAllElements('category')) {
      if (category.getAttribute('android:name') == 'android.intent.category.LAUNCHER') {
        xml.XmlElement activity = category.parent.parent;
        String activityName = activity.getAttribute('android:name');
        launchActivity = "$id/$activityName";
        break;
      }
    }
    if (id == null || launchActivity == null)
      return null;

    return new AndroidApk(
      androidBuildDir: 'build',
      androidApkPath: path.join('build', 'app.apk'),
      id: id,
      launchActivity: launchActivity
    );
  }
}

class IOSApp extends ApplicationPackage {
  IOSApp({
    String iosProjectDir,
    String iosAppPath,
    String iosProjectBundleId
  }) : super(
    rootPath: iosProjectDir,
    localPath: iosAppPath,
    id: iosProjectBundleId
  );

  factory IOSApp.fromCurrentDirectory() {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      return null;

    String plistPath = path.join('ios', 'Info.plist');
    String value = getValueFromFile(plistPath, kCFBundleIdentifierKey);
    if (value == null)
      return null;

    String projectDir = path.join('ios', '.generated');
    return new IOSApp(
      iosProjectDir: projectDir,
      iosAppPath: path.join(projectDir, 'build', 'Release-iphoneos', 'Runner.app'),
      iosProjectBundleId: value
    );
  }

  @override
  String get displayName => id;
}

ApplicationPackage getApplicationPackageForPlatform(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return new AndroidApk.fromCurrentDirectory();
    case TargetPlatform.ios:
      return new IOSApp.fromCurrentDirectory();
    case TargetPlatform.darwin_x64:
    case TargetPlatform.linux_x64:
      return null;
  }
}

class ApplicationPackageStore {
  AndroidApk android;
  IOSApp iOS;

  ApplicationPackageStore({ this.android, this.iOS });

  ApplicationPackage getPackageForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        android ??= new AndroidApk.fromCurrentDirectory();
        return android;
      case TargetPlatform.ios:
        iOS ??= new IOSApp.fromCurrentDirectory();
        return iOS;
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
        return null;
    }
  }
}
