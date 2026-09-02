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
  }) : _androidContext = androidContext,
       _appleContext = appleContext,
       _buildSystem = buildSystem,
       _templateRenderer = templateRenderer,
       _toolContext = toolContext,
       super(verboseHelp: verboseHelp) {
    
    _addSubcommand(
      BuildAarCommand(
        fileSystem: _toolContext.fs,
        androidSdk: _androidContext.androidSdk,
        logger: _toolContext.logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildApkCommand(logger: _toolContext.logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: _toolContext.logger, verboseHelp: verboseHelp));
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
          logger: _toolContext.logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: _toolContext.config,
            fileSystem: _toolContext.fs,
            fileSystemUtils: _toolContext.fileSystemUtils,
            logger: _toolContext.logger,
            platform: _toolContext.platform,
            plistParser: _appleContext.plistParser,
            processUtils: _toolContext.processUtils,
            terminal: _toolContext.terminal,
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
          logger: _toolContext.logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: _toolContext.config,
            fileSystem: _toolContext.fs,
            fileSystemUtils: _toolContext.fileSystemUtils,
            logger: _toolContext.logger,
            platform: _toolContext.platform,
            plistParser: _appleContext.plistParser,
            processUtils: _toolContext.processUtils,
            terminal: _toolContext.terminal,
          ),
        ),
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        analytics: analytics,
        artifacts: _toolContext.artifacts,
        buildSystem: _buildSystem,
        cache: _toolContext.cache,
        codesign: DarwinAddToAppCodesigning(
          logger: _toolContext.logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: _toolContext.config,
            fileSystem: _toolContext.fs,
            fileSystemUtils: _toolContext.fileSystemUtils,
            logger: _toolContext.logger,
            platform: _toolContext.platform,
            plistParser: _appleContext.plistParser,
            processUtils: _toolContext.processUtils,
            terminal: _toolContext.terminal,
          ),
        ),
        featureFlags: featureFlags,
        fileSystem: _toolContext.fs,
        flutterVersion: _toolContext.flutterVersion,
        logger: _toolContext.logger,
        platform: _toolContext.platform,
        processManager: _toolContext.processManager,
        templateRenderer: _templateRenderer,
        verboseHelp: verboseHelp,
        xcode: _appleContext.xcode,
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
    _addSubcommand(BuildBundleCommand(logger: _toolContext.logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: _toolContext.fs, logger: _toolContext.logger, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildMacosCommand(
        buildSystem: _buildSystem,
        toolContext: _toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildLinuxCommand(logger: _toolContext.logger, operatingSystemUtils: _toolContext.os, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: _toolContext.logger, operatingSystemUtils: _toolContext.os, verboseHelp: verboseHelp),
    );
  }


  final AndroidContext _androidContext;
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
