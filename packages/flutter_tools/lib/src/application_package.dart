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

  /// Package ID from the Android Manifest or equivalent.
  final String id;

  ApplicationPackage({this.rootPath, this.id}) {
    assert(rootPath != null);
    assert(id != null);
  }

  String get name;

  String get displayName => name;

  @override
  String toString() => displayName;
}

class AndroidApk extends ApplicationPackage {
  /// Path to the actual apk file.
  final String apkPath;

  /// The path to the activity that should be launched.
  final String launchActivity;

  AndroidApk({
    String buildDir,
    String id,
    this.apkPath,
    this.launchActivity
  }) : super(rootPath: buildDir, id: id) {
    assert(apkPath != null);
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
      buildDir: 'build',
      id: id,
      apkPath: path.join('build', 'app.apk'),
      launchActivity: launchActivity
    );
  }

  @override
  String get name => path.basename(apkPath);
}

class IOSApp extends ApplicationPackage {
  static final String kBundleName = 'Runner.app';

  IOSApp({
    String projectDir,
    String projectBundleId
  }) : super(rootPath: projectDir, id: projectBundleId);

  factory IOSApp.fromCurrentDirectory() {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      return null;

    String plistPath = path.join('ios', 'Info.plist');
    String value = getValueFromFile(plistPath, kCFBundleIdentifierKey);
    if (value == null)
      return null;

    return new IOSApp(
      projectDir: path.join('ios', '.generated'),
      projectBundleId: value
    );
  }

  @override
  String get name => kBundleName;

  @override
  String get displayName => id;

  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  String get deviceBundlePath => _buildAppPath('iphoneos');

  String _buildAppPath(String type) {
    return path.join(rootPath, 'build', 'Release-$type', kBundleName);
  }
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
  assert(platform != null);
  return null;
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
    return null;
  }
}
