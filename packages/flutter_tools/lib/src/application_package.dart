// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart' as xml;

import 'android/gradle.dart';
import 'base/os.dart' show os;
import 'base/process.dart';
import 'build_info.dart';
import 'globals.dart';
import 'ios/plist_utils.dart' as plist;
import 'ios/xcodeproj.dart';

abstract class ApplicationPackage {
  /// Package ID from the Android Manifest or equivalent.
  final String id;

  ApplicationPackage({ this.id }) {
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
    String id,
    this.apkPath,
    this.launchActivity
  }) : super(id: id) {
    assert(apkPath != null);
    assert(launchActivity != null);
  }

  /// Creates a new AndroidApk from an existing APK.
  factory AndroidApk.fromApk(String applicationBinary) {
    String aaptPath = androidSdk?.latestVersion?.aaptPath;
    if (aaptPath == null) {
      printError('Unable to locate the Android SDK; please run \'flutter doctor\'.');
      return null;
    }

    List<String> aaptArgs = <String>[aaptPath, 'dump', 'badging', applicationBinary];
    ApkManifestData data = ApkManifestData.parseFromAaptBadging(runCheckedSync(aaptArgs));

    if (data == null) {
      printError('Unable to read manifest info from $applicationBinary.');
      return null;
    }

    if (data.packageName == null || data.launchableActivityName == null) {
      printError('Unable to read manifest info from $applicationBinary.');
      return null;
    }

    return new AndroidApk(
      id: data.packageName,
      apkPath: applicationBinary,
      launchActivity: '${data.packageName}/${data.launchableActivityName}'
    );
  }

  /// Creates a new AndroidApk based on the information in the Android manifest.
  factory AndroidApk.fromCurrentDirectory() {
    String manifestPath;
    String apkPath;

    if (isProjectUsingGradle()) {
      manifestPath = gradleManifestPath;
      apkPath = gradleAppOut;
    } else {
      manifestPath = path.join('android', 'AndroidManifest.xml');
      apkPath = path.join(getAndroidBuildDirectory(), 'app.apk');
    }

    if (!FileSystemEntity.isFileSync(manifestPath))
      return null;

    String manifestString = new File(manifestPath).readAsStringSync();
    xml.XmlDocument document = xml.parse(manifestString);

    Iterable<xml.XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty)
      return null;
    String packageId = manifests.first.getAttribute('package');

    String launchActivity;
    for (xml.XmlElement category in document.findAllElements('category')) {
      if (category.getAttribute('android:name') == 'android.intent.category.LAUNCHER') {
        xml.XmlElement activity = category.parent.parent;
        String activityName = activity.getAttribute('android:name');
        launchActivity = "$packageId/$activityName";
        break;
      }
    }

    if (packageId == null || launchActivity == null)
      return null;

    return new AndroidApk(
      id: packageId,
      apkPath: apkPath,
      launchActivity: launchActivity
    );
  }

  @override
  String get name => path.basename(apkPath);
}

/// Tests whether a [FileSystemEntity] is an iOS bundle directory
bool _isBundleDirectory(FileSystemEntity entity) =>
    entity is Directory && entity.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing IPA.
  factory IOSApp.fromIpa(String applicationBinary) {
    Directory bundleDir;
    try {
      Directory tempDir = Directory.systemTemp.createTempSync('flutter_app_');
      addShutdownHook(() async => await tempDir.delete(recursive: true));
      os.unzip(new File(applicationBinary), tempDir);
      Directory payloadDir = new Directory(path.join(tempDir.path, 'Payload'));
      bundleDir = payloadDir.listSync().singleWhere(_isBundleDirectory);
    } on StateError catch (e, stackTrace) {
      printError('Invalid prebuilt iOS binary: ${e.toString()}', stackTrace);
      return null;
    }

    String plistPath = path.join(bundleDir.path, 'Info.plist');
    String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    if (id == null)
      return null;

    return new PrebuiltIOSApp(
      ipaPath: applicationBinary,
      bundleDir: bundleDir,
      bundleName: path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  factory IOSApp.fromCurrentDirectory() {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      return null;

    String plistPath = path.join('ios', 'Runner', 'Info.plist');
    String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    if (id == null)
      return null;
    String projectPath = path.join('ios', 'Runner.xcodeproj');
    id = substituteXcodeVariables(id, projectPath, 'Runner');

    return new BuildableIOSApp(
      appDirectory: path.join('ios'),
      projectBundleId: id
    );
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;
}

class BuildableIOSApp extends IOSApp {
  static final String kBundleName = 'Runner.app';

  BuildableIOSApp({
    this.appDirectory,
    String projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  final String appDirectory;

  @override
  String get name => kBundleName;

  @override
  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  @override
  String get deviceBundlePath => _buildAppPath('iphoneos');

  String _buildAppPath(String type) {
    return path.join(getIosBuildDirectory(), 'Release-$type', kBundleName);
  }
}

class PrebuiltIOSApp extends IOSApp {
  final String ipaPath;
  final Directory bundleDir;
  final String bundleName;

  PrebuiltIOSApp({
    this.ipaPath,
    this.bundleDir,
    this.bundleName,
    String projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  @override
  String get name => bundleName;

  @override
  String get simulatorBundlePath => _bundlePath;

  @override
  String get deviceBundlePath => _bundlePath;

  String get _bundlePath => bundleDir.path;
}

ApplicationPackage getApplicationPackageForPlatform(TargetPlatform platform, {
  String applicationBinary
}) {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return applicationBinary == null
          ? new AndroidApk.fromCurrentDirectory()
          : new AndroidApk.fromApk(applicationBinary);
    case TargetPlatform.ios:
      return applicationBinary == null
          ? new IOSApp.fromCurrentDirectory()
          : new IOSApp.fromIpa(applicationBinary);
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

class ApkManifestData {
  ApkManifestData._(this._data);

  static ApkManifestData parseFromAaptBadging(String data) {
    if (data == null || data.trim().isEmpty)
      return null;

    // package: name='io.flutter.gallery' versionCode='1' versionName='0.0.1' platformBuildVersionName='NMR1'
    // launchable-activity: name='org.domokit.sky.shell.SkyActivity'  label='' icon=''
    Map<String, Map<String, String>> map = <String, Map<String, String>>{};

    for (String line in data.split('\n')) {
      int index = line.indexOf(':');
      if (index != -1) {
        String name = line.substring(0, index);
        line = line.substring(index + 1).trim();

        Map<String, String> entries = <String, String>{};
        map[name] = entries;

        for (String entry in line.split(' ')) {
          entry = entry.trim();
          if (entry.isNotEmpty && entry.contains('=')) {
            int split = entry.indexOf('=');
            String key = entry.substring(0, split);
            String value = entry.substring(split + 1);
            if (value.startsWith("'") && value.endsWith("'"))
              value = value.substring(1, value.length - 1);
            entries[key] = value;
          }
        }
      }
    }

    return new ApkManifestData._(map);
  }

  final Map<String, Map<String, String>> _data;

  String get packageName => _data['package'] == null ? null : _data['package']['name'];

  String get launchableActivityName {
    return _data['launchable-activity'] == null ? null : _data['launchable-activity']['name'];
  }

  @override
  String toString() => _data.toString();
}
