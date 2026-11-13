// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl_standalone.dart' as intl_standalone;
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'src/android/android_sdk.dart';
import 'src/android/android_studio.dart';
import 'src/android/android_workflow.dart';
import 'src/android/gradle_utils.dart';
import 'src/android/java.dart';
import 'src/artifacts.dart';
import 'src/base/async_guard.dart';
import 'src/base/bot_detector.dart';
import 'src/base/common.dart';
import 'src/base/config.dart';
import 'src/base/context.dart';
import 'src/base/error_handling_io.dart';
import 'src/base/exit.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/net.dart';
import 'src/base/os.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/signals.dart';
import 'src/base/template.dart';
import 'src/base/terminal.dart';
import 'src/base/time.dart';
import 'src/base/user_messages.dart';
import 'src/build_system/build_system.dart';
import 'src/build_system/build_targets.dart';
import 'src/cache.dart';
import 'src/context/android_context.dart';
import 'src/context/apple_context.dart';
import 'src/context/tool_context.dart';
import 'src/context/tool_dependencies.dart';
import 'src/context_runner.dart';
import 'src/custom_devices/custom_devices_config.dart';
import 'src/device.dart';
import 'src/doctor.dart';
import 'src/emulator.dart';
import 'src/experimental/extension_discovery.dart';
import 'src/experimental/extension_manager.dart';
import 'src/features.dart';
import 'src/git.dart';
import 'src/ios/ios_workflow.dart';
import 'src/ios/plist_parser.dart';
import 'src/ios/simulators.dart';
import 'src/ios/xcodeproj.dart';
import 'src/macos/cocoapods.dart';
import 'src/macos/cocoapods_validator.dart';
import 'src/macos/macos_workflow.dart';
import 'src/macos/xcdevice.dart';
import 'src/macos/xcode.dart';
import 'src/native_assets.dart';
import 'src/persistent_tool_state.dart';
import 'src/pre_run_validator.dart';
import 'src/project.dart';
import 'src/reporting/crash_reporting.dart';
import 'src/reporting/unified_analytics.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/runner/local_engine.dart';
import 'src/version.dart';
import 'src/windows/windows_workflow.dart';

/// Runs the Flutter tool with support for the specified list of [commands].
Future<int> run(
  List<String> args,
  List<FlutterCommand> Function(ToolDependencies toolDependencies) commands, {
  required ShutdownHooks shutdownHooks,
  BuildTargets? buildTargets,
  List<ExtensionEntryPoint> extensionEntryPoints = const <ExtensionEntryPoint>[],
  String? flutterVersion,
  bool muteCommandLogging = false,
  TestCompilerNativeAssetsBuilder? nativeAssetsBuilder,
  Map<Type, Generator>? overrides,
  PreRunValidator Function({required Cache cache, required FileSystem fileSystem})?
  preRunValidatorBuilder,
  bool? reportCrashes,
  TemplateRenderer? templateRenderer,
  bool verbose = false,
  bool verboseHelp = false,
}) async {
  if (muteCommandLogging) {
    // Remove the verbose option; for help and doctor, users don't need to see
    // verbose logs.
    args = List<String>.of(args);
    args.removeWhere((String option) => option == '-vv' || option == '-v' || option == '--verbose');
  }

  // Reset this on each run to ensure we don't leak state across tests.
  _alreadyHandlingToolError = null;

  final bool usingLocalEngine = args.any((a) => a.startsWith('--local-engine'));

  return runInContext<int>(() async {
    final Platform initialPlatform = context.resolveOverride<Platform>() ?? const LocalPlatform();
    final SystemClock initialSystemClock =
        context.resolveOverride<SystemClock>() ?? const SystemClock();
    final Stdio initialStdio = context.resolveOverride<Stdio>() ?? Stdio();
    final AnsiTerminal initialTerminal =
        context.resolveOverride<AnsiTerminal>() ??
        AnsiTerminal(
          stdio: initialStdio,
          platform: initialPlatform,
          now: initialSystemClock.now(),
          // So that we don't animate anything before calling applyFeatureFlags, default
          // the animations to disabled in real apps.
          defaultCliAnimationEnabled: false,
          shutdownHooks: shutdownHooks,
        );
    final OutputPreferences initialOutputPreferences =
        context.resolveOverride<OutputPreferences>() ??
        OutputPreferences(
          wrapText: initialStdio.hasTerminal,
          showColor: initialPlatform.stdoutSupportsAnsi,
          stdio: initialStdio,
        );
    return context.run<int>(
      overrides: <Type, Generator>{
        AnsiTerminal: () => initialTerminal,
        OutputPreferences: () => initialOutputPreferences,
        Platform: () => initialPlatform,
        ShutdownHooks: () => shutdownHooks,
        Stdio: () => initialStdio,
        SystemClock: () => initialSystemClock,
      },
      body: () async {
        final AppContext bootstrapContext = context;
        final TemplateRenderer? overriddenTemplateRenderer =
            templateRenderer ?? bootstrapContext.resolveOverride<TemplateRenderer>();
        if (overriddenTemplateRenderer == null) {
          throw StateError(
            'TemplateRenderer must be passed via templateRenderer or overridden in AppContext.',
          );
        }
        final DoctorValidatorsProvider? overriddenDoctorValidatorsProvider = bootstrapContext
            .resolveOverride<DoctorValidatorsProvider>();
        final HttpClientFactory? httpClientFactory = bootstrapContext
            .resolveOverride<HttpClientFactory>();
        final ToolDependencies toolDeps = await ToolDependencies.bootstrap(
          analytics: bootstrapContext.resolveOverride<Analytics>(),
          androidSdkBuilder: bootstrapContext.hasOverride(AndroidSdk)
              ? () => bootstrapContext.resolveOverride<AndroidSdk>()
              : null,
          androidStudioBuilder: bootstrapContext.hasOverride(AndroidStudio)
              ? () => bootstrapContext.resolveOverride<AndroidStudio>()
              : null,
          androidWorkflow: bootstrapContext.resolveOverride<AndroidWorkflow>(),
          artifacts: bootstrapContext.resolveOverride<Artifacts>(),
          botDetector: bootstrapContext.resolveOverride<BotDetector>(),
          buildSystem: bootstrapContext.resolveOverride<BuildSystem>(),
          buildTargets: buildTargets ?? bootstrapContext.resolveOverride<BuildTargets>(),
          cache: bootstrapContext.resolveOverride<Cache>(),
          cocoaPodsBuilder: bootstrapContext.hasOverride(CocoaPods)
              ? () => bootstrapContext.resolveOverride<CocoaPods>()
              : null,
          cocoapodsValidatorBuilder: bootstrapContext.hasOverride(CocoaPodsValidator)
              ? () => bootstrapContext.resolveOverride<CocoaPodsValidator>()
              : null,
          config: bootstrapContext.resolveOverride<Config>(),
          crashReporter: bootstrapContext.resolveOverride<CrashReporter>(),
          customDevicesConfig: bootstrapContext.resolveOverride<CustomDevicesConfig>(),
          deviceManager: bootstrapContext.resolveOverride<DeviceManager>(),
          doctor: bootstrapContext.resolveOverride<Doctor>(),
          doctorValidatorsProvider: overriddenDoctorValidatorsProvider,
          emulatorManager: bootstrapContext.resolveOverride<EmulatorManager>(),
          extensionEntryPoints: extensionEntryPoints,
          featureFlags: bootstrapContext.resolveOverride<FeatureFlags>(),
          flutterVersion: bootstrapContext.resolveOverride<FlutterVersion>(),
          fs: bootstrapContext.resolveOverride<FileSystem>(),
          git: bootstrapContext.resolveOverride<Git>(),
          gradleUtilsBuilder: bootstrapContext.hasOverride(GradleUtils)
              ? () => bootstrapContext.resolveOverride<GradleUtils>()!
              : null,
          httpClientFactory: httpClientFactory,
          iosSimulatorUtilsBuilder: bootstrapContext.hasOverride(IOSSimulatorUtils)
              ? () => bootstrapContext.resolveOverride<IOSSimulatorUtils>()
              : null,
          iosWorkflowBuilder: bootstrapContext.hasOverride(IOSWorkflow)
              ? () => bootstrapContext.resolveOverride<IOSWorkflow>()
              : null,
          javaBuilder: bootstrapContext.hasOverride(Java)
              ? () => bootstrapContext.resolveOverride<Java>()
              : null,
          localEngineLocator: bootstrapContext.resolveOverride<LocalEngineLocator>(),
          logger: bootstrapContext.resolveOverride<Logger>(),
          macOSWorkflow: bootstrapContext.resolveOverride<MacOSWorkflow>(),
          nativeAssetsBuilder:
              nativeAssetsBuilder ??
              bootstrapContext.resolveOverride<TestCompilerNativeAssetsBuilder>(),
          outputPreferences: initialOutputPreferences,
          persistentToolState: bootstrapContext.resolveOverride<PersistentToolState>(),
          platform: initialPlatform,
          plistParserBuilder: bootstrapContext.hasOverride(PlistParser)
              ? () => bootstrapContext.resolveOverride<PlistParser>()
              : null,
          preRunValidator: bootstrapContext.resolveOverride<PreRunValidator>(),
          preRunValidatorBuilder: bootstrapContext.hasOverride(PreRunValidator)
              ? null
              : preRunValidatorBuilder,
          processInfo: bootstrapContext.resolveOverride<ProcessInfo>(),
          processManager: bootstrapContext.resolveOverride<ProcessManager>(),
          projectFactory: bootstrapContext.resolveOverride<FlutterProjectFactory>(),
          shutdownHooks: shutdownHooks,
          signals: bootstrapContext.resolveOverride<Signals>(),
          stdio: initialStdio,
          systemClock: initialSystemClock,
          templateRenderer: overriddenTemplateRenderer,
          terminal: initialTerminal,
          userMessages: bootstrapContext.resolveOverride<UserMessages>(),
          windowsWorkflow: bootstrapContext.resolveOverride<WindowsWorkflow>(),
          xcdeviceBuilder: bootstrapContext.hasOverride(XCDevice)
              ? () => bootstrapContext.resolveOverride<XCDevice>()
              : null,
          xcodeBuilder: bootstrapContext.hasOverride(Xcode)
              ? () => bootstrapContext.resolveOverride<Xcode>()
              : null,
          xcodeProjectInterpreterBuilder: bootstrapContext.hasOverride(XcodeProjectInterpreter)
              ? () => bootstrapContext.resolveOverride<XcodeProjectInterpreter>()
              : null,
        );
        final ToolDependencies(
          :Analytics analytics,
          :AndroidContext androidContext,
          :AndroidWorkflow androidWorkflow,
          :AppleContext appleContext,
          :BuildSystem buildSystem,
          buildTargets: BuildTargets resolvedBuildTargets,
          :CrashReporter crashReporter,
          :DeviceManager deviceManager,
          :Doctor doctor,
          :EmulatorManager emulatorManager,
          :ExtensionManager? extensionManager,
          :FeatureFlags featureFlags,
          :MacOSWorkflow macOSWorkflow,
          templateRenderer: TemplateRenderer resolvedTemplateRenderer,
          :ToolContext toolContext,
          :WindowsWorkflow windowsWorkflow,
        ) = toolDeps;
        final ToolContext(
          :Artifacts artifacts,
          :BotDetector botDetector,
          :Cache cache,
          :Config config,
          :CustomDevicesConfig customDevicesConfig,
          flutterVersion: FlutterVersion resolvedFlutterVersion,
          :FileSystem fs,
          :Git git,
          :LocalEngineLocator localEngineLocator,
          :Logger logger,
          :OperatingSystemUtils os,
          :OutputPreferences outputPreferences,
          :PersistentToolState persistentToolState,
          :Platform platform,
          :PreRunValidator preRunValidator,
          :ProcessInfo processInfo,
          :ProcessManager processManager,
          :ProcessUtils processUtils,
          :FlutterProjectFactory projectFactory,
          :Signals signals,
          :Stdio stdio,
          :SystemClock systemClock,
          :AnsiTerminal terminal,
          :UserMessages userMessages,
        ) = toolContext;
        terminal.applyFeatureFlags(featureFlags);
        reportCrashes ??= !botDetector.isRunningOnBot;
        DoctorValidatorsProvider createDoctorValidatorsProvider({
          ExtensionManager? extensionManager,
        }) =>
            overriddenDoctorValidatorsProvider ??
            DoctorValidatorsProvider.create(
              appleContext: appleContext,
              deviceManager: deviceManager,
              extensionManager: extensionManager,
              featureFlags: featureFlags,
              httpClientFactory: httpClientFactory,
              toolContext: toolContext,
            );
        return context.run<int>(
          overrides: <Type, Generator>{
            Analytics: () => analytics,
            AndroidSdk: () => androidContext.androidSdk,
            AndroidStudio: () => androidContext.androidStudio,
            AndroidWorkflow: () => androidWorkflow,
            AnsiTerminal: () => terminal,
            Artifacts: () => artifacts,
            BotDetector: () => botDetector,
            BuildSystem: () => buildSystem,
            BuildTargets: () => resolvedBuildTargets,
            Cache: () => cache,
            CocoaPods: () => appleContext.cocoaPods,
            CocoaPodsValidator: () => appleContext.cocoapodsValidator,
            Config: () => config,
            CrashReporter: () => crashReporter,
            CustomDevicesConfig: () => customDevicesConfig,
            DeviceManager: () => deviceManager,
            Doctor: () => doctor,
            DoctorValidatorsProvider: createDoctorValidatorsProvider,
            EmulatorManager: () => emulatorManager,
            FeatureFlags: () => featureFlags,
            FileSystem: () => fs,
            FlutterProjectFactory: () => projectFactory,
            FlutterVersion: () => resolvedFlutterVersion,
            Git: () => git,
            GradleUtils: () => androidContext.gradleUtils,
            IOSSimulatorUtils: () => appleContext.iosSimulatorUtils,
            IOSWorkflow: () => appleContext.iosWorkflow,
            Java: () => androidContext.java,
            LocalEngineLocator: () => localEngineLocator,
            Logger: () => logger,
            MacOSWorkflow: () => macOSWorkflow,
            OperatingSystemUtils: () => os,
            OutputPreferences: () => outputPreferences,
            PersistentToolState: () => persistentToolState,
            Platform: () => platform,
            PlistParser: () => appleContext.plistParser,
            PreRunValidator: () => preRunValidator,
            ProcessInfo: () => processInfo,
            ProcessManager: () => processManager,
            ProcessUtils: () => processUtils,
            ShutdownHooks: () => shutdownHooks,
            Signals: () => signals,
            Stdio: () => stdio,
            SystemClock: () => systemClock,
            TemplateRenderer: () => resolvedTemplateRenderer,
            UserMessages: () => userMessages,
            WindowsWorkflow: () => windowsWorkflow,
            XCDevice: () => appleContext.xcdevice,
            Xcode: () => appleContext.xcode,
            XcodeProjectInterpreter: () => appleContext.xcodeProjectInterpreter,
          },
          body: () async {
            final runner = FlutterCommandRunner(
              analytics: analytics,
              androidContext: androidContext,
              cocoaPods: appleContext.cocoaPods,
              deviceManager: deviceManager,
              doctor: doctor,
              extensionManager: extensionManager!,
              featureFlags: featureFlags,
              plistParser: appleContext.plistParser,
              templateRenderer: resolvedTemplateRenderer,
              toolContext: toolContext,
              verboseHelp: verboseHelp,
            );
            commands(toolDeps).forEach(runner.addCommand);

            // Initialize the system locale.
            final String systemLocale = await intl_standalone.findSystemLocale();
            intl.Intl.defaultLocale = intl.Intl.verifiedLocale(
              systemLocale,
              intl.NumberFormat.localeExists,
              onFailure: (String _) => 'en_US',
            );

            String getVersion() =>
                flutterVersion ??
                resolvedFlutterVersion.getVersionString(redactUnknownBranches: true);
            Object? firstError;
            StackTrace? firstStackTrace;
            return runZonedGuarded<Future<int>>(
              () async {
                try {
                  if (args.contains('--disable-analytics') && args.contains('--enable-analytics')) {
                    throwToolExit(
                      'Both enable and disable analytics commands were detected '
                      'when only one can be supplied per invocation.',
                      exitCode: 1,
                    );
                  }

                  // When analytics are suppressed by DASH__SUPPRESS_ANALYTICS,
                  // `analytics` is a no-op and `setTelemetry` would
                  // silently do nothing, so warn rather than report a change that
                  // was not persisted.
                  final bool dashSuppressed = isDashAnalyticsSuppressionRequested(
                    platform.environment,
                  );

                  if (args.contains('--disable-analytics')) {
                    if (dashSuppressed) {
                      logger.printWarning(dashSuppressedTelemetryChangeMessage(enable: false));
                    } else {
                      if (analytics.telemetryEnabled) {
                        analytics.send(Event.analyticsCollectionEnabled(status: false));
                        // Before disabling analytics, we need to close the client to make
                        // sure the above collection event is sent.
                        await analytics.close();
                      }
                      await analytics.setTelemetry(false);
                      logger.printStatus('Analytics reporting disabled.');
                    }
                  }

                  if (args.contains('--enable-analytics')) {
                    if (dashSuppressed) {
                      logger.printWarning(dashSuppressedTelemetryChangeMessage(enable: true));
                    } else {
                      final bool alreadyEnabled = analytics.telemetryEnabled;
                      await analytics.setTelemetry(true);
                      if (!alreadyEnabled) {
                        analytics.send(Event.analyticsCollectionEnabled(status: true));
                      }
                      logger.printStatus('Analytics reporting enabled.');
                    }
                  }

                  await runner.run(args);

                  // Triggering [runZoned]'s error callback does not necessarily mean that
                  // we stopped executing the body. See https://github.com/dart-lang/sdk/issues/42150.
                  if (firstError == null) {
                    return await exitWithHooks(
                      0,
                      analytics: analytics,
                      logger: logger,
                      shutdownHooks: shutdownHooks,
                    );
                  }

                  // We already hit some error, so don't return success. The error path
                  // (which should be in progress) is responsible for calling _exit().
                  return 1;
                  // This catches all exceptions to send to crash logging, etc.
                  // ignore: avoid_catches_without_on_clauses
                } catch (error, stackTrace) {
                  firstError = error;
                  firstStackTrace = stackTrace;
                  return _handleToolError(
                    error,
                    stackTrace,
                    verbose,
                    args,
                    reportCrashes!,
                    getVersion,
                    shutdownHooks,
                    analytics: analytics,
                    crashReporter: crashReporter,
                    doctorValidatorsProviderBuilder: createDoctorValidatorsProvider,
                    featureFlags: featureFlags,
                    toolContext: toolContext,
                    usingLocalEngine: usingLocalEngine,
                  );
                }
              },
              (Object error, StackTrace stackTrace) async {
                // If sending a crash report throws an error into the zone, we don't want
                // to re-try sending the crash report with *that* error. Rather, we want
                // to send the original error that triggered the crash report.
                firstError ??= error;
                firstStackTrace ??= stackTrace;
                await _handleToolError(
                  firstError!,
                  firstStackTrace,
                  verbose,
                  args,
                  reportCrashes!,
                  getVersion,
                  shutdownHooks,
                  analytics: analytics,
                  crashReporter: crashReporter,
                  doctorValidatorsProviderBuilder: createDoctorValidatorsProvider,
                  featureFlags: featureFlags,
                  toolContext: toolContext,
                  usingLocalEngine: usingLocalEngine,
                );
              },
            )!;
          },
        );
      },
    );
  }, overrides: overrides);
}

/// Track if we're actively processing an error so we don't try and process
/// additional asynchronous exceptions while we're trying to shut down.
///
/// NOTE: This state is cleared at the beginning of [run] to ensure state
/// doesn't leak when running tests.
Future<int>? _alreadyHandlingToolError;

Future<int> _handleToolError(
  Object error,
  StackTrace? stackTrace,
  bool verbose,
  List<String> args,
  bool reportCrashes,
  String Function() getFlutterVersion,
  ShutdownHooks shutdownHooks, {
  required Analytics analytics,
  required CrashReporter crashReporter,
  required DoctorValidatorsProviderBuilder doctorValidatorsProviderBuilder,
  required FeatureFlags featureFlags,
  required ToolContext toolContext,
  required bool usingLocalEngine,
}) async {
  return _alreadyHandlingToolError ??= _handleToolErrorImpl(
    error,
    stackTrace,
    verbose,
    args,
    reportCrashes,
    getFlutterVersion,
    shutdownHooks,
    analytics: analytics,
    crashReporter: crashReporter,
    doctorValidatorsProviderBuilder: doctorValidatorsProviderBuilder,
    featureFlags: featureFlags,
    toolContext: toolContext,
    usingLocalEngine: usingLocalEngine,
  );
}

Future<int> _handleToolErrorImpl(
  Object error,
  StackTrace? stackTrace,
  bool verbose,
  List<String> args,
  bool reportCrashes,
  String Function() getFlutterVersion,
  ShutdownHooks shutdownHooks, {
  required Analytics analytics,
  required CrashReporter crashReporter,
  required DoctorValidatorsProviderBuilder doctorValidatorsProviderBuilder,
  required FeatureFlags featureFlags,
  required ToolContext toolContext,
  required bool usingLocalEngine,
}) async {
  final ToolContext(
    :Cache cache,
    :Logger logger,
    :OperatingSystemUtils os,
    :OutputPreferences outputPreferences,
    :Platform platform,
    :ProcessManager processManager,
    :Stdio stdio,
    :SystemClock systemClock,
    :AnsiTerminal terminal,
    :UserMessages userMessages,
  ) = toolContext;
  if (error is UsageException) {
    logger.printError('${error.message}\n');
    logger.printError(
      "Run 'flutter -h' (or 'flutter <command> -h') for available flutter commands and options.",
    );
    // Argument error exit code.
    return exitWithHooks(64, analytics: analytics, logger: logger, shutdownHooks: shutdownHooks);
  } else if (error is ToolExit) {
    if (error.message != null) {
      logger.printError(error.message!);
    }
    if (verbose) {
      logger.printError('\n$stackTrace\n');
    }
    return exitWithHooks(
      error.exitCode ?? 1,
      analytics: analytics,
      logger: logger,
      shutdownHooks: shutdownHooks,
    );
  } else if (error is ProcessExit) {
    // We've caught an exit code.
    if (error.immediate) {
      exit(error.exitCode);
      return error.exitCode;
    } else {
      return exitWithHooks(
        error.exitCode,
        analytics: analytics,
        logger: logger,
        shutdownHooks: shutdownHooks,
      );
    }
  } else if (error is ProcessException && _isErrorDueToGitMissing(error, processManager, logger)) {
    logger.printError('${error.message}\n');
    logger.printError(
      'An error was encountered when trying to run git.\n'
      "Please ensure git is installed and available in your system's search path. "
      'See https://docs.flutter.dev/get-started for instructions on '
      'installing git for your platform.',
    );
    return exitWithHooks(1, analytics: analytics, logger: logger, shutdownHooks: shutdownHooks);
  } else {
    // We've crashed; emit a log report.
    stdio.stderrWrite('\n');
    if (!reportCrashes) {
      // Print the stack trace on the bots - don't write a crash report.
      stdio.stderrWrite('$error\n');
      stdio.stderrWrite('$stackTrace\n');

      final String featureFlagsEnabled = allConfigurableFeatures
          .where(featureFlags.isEnabled)
          .map((Feature f) => f.configSetting)
          .join(', ');
      stdio.stderrWrite('Feature flags enabled: $featureFlagsEnabled\n');
      return exitWithHooks(1, analytics: analytics, logger: logger, shutdownHooks: shutdownHooks);
    }

    // Flutter tool crash analytics benefits from the concrete Dart error type.
    // The tool is not obfuscated, and collapsing unknown types to Object loses useful signal.
    // ignore: avoid_type_to_string
    analytics.send(Event.exception(exception: error.runtimeType.toString()));

    if (!usingLocalEngine) {
      await asyncGuard(
        () async {
          final crashReportSender = CrashReportSender(
            platform: platform,
            logger: logger,
            operatingSystemUtils: os,
            analytics: analytics,
          );
          await crashReportSender.sendReport(
            error: error,
            stackTrace: stackTrace!,
            getFlutterVersion: getFlutterVersion,
            command: args.join(' '),
          );
        },
        onError: (Object error) {
          logger.printError('Error sending crash report: $error');
        },
      );
    }

    logger.printError('Oops; flutter has exited unexpectedly: "$error".');

    try {
      final doctorLogger = BufferLogger(
        terminal: terminal,
        outputPreferences: outputPreferences,
        verbose: true /* Capture flutter doctor -v */,
      );

      final doctorText = DoctorText(
        doctorLogger,
        doctor: Doctor(
          analytics: analytics,
          cache: cache,
          clock: systemClock,
          logger: doctorLogger,
          validatorsProviderBuilder: doctorValidatorsProviderBuilder,
        ),
      );

      final details = CrashDetails(
        command: _crashCommand(args),
        error: error,
        stackTrace: stackTrace!,
        doctorText: doctorText,
      );
      final File file = await _createLocalCrashReport(details, toolContext: toolContext);
      await crashReporter.informUser(details, file);

      return await exitWithHooks(
        1,
        analytics: analytics,
        logger: logger,
        shutdownHooks: shutdownHooks,
      );
      // This catch catches all exceptions to ensure the message below is printed.
      // ignore: avoid_catches_without_on_clauses
    } catch (error, st) {
      stdio.stderrWrite(
        'Unable to generate crash report due to secondary error: $error\n$st\n'
        '${userMessages.flutterToolBugInstructions}\n',
      );
      // Any exception thrown here (including one thrown by `_exit()`) will
      // get caught by our zone's `onError` handler. In order to avoid an
      // infinite error loop, we throw an error that is recognized above
      // and will trigger an immediate exit.
      throw ProcessExit(1, immediate: true);
    }
  }
}

String _crashCommand(List<String> args) => 'flutter ${args.join(' ')}';

String _crashException(Object error) => '${error.runtimeType}: $error';

/// Saves the crash report to a local file.
Future<File> _createLocalCrashReport(
  CrashDetails details, {
  required ToolContext toolContext,
}) async {
  final ToolContext(
    :FileSystem fs,
    :Logger logger,
    :Platform platform,
    :UserMessages userMessages,
  ) = toolContext;
  final fsUtils = FileSystemUtils(fileSystem: fs, platform: platform);
  final buffer = StringBuffer();

  buffer.writeln('Flutter crash report.');
  buffer.writeln('${userMessages.flutterToolBugInstructions}\n');

  buffer.writeln('## command\n');
  buffer.writeln('${details.command}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('${_crashException(details.error)}\n');
  buffer.writeln('```\n${details.stackTrace}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await details.doctorText.text}```');

  late File crashFile;
  ErrorHandlingFileSystem.noExitOnFailure(() {
    try {
      crashFile = fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'log');
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException {
      // Fallback to the system temporary directory.
      try {
        crashFile = fsUtils.getUniqueFile(fs.systemTempDirectory, 'flutter', 'log');
        crashFile.writeAsStringSync(buffer.toString());
      } on FileSystemException catch (e) {
        logger.printError('Could not write crash report to disk: $e');
        logger.printError(buffer.toString());

        rethrow;
      }
    }
  });

  return crashFile;
}

bool _isErrorDueToGitMissing(
  ProcessException exception,
  ProcessManager processManager,
  Logger logger,
) {
  if (!exception.message.contains('git')) {
    return false;
  }

  try {
    return !processManager.canRun('git');
  } on Object catch (error) {
    logger.printTrace('Unable to check whether git is runnable: $error\n');
    return true;
  }
}
