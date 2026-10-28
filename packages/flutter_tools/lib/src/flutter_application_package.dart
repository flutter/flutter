// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android/android_sdk.dart';
import 'android/application_package.dart';
import 'application_package.dart';
import 'base/file_system.dart';
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
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = _toolContext;
    switch (platform.os) {
      case .android:
        if (applicationBinary == null) {
          return AndroidApk.fromAndroidProject(
            projectFactory.fromDirectory(fs.currentDirectory).android,
            androidSdk: _androidSdk,
            buildInfo: buildInfo,
            toolContext: _toolContext,
          );
        }
        return AndroidApk.fromApk(
          applicationBinary,
          androidSdk: _androidSdk!,
          toolContext: _toolContext,
        );
      case .ios:
        return applicationBinary == null
            ? await IOSApp.fromIosProject(
                projectFactory.fromDirectory(fs.currentDirectory).ios,
                buildInfo,
                toolContext: _toolContext,
              )
            : IOSApp.fromPrebuiltApp(applicationBinary);
      case .tester:
        return FlutterTesterApp.fromCurrentDirectory(fs);
      case .macos:
        return applicationBinary == null
            ? MacOSApp.fromMacOSProject(
                projectFactory.fromDirectory(fs.currentDirectory).macos,
                toolContext: _toolContext,
              )
            : MacOSApp.fromPrebuiltApp(applicationBinary);
      case .web:
        final FlutterProject project = projectFactory.fromDirectory(fs.currentDirectory);
        if (!project.web.existsSync()) {
          return null;
        }
        return WebApplicationPackage(project);
      case .linux:
        return applicationBinary == null
            ? LinuxApp.fromLinuxProject(
                projectFactory.fromDirectory(fs.currentDirectory).linux,
                toolContext: _toolContext,
              )
            : LinuxApp.fromPrebuiltApp(applicationBinary);
      case .windows:
        return applicationBinary == null
            ? WindowsApp.fromWindowsProject(
                projectFactory.fromDirectory(fs.currentDirectory).windows,
                toolContext: _toolContext,
              )
            : WindowsApp.fromPrebuiltApp(applicationBinary);
      case .fuchsia || .unsupported:
        TargetPlatform.throwUnsupportedTarget();
    }
  }
}
