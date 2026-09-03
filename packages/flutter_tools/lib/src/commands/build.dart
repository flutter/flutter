// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/logger.dart';
import '../base/template.dart';
import '../build_system/build_system.dart';
import '../context/android_context.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../ios/code_signing.dart';
import '../runner/flutter_command.dart';
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
  }) : _appleContext = appleContext,
       _buildSystem = buildSystem,
       _templateRenderer = templateRenderer,
       _toolContext = toolContext,
       super(toolContext: toolContext, verboseHelp: verboseHelp) {
    // ignore: omit_obvious_local_variable_types
    final ToolContext(
      :artifacts,
      :cache,
      :config,
      fileSystemUtils: fsUtils,
      :flutterVersion,
      fs: fileSystem,
      :logger,
      os: osUtils,
      :platform,
      :processManager,
      :processUtils,
      :terminal,
    ) = toolContext;
    // ignore: omit_obvious_local_variable_types
    final AppleContext(:plistParser, :xcode) = appleContext;
    // ignore: omit_obvious_local_variable_types
    final AndroidContext(:androidSdk) = androidContext;

    _addSubcommand(
      BuildAarCommand(
        fileSystem: fileSystem,
        androidSdk: androidSdk,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildApkCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildIOSCommand(
        appleContext: _appleContext,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSFrameworkCommand(
        appleContext: _appleContext,
        buildSystem: _buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fsUtils,
            logger: logger,
            platform: platform,
            plistParser: plistParser,
            processUtils: processUtils,
            terminal: terminal,
          ),
        ),
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        appleContext: _appleContext,
        buildSystem: _buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fsUtils,
            logger: logger,
            platform: platform,
            plistParser: plistParser,
            processUtils: processUtils,
            terminal: terminal,
          ),
        ),
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        analytics: analytics,
        artifacts: artifacts,
        buildSystem: _buildSystem,
        cache: cache,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fsUtils,
            logger: logger,
            platform: platform,
            plistParser: plistParser,
            processUtils: processUtils,
            terminal: terminal,
          ),
        ),
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        logger: logger,
        platform: platform,
        processManager: processManager,
        templateRenderer: _templateRenderer,
        verboseHelp: verboseHelp,
        xcode: xcode,
      ),
    );

    _addSubcommand(
      BuildIOSArchiveCommand(
        appleContext: _appleContext,
        buildSystem: _buildSystem,
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: fileSystem, logger: logger, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildMacosCommand(
        buildSystem: _buildSystem,
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildLinuxCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
  }

  final AppleContext _appleContext;
  final BuildSystem _buildSystem;
  final TemplateRenderer _templateRenderer;
  final ToolContext _toolContext;

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  final name = 'build';

  @override
  final description = 'Build an executable app or install bundle.';

  @override
  final category = FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required this.logger,
    required bool verboseHelp,
    super.outputPreferences,
    super.toolContext,
  }) : super(verboseHelp: verboseHelp) {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}
