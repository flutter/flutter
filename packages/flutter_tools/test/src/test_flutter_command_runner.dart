// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
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

import 'context.dart';
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
  final ToolContext resolvedToolContext = toolContext ?? DelegatingToolContext(fs: temp.fileSystem);
  final Pub resolvedPub =
      TestFlutterCommandRunner._defaultFromContext<Pub>() ?? Pub(toolContext: resolvedToolContext);
  final command = CreateCommand(
    androidContext: FakeAndroidContext(),
    appleContext: FakeAppleContext(),
    pub: resolvedPub,
    templatePathProvider: _DeferredTestTemplatePathProvider(resolvedToolContext),
    templateRenderer: const MustacheTemplateRenderer(),
    toolContext: resolvedToolContext,
  );
  final CommandRunner<void> runner = createTestCommandRunner(
    command,
    null,
    resolvedToolContext,
    null,
    resolvedPub,
  );
  await runner.run(<String>['create', ...arguments, projectPath]);
  return projectPath;
}

class TestFlutterCommandRunner extends FlutterCommandRunner {
  TestFlutterCommandRunner({
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
    super.verboseHelp,
  }) : super(
         analytics: analytics ?? _defaultFromContext<Analytics>() ?? const NoOpAnalytics(),
         androidContext:
             androidContext ??
             FakeAndroidContext(gradleUtils: gradleUtils ?? _defaultFromContext<GradleUtils>()),
         applicationPackageFactory:
             applicationPackageFactory ??
             _defaultFromContext<ApplicationPackageFactory>() ??
             FlutterApplicationPackageFactory(
               androidSdkBuilder: () => _defaultFromContext<AndroidSdk>(),
               plistParserBuilder: () => _defaultFromContext<PlistParser>() ?? FakePlistParser(),
               templatePathProvider: _DeferredTestTemplatePathProvider(
                 toolContext ?? const DelegatingToolContext(),
               ),
               toolContext: toolContext ?? const DelegatingToolContext(),
             ),
         cocoaPods: cocoaPods ?? _defaultFromContext<CocoaPods>() ?? FakeCocoaPods(),
         deviceManager:
             deviceManager ?? _defaultFromContext<DeviceManager>() ?? FakeDeviceManager(),
         devtoolsLauncher:
             devtoolsLauncher ?? _defaultFromContext<DevtoolsLauncher>() ?? FakeDevtoolsLauncher(),
         doctor: doctor ?? _defaultFromContext<Doctor>() ?? FakeDoctor(),
         extensionManager: extensionManager ?? FakeExtensionManager(),
         featureFlags: featureFlags ?? _defaultFromContext<FeatureFlags>() ?? TestFeatureFlags(),
         plistParser: plistParser ?? _defaultFromContext<PlistParser>() ?? FakePlistParser(),
         pub: pub ?? _defaultFromContext<Pub>() ?? const ThrowingPub(),
         templatePathProvider:
             templatePathProvider ??
             _defaultFromContext<TemplatePathProvider>() ??
             _DeferredTestTemplatePathProvider(toolContext ?? const DelegatingToolContext()),
         templateRenderer:
             templateRenderer ??
             _defaultFromContext<TemplateRenderer>() ??
             const MustacheTemplateRenderer(),
         toolContext: toolContext ?? const DelegatingToolContext(),
       );

  static T? _defaultFromContext<T>() {
    if (Zone.current[contextKey] case final AppContext appContext
        when appContext.runtimeType == AppContext) {
      return appContext.get<T>();
    }
    return null;
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    final ToolContext(:Cache cache, :FileSystem fs, :Logger logger, :ProcessInfo processInfo) =
        toolContext;
    final contextOverrides = <Type, Object?>{
      if (topLevelResults['verbose'] as bool) Logger: VerboseLogger(logger),
      ProcessInfo: processInfo,
    };
    return context.run<void>(
      overrides: contextOverrides.map<Type, Generator>((Type type, Object? value) {
        return MapEntry<Type, Generator>(type, () => value);
      }),
      body: () {
        // For compatibility with tests that set this to a relative path.
        cache.flutterRoot = fs.path.normalize(fs.path.absolute(cache.flutterRoot));
        return super.runCommand(topLevelResults);
      },
    );
  }

  @override
  void printUsage() {
    toolContext.logger.printStatus(usage);
  }
}

// TODO(bkonyi): Remove once remaining command tests stop constructing
// createTestCommandRunner with DelegatingToolContext inside setUp() outside
// testUsingContext. https://github.com/flutter/flutter/issues/47161.
final class _DeferredTestTemplatePathProvider implements TemplatePathProvider {
  const _DeferredTestTemplatePathProvider(this._toolContext);

  final ToolContext _toolContext;

  TemplatePathProvider _resolveDelegate() =>
      TestFlutterCommandRunner._defaultFromContext<TemplatePathProvider>() ??
      TemplatePathProvider(flutterRoot: _toolContext.cache.flutterRoot);

  @override
  Directory directoryInPackage(String name, FileSystem fileSystem) =>
      _resolveDelegate().directoryInPackage(name, fileSystem);

  @override
  Future<Directory> imageDirectory(String? name, FileSystem fileSystem, Logger logger) =>
      _resolveDelegate().imageDirectory(name, fileSystem, logger);
}
