// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'android/android_sdk.dart';
import 'android/application_package.dart';
import 'application_package.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/process.dart';
import 'base/user_messages.dart';
import 'build_info.dart';
import 'context/tool_context.dart';
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
    required this._plistParser,
    required this._toolContext,
  });

  final AndroidSdk? _androidSdk;
  final PlistParser _plistParser;
  final ToolContext _toolContext;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    final ToolContext(
      :FileSystem fs,
      :Logger logger,
      :ProcessManager processManager,
      :ProcessUtils processUtils,
      :UserMessages userMessages,
    ) = _toolContext;
    switch (platform.os) {
      case .android:
        if (applicationBinary == null) {
          return AndroidApk.fromAndroidProject(
            FlutterProject.current().android,
            processManager: processManager,
            processUtils: processUtils,
            logger: logger,
            androidSdk: _androidSdk,
            userMessages: userMessages,
            fileSystem: fs,
            buildInfo: buildInfo,
          );
        }
        return AndroidApk.fromApk(
          applicationBinary,
          processManager: processManager,
          logger: logger,
          androidSdk: _androidSdk!,
          userMessages: userMessages,
          processUtils: processUtils,
        );
      case .ios:
        return applicationBinary == null
            ? await IOSApp.fromIosProject(
                FlutterProject.current().ios,
                buildInfo,
                toolContext: _toolContext,
              )
            : IOSApp.fromPrebuiltApp(
                applicationBinary,
                plistParser: _plistParser,
                toolContext: _toolContext,
              );
      case .tester:
        return FlutterTesterApp.fromCurrentDirectory(fs);
      case .macos:
        return applicationBinary == null
            ? MacOSApp.fromMacOSProject(
                FlutterProject.current().macos,
                plistParser: _plistParser,
                toolContext: _toolContext,
              )
            : MacOSApp.fromPrebuiltApp(
                applicationBinary,
                plistParser: _plistParser,
                toolContext: _toolContext,
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
            : WindowsApp.fromPrebuiltApp(applicationBinary, toolContext: _toolContext);
      case .fuchsia || .unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }
}
