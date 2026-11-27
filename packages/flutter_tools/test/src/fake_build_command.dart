// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_builder.dart';
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
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/application_package.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import 'android_common.dart';
import 'fake_process_manager.dart';
import 'fakes.dart';

BuildCommand createFakeBuildCommand({
  AndroidBuilder? androidBuilder,
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
  TemplatePathProvider? templatePathProvider,
  TemplateRenderer? templateRenderer,
  AnsiTerminal? terminal,
  ToolContext? toolContext,
  bool verboseHelp = false,
  Xcode? xcode,
  XcodeProjectInterpreter? xcodeProjectInterpreter,
}) {
  final FileSystem fs = fileSystem ?? MemoryFileSystem.test();
  final Platform targetPlatform = platform ?? FakePlatform();
  final Logger targetLogger = logger ?? BufferLogger.test();
  final ProcessManager targetProcessManager = processManager ?? FakeProcessManager.any();
  final OperatingSystemUtils targetOsUtils = osUtils ?? FakeOperatingSystemUtils();
  final FeatureFlags targetFeatureFlags = featureFlags ?? TestFeatureFlags();
  final appleCtx = FakeAppleContext(
    plistParser: plistParser ?? FakePlistParser(),
    xcode: xcode ?? FakeXcode(),
    xcodeProjectInterpreter: xcodeProjectInterpreter,
  );
  final Cache targetCache = cache ?? FakeCache();
  final TemplatePathProvider targetTemplatePathProvider =
      templatePathProvider ?? TemplatePathProvider(flutterRoot: targetCache.flutterRoot);
  final ToolContext targetToolContext =
      toolContext ??
      FakeToolContext(
        artifacts: artifacts ?? FakeArtifacts(),
        cache: targetCache,
        config: config ?? FakeConfig(),
        fs: fs,
        flutterVersion: flutterVersion ?? FakeFlutterVersion(),
        logger: targetLogger,
        os: targetOsUtils,
        platform: targetPlatform,
        processManager: targetProcessManager,
        processUtils:
            processUtils ??
            ProcessUtils(processManager: targetProcessManager, logger: targetLogger),
        projectFactory: FlutterProjectFactory(
          config: config ?? FakeConfig(),
          featureFlags: targetFeatureFlags,
          fileSystem: fs,
          logger: targetLogger,
          plistParser: appleCtx.plistParser,
          xcode: appleCtx.xcode,
          xcodeProjectInterpreter: appleCtx.xcodeProjectInterpreter,
        ),
        terminal: terminal ?? FakeTerminal(),
      );
  final command = BuildCommand(
    androidBuilder: androidBuilder ?? FakeAndroidBuilder(),
    androidContext: FakeAndroidContext(androidSdk: androidSdk),
    appleContext: appleCtx,
    buildSystem: buildSystem ?? FakeBuildSystem(),
    featureFlags: targetFeatureFlags,
    templatePathProvider: targetTemplatePathProvider,
    templateRenderer: templateRenderer ?? FakeTemplateRenderer(),
    toolContext: targetToolContext,
    verboseHelp: verboseHelp,
  );
  final ApplicationPackageFactory packageFactory =
      applicationPackageFactory ??
      FakeIOSApplicationPackageFactory(
        templatePathProvider: targetTemplatePathProvider,
        toolContext: targetToolContext,
      );
  command.applicationPackages = packageFactory;
  for (final Command<void> subcommand in command.subcommands.values) {
    if (subcommand is FlutterCommand) {
      subcommand.applicationPackages = packageFactory;
    }
  }
  return command;
}

class FakeIOSApplicationPackageFactory extends Fake implements ApplicationPackageFactory {
  FakeIOSApplicationPackageFactory({required this.templatePathProvider, required this.toolContext});

  final TemplatePathProvider templatePathProvider;
  final ToolContext toolContext;

  @override
  Future<ApplicationPackage?> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo? buildInfo,
    File? applicationBinary,
  }) async {
    if (platform != TargetPlatform.ios) {
      return null;
    }
    final ToolContext(:FileSystem fs, :FlutterProjectFactory projectFactory) = toolContext;
    final FlutterProject project = projectFactory.fromDirectory(fs.currentDirectory);
    if (!project.ios.exists) {
      return null;
    }
    return BuildableIOSApp(
      project.ios,
      'com.example.test',
      'Runner',
      templatePathProvider: templatePathProvider,
      toolContext: toolContext,
    );
  }
}
