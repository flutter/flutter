// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import 'fake_process_manager.dart';
import 'fakes.dart';

BuildCommand createFakeBuildCommand({
  AndroidSdk? androidSdk,
  ApplicationPackageFactory? applicationPackageFactory,
  BuildSystem? buildSystem,
  FileSystem? fileSystem,
  Logger? logger,
  OperatingSystemUtils? osUtils,
  Config? config,
  Platform? platform,
  FileSystemUtils? fileSystemUtils,
  AnsiTerminal? terminal,
  PlistParser? plistParser,
  ProcessUtils? processUtils,
  ProcessManager? processManager,
  TemplateRenderer? templateRenderer,
  Xcode? xcode,
  XcodeProjectInterpreter? xcodeProjectInterpreter,
  Artifacts? artifacts,
  Cache? cache,
  FlutterVersion? flutterVersion,
  bool verboseHelp = false,
}) {
  final FileSystem fs = fileSystem ?? MemoryFileSystem.test();
  final Platform effectivePlatform = platform ?? FakePlatform();
  final command = BuildCommand(
    androidContext: FakeAndroidContext(androidSdk: androidSdk),
    appleContext: FakeAppleContext(
      plistParser: plistParser ?? FakePlistParser(),
      xcode: xcode ?? FakeXcode(),
      xcodeProjectInterpreter: xcodeProjectInterpreter,
    ),
    buildSystem: buildSystem ?? FakeBuildSystem(),
    templateRenderer: templateRenderer ?? FakeTemplateRenderer(),
    toolContext: FakeToolContext(
      artifacts: artifacts ?? FakeArtifacts(),
      cache: cache ?? FakeCache(),
      config: config ?? FakeConfig(),
      fs: fs,
      flutterVersion: flutterVersion ?? FakeFlutterVersion(),
      logger: logger ?? BufferLogger.test(),
      os: osUtils ?? FakeOperatingSystemUtils(),
      platform: effectivePlatform,
      processManager: processManager ?? FakeProcessManager.any(),
      processUtils:
          processUtils ??
          ProcessUtils(
            processManager: processManager ?? FakeProcessManager.any(),
            logger: logger ?? BufferLogger.test(),
          ),
      terminal: terminal ?? FakeTerminal(),
    ),
    verboseHelp: verboseHelp,
  );
  final ApplicationPackageFactory packageFactory =
      applicationPackageFactory ?? FakeIOSApplicationPackageFactory(fileSystem: fs);
  command.applicationPackages = packageFactory;
  for (final Command<void> subcommand in command.subcommands.values) {
    if (subcommand is FlutterCommand) {
      subcommand.applicationPackages = packageFactory;
    }
  }
  return command;
}

class FakeIOSApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeIOSApplicationPackageFactory({required this.fileSystem});

  final FileSystem fileSystem;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    if (platform != TargetPlatform.ios) {
      return null;
    }
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    if (!project.ios.exists) {
      return null;
    }
    return BuildableIOSApp(project.ios, 'com.example.test', 'Runner');
  }
}
