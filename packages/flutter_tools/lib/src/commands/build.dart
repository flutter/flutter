// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../macos/xcode.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'build_aar.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_linux.dart';
import 'build_macos.dart';
import 'build_macos_framework.dart';
import 'build_swift_package.dart';
import 'build_web.dart';
import 'build_windows.dart';
import 'darwin_add_to_app.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({
    required AndroidContext androidContext,
    required AppleContext appleContext,
    required BuildSystem buildSystem,
    required TemplateRenderer templateRenderer,
    required ToolContext toolContext,
    bool verboseHelp = false,
    FeatureFlags? featureFlags,
  }) : _toolContext = toolContext,
       super(toolContext: toolContext, verboseHelp: verboseHelp) {
    final ToolContext(
      :Artifacts artifacts,
      :Cache cache,
      :FlutterVersion flutterVersion,
      fs: FileSystem fileSystem,
      :Logger logger,
      os: OperatingSystemUtils osUtils,
      :Platform platform,
      :ProcessManager processManager,
    ) = toolContext;
    final AppleContext(:Xcode? xcode) = appleContext;
    final AndroidContext(:AndroidSdk? androidSdk) = androidContext;

    final codesign = DarwinAddToAppCodesigning.fromContexts(
      appleContext: appleContext,
      toolContext: toolContext,
    );

    FeatureFlags? contextFeatureFlags;
    try {
      contextFeatureFlags = context.get<FeatureFlags>();
    } on UnsupportedError {
      // In testWithoutContext, context.get is not supported.
    }
    Analytics effectiveAnalytics;
    try {
      effectiveAnalytics = analytics;
    } on UnsupportedError {
      effectiveAnalytics = const NoOpAnalytics();
    }
    final FeatureFlags? effectiveFeatureFlags = featureFlags ?? contextFeatureFlags;

    _addSubcommand(
      BuildAarCommand(
        androidSdk: androidSdk,
        fileSystem: fileSystem,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildApkCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildIOSFrameworkCommand(
        buildSystem: buildSystem,
        codesign: codesign,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        buildSystem: buildSystem,
        codesign: codesign,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildIOSArchiveCommand(logger: logger, verboseHelp: verboseHelp));
    if (effectiveFeatureFlags != null) {
      _addSubcommand(
        BuildSwiftPackage(
          analytics: effectiveAnalytics,
          artifacts: artifacts,
          buildSystem: buildSystem,
          cache: cache,
          codesign: codesign,
          featureFlags: effectiveFeatureFlags,
          fileSystem: fileSystem,
          flutterVersion: flutterVersion,
          logger: logger,
          platform: platform,
          processManager: processManager,
          templateRenderer: templateRenderer,
          verboseHelp: verboseHelp,
          xcode: xcode,
        ),
      );
      _addSubcommand(
        BuildBundleCommand(
          buildSystem: buildSystem,
          featureFlags: effectiveFeatureFlags,
          toolContext: _toolContext,
          verboseHelp: verboseHelp,
        ),
      );
      _addSubcommand(
        BuildWebCommand(
          buildSystem: buildSystem,
          featureFlags: effectiveFeatureFlags,
          toolContext: _toolContext,
          verboseHelp: verboseHelp,
        ),
      );
    }
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildLinuxCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
  }

  final ToolContext _toolContext;

  void _addSubcommand(BuildSubCommand command) {
    bool isSupported;
    try {
      isSupported = command.supported;
    } on UnsupportedError {
      isSupported = true;
    }
    if (isSupported) {
      addSubcommand(command);
    }
  }

  @override
  final String name = 'build';

  @override
  final String description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required this.logger,
    required super.verboseHelp,
    super.outputPreferences,
    super.toolContext,
  }) : super() {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}
