// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/gradle_utils.dart';
import '../artifacts.dart';
import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/template.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/tool_context.dart';
import '../custom_devices/custom_devices_config.dart';
import '../features.dart';
import '../git.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../macos/xcode.dart';
import '../persistent_tool_state.dart';
import '../pre_run_validator.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../runner/local_engine.dart';
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
    required Artifacts artifacts,
    required Cache cache,
    required FileSystem fileSystem,
    required FlutterVersion flutterVersion,
    required BuildSystem buildSystem,
    required OperatingSystemUtils osUtils,
    required Logger logger,
    required AndroidSdk? androidSdk,
    required Config config,
    required Platform platform,
    required ProcessUtils processUtils,
    required ProcessManager processManager,
    required FileSystemUtils fileSystemUtils,
    required TemplateRenderer templateRenderer,
    required Terminal terminal,
    required PlistParser plistParser,
    required Xcode? xcode,
    AndroidBuilder? androidBuilder,
    AndroidContext? androidContext,
    ToolContext? toolContext,
    bool verboseHelp = false,
  }) {
    final persistentToolState = PersistentToolState(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
    );
    final ToolContext effectiveToolContext =
        toolContext ??
        ToolContext(
          artifacts: artifacts,
          botDetector: BotDetector(
            httpClientFactory: () => HttpClient(),
            persistentToolState: persistentToolState,
            platform: platform,
          ),
          cache: cache,
          config: config,
          customDevicesConfig: CustomDevicesConfig(
            fileSystem: fileSystem,
            logger: logger,
            platform: platform,
          ),
          flutterVersion: flutterVersion,
          fs: fileSystem,
          git: Git(currentPlatform: platform, runProcessWith: processUtils),
          localEngineLocator: LocalEngineLocator(
            fileSystem: fileSystem,
            flutterRoot: Cache.flutterRoot ?? '',
            logger: logger,
            platform: platform,
            userMessages: UserMessages(),
          ),
          logger: logger,
          os: osUtils,
          outputPreferences: OutputPreferences.test(),
          platform: platform,
          preRunValidator: PreRunValidator(fileSystem: fileSystem),
          processManager: processManager,
          processUtils: processUtils,
          projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
          shutdownHooks: ShutdownHooks(),
          signals: LocalSignals.instance,
          stdio: Stdio(),
          systemClock: const SystemClock(),
          terminal: terminal is AnsiTerminal
              ? terminal
              : AnsiTerminal(stdio: Stdio(), platform: platform),
          userMessages: UserMessages(),
        );
    final AndroidContext effectiveAndroidContext =
        androidContext ??
        AndroidContext(
          androidSdk: androidSdk,
          androidStudio: null,
          gradleUtils: GradleUtils(
            cache: cache,
            logger: logger,
            operatingSystemUtils: osUtils,
            platform: platform,
          ),
          java: null,
        );
    _addSubcommand(
      BuildAarCommand(
        androidBuilder: androidBuilder,
        androidContext: effectiveAndroidContext,
        androidSdk: androidSdk,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildApkCommand(
        androidBuilder: androidBuilder,
        androidContext: effectiveAndroidContext,
        androidSdk: androidSdk,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildAppBundleCommand(
        androidBuilder: androidBuilder,
        androidContext: effectiveAndroidContext,
        androidSdk: androidSdk,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
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
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildLinuxCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
  }

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
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required this.logger,
    required bool verboseHelp,
    super.analytics,
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
