// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;

import 'android/android_sdk.dart';
import 'android/gradle.dart';
import 'base/file_system.dart';
import 'base/os.dart' show os;
import 'base/process.dart';
import 'build_info.dart';
import 'globals.dart';
import 'ios/ios_workflow.dart';
import 'ios/plist_utils.dart' as plist;
import 'project.dart';
import 'tester/flutter_tester.dart';

abstract class ApplicationPackage {
  ApplicationPackage({ @required this.id })
    : assert(id != null);

  /// Package ID from the Android Manifest or equivalent.
  final String id;

  String get name;

  String get displayName => name;

  File get packagesFile => null;

  @override
  String toString() => displayName ?? id;
}

class AndroidApk extends ApplicationPackage {
  AndroidApk({
    String id,
    @required this.file,
    @required this.launchActivity
  }) : assert(file != null),
       assert(launchActivity != null),
       super(id: id);

  /// Creates a new AndroidApk from an existing APK.
  factory AndroidApk.fromApk(File apk) {
    final String aaptPath = androidSdk?.latestVersion?.aaptPath;
    if (aaptPath == null) {
      printError('Unable to locate the Android SDK; please run \'flutter doctor\'.');
      return null;
    }

     final List<String> aaptArgs = <String>[
       aaptPath,
      'dump',
      'xmltree',
      apk.path,
      'AndroidManifest.xml',
    ];

    final ApkManifestData data = ApkManifestData
        .parseFromXmlDump(runCheckedSync(aaptArgs));

    if (data == null) {
      printError('Unable to read manifest info from ${apk.path}.');
      return null;
    }

    if (data.packageName == null || data.launchableActivityName == null) {
      printError('Unable to read manifest info from ${apk.path}.');
      return null;
    }

    return AndroidApk(
      id: data.packageName,
      file: apk,
      launchActivity: '${data.packageName}/${data.launchableActivityName}'
    );
  }

  /// Path to the actual apk file.
  final File file;

  /// The path to the activity that should be launched.
  final String launchActivity;

  /// Creates a new AndroidApk based on the information in the Android manifest.
  static Future<AndroidApk> fromAndroidProject(AndroidProject androidProject) async {
    File apkFile;

    if (androidProject.isUsingGradle) {
      apkFile = await getGradleAppOut(androidProject);
      if (apkFile.existsSync()) {
        // Grab information from the .apk. The gradle build script might alter
        // the application Id, so we need to look at what was actually built.
        return AndroidApk.fromApk(apkFile);
      }
      // The .apk hasn't been built yet, so we work with what we have. The run
      // command will grab a new AndroidApk after building, to get the updated
      // IDs.
    } else {
      apkFile = fs.file(fs.path.join(getAndroidBuildDirectory(), 'app.apk'));
    }

    final File manifest = androidProject.appManifestFile;

    if (!manifest.existsSync())
      return null;

    final String manifestString = manifest.readAsStringSync();
    final xml.XmlDocument document = xml.parse(manifestString);

    final Iterable<xml.XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty)
      return null;
    final String packageId = manifests.first.getAttribute('package');

    String launchActivity;
    for (xml.XmlElement category in document.findAllElements('category')) {
      if (category.getAttribute('android:name') == 'android.intent.category.LAUNCHER') {
        final xml.XmlElement activity = category.parent.parent;
        final String enabled = activity.getAttribute('android:enabled');
        if (enabled == null || enabled == 'true') {
          final String activityName = activity.getAttribute('android:name');
          launchActivity = '$packageId/$activityName';
          break;
        }
      }
    }

    if (packageId == null || launchActivity == null)
      return null;

    return AndroidApk(
      id: packageId,
      file: apkFile,
      launchActivity: launchActivity
    );
  }

  @override
  File get packagesFile => file;

  @override
  String get name => file.basename;
}

/// Tests whether a [FileSystemEntity] is an iOS bundle directory
bool _isBundleDirectory(FileSystemEntity entity) =>
    entity is Directory && entity.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing app bundle or IPA.
  factory IOSApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = fs.typeSync(applicationBinary.path);
    if (entityType == FileSystemEntityType.notFound) {
      printError(
          'File "${applicationBinary.path}" does not exist. Use an app bundle or an ipa.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = fs.directory(applicationBinary);
      if (!_isBundleDirectory(directory)) {
        printError('Folder "${applicationBinary.path}" is not an app bundle.');
        return null;
      }
      bundleDir = fs.directory(applicationBinary);
    } else {
      // Try to unpack as an ipa.
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_app.');
      addShutdownHook(() async {
        await tempDir.delete(recursive: true);
      }, ShutdownStage.STILL_RECORDING);
      os.unzip(fs.file(applicationBinary), tempDir);
      final Directory payloadDir = fs.directory(
        fs.path.join(tempDir.path, 'Payload'),
      );
      if (!payloadDir.existsSync()) {
        printError(
            'Invalid prebuilt iOS ipa. Does not contain a "Payload" directory.');
        return null;
      }
      try {
        bundleDir = payloadDir.listSync().singleWhere(_isBundleDirectory);
      } on StateError {
        printError(
            'Invalid prebuilt iOS ipa. Does not contain a single app bundle.');
        return null;
      }
    }
    final String plistPath = fs.path.join(bundleDir.path, 'Info.plist');
    if (!fs.file(plistPath).existsSync()) {
      printError('Invalid prebuilt iOS app. Does not contain Info.plist.');
      return null;
    }
    final String id = iosWorkflow.getPlistValueFromFile(
      plistPath,
      plist.kCFBundleIdentifierKey,
    );
    if (id == null) {
      printError('Invalid prebuilt iOS app. Info.plist does not contain bundle identifier');
      return null;
    }

    return PrebuiltIOSApp(
      bundleDir: bundleDir,
      bundleName: fs.path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  factory IOSApp.fromIosProject(IosProject project) {
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64)
      return null;
    return BuildableIOSApp(project);
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;
}

class BuildableIOSApp extends IOSApp {
  BuildableIOSApp(this.project) : super(projectBundleId: project.productBundleIdentifier);

  final IosProject project;

  @override
  String get name => project.hostAppBundleName;

  @override
  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  @override
  String get deviceBundlePath => _buildAppPath('iphoneos');

  String _buildAppPath(String type) {
    return fs.path.join(getIosBuildDirectory(), type, name);
  }
}

class PrebuiltIOSApp extends IOSApp {
  PrebuiltIOSApp({
    this.bundleDir,
    this.bundleName,
    @required String projectBundleId,
  }) : super(projectBundleId: projectBundleId);

  final Directory bundleDir;
  final String bundleName;

  @override
  String get name => bundleName;

  @override
  String get simulatorBundlePath => _bundlePath;

  @override
  String get deviceBundlePath => _bundlePath;

  String get _bundlePath => bundleDir.path;
}

Future<ApplicationPackage> getApplicationPackageForPlatform(
    TargetPlatform platform,
    {File applicationBinary}) async {
  switch (platform) {
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return applicationBinary == null
          ? await AndroidApk.fromAndroidProject((await FlutterProject.current()).android)
          : AndroidApk.fromApk(applicationBinary);
    case TargetPlatform.ios:
      return applicationBinary == null
          ? IOSApp.fromIosProject((await FlutterProject.current()).ios)
          : IOSApp.fromPrebuiltApp(applicationBinary);
    case TargetPlatform.tester:
      return FlutterTesterApp.fromCurrentDirectory();
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
  ApplicationPackageStore({ this.android, this.iOS });

  AndroidApk android;
  IOSApp iOS;

  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform) async {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        android ??= await AndroidApk.fromAndroidProject((await FlutterProject.current()).android);
        return android;
      case TargetPlatform.ios:
        iOS ??= IOSApp.fromIosProject((await FlutterProject.current()).ios);
        return iOS;
      case TargetPlatform.darwin_x64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.windows_x64:
      case TargetPlatform.fuchsia:
      case TargetPlatform.tester:
        return null;
    }
    return null;
  }
}

class _Entry {
  _Element parent;
  int level;
}

class _Element extends _Entry {
  _Element.fromLine(String line, _Element parent) {
    //      E: application (line=29)
    final List<String> parts = line.trimLeft().split(' ');
    name = parts[1];
    level = line.length - line.trimLeft().length;
    this.parent = parent;
    children = <_Entry>[];
  }

  List<_Entry> children;
  String name;

  void addChild(_Entry child) {
    children.add(child);
  }

  _Attribute firstAttribute(String name) {
    return children.firstWhere(
        (_Entry e) => e is _Attribute && e.key.startsWith(name),
        orElse: () => null,
    );
  }

  _Element firstElement(String name) {
    return children.firstWhere(
        (_Entry e) => e is _Element && e.name.startsWith(name),
        orElse: () => null,
    );
  }

  Iterable<_Entry> allElements(String name) {
    return children.where(
            (_Entry e) => e is _Element && e.name.startsWith(name));
  }
}

class _Attribute extends _Entry {
  _Attribute.fromLine(String line, _Element parent) {
    //     A: android:label(0x01010001)="hello_world" (Raw: "hello_world")
    const String attributePrefix = 'A: ';
    final List<String> keyVal = line
        .substring(line.indexOf(attributePrefix) + attributePrefix.length)
        .split('=');
    key = keyVal[0];
    value = keyVal[1];
    level = line.length - line.trimLeft().length;
    this.parent = parent;
  }

  String key;
  String value;
}

class ApkManifestData {
  ApkManifestData._(this._data);

  static ApkManifestData parseFromXmlDump(String data) {
    if (data == null || data.trim().isEmpty)
      return null;

    final List<String> lines = data.split('\n');
    assert(lines.length > 3);

    final _Element manifest = _Element.fromLine(lines[1], null);
    _Element currentElement = manifest;

    for (String line in lines.skip(2)) {
      final String trimLine = line.trimLeft();
      final int level = line.length - trimLine.length;

      // Handle level out
      while(level <= currentElement.level) {
        currentElement = currentElement.parent;
      }

      if (level > currentElement.level) {
        switch (trimLine[0]) {
          case 'A':
            currentElement
                .addChild(_Attribute.fromLine(line, currentElement));
            break;
          case 'E':
            final _Element element = _Element.fromLine(line, currentElement);
            currentElement.addChild(element);
            currentElement = element;
        }
      }
    }

    final _Element application = manifest.firstElement('application');
    assert(application != null);

    final Iterable<_Entry> activities = application.allElements('activity');

    _Element launchActivity;
    for (_Element activity in activities) {
      final _Attribute enabled = activity.firstAttribute('android:enabled');
      if (enabled == null || enabled.value.contains('0xffffffff')) {
        launchActivity = activity;
        break;
      }
    }

    final _Attribute package = manifest.firstAttribute('package');
    // "io.flutter.examples.hello_world" (Raw: "io.flutter.examples.hello_world")
    final String packageName = package.value.substring(1, package.value.indexOf('" '));

    if (launchActivity == null) {
      printError('Error running $packageName. Default activity not found');
      return null;
    }

    final _Attribute nameAttribute = launchActivity.firstAttribute('android:name');
    // "io.flutter.examples.hello_world.MainActivity" (Raw: "io.flutter.examples.hello_world.MainActivity")
    final String activityName = nameAttribute
        .value.substring(1, nameAttribute.value.indexOf('" '));

    final Map<String, Map<String, String>> map = <String, Map<String, String>>{};
    map['package'] = <String, String>{'name': packageName};
    map['launchable-activity'] = <String, String>{'name': activityName};

    return ApkManifestData._(map);
  }

  final Map<String, Map<String, String>> _data;

  @visibleForTesting
  Map<String, Map<String, String>> get data =>
      UnmodifiableMapView<String, Map<String, String>>(_data);

  String get packageName => _data['package'] == null ? null : _data['package']['name'];

  String get launchableActivityName {
    return _data['launchable-activity'] == null ? null : _data['launchable-activity']['name'];
  }

  @override
  String toString() => _data.toString();
}
