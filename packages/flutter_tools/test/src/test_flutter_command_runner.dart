// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/template.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/context/android_context.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/flutter_application_package.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'fakes.dart';
import 'throwing_pub.dart';

export 'package:test/test.dart' hide isInstanceOf, test;

CommandRunner<void> createTestCommandRunner([
  FlutterCommand? command,
  Analytics? analytics,
  ToolContext? toolContext,
  FeatureFlags? featureFlags,
  Pub? pub,
  ApplicationPackageFactory? applicationPackageFactory,
]) {
  final ToolContext? resolvedToolContext = toolContext ?? command?.toolContext;
  final runner = TestFlutterCommandRunner(
    analytics: analytics,
    applicationPackageFactory: applicationPackageFactory,
    featureFlags: featureFlags,
    pub: pub,
    toolContext: resolvedToolContext,
  );
  if (command != null) {
    runner.addCommand(command);
  }
  return runner;
}

/// Creates a flutter project in the [temp] directory using the
/// [arguments] list if specified, or `--no-pub` if not.
/// Returns the path to the flutter project.
Future<String> createProject(
  Directory temp, {
  String name = 'flutter_project',
  List<String>? arguments,
  ToolContext? toolContext,
}) async {
  arguments ??= <String>['--no-pub'];
  final String projectPath = temp.fileSystem.path.join(temp.path, name);
  final ToolContext resolvedToolContext = toolContext ?? FakeToolContext(fs: temp.fileSystem);
  final FeatureFlags resolvedFeatureFlags = TestFeatureFlags();
  final resolvedPub = Pub(featureFlags: resolvedFeatureFlags, toolContext: resolvedToolContext);
  final command = CreateCommand(
    androidContext: FakeAndroidContext(),
    appleContext: FakeAppleContext(),
    featureFlags: resolvedFeatureFlags,
    pub: resolvedPub,
    templatePathProvider: TemplatePathProvider(flutterRoot: resolvedToolContext.cache.flutterRoot),
    templateRenderer: const MustacheTemplateRenderer(),
    toolContext: resolvedToolContext,
  );
  final CommandRunner<void> runner = createTestCommandRunner(
    command,
    null,
    resolvedToolContext,
    resolvedFeatureFlags,
    resolvedPub,
  );
  await runner.run(<String>['create', ...arguments, projectPath]);
  return projectPath;
}

class TestFlutterCommandRunner extends FlutterCommandRunner {
  factory TestFlutterCommandRunner({
    Analytics? analytics,
    AndroidContext? androidContext,
    ApplicationPackageFactory? applicationPackageFactory,
    CocoaPods? cocoaPods,
    DeviceManager? deviceManager,
    DevtoolsLauncher? devtoolsLauncher,
    Doctor? doctor,
    ExtensionManager? extensionManager,
    FeatureFlags? featureFlags,
    GradleUtils? gradleUtils,
    PlistParser? plistParser,
    Pub? pub,
    TemplatePathProvider? templatePathProvider,
    TemplateRenderer? templateRenderer,
    ToolContext? toolContext,
    bool verboseHelp = false,
  }) {
    final ToolContext resolvedToolContext = toolContext ?? FakeToolContext();
    final PlistParser resolvedPlistParser = plistParser ?? FakePlistParser();
    final TemplatePathProvider resolvedTemplatePathProvider =
        templatePathProvider ??
        TemplatePathProvider(flutterRoot: resolvedToolContext.cache.flutterRoot);
    return TestFlutterCommandRunner._(
      analytics: analytics ?? const NoOpAnalytics(),
      androidContext: androidContext ?? FakeAndroidContext(gradleUtils: gradleUtils),
      applicationPackageFactory:
          applicationPackageFactory ??
          FlutterApplicationPackageFactory(
            androidSdkBuilder: () => null,
            plistParserBuilder: () => resolvedPlistParser,
            templatePathProvider: resolvedTemplatePathProvider,
            toolContext: resolvedToolContext,
          ),
      cocoaPods: cocoaPods ?? FakeCocoaPods(),
      deviceManager: deviceManager ?? FakeDeviceManager(),
      devtoolsLauncher: devtoolsLauncher ?? FakeDevtoolsLauncher(),
      doctor: doctor ?? FakeDoctor(),
      extensionManager: extensionManager ?? FakeExtensionManager(),
      featureFlags: featureFlags ?? TestFeatureFlags(),
      plistParser: resolvedPlistParser,
      pub: pub ?? const ThrowingPub(),
      templatePathProvider: resolvedTemplatePathProvider,
      templateRenderer: templateRenderer ?? const MustacheTemplateRenderer(),
      toolContext: resolvedToolContext,
      verboseHelp: verboseHelp,
    );
  }

  TestFlutterCommandRunner._({
    required super.analytics,
    required super.androidContext,
    required super.applicationPackageFactory,
    required super.cocoaPods,
    required super.deviceManager,
    required super.devtoolsLauncher,
    required super.doctor,
    required super.extensionManager,
    required super.featureFlags,
    required super.plistParser,
    required super.pub,
    required super.templatePathProvider,
    required super.templateRenderer,
    required super.toolContext,
    super.verboseHelp,
  });

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final ToolContext(:Cache cache, :FileSystem fs) = toolContext;
    // For compatibility with tests that set this to a relative path.
    cache.flutterRoot = fs.path.normalize(fs.path.absolute(cache.flutterRoot));
    return super.runCommand(topLevelResults);
  }

  @override
  void printUsage() {
    toolContext.logger.printStatus(usage);
  }
}
