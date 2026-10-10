// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'android/android_sdk.dart';
import 'android/application_package.dart';
import 'application_package.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'base/process.dart';
import 'base/user_messages.dart';
import 'build_info.dart';
import 'ios/application_package.dart';
import 'ios/plist_parser.dart';
import 'linux/application_package.dart';
import 'macos/application_package.dart';
import 'project.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/application_package.dart';

/// A package factory that supports all Flutter target platforms.
class FlutterApplicationPackageFactory extends ApplicationPackageFactory {
  FlutterApplicationPackageFactory({
    required this._androidSdk,
    required this._fileSystem,
    required this._logger,
    required this._operatingSystemUtils,
    required this._platform,
    required this._plistParser,
    required this._processManager,
    required this._userMessages,
  }) : _processUtils = ProcessUtils(processManager: _processManager, logger: _logger);

  final AndroidSdk? _androidSdk;
  final FileSystem _fileSystem;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final Platform _platform;
  final PlistParser _plistParser;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;
  final UserMessages _userMessages;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    switch (platform.os) {
      case .android:
        if (applicationBinary == null) {
          return AndroidApk.fromAndroidProject(
            FlutterProject.current().android,
            processManager: _processManager,
            processUtils: _processUtils,
            logger: _logger,
            androidSdk: _androidSdk,
            userMessages: _userMessages,
            fileSystem: _fileSystem,
            buildInfo: buildInfo,
          );
        }
        return AndroidApk.fromApk(
          applicationBinary,
          processManager: _processManager,
          logger: _logger,
          androidSdk: _androidSdk!,
          userMessages: _userMessages,
          processUtils: _processUtils,
        );
      case .ios:
        return applicationBinary == null
            ? await IOSApp.fromIosProject(
                FlutterProject.current().ios,
                buildInfo,
                fileSystem: _fileSystem,
                logger: _logger,
                platform: _platform,
              )
            : IOSApp.fromPrebuiltApp(
                applicationBinary,
                fileSystem: _fileSystem,
                logger: _logger,
                operatingSystemUtils: _operatingSystemUtils,
                plistParser: _plistParser,
              );
      case .tester:
        return FlutterTesterApp.fromCurrentDirectory(_fileSystem);
      case .macos:
        return applicationBinary == null
            ? MacOSApp.fromMacOSProject(
                FlutterProject.current().macos,
                fileSystem: _fileSystem,
                logger: _logger,
                operatingSystemUtils: _operatingSystemUtils,
                plistParser: _plistParser,
              )
            : MacOSApp.fromPrebuiltApp(
                applicationBinary,
                fileSystem: _fileSystem,
                logger: _logger,
                operatingSystemUtils: _operatingSystemUtils,
                plistParser: _plistParser,
              );
      case .web:
        if (!FlutterProject.current().web.existsSync()) {
          return null;
        }
        return WebApplicationPackage(FlutterProject.current());
      case .linux:
        return applicationBinary == null
            ? LinuxApp.fromLinuxProject(FlutterProject.current().linux)
            : LinuxApp.fromPrebuiltApp(applicationBinary);
      case .windows:
        return applicationBinary == null
            ? WindowsApp.fromWindowsProject(FlutterProject.current().windows)
            : WindowsApp.fromPrebuiltApp(
                applicationBinary,
                fileSystem: _fileSystem,
                logger: _logger,
                operatingSystemUtils: _operatingSystemUtils,
              );
      case .fuchsia || .unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }
}
