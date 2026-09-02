// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/context.dart';
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
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../custom_devices/custom_devices_config.dart';
import '../features.dart';
import '../git.dart';
import '../ios/code_signing.dart';
import '../ios/ios_workflow.dart';
import '../ios/iproxy.dart';
import '../ios/plist_parser.dart';
import '../ios/simulators.dart';
import '../ios/xcodeproj.dart';
import '../macos/cocoapods.dart';
import '../macos/cocoapods_validator.dart';
import '../macos/xcdevice.dart';
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
    required AndroidSdk? androidSdk,
    required Artifacts artifacts,
    required BuildSystem buildSystem,
    required Cache cache,
    required Config config,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required FlutterVersion flutterVersion,
    required Logger logger,
    required OperatingSystemUtils osUtils,
    required Platform platform,
    required PlistParser plistParser,
    required ProcessManager processManager,
    required TemplateRenderer templateRenderer,
    required Terminal terminal,
    required Xcode? xcode,
    AppleContext? appleContext,
    OutputPreferences? outputPreferences,
    PreRunValidator? preRunValidator,
    ProcessUtils? processUtils,
    ToolContext? toolContext,
    bool verboseHelp = false,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
  }) : super(outputPreferences: outputPreferences, toolContext: toolContext) {
    final Analytics effectiveAnalytics = context.get<Analytics>() ?? analytics;
    final Platform effectivePlatform = context.get<Platform>() ?? platform;
    final PersistentToolState persistentToolState =
        context.get<PersistentToolState>() ??
        PersistentToolState(fileSystem: fileSystem, logger: logger, platform: effectivePlatform);
    final ProcessUtils effectiveProcessUtils =
        processUtils ?? ProcessUtils(processManager: processManager, logger: logger);
    final OutputPreferences effectiveOutputPreferences =
        outputPreferences ?? (context.get<OutputPreferences>() ?? OutputPreferences.test());
    final ToolContext effectiveToolContext =
        toolContext ??
        ToolContext(
          artifacts: artifacts,
          botDetector: BotDetector(
            httpClientFactory: () => HttpClient(),
            persistentToolState: persistentToolState,
            platform: effectivePlatform,
          ),
          cache: cache,
          config: config,
          customDevicesConfig: CustomDevicesConfig(
            fileSystem: fileSystem,
            logger: logger,
            platform: effectivePlatform,
          ),
          flutterVersion: flutterVersion,
          fs: fileSystem,
          git: Git(currentPlatform: effectivePlatform, runProcessWith: effectiveProcessUtils),
          localEngineLocator: LocalEngineLocator(
            fileSystem: fileSystem,
            flutterRoot: Cache.flutterRoot ?? '',
            logger: logger,
            platform: effectivePlatform,
            userMessages: UserMessages(),
          ),
          logger: logger,
          os: osUtils,
          outputPreferences: effectiveOutputPreferences,
          persistentToolState: persistentToolState,
          platform: effectivePlatform,
          preRunValidator:
              preRunValidator ??
              (context.get<PreRunValidator>() ??
                  (!fileSystem
                          .directory(
                            fileSystem.path.join(
                              Cache.flutterRoot ?? '',
                              'packages',
                              'flutter_tools',
                            ),
                          )
                          .existsSync()
                      ? _NoopPreRunValidator()
                      : PreRunValidator(fileSystem: fileSystem))),
          processInfo: ProcessInfo(fileSystem),
          processManager: processManager,
          processUtils: effectiveProcessUtils,
          projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
          shutdownHooks: ShutdownHooks(),
          signals: LocalSignals.instance,
          stdio: Stdio(),
          systemClock: const SystemClock(),
          terminal: terminal is AnsiTerminal
              ? terminal
              : AnsiTerminal(stdio: Stdio(), platform: effectivePlatform),
          userMessages: UserMessages(),
        );
    final XcodeProjectInterpreter effectiveXcodeProjectInterpreter =
        xcodeProjectInterpreter ??
        XcodeProjectInterpreter(
          analytics: effectiveAnalytics,
          fileSystem: fileSystem,
          logger: logger,
          platform: effectivePlatform,
          processManager: processManager,
        );
    final effectiveCocoaPods = CocoaPods(
      analytics: effectiveAnalytics,
      fileSystem: fileSystem,
      logger: logger,
      platform: effectivePlatform,
      processManager: processManager,
      xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
    );
    final Xcode effectiveXcode =
        xcode ??
        Xcode(
          fileSystem: fileSystem,
          logger: logger,
          platform: effectivePlatform,
          processManager: processManager,
          userMessages: UserMessages(),
          xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
        );
    final AppleContext effectiveAppleContext =
        appleContext ??
        AppleContext(
          cocoaPods: effectiveCocoaPods,
          cocoapodsValidator: CocoaPodsValidator(effectiveCocoaPods, UserMessages()),
          iosSimulatorUtils: IOSSimulatorUtils(
            logger: logger,
            operatingSystemUtils: osUtils,
            processManager: processManager,
            xcode: effectiveXcode,
          ),
          iosWorkflow: IOSWorkflow(
            featureFlags: featureFlags,
            platform: effectivePlatform,
            xcode: effectiveXcode,
          ),
          plistParser: context.get<PlistParser>() ?? plistParser,
          xcdevice: XCDevice(
            analytics: effectiveAnalytics,
            artifacts: artifacts,
            cache: cache,
            fileSystem: fileSystem,
            iproxy: IProxy(
              artifacts: artifacts,
              dyLdLibEntry: cache.dyLdLibEntry,
              logger: logger,
              processManager: processManager,
            ),
            logger: logger,
            platform: effectivePlatform,
            processManager: processManager,
            shutdownHooks: ShutdownHooks(),
            xcode: effectiveXcode,
          ),
          xcode: effectiveXcode,
          xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
        );
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
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSFrameworkCommand(
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: effectivePlatform,
            plistParser: plistParser,
            processUtils: effectiveProcessUtils,
            terminal: terminal,
          ),
        ),
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: effectivePlatform,
            plistParser: plistParser,
            processUtils: effectiveProcessUtils,
            terminal: terminal,
          ),
        ),
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        analytics: effectiveAnalytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: effectivePlatform,
            plistParser: plistParser,
            processUtils: effectiveProcessUtils,
            terminal: terminal,
          ),
        ),
        featureFlags: featureFlags,
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        logger: logger,
        platform: effectivePlatform,
        processManager: processManager,
        templateRenderer: templateRenderer,
        verboseHelp: verboseHelp,
        xcode: effectiveXcode,
      ),
    );

    _addSubcommand(
      BuildIOSArchiveCommand(
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: fileSystem, logger: logger, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildMacosCommand(
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
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

class _NoopPreRunValidator implements PreRunValidator {
  @override
  void validate() {}
}
