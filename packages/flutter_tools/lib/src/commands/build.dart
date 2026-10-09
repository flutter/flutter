// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../android/android_builder.dart';
import '../android/gradle.dart';
import '../artifacts.dart';
import '../base/common.dart' show throwToolExit;
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../experimental/extension_build_manager.dart';
import '../features.dart';
import '../macos/xcode.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import '../windows/visual_studio.dart';
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
    required FeatureFlags featureFlags,
    required TemplateRenderer templateRenderer,
    required ToolContext toolContext,
    AndroidBuilder? androidBuilder,
    this._extensionBuildManager,
    bool verboseHelp = false,
  }) : _appleContext = appleContext,
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
    final Xcode xcode = appleContext.xcode;

    final codesign = DarwinAddToAppCodesigning.fromContexts(
      appleContext: appleContext,
      toolContext: toolContext,
    );
    final AndroidBuilder effectiveAndroidBuilder =
        androidBuilder ??
        AndroidGradleBuilder.fromContexts(
          analytics: analytics,
          androidContext: androidContext,
          toolContext: toolContext,
        );
    _addSubcommand(
      BuildAarCommand(
        androidBuilder: effectiveAndroidBuilder,
        androidContext: androidContext,
        buildSystem: buildSystem,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildApkCommand(
        androidBuilder: effectiveAndroidBuilder,
        androidContext: androidContext,
        buildSystem: buildSystem,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildAppBundleCommand(
        androidBuilder: effectiveAndroidBuilder,
        androidContext: androidContext,
        buildSystem: buildSystem,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSFrameworkCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        codesign: codesign,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        codesign: codesign,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        analytics: analytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        codesign: codesign,
        featureFlags: featureFlags,
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
      BuildIOSArchiveCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildBundleCommand(
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWebCommand(
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacosCommand(
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildLinuxCommand(
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWindowsCommand(
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
        visualStudio: VisualStudio(
          fileSystem: fileSystem,
          platform: platform,
          logger: logger,
          processManager: processManager,
          osUtils: osUtils,
        ),
      ),
    );
  }

  final ExtensionBuildManager? _extensionBuildManager;

  @override
  Future<void> initializeDynamicOptions() async {
    if (_extensionBuildManager case final extensionBuildManager?) {
      final List<ExtensionBuildTarget> targets = await extensionBuildManager.getBuildTargets();
      for (final target in targets) {
        if (!subcommands.containsKey(target.name)) {
          _addSubcommand(
            ExtensionBuildSubCommand(
              buildManager: extensionBuildManager,
              target: target,
              toolContext: toolContext,
              verboseHelp: verboseHelp,
            ),
          );
        } else {
          toolContext.logger.printWarning(
            'Skipping custom build target "${target.name}" because a subcommand with that name already exists.',
          );
        }
      }
    }
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final String name = 'build';

  @override
  final String description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();

  final AppleContext _appleContext;

  /// The Apple-specific context dependencies, exposed for hermetic testing.
  @visibleForTesting
  AppleContext get appleContext => _appleContext;
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required this.logger,
    required super.verboseHelp,
    super.outputPreferences,
    super.toolContext,
  }) {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}

/// A dynamically registered `flutter build` subcommand backed by a tool extension.
class ExtensionBuildSubCommand extends BuildSubCommand {
  ExtensionBuildSubCommand({
    required this._buildManager,
    required this.target,
    required ToolContext toolContext,
    required super.verboseHelp,
  }) : super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
       ) {
    usesTargetOption();
    usesPubOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
  }

  final ExtensionBuildManager _buildManager;

  /// The custom build target definition provided by the tool extension.
  final ExtensionBuildTarget target;

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  String get name => target.name;

  @override
  String get description => target.description;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();

    final ExtensionBuildResult result = await _buildManager.build(
      buildMode: buildInfo.mode,
      mainPath: targetFile,
      projectRoot: toolContext.fs.currentDirectory.uri,
      targetName: target.name,
    );

    if (result.success) {
      return FlutterCommandResult.success();
    } else {
      final String? errorMessage = result.errorMessage;
      throwToolExit(
        errorMessage != null && errorMessage.isNotEmpty
            ? 'Build failed: $errorMessage'
            : 'Build failed.',
      );
    }
  }
}
