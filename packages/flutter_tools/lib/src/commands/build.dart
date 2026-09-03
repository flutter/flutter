// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/template.dart';
import '../base/terminal.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
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
    required AndroidSdk? androidSdk,
    required Artifacts artifacts,
    required BuildSystem buildSystem,
    required Cache cache,
    required Config config,
    required FeatureFlags featureFlags,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required FlutterVersion flutterVersion,
    required Logger logger,
    // ignore: avoid_unused_constructor_parameters
    required OperatingSystemUtils osUtils,
    required Platform platform,
    required PlistParser plistParser,
    required ProcessManager processManager,
    required ProcessUtils processUtils,
    required TemplateRenderer templateRenderer,
    required Terminal terminal,
    required super.toolContext,
    required Xcode? xcode,
    super.outputPreferences,
    super.verboseHelp,
  }) : super() {
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
    _addSubcommand(BuildIOSCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildIOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        logger: logger,
        analytics: analytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        platform: platform,
        processManager: processManager,
        templateRenderer: templateRenderer,
        xcode: xcode,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        verboseHelp: verboseHelp,
      ),
    );

    _addSubcommand(BuildIOSArchiveCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: fileSystem, logger: logger, verboseHelp: verboseHelp),
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

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final name = 'build';

  @override
  final description = 'Build an executable app or install bundle.';

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
  }) {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}
