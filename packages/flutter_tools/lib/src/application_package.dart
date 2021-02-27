// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:xml/xml.dart';

import 'android/android_sdk.dart';
import 'android/gradle.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'base/user_messages.dart';
import 'build_info.dart';
import 'fuchsia/application_package.dart';
import 'globals.dart' as globals;
import 'ios/plist_parser.dart';
import 'linux/application_package.dart';
import 'macos/application_package.dart';
import 'project.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/application_package.dart';

class ApplicationPackageFactory {
  ApplicationPackageFactory({
    @required AndroidSdk androidSdk,
    @required ProcessManager processManager,
    @required Logger logger,
    @required UserMessages userMessages,
    @required FileSystem fileSystem,
  }) : _androidSdk = androidSdk,
       _processManager = processManager,
       _logger = logger,
       _userMessages = userMessages,
       _fileSystem = fileSystem,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager);

  static ApplicationPackageFactory get instance => context.get<ApplicationPackageFactory>();

  final AndroidSdk _androidSdk;
  final ProcessManager _processManager;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final UserMessages _userMessages;
  final FileSystem _fileSystem;

  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo buildInfo,
    File applicationBinary,
  }) async {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        if (applicationBinary == null) {
          return await AndroidApk.fromAndroidProject(
            FlutterProject.current().android,
            processManager: _processManager,
            processUtils: _processUtils,
            logger: _logger,
            androidSdk: _androidSdk,
            userMessages: _userMessages,
            fileSystem: _fileSystem,
          );
        }
        return AndroidApk.fromApk(
          applicationBinary,
          processManager: _processManager,
          logger: _logger,
          androidSdk: _androidSdk,
          userMessages: _userMessages,
        );
      case TargetPlatform.ios:
        return applicationBinary == null
            ? await IOSApp.fromIosProject(FlutterProject.current().ios, buildInfo)
            : IOSApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.tester:
        return FlutterTesterApp.fromCurrentDirectory(globals.fs);
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
      case TargetPlatform.linux_arm64:
        return applicationBinary == null
            ? LinuxApp.fromLinuxProject(FlutterProject.current().linux)
            : LinuxApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.windows_x64:
        return applicationBinary == null
            ? WindowsApp.fromWindowsProject(FlutterProject.current().windows)
            : WindowsApp.fromPrebuiltApp(applicationBinary);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
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

/// An application package created from an already built Android APK.
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
  ///
  /// Returns `null` if the APK was invalid or any required tooling was missing.
  factory AndroidApk.fromApk(File apk, {
    @required AndroidSdk androidSdk,
    @required ProcessManager processManager,
    @required UserMessages userMessages,
    @required Logger logger,
  }) {
    final String aaptPath = androidSdk?.latestVersion?.aaptPath;
    if (aaptPath == null || !processManager.canRun(aaptPath)) {
      logger.printError(userMessages.aaptNotFound);
      return null;
    }

    String apptStdout;
    try {
      apptStdout = globals.processUtils.runSync(
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
      globals.printError('Failed to extract manifest from APK: $error.');
      return null;
    }

    final ApkManifestData data = ApkManifestData.parseFromXmlDump(apptStdout, logger);

    if (data == null) {
      logger.printError('Unable to read manifest info from ${apk.path}.');
      return null;
    }

    if (data.packageName == null || data.launchableActivityName == null) {
      logger.printError('Unable to read manifest info from ${apk.path}.');
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
  static Future<AndroidApk> fromAndroidProject(AndroidProject androidProject, {
    @required AndroidSdk androidSdk,
    @required ProcessManager processManager,
    @required UserMessages userMessages,
    @required ProcessUtils processUtils,
    @required Logger logger,
    @required FileSystem fileSystem,
  }) async {
    File apkFile;

    if (androidProject.isUsingGradle && androidProject.isSupportedVersion) {
      apkFile = getApkDirectory(androidProject.parent).childFile('app.apk');
      if (apkFile.existsSync()) {
        // Grab information from the .apk. The gradle build script might alter
        // the application Id, so we need to look at what was actually built.
        return AndroidApk.fromApk(
          apkFile,
          androidSdk: androidSdk,
          processManager: processManager,
          logger: logger,
          userMessages: userMessages,
        );
      }
      // The .apk hasn't been built yet, so we work with what we have. The run
      // command will grab a new AndroidApk after building, to get the updated
      // IDs.
    } else {
      apkFile = fileSystem.file(fileSystem.path.join(getAndroidBuildDirectory(), 'app.apk'));
    }

    final File manifest = androidProject.appManifestFile;

    if (!manifest.existsSync()) {
      logger.printError('AndroidManifest.xml could not be found.');
      logger.printError('Please check ${manifest.path} for errors.');
      return null;
    }

    final String manifestString = manifest.readAsStringSync();
    XmlDocument document;
    try {
      document = XmlDocument.parse(manifestString);
    } on XmlParserException catch (exception) {
      String manifestLocation;
      if (androidProject.isUsingGradle) {
        manifestLocation = fileSystem.path.join(androidProject.hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml');
      } else {
        manifestLocation = fileSystem.path.join(androidProject.hostAppGradleRoot.path, 'AndroidManifest.xml');
      }
      logger.printError('AndroidManifest.xml is not a valid XML document.');
      logger.printError('Please check $manifestLocation for errors.');
      throwToolExit('XML Parser error message: ${exception.toString()}');
    }

    final Iterable<XmlElement> manifests = document.findElements('manifest');
    if (manifests.isEmpty) {
      logger.printError('AndroidManifest.xml has no manifest element.');
      logger.printError('Please check ${manifest.path} for errors.');
      return null;
    }
    final String packageId = manifests.first.getAttribute('package');

    String launchActivity;
    for (final XmlElement activity in document.findAllElements('activity')) {
      final String enabled = activity.getAttribute('android:enabled');
      if (enabled != null && enabled == 'false') {
        continue;
      }

      for (final XmlElement element in activity.findElements('intent-filter')) {
        String actionName = '';
        String categoryName = '';
        for (final XmlNode node in element.children) {
          if (node is! XmlElement) {
            continue;
          }
          final XmlElement xmlElement = node as XmlElement;
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
      logger.printError('package identifier or launch activity not found.');
      logger.printError('Please check ${manifest.path} for errors.');
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

/// Tests whether a [Directory] is an iOS bundle directory.
bool _isBundleDirectory(Directory dir) => dir.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({@required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing app bundle or IPA.
  factory IOSApp.fromPrebuiltApp(FileSystemEntity applicationBinary) {
    final FileSystemEntityType entityType = globals.fs.typeSync(applicationBinary.path);
    if (entityType == FileSystemEntityType.notFound) {
      globals.printError(
          'File "${applicationBinary.path}" does not exist. Use an app bundle or an ipa.');
      return null;
    }
    Directory bundleDir;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = globals.fs.directory(applicationBinary);
      if (!_isBundleDirectory(directory)) {
        globals.printError('Folder "${applicationBinary.path}" is not an app bundle.');
        return null;
      }
      bundleDir = globals.fs.directory(applicationBinary);
    } else {
      // Try to unpack as an ipa.
      final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_app.');
      shutdownHooks.addShutdownHook(() async {
        await tempDir.delete(recursive: true);
      }, ShutdownStage.STILL_RECORDING);
      globals.os.unzip(globals.fs.file(applicationBinary), tempDir);
      final Directory payloadDir = globals.fs.directory(
        globals.fs.path.join(tempDir.path, 'Payload'),
      );
      if (!payloadDir.existsSync()) {
        globals.printError(
            'Invalid prebuilt iOS ipa. Does not contain a "Payload" directory.');
        return null;
      }
      try {
        bundleDir = payloadDir.listSync().whereType<Directory>().singleWhere(_isBundleDirectory);
      } on StateError {
        globals.printError(
            'Invalid prebuilt iOS ipa. Does not contain a single app bundle.');
        return null;
      }
    }
    final String plistPath = globals.fs.path.join(bundleDir.path, 'Info.plist');
    if (!globals.fs.file(plistPath).existsSync()) {
      globals.printError('Invalid prebuilt iOS app. Does not contain Info.plist.');
      return null;
    }
    final String id = globals.plistParser.getValueFromFile(
      plistPath,
      PlistParser.kCFBundleIdentifierKey,
    );
    if (id == null) {
      globals.printError('Invalid prebuilt iOS app. Info.plist does not contain bundle identifier');
      return null;
    }

    return PrebuiltIOSApp(
      bundleDir: bundleDir,
      bundleName: globals.fs.path.basename(bundleDir.path),
      projectBundleId: id,
    );
  }

  static Future<IOSApp> fromIosProject(IosProject project, BuildInfo buildInfo) {
    if (!globals.platform.isMacOS) {
      return null;
    }
    if (!project.exists) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    if (!project.xcodeProject.existsSync()) {
      globals.printError('Expected ios/Runner.xcodeproj but this file is missing.');
      return null;
    }
    if (!project.xcodeProjectInfoFile.existsSync()) {
      globals.printError('Expected ios/Runner.xcodeproj/project.pbxproj but this file is missing.');
      return null;
    }
    return BuildableIOSApp.fromProject(project, buildInfo);
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;
}

class BuildableIOSApp extends IOSApp {
  BuildableIOSApp(this.project, String projectBundleId, String hostAppBundleName)
    : _hostAppBundleName = hostAppBundleName,
      super(projectBundleId: projectBundleId);

  static Future<BuildableIOSApp> fromProject(IosProject project, BuildInfo buildInfo) async {
    final String projectBundleId = await project.productBundleIdentifier(buildInfo);
    final String hostAppBundleName = await project.hostAppBundleName(buildInfo);
    return BuildableIOSApp(project, projectBundleId, hostAppBundleName);
  }

  final IosProject project;

  final String _hostAppBundleName;

  @override
  String get name => _hostAppBundleName;

  @override
  String get simulatorBundlePath => _buildAppPath('iphonesimulator');

  @override
  String get deviceBundlePath => _buildAppPath('iphoneos');

  // Xcode uses this path for the final archive bundle location,
  // not a top-level output directory.
  // Specifying `build/ios/archive/Runner` will result in `build/ios/archive/Runner.xcarchive`.
  String get archiveBundlePath
    => globals.fs.path.join(getIosBuildDirectory(), 'archive', globals.fs.path.withoutExtension(_hostAppBundleName));

  // The output xcarchive bundle path `build/ios/archive/Runner.xcarchive`.
  String get archiveBundleOutputPath =>
      globals.fs.path.setExtension(archiveBundlePath, '.xcarchive');

  String get ipaOutputPath =>
      globals.fs.path.join(getIosBuildDirectory(), 'ipa');

  String _buildAppPath(String type) {
    return globals.fs.path.join(getIosBuildDirectory(), type, _hostAppBundleName);
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
    return children.whereType<_Attribute>().firstWhere(
        (_Attribute e) => e.key.startsWith(name),
        orElse: () => null,
    );
  }

  _Element firstElement(String name) {
    return children.whereType<_Element>().firstWhere(
        (_Element e) => e.name.startsWith(name),
        orElse: () => null,
    );
  }

  Iterable<_Element> allElements(String name) {
    return children.whereType<_Element>().where((_Element e) => e.name.startsWith(name));
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

  static bool isAttributeWithValuePresent(_Element baseElement,
      String childElement, String attributeName, String attributeValue) {
    final Iterable<_Element> allElements = baseElement.allElements(childElement);
    for (final _Element oneElement in allElements) {
      final String elementAttributeValue = oneElement
          ?.firstAttribute(attributeName)
          ?.value;
      if (elementAttributeValue != null &&
          elementAttributeValue.startsWith(attributeValue)) {
        return true;
      }
    }
    return false;
  }

  static ApkManifestData parseFromXmlDump(String data, Logger logger) {
    if (data == null || data.trim().isEmpty) {
      return null;
    }

    final List<String> lines = data.split('\n');
    assert(lines.length > 3);

    final int manifestLine = lines.indexWhere((String line) => line.contains('E: manifest'));
    final _Element manifest = _Element.fromLine(lines[manifestLine], null);
    _Element currentElement = manifest;

    for (final String line in lines.skip(manifestLine)) {
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
    if (application == null) {
      return null;
    }

    final Iterable<_Element> activities = application.allElements('activity');

    _Element launchActivity;
    for (final _Element activity in activities) {
      final _Attribute enabled = activity.firstAttribute('android:enabled');
      final Iterable<_Element> intentFilters = activity.allElements('intent-filter');
      final bool isEnabledByDefault = enabled == null;
      final bool isExplicitlyEnabled = enabled != null && enabled.value.contains('0xffffffff');
      if (!(isEnabledByDefault || isExplicitlyEnabled)) {
        continue;
      }

      for (final _Element element in intentFilters) {
        final bool isMainAction = isAttributeWithValuePresent(
            element, 'action', 'android:name', '"android.intent.action.MAIN"');
        if (!isMainAction) {
          continue;
        }
        final bool isLauncherCategory = isAttributeWithValuePresent(
            element, 'category', 'android:name',
            '"android.intent.category.LAUNCHER"');
        if (!isLauncherCategory) {
          continue;
        }
        launchActivity = activity;
        break;
      }
      if (launchActivity != null) {
        break;
      }
    }

    final _Attribute package = manifest.firstAttribute('package');
    // "io.flutter.examples.hello_world" (Raw: "io.flutter.examples.hello_world")
    final String packageName = package.value.substring(1, package.value.indexOf('" '));

    if (launchActivity == null) {
      logger.printError('Error running $packageName. Default activity not found');
      return null;
    }

    final _Attribute nameAttribute = launchActivity.firstAttribute('android:name');
    // "io.flutter.examples.hello_world.MainActivity" (Raw: "io.flutter.examples.hello_world.MainActivity")
    final String activityName = nameAttribute
        .value.substring(1, nameAttribute.value.indexOf('" '));

    // Example format: (type 0x10)0x1
    final _Attribute versionCodeAttr = manifest.firstAttribute('android:versionCode');
    if (versionCodeAttr == null) {
      logger.printError('Error running $packageName. Manifest versionCode not found');
      return null;
    }
    if (!versionCodeAttr.value.startsWith('(type 0x10)')) {
      logger.printError('Error running $packageName. Manifest versionCode invalid');
      return null;
    }
    final int versionCode = int.tryParse(versionCodeAttr.value.substring(11));
    if (versionCode == null) {
      logger.printError('Error running $packageName. Manifest versionCode invalid');
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
