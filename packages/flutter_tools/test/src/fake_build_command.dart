// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/context.dart';
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
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
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
  Artifacts? artifacts,
  BuildSystem? buildSystem,
  Cache? cache,
  Config? config,
  FeatureFlags? featureFlags,
  FileSystem? fileSystem,
  FileSystemUtils? fileSystemUtils,
  FlutterVersion? flutterVersion,
  Logger? logger,
  OperatingSystemUtils? osUtils,
  Platform? platform,
  PlistParser? plistParser,
  ProcessManager? processManager,
  ProcessUtils? processUtils,
  TemplateRenderer? templateRenderer,
  AnsiTerminal? terminal,
  ToolContext? toolContext,
  bool verboseHelp = false,
  Xcode? xcode,
  XcodeProjectInterpreter? xcodeProjectInterpreter,
}) {
  var effectiveFileSystem = fileSystem;
  if (effectiveFileSystem == null) {
    try {
      effectiveFileSystem = context.get<FileSystem>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }
  final FileSystem fs = effectiveFileSystem ?? MemoryFileSystem.test();

  var effectivePlatform = platform;
  if (effectivePlatform == null) {
    try {
      effectivePlatform = context.get<Platform>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }
  final Platform resolvedPlatform = effectivePlatform ?? FakePlatform();

  var effectiveFeatureFlags = featureFlags;
  if (effectiveFeatureFlags == null) {
    try {
      effectiveFeatureFlags = context.get<FeatureFlags>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }

  var effectiveLogger = logger;
  if (effectiveLogger == null) {
    try {
      effectiveLogger = context.get<Logger>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }
  final Logger resolvedLogger = effectiveLogger ?? BufferLogger.test();

  var effectiveProcessManager = processManager;
  if (effectiveProcessManager == null) {
    try {
      effectiveProcessManager = context.get<ProcessManager>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }
  final ProcessManager resolvedProcessManager = effectiveProcessManager ?? FakeProcessManager.any();

  var effectiveOsUtils = osUtils;
  if (effectiveOsUtils == null) {
    try {
      effectiveOsUtils = context.get<OperatingSystemUtils>();
    } on Object {
      // testWithoutContext or not provided.
    }
  }
  final OperatingSystemUtils resolvedOsUtils = effectiveOsUtils ?? FakeOperatingSystemUtils();

  final command = BuildCommand(
    androidContext: FakeAndroidContext(androidSdk: androidSdk),
    appleContext: FakeAppleContext(
      plistParser: plistParser ?? FakePlistParser(),
      xcode: xcode ?? FakeXcode(),
      xcodeProjectInterpreter: xcodeProjectInterpreter,
    ),
    buildSystem: buildSystem ?? FakeBuildSystem(),
    featureFlags: effectiveFeatureFlags ?? TestFeatureFlags(),
    templateRenderer: templateRenderer ?? FakeTemplateRenderer(),
    toolContext:
        toolContext ??
        FakeToolContext(
          artifacts: artifacts ?? FakeArtifacts(),
          cache: cache ?? FakeCache(),
          config: config ?? FakeConfig(),
          fs: fs,
          flutterVersion: flutterVersion ?? FakeFlutterVersion(),
          logger: resolvedLogger,
          os: resolvedOsUtils,
          platform: resolvedPlatform,
          processManager: resolvedProcessManager,
          processUtils:
              processUtils ??
              ProcessUtils(processManager: resolvedProcessManager, logger: resolvedLogger),
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
