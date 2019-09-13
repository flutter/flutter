// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:xml/xml.dart' as xml;

import 'android/android_sdk.dart';
import 'android/gradle.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/os.dart' show os;
import 'base/process.dart';
import 'base/user_messages.dart';
import 'build_info.dart';
import 'fuchsia/application_package.dart';
import 'globals.dart';
import 'ios/plist_parser.dart';
import 'linux/application_package.dart';
import 'macos/application_package.dart';
import 'project.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/application_package.dart';

class ApplicationPackageFactory {
  static ApplicationPackageFactory get instance => context.get<ApplicationPackageFactory>();

  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    File applicationBinary,
  }) async {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        if (androidSdk?.licensesAvailable == true  && androidSdk.latestVersion == null) {
          await checkGradleDependencies();
        }
        return applicationBinary == null
            ? await AndroidApk.fromAndroidProject(FlutterProject.current().android)
            : AndroidApk.fromApk(applicationBinary);
      case TargetPlatform.ios:
        return applicationBinary == null
            ? IOSApp.fromIosProject(FlutterProject.current().ios)
            : IOSApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.tester:
        return FlutterTesterApp.fromCurrentDirectory();
      case TargetPlatform.darwin_x64:
        return applicationBinary == null
            ? MacOSApp.fromMacOSProject(FlutterProject.current().macos)
            : MacOSApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.web_javascript:
        if (!FlutterProject.current().web.existsSync()) {
          return null;
        }
        return WebApplicationPackage(FlutterProject.current());
      case TargetPlatform.linux_x64:
        return applicationBinary == null
            ? LinuxApp.fromLinuxProject(FlutterProject.current().linux)
            : LinuxApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.windows_x64:
        return applicationBinary == null
            ? WindowsApp.fromWindowsProject(FlutterProject.current().windows)
            : WindowsApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.fuchsia:
        return applicationBinary == null
            ? FuchsiaApp.fromFuchsiaProject(FlutterProject.current().fuchsia)
            : FuchsiaApp.fromPrebuiltApp(applicationBinary);
    }
    assert(platform != null);
    return null;
  }
}

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
    @required this.versionCode,
    @required this.launchActivity,
  }) : assert(file != null),
       assert(launchActivity != null),
       super(id: id);

  /// Creates a new AndroidApk from an existing APK.
  factory AndroidApk.fromApk(File apk) {
    final String aaptPath = androidSdk?.latestVersion?.aaptPath;
    if (aaptPath == null) {
      printError(userMessages.aaptNotFound);
      return null;
    }

    String apptStdout;
    try {
      apptStdout = processUtils.runSync(
        <String>[
          aaptPath,
          'dump',
          'xmltree',
          apk.path,
          'AndroidManifest.xml',
        ],
        throwOnError: true,
      ).stdout.trim();
    } on ProcessException catch (error) {
      printError('Failed to extract manifest from APK: $error.');
      return null;
    }

    final ApkManifestData data = ApkManifestData.parseFromXmlDump(apptStdout);

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
      versionCode: int.tryParse(data.versionCode),
      launchActivity: '${data.packageName}/${data.launchableActivityName}',
    );
  }

  /// Path to the actual apk file.
  final File file;

  /// The path to the activity that should be launched.
  final String launchActivity;

  /// The version code of the APK.
  final int versionCode;

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

    if (!manifest.existsSync()) {
      printError('AndroidManifest.xml could not be found.');
      printError('Please check ${manifest.path} for errors.');
      return null;
    }

    final String manifestString = manifest.readAsStringSync();
    xml.XmlDocument document;
    try {
      document = xml.parse(manifestString);
    } on xml.XmlParserException catch (exception) {
      String manifestLocation;
      if (androidProject.isUsingGradle) {
        manifestLocation = fs.path.join(androidProject.hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml');
      } else {
        manifestLocation = fs.path.join(androidProject.hostAppGradleRoot.path, 'AndroidManifest.xml');
      }
      printError('AndroidManifest.xml is not a valid XML document.');
      printError('Please check $manifestLocation for errors.');
      throwToolExit('XML Parser error message: ${exception.toString()}');
    }

    final Iterable<xml.XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty) {
      printError('AndroidManifest.xml has no manifest element.');
      printError('Please check ${manifest.path} for errors.');
      return null;
    }
    final String packageId = manifests.first.getAttribute('package');

    String launchActivity;
    for (xml.XmlElement activity in document.findAllElements('activity')) {
      final String enabled = activity.getAttribute('android:enabled');
      if (enabled != null && enabled == 'false') {
        continue;
      }

      for (xml.XmlElement element in activity.findElements('intent-filter')) {
        String actionName = '';
        String categoryName = '';
        for (xml.XmlNode node in element.children) {
          if (!(node is xml.XmlElement)) {
            continue;
          }
          final xml.XmlElement xmlElement = node;
          final String name = xmlElement.getAttribute('android:name');
          if (name == 'android.intent.action.MAIN') {
            actionName = name;
          } else if (name == 'android.intent.category.LAUNCHER') {
            categoryName = name;
          }
        }
        if (actionName.isNotEmpty && categoryName.isNotEmpty) {
          final String activityName = activity.getAttribute('android:name');
          launchActivity = '$packageId/$activityName';
          break;
        }
      }
    }

    if (packageId == null || launchActivity == null) {
      printError('package identifier or launch activity not found.');
      printError('Please check ${manifest.path} for errors.');
      return null;
    }

    return AndroidApk(
      id: packageId,
      file: apkFile,
      versionCode: null,
      launchActivity: launchActivity,
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
    final String id = PlistParser.instance.getValueFromFile(
      plistPath,
      PlistParser.kCFBundleIdentifierKey,
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
    if (getCurrentHostPlatform() != HostPlatform.darwin_x64) {
      return null;
    }
    if (!project.exists) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    if (!project.xcodeProject.existsSync()) {
      printError('Expected ios/Runner.xcodeproj but this file is missing.');
      return null;
    }
    if (!project.xcodeProjectInfoFile.existsSync()) {
      printError('Expected ios/Runner.xcodeproj/project.pbxproj but this file is missing.');
      return null;
    }
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

class ApplicationPackageStore {
  ApplicationPackageStore({ this.android, this.iOS, this.fuchsia });

  AndroidApk android;
  IOSApp iOS;
  FuchsiaApp fuchsia;
  LinuxApp linux;
  MacOSApp macOS;
  WindowsApp windows;

  Future<ApplicationPackage> getPackageForPlatform(TargetPlatform platform) async {
    switch (platform) {
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        android ??= await AndroidApk.fromAndroidProject(FlutterProject.current().android);
        return android;
      case TargetPlatform.ios:
        iOS ??= IOSApp.fromIosProject(FlutterProject.current().ios);
        return iOS;
      case TargetPlatform.fuchsia:
        fuchsia ??= FuchsiaApp.fromFuchsiaProject(FlutterProject.current().fuchsia);
        return fuchsia;
      case TargetPlatform.darwin_x64:
        macOS ??= MacOSApp.fromMacOSProject(FlutterProject.current().macos);
        return macOS;
      case TargetPlatform.linux_x64:
        linux ??= LinuxApp.fromLinuxProject(FlutterProject.current().linux);
        return linux;
      case TargetPlatform.windows_x64:
        windows ??= WindowsApp.fromWindowsProject(FlutterProject.current().windows);
        return windows;
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
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

    final int manifestLine = lines.indexWhere((String line) => line.contains('E: manifest'));
    final _Element manifest = _Element.fromLine(lines[manifestLine], null);
    _Element currentElement = manifest;

    for (String line in lines.skip(manifestLine)) {
      final String trimLine = line.trimLeft();
      final int level = line.length - trimLine.length;

      // Handle level out
      while (currentElement.parent != null && level <= currentElement.level) {
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
      final Iterable<_Element> intentFilters = activity
          .allElements('intent-filter')
          .cast<_Element>();
      final bool isEnabledByDefault = enabled == null;
      final bool isExplicitlyEnabled = enabled != null && enabled.value.contains('0xffffffff');
      if (!(isEnabledByDefault || isExplicitlyEnabled)) {
        continue;
      }

      for (_Element element in intentFilters) {
        final _Element action = element.firstElement('action');
        final _Element category = element.firstElement('category');
        final String actionAttributeValue = action
            ?.firstAttribute('android:name')
            ?.value;
        final String categoryAttributeValue =
            category?.firstAttribute('android:name')?.value;
        final bool isMainAction = actionAttributeValue != null &&
            actionAttributeValue.startsWith('"android.intent.action.MAIN"');
        final bool isLauncherCategory = categoryAttributeValue != null &&
            categoryAttributeValue.startsWith('"android.intent.category.LAUNCHER"');
        if (isMainAction && isLauncherCategory) {
          launchActivity = activity;
          break;
        }
      }
      if (launchActivity != null) {
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

    // Example format: (type 0x10)0x1
    final _Attribute versionCodeAttr = manifest.firstAttribute('android:versionCode');
    if (versionCodeAttr == null) {
      printError('Error running $packageName. Manifest versionCode not found');
      return null;
    }
    if (!versionCodeAttr.value.startsWith('(type 0x10)')) {
      printError('Error running $packageName. Manifest versionCode invalid');
      return null;
    }
    final int versionCode = int.tryParse(versionCodeAttr.value.substring(11));
    if (versionCode == null) {
      printError('Error running $packageName. Manifest versionCode invalid');
      return null;
    }

    final Map<String, Map<String, String>> map = <String, Map<String, String>>{};
    map['package'] = <String, String>{'name': packageName};
    map['version-code'] = <String, String>{'name': versionCode.toString()};
    map['launchable-activity'] = <String, String>{'name': activityName};

    return ApkManifestData._(map);
  }

  final Map<String, Map<String, String>> _data;

  @visibleForTesting
  Map<String, Map<String, String>> get data =>
      UnmodifiableMapView<String, Map<String, String>>(_data);

  String get packageName => _data['package'] == null ? null : _data['package']['name'];

  String get versionCode => _data['version-code'] == null ? null : _data['version-code']['name'];

  String get launchableActivityName {
    return _data['launchable-activity'] == null ? null : _data['launchable-activity']['name'];
  }

  @override
  String toString() => _data.toString();
}
