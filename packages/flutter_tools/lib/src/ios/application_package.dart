// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../template.dart';
import '../xcode_project.dart';
import 'plist_parser.dart';
import 'xcodeproj.dart';

/// Tests whether a [Directory] is an iOS bundle directory.
bool _isBundleDirectory(Directory dir) => dir.path.endsWith('.app');

abstract class IOSApp extends ApplicationPackage {
  IOSApp({required String projectBundleId}) : super(id: projectBundleId);

  /// Creates a new IOSApp from an existing app bundle or IPA.
  static IOSApp? fromPrebuiltApp(
    FileSystemEntity applicationBinary, {
    required FileSystem fileSystem,
    required Logger logger,
    required OperatingSystemUtils operatingSystemUtils,
    required PlistParser plistParser,
  }) {
    final FileSystemEntityType entityType = fileSystem.typeSync(applicationBinary.path);
    if (entityType == FileSystemEntityType.notFound) {
      logger.printError(
        'File "${applicationBinary.path}" does not exist. Use an app bundle or an ipa.',
      );
      return null;
    }
    Directory uncompressedBundle;
    if (entityType == FileSystemEntityType.directory) {
      final Directory directory = fileSystem.directory(applicationBinary);
      if (!_isBundleDirectory(directory)) {
        logger.printError('Folder "${applicationBinary.path}" is not an app bundle.');
        return null;
      }
      uncompressedBundle = fileSystem.directory(applicationBinary);
    } else {
      // Try to unpack as an ipa.
      final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_app.');
      operatingSystemUtils.unzip(fileSystem.file(applicationBinary), tempDir);
      final Directory payloadDir = fileSystem.directory(
        fileSystem.path.join(tempDir.path, 'Payload'),
      );
      if (!payloadDir.existsSync()) {
        logger.printError('Invalid prebuilt iOS ipa. Does not contain a "Payload" directory.');
        return null;
      }
      try {
        uncompressedBundle = payloadDir.listSync().whereType<Directory>().singleWhere(
          _isBundleDirectory,
        );
      } on StateError {
        logger.printError('Invalid prebuilt iOS ipa. Does not contain a single app bundle.');
        return null;
      }
    }
    final String plistPath = fileSystem.path.join(uncompressedBundle.path, 'Info.plist');
    if (!fileSystem.file(plistPath).existsSync()) {
      logger.printError('Invalid prebuilt iOS app. Does not contain Info.plist.');
      return null;
    }
    final String? id = plistParser.getValueFromFile<String>(
      plistPath,
      PlistParser.kCFBundleIdentifierKey,
    );
    if (id == null) {
      logger.printError('Invalid prebuilt iOS app. Info.plist does not contain bundle identifier');
      return null;
    }

    return PrebuiltIOSApp(
      uncompressedBundle: uncompressedBundle,
      bundleName: fileSystem.path.basename(uncompressedBundle.path),
      projectBundleId: id,
      applicationPackage: applicationBinary,
    );
  }

  static Future<IOSApp?> fromIosProject(
    IosProject project,
    BuildInfo? buildInfo, {
    required FileSystem fileSystem,
    required Logger logger,
    required Platform platform,
  }) async {
    if (!platform.isMacOS) {
      return null;
    }
    if (!project.exists) {
      // If the project doesn't exist at all the current hint to run flutter
      // create is accurate.
      return null;
    }
    if (!project.xcodeProject.existsSync()) {
      logger.printError('Expected ios/Runner.xcodeproj but this file is missing.');
      return null;
    }
    if (!project.xcodeProjectInfoFile.existsSync()) {
      logger.printError('Expected ios/Runner.xcodeproj/project.pbxproj but this file is missing.');
      return null;
    }
    return BuildableIOSApp.fromProject(project, buildInfo, fileSystem: fileSystem, logger: logger);
  }

  @override
  String get displayName => id;

  String get simulatorBundlePath;

  String get deviceBundlePath;

  /// Directory used by ios-deploy to store incremental installation metadata for
  /// faster second installs.
  Directory? get appDeltaDirectory;
}

class BuildableIOSApp extends IOSApp {
  BuildableIOSApp(
    this.project,
    String projectBundleId,
    String? productName, {
    required this._fileSystem,
    required this._logger,
  }) : _appProductName = productName,
       super(projectBundleId: projectBundleId);

  static Future<BuildableIOSApp?> fromProject(
    IosProject project,
    BuildInfo? buildInfo, {
    required FileSystem fileSystem,
    required Logger logger,
  }) async {
    final String? productName = await project.productName(buildInfo);
    final String? projectBundleId = await project.productBundleIdentifier(buildInfo);
    if (projectBundleId != null) {
      return BuildableIOSApp(
        project,
        projectBundleId,
        productName,
        fileSystem: fileSystem,
        logger: logger,
      );
    }
    return null;
  }

  final IosProject project;
  final FileSystem _fileSystem;
  final Logger _logger;

  final String? _appProductName;

  @override
  String? get name => _appProductName;

  @override
  String get simulatorBundlePath => _buildAppPath(XcodeSdk.IPhoneSimulator.platformName);

  @override
  String get deviceBundlePath => _buildAppPath(XcodeSdk.IPhoneOS.platformName);

  @override
  Directory get appDeltaDirectory =>
      _fileSystem.directory(_fileSystem.path.join(getIosBuildDirectory(), 'app-delta'));

  // Xcode uses this path for the final archive bundle location,
  // not a top-level output directory.
  // Specifying `build/ios/archive/Runner` will result in `build/ios/archive/Runner.xcarchive`.
  String get archiveBundlePath =>
      _fileSystem.path.join(getIosBuildDirectory(), 'archive', _appProductName ?? 'Runner');

  // The output xcarchive bundle path `build/ios/archive/Runner.xcarchive`.
  String get archiveBundleOutputPath => '$archiveBundlePath.xcarchive';

  String get builtInfoPlistPathAfterArchive => _fileSystem.path.join(
    archiveBundleOutputPath,
    'Products',
    'Applications',
    _appProductName != null ? '$_appProductName.app' : 'Runner.app',
    'Info.plist',
  );

  String get projectAppIconDirName => _projectImageAssetDirName(_appIconAsset);

  String get projectLaunchImageDirName => _projectImageAssetDirName(_launchImageAsset);

  String get templateAppIconDirNameForContentsJson =>
      _templateImageAssetDirNameForContentsJson(_appIconAsset);

  String get templateLaunchImageDirNameForContentsJson =>
      _templateImageAssetDirNameForContentsJson(_launchImageAsset);

  Future<String> get templateAppIconDirNameForImages async =>
      _templateImageAssetDirNameForImages(_appIconAsset);

  Future<String> get templateLaunchImageDirNameForImages async =>
      _templateImageAssetDirNameForImages(_launchImageAsset);

  String get ipaOutputPath => _fileSystem.path.join(getIosBuildDirectory(), 'ipa');

  String _buildAppPath(String type) {
    return _fileSystem.path.join(getIosBuildDirectory(), type, '$_appProductName.app');
  }

  String _projectImageAssetDirName(String asset) =>
      _fileSystem.path.join('ios', 'Runner', 'Assets.xcassets', asset);

  // Template asset's Contents.json file is in flutter_tools, but the actual
  String _templateImageAssetDirNameForContentsJson(String asset) => _fileSystem.path.join(
    Cache.flutterRoot!,
    'packages',
    'flutter_tools',
    'templates',
    _templateImageAssetDirNameSuffix(asset),
  );

  // Template asset's images are in flutter_template_images package.
  Future<String> _templateImageAssetDirNameForImages(String asset) async {
    final Directory imageTemplate = await templatePathProvider.imageDirectory(
      null,
      _fileSystem,
      _logger,
    );
    return _fileSystem.path.join(imageTemplate.path, _templateImageAssetDirNameSuffix(asset));
  }

  String _templateImageAssetDirNameSuffix(String asset) =>
      _fileSystem.path.join('app', 'ios.tmpl', 'Runner', 'Assets.xcassets', asset);

  String get _appIconAsset => 'AppIcon.appiconset';
  String get _launchImageAsset => 'LaunchImage.imageset';
}

class PrebuiltIOSApp extends IOSApp implements PrebuiltApplicationPackage {
  PrebuiltIOSApp({
    required this.uncompressedBundle,
    this.bundleName,
    required super.projectBundleId,
    required this.applicationPackage,
  });

  /// The uncompressed bundle of the application.
  ///
  /// [IOSApp.fromPrebuiltApp] will uncompress the application into a temporary
  /// directory even when an `.ipa` file was used to create the [IOSApp] instance.
  final Directory uncompressedBundle;
  final String? bundleName;

  @override
  final Directory? appDeltaDirectory = null;

  @override
  String? get name => bundleName;

  @override
  String get simulatorBundlePath => _bundlePath;

  @override
  String get deviceBundlePath => _bundlePath;

  String get _bundlePath => uncompressedBundle.path;

  /// A [File] or [Directory] pointing to the application bundle.
  ///
  /// This can be either an `.ipa` file or an uncompressed `.app` directory.
  @override
  final FileSystemEntity applicationPackage;
}
