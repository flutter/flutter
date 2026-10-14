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
import 'linux/application_package.dart';
import 'macos/application_package.dart';
import 'project.dart';
import 'tester/flutter_tester.dart';
import 'web/web_device.dart';
import 'windows/application_package.dart';

/// A package factory that supports all Flutter target platforms.
class FlutterApplicationPackageFactory extends ApplicationPackageFactory {
  FlutterApplicationPackageFactory({required this._androidSdk, required this._toolContext});

  final AndroidSdk? _androidSdk;
  final ToolContext _toolContext;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    final ToolContext(
      fs: FileSystem fileSystem,
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
            androidSdk: _androidSdk,
            buildInfo: buildInfo,
            toolContext: _toolContext,
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
            ? await IOSApp.fromIosProject(FlutterProject.current().ios, buildInfo)
            : IOSApp.fromPrebuiltApp(applicationBinary);
      case .tester:
        return FlutterTesterApp.fromCurrentDirectory(fileSystem);
      case .macos:
        return applicationBinary == null
            ? MacOSApp.fromMacOSProject(FlutterProject.current().macos)
            : MacOSApp.fromPrebuiltApp(applicationBinary);
      case .web:
        if (!FlutterProject.current().web.existsSync()) {
          return null;
        }
        return WebApplicationPackage(FlutterProject.current());
      case .linux:
        return applicationBinary == null
            ? LinuxApp.fromLinuxProject(FlutterProject.current().linux, toolContext: _toolContext)
            : LinuxApp.fromPrebuiltApp(applicationBinary);
      case .windows:
        return applicationBinary == null
            ? WindowsApp.fromWindowsProject(FlutterProject.current().windows)
            : WindowsApp.fromPrebuiltApp(applicationBinary);
      case .fuchsia || .unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }
}
