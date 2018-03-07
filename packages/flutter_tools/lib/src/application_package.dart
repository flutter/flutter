// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required;
import 'package:xml/xml.dart' as xml;

import 'android/android_sdk.dart';
import 'android/gradle.dart';
import 'base/file_system.dart';
import 'base/os.dart' show os;
import 'base/process.dart';
import 'build_info.dart';
import 'globals.dart';
import 'ios/plist_utils.dart' as plist;
import 'ios/xcodeproj.dart';

abstract class ApplicationPackage {
  /// Package ID from the Android Manifest or equivalent.
  final String id;

  ApplicationPackage({ @required this.id })
    : assert(id != null);

  String get name;

  String get displayName => name;

  String get packagePath => null;

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
    @required this.apkPath,
    @required this.launchActivity
  }) : assert(apkPath != null),
       assert(launchActivity != null),
       super(id: id);

  /// Creates a new AndroidApk from an existing APK.
  factory AndroidApk.fromApk(String applicationBinary) {
    final String aaptPath = androidSdk?.latestVersion?.aaptPath;
    if (aaptPath == null) {
      printError('Unable to locate the Android SDK; please run \'flutter doctor\'.');
      return null;
    }

    final List<String> aaptArgs = <String>[aaptPath, 'dump', 'badging', applicationBinary];
    final ApkManifestData data = ApkManifestData.parseFromAaptBadging(runCheckedSync(aaptArgs));

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
  static Future<AndroidApk> fromCurrentDirectory() async {
    String manifestPath;
    String apkPath;

    if (isProjectUsingGradle()) {
      apkPath = await getGradleAppOut();
      if (fs.file(apkPath).existsSync()) {
        // Grab information from the .apk. The gradle build script might alter
        // the application Id, so we need to look at what was actually built.
        return new AndroidApk.fromApk(apkPath);
      }
      // The .apk hasn't been built yet, so we work with what we have. The run
      // command will grab a new AndroidApk after building, to get the updated
      // IDs.
      manifestPath = gradleManifestPath;
    } else {
      manifestPath = fs.path.join('android', 'AndroidManifest.xml');
      apkPath = fs.path.join(getAndroidBuildDirectory(), 'app.apk');
    }

    if (!fs.isFileSync(manifestPath))
      return null;

    final String manifestString = fs.file(manifestPath).readAsStringSync();
    final xml.XmlDocument document = xml.parse(manifestString);

    final Iterable<xml.XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty)
      return null;
    final String packageId = manifests.first.getAttribute('package');

    String launchActivity;
    for (xml.XmlElement category in document.findAllElements('category')) {
      if (category.getAttribute('android:name') == 'android.intent.category.LAUNCHER') {
        final xml.XmlElement activity = category.parent.parent;
        final String activityName = activity.getAttribute('android:name');
        launchActivity = '$packageId/$activityName';
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
  String get packagePath => apkPath;

  @override
  String get name => fs.path.basename(apkPath);
}

/// Tests whether a [FileSystemEntity] is an iOS bundle directory
bool _isBundleDirectory(FileSystemEntity entity) =>
    entity is Directory && entity.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing IPA.
  factory IOSApp.fromIpa(String applicationBinary) {
    Directory bundleDir;
    try {
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_app_');
      addShutdownHook(() async {
        await tempDir.delete(recursive: true);
      }, ShutdownStage.STILL_RECORDING);
      os.unzip(fs.file(applicationBinary), tempDir);
      final Directory payloadDir = fs.directory(fs.path.join(tempDir.path, 'Payload'));
      bundleDir = payloadDir.listSync().singleWhere(_isBundleDirectory);
    } on StateError catch (e, stackTrace) {
      printError('Invalid prebuilt iOS binary: ${e.toString()}', stackTrace: stackTrace);
      return null;
    }

    final String plistPath = fs.path.join(bundleDir.path, 'Info.plist');
    final String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    if (id == null)
      return null;

    return new PrebuiltIOSApp(
      ipaPath: applicationBinary,
      bundleDir: bundleDir,
      bundleName: fs.path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  factory IOSApp.fromCurrentDirectory() {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      return null;

    final String plistPath = fs.path.join('ios', 'Runner', 'Info.plist');
    String id = plist.getValueFromFile(plistPath, plist.kCFBundleIdentifierKey);
    if (id == null || !xcodeProjectInterpreter.isInstalled)
      return null;
    final String projectPath = fs.path.join('ios', 'Runner.xcodeproj');
    final Map<String, String> buildSettings = xcodeProjectInterpreter.getBuildSettings(projectPath, 'Runner');
    id = substituteXcodeVariables(id, buildSettings);

    return new BuildableIOSApp(
      appDirectory: 'ios',
      projectBundleId: id,
      buildSettings: buildSettings,
    );
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;
}

class BuildableIOSApp extends IOSApp {
  static const String kBundleName = 'Runner.app';

  BuildableIOSApp({
    this.appDirectory,
    String projectBundleId,
    this.buildSettings,
  }) : super(projectBundleId: projectBundleId);

  final String appDirectory;

  /// Build settings of the app's Xcode project.
  ///
  /// These are the build settings as specified in the Xcode project files.
  ///
  /// Build settings may change depending on the parameters passed while building.
  final Map<String, String> buildSettings;

  @override
  String get name => kBundleName;

  @override
  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  @override
  String get deviceBundlePath => _buildAppPath('iphoneos');

  /// True if the app is built from a Swift project. Null if unknown.
  bool get isSwift => buildSettings?.containsKey('SWIFT_VERSION');

  String _buildAppPath(String type) {
    return fs.path.join(getIosBuildDirectory(), type, kBundleName);
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
    @required String projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  @override
  String get name => bundleName;

  @override
  String get simulatorBundlePath => _bundlePath;

  @override
  String get deviceBundlePath => _bundlePath;

  String get _bundlePath => bundleDir.path;
}

Future<ApplicationPackage> getApplicationPackageForPlatform(TargetPlatform platform, {
  String applicationBinary
}) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return applicationBinary == null
          ? await AndroidApk.fromCurrentDirectory()
          : new AndroidApk.fromApk(applicationBinary);
    case TargetPlatform.ios:
      return applicationBinary == null
          ? new IOSApp.fromCurrentDirectory()
          : new IOSApp.fromIpa(applicationBinary);
    case TargetPlatform.darwin_x64:
    case TargetPlatform.linux_x64:
    case TargetPlatform.windows_x64:
    case TargetPlatform.fuchsia:
      return null;
  }
  assert(platform != null);
  return null;
}

class ApplicationPackageStore {
  AndroidApk android;
  IOSApp iOS;

  ApplicationPackageStore({ this.android, this.iOS });

  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform) async {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        android ??= await AndroidApk.fromCurrentDirectory();
        return android;
      case TargetPlatform.ios:
        iOS ??= new IOSApp.fromCurrentDirectory();
        return iOS;
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia:
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
    // launchable-activity: name='io.flutter.app.FlutterActivity'  label='' icon=''
    final Map<String, Map<String, String>> map = <String, Map<String, String>>{};

    for (String line in data.split('\n')) {
      final int index = line.indexOf(':');
      if (index != -1) {
        final String name = line.substring(0, index);
        line = line.substring(index + 1).trim();

        final Map<String, String> entries = <String, String>{};
        map[name] = entries;

        for (String entry in line.split(' ')) {
          entry = entry.trim();
          if (entry.isNotEmpty && entry.contains('=')) {
            final int split = entry.indexOf('=');
            final String key = entry.substring(0, split);
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
