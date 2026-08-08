// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/gradle_utils.dart';
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
import '../context/android_context.dart';
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
    ProcessUtils? processUtils,
    required ProcessManager processManager,
    required FileSystemUtils fileSystemUtils,
    required TemplateRenderer templateRenderer,
    required Terminal terminal,
    required PlistParser plistParser,
    required Xcode? xcode,
    Analytics? analytics,
    XcodeProjectInterpreter? xcodeProjectInterpreter,
    AndroidBuilder? androidBuilder,
    AndroidContext? androidContext,
    AppleContext? appleContext,
    FeatureFlags? featureFlags,
    OutputPreferences? outputPreferences,
    PreRunValidator? preRunValidator,
    ToolContext? toolContext,
    bool verboseHelp = false,
  }) : super(analytics: analytics, outputPreferences: outputPreferences, toolContext: toolContext) {
    Analytics? contextAnalytics;
    FeatureFlags? contextFeatureFlags;
    Platform? contextPlatform;
    OutputPreferences? contextOutputPreferences;
    PreRunValidator? contextPreRunValidator;
    XcodeProjectInterpreter? contextXcodeProjectInterpreter;
    PlistParser? contextPlistParser;
    try {
      contextAnalytics = context.get<Analytics>();
      contextFeatureFlags = context.get<FeatureFlags>();
      contextPlatform = context.get<Platform>();
      contextOutputPreferences = context.get<OutputPreferences>();
      contextPreRunValidator = context.get<PreRunValidator>();
      contextXcodeProjectInterpreter = context.get<XcodeProjectInterpreter>();
      contextPlistParser = context.get<PlistParser>();
    } on UnsupportedError {
      // In testWithoutContext, context.get is not supported.
    }
    final Analytics effectiveAnalytics = analytics ?? (contextAnalytics ?? const NoOpAnalytics());
    final FeatureFlags effectiveFeatureFlags =
        featureFlags ?? (contextFeatureFlags ?? const _DefaultFeatureFlags());
    final Platform effectivePlatform =
        (platform.isMacOS || contextPlatform == null || !contextPlatform.isMacOS)
        ? platform
        : contextPlatform;
    final persistentToolState = PersistentToolState.test(
      directory: fileSystem.directory('.tmp_state')..createSync(recursive: true),
      logger: logger,
    );

    final ProcessUtils effectiveProcessUtils =
        processUtils ?? ProcessUtils(processManager: processManager, logger: logger);
    final OutputPreferences effectiveOutputPreferences =
        outputPreferences ?? (contextOutputPreferences ?? OutputPreferences.test());
    final ToolContext effectiveToolContext =
        toolContext ??
        (_fallbackToolContext = ToolContext(
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
          platform: effectivePlatform,
          preRunValidator:
              preRunValidator ??
              (contextPreRunValidator ??
                  (!fileSystem.directory(Cache.flutterRoot ?? '').existsSync()
                      ? _NoopPreRunValidator()
                      : PreRunValidator(fileSystem: fileSystem))),
          processManager: processManager,
          processUtils: effectiveProcessUtils,
          projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
          shutdownHooks: ShutdownHooks(),
          signals: LocalSignals.instance,
          stdio: Stdio(),
          systemClock: const SystemClock(),
          terminal: terminal is AnsiTerminal
              ? terminal
              : AnsiTerminal(stdio: Stdio(), platform: platform),
          userMessages: UserMessages(),
        ));

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
    final XcodeProjectInterpreter effectiveXcodeProjectInterpreter =
        xcodeProjectInterpreter ??
        (contextXcodeProjectInterpreter ??
            XcodeProjectInterpreter(
              platform: platform,
              processManager: processManager,
              logger: logger,
              fileSystem: fileSystem,
              analytics: effectiveAnalytics,
            ));
    final AppleContext effectiveAppleContext =
        appleContext ??
        AppleContext(
          cocoaPods: CocoaPods(
            fileSystem: fileSystem,
            processManager: processManager,
            logger: logger,
            platform: platform,
            xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
            analytics: effectiveAnalytics,
          ),
          cocoapodsValidator: CocoaPodsValidator(
            CocoaPods(
              fileSystem: fileSystem,
              processManager: processManager,
              logger: logger,
              platform: platform,
              xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
              analytics: effectiveAnalytics,
            ),
            UserMessages(),
          ),
          iosSimulatorUtils: IOSSimulatorUtils(
            logger: logger,
            operatingSystemUtils: osUtils,
            processManager: processManager,
            xcode:
                xcode ??
                Xcode(
                  platform: platform,
                  processManager: processManager,
                  logger: logger,
                  fileSystem: fileSystem,
                  xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
                  userMessages: UserMessages(),
                ),
          ),
          iosWorkflow: IOSWorkflow(
            featureFlags: effectiveFeatureFlags,
            xcode:
                xcode ??
                Xcode(
                  platform: platform,
                  processManager: processManager,
                  logger: logger,
                  fileSystem: fileSystem,
                  xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
                  userMessages: UserMessages(),
                ),
            platform: platform,
          ),
          plistParser: contextPlistParser ?? plistParser,
          xcdevice: XCDevice(
            processManager: processManager,
            logger: logger,
            artifacts: artifacts,
            cache: cache,
            platform: platform,
            xcode:
                xcode ??
                Xcode(
                  platform: platform,
                  processManager: processManager,
                  logger: logger,
                  fileSystem: fileSystem,
                  xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
                  userMessages: UserMessages(),
                ),
            iproxy: IProxy(
              iproxyPath: artifacts.getHostArtifact(HostArtifact.iproxy).path,
              logger: logger,
              processManager: processManager,
              dyLdLibEntry: cache.dyLdLibEntry,
            ),
            fileSystem: fileSystem,
            analytics: effectiveAnalytics,
            shutdownHooks: ShutdownHooks(),
          ),
          xcode:
              xcode ??
              Xcode(
                platform: platform,
                processManager: processManager,
                logger: logger,
                fileSystem: fileSystem,
                xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
                userMessages: UserMessages(),
              ),
          xcodeProjectInterpreter: effectiveXcodeProjectInterpreter,
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
    _addSubcommand(
      BuildIOSCommand(
        analytics: effectiveAnalytics,
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSFrameworkCommand(
        analytics: effectiveAnalytics,
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: effectiveProcessUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        analytics: effectiveAnalytics,
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: effectiveProcessUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        logger: logger,
        analytics: effectiveAnalytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        featureFlags: effectiveFeatureFlags,
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
            processUtils: effectiveProcessUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        verboseHelp: verboseHelp,
      ),
    );

    _addSubcommand(
      BuildIOSArchiveCommand(
        analytics: effectiveAnalytics,
        appleContext: effectiveAppleContext,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildBundleCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWebCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacosCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildLinuxCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWindowsCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  ToolContext? _fallbackToolContext;

  @override
  ToolContext? get toolContext => super.toolContext ?? _fallbackToolContext;

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

class _NoopPreRunValidator implements PreRunValidator {
  @override
  void validate() {}
}

class _DefaultFeatureFlags implements FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool get isLinuxEnabled => true;

  @override
  bool get isWindowsEnabled => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
