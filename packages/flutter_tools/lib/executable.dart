// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:process/process.dart';

import 'runner.dart' as runner;
import 'src/android/gradle.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/signals.dart';
import 'src/base/terminal.dart';
import 'src/base/time.dart';
import 'src/build_system/targets/hook_runner_native.dart' show FlutterHookRunnerNative;
import 'src/cache.dart';
import 'src/commands/analyze.dart';
import 'src/commands/assemble.dart';
import 'src/commands/attach.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/custom_devices.dart';
import 'src/commands/daemon.dart';
import 'src/commands/debug_adapter.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/downgrade.dart';
import 'src/commands/drive.dart';
import 'src/commands/emulators.dart';
import 'src/commands/generate.dart';
import 'src/commands/generate_localizations.dart';
import 'src/commands/ide_config.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/shell_completion.dart';
import 'src/commands/symbolize.dart';
import 'src/commands/test.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/commands/widget_preview.dart';
import 'src/context/tool_context.dart';
import 'src/context/tool_dependencies.dart';
import 'src/experimental/extension_discovery.dart';
import 'src/experimental/extension_manager.dart';
import 'src/experimental/templates.dart';
import 'src/features.dart';
// Files in `isolated` are intentionally excluded from google3 tooling.
import 'src/hook_runner.dart' show FlutterHookRunner;
import 'src/isolated/build_targets.dart';
import 'src/isolated/mustache_template.dart';
import 'src/isolated/native_assets/test/native_assets.dart';
import 'src/isolated/resident_web_runner.dart';
import 'src/native_assets.dart';
import 'src/pre_run_validator.dart';
import 'src/project_validator.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/web/web_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<void> main(List<String> args) async {
  final bool veryVerbose = args.contains('-vv');
  final bool verbose = args.contains('-v') || args.contains('--verbose') || veryVerbose;
  final bool prefixedErrors = args.contains('--prefixed-errors');
  // Support universal help idioms.
  final int powershellHelpIndex = args.indexOf('-?');
  if (powershellHelpIndex != -1) {
    args[powershellHelpIndex] = '-h';
  }
  final int slashQuestionHelpIndex = args.indexOf('/?');
  if (slashQuestionHelpIndex != -1) {
    args[slashQuestionHelpIndex] = '-h';
  }

  final String? commandName = FlutterCommandRunner.findCommandName(args);
  final doctor = commandName == 'doctor';
  final bool help =
      args.contains('-h') ||
      args.contains('--help') ||
      commandName == 'help' ||
      (args.length == 1 && verbose);
  final bool muteCommandLogging = (help || doctor) && !veryVerbose;
  final bool verboseHelp = help && verbose;
  final daemon = commandName == 'daemon';
  final widgetPreviews = commandName == WidgetPreviewCommand.kWidgetPreview;
  final bool runMachine = args.contains('--machine');
  const Platform platform = LocalPlatform();
  final stdio = Stdio();
  final ShutdownHooks shutdownHooks = LocalSignals.instance.shutdownHooks;
  final terminal = AnsiTerminal(
    stdio: stdio,
    platform: platform,
    now: const SystemClock().now(),
    // So that we don't animate anything before calling applyFeatureFlags, default
    // the animations to disabled in real apps.
    defaultCliAnimationEnabled: false,
    shutdownHooks: shutdownHooks,
  );
  final outputPreferences = OutputPreferences(
    wrapText: stdio.hasTerminal,
    showColor: platform.stdoutSupportsAnsi,
    stdio: stdio,
  );
  final Logger logger =
      LoggerFactory(
        outputPreferences: outputPreferences,
        terminal: terminal,
        stdio: stdio,
      ).createLogger(
        daemon: daemon,
        machine: runMachine,
        verbose: verbose && !muteCommandLogging,
        prefixedErrors: prefixedErrors,
        windows: platform.isWindows,
        widgetPreviews: widgetPreviews,
      );

  await runner.run(
    args,
    (ToolDependencies toolDependencies) {
      final ToolDependencies(
        :ExtensionManager? extensionManager,
        :FeatureFlags featureFlags,
        toolContext: ToolContext(:Cache cache, :FileSystem fs, :Logger logger),
      ) = toolDependencies;
      final ExtensionManager manager = extensionManager!;
      final templateManager = ExtensionTemplateManager(
        extensionManager: manager,
        featureFlags: featureFlags,
        fileSystem: fs,
        flutterRoot: cache.flutterRoot,
        logger: logger,
      );
      return generateCommands(
        toolDependencies: toolDependencies,
        verboseHelp: verboseHelp,
        verbose: verbose,
        extensionTemplateManager: templateManager,
      );
    },
    buildTargets: const BuildTargetsImpl(),
    extensionEntryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
    muteCommandLogging: muteCommandLogging,
    nativeAssetsBuilder: const TestCompilerNativeAssetsBuilderImpl(),
    overrides: <Type, Generator>{
      AnsiTerminal: () => terminal,
      FlutterHookRunner: () => FlutterHookRunnerNative(),
      Logger: () => logger,
      OutputPreferences: () => outputPreferences,
      Stdio: () => stdio,
      // The web runner is not supported in google3 because it depends
      // on dwds.
      WebRunnerFactory: () => DwdsWebRunnerFactory(),
    },
    preRunValidatorBuilder: PreRunValidator.new,
    shutdownHooks: shutdownHooks,
    templateRenderer: const MustacheTemplateRenderer(),
    verbose: verbose,
    verboseHelp: verboseHelp,
  );
}

List<FlutterCommand> generateCommands({
  required ToolDependencies toolDependencies,
  required bool verbose,
  required bool verboseHelp,
  ExtensionTemplateManager? extensionTemplateManager,
}) {
  final ToolDependencies(:FeatureFlags featureFlags, :ToolContext toolContext) = toolDependencies;
  final ToolContext(
    :Cache cache,
    :Logger logger,
    :TestCompilerNativeAssetsBuilder? nativeAssetsBuilder,
    :Platform platform,
    :ProcessManager processManager,
  ) = toolContext;
  return <FlutterCommand>[
    AnalyzeCommand(
      allProjectValidators: <ProjectValidator>[
        GeneralInfoProjectValidator(
          androidContext: toolDependencies.androidContext,
          logger: logger,
          processManager: processManager,
        ),
        VariableDumpMachineProjectValidator(toolContext: toolContext),
      ],
      androidBuilder: AndroidGradleBuilder.fromContexts(
        analytics: toolDependencies.analytics,
        androidContext: toolDependencies.androidContext,
        toolContext: toolContext,
      ),
      suppressAnalytics: !toolDependencies.analytics.okToSend,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    AssembleCommand(
      androidContext: toolDependencies.androidContext,
      buildSystem: toolDependencies.buildSystem,
      extensionBuildManager: toolDependencies.extensionBuildManager,
      featureFlags: featureFlags,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
      xcode: toolDependencies.appleContext.xcode,
    ),
    AttachCommand(
      buildSystem: toolDependencies.buildSystem,
      buildTargets: toolDependencies.buildTargets,
      toolContext: toolContext,
      xcode: toolDependencies.appleContext.xcode,
      verboseHelp: verboseHelp,
    ),
    BuildCommand(
      androidBuilder: AndroidGradleBuilder.fromContexts(
        analytics: toolDependencies.analytics,
        androidContext: toolDependencies.androidContext,
        toolContext: toolContext,
      ),
      androidContext: toolDependencies.androidContext,
      appleContext: toolDependencies.appleContext,
      buildSystem: toolDependencies.buildSystem,
      extensionBuildManager: toolDependencies.extensionBuildManager,
      featureFlags: featureFlags,
      templateRenderer: const MustacheTemplateRenderer(),
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    ChannelCommand(verboseHelp: verboseHelp, toolContext: toolContext),
    CleanCommand(
      extensionCleanManager: toolDependencies.extensionCleanManager,
      verbose: verbose,
      toolContext: toolContext,
      xcode: toolDependencies.appleContext.xcode,
      xcodeProjectInterpreter: toolDependencies.appleContext.xcodeProjectInterpreter,
    ),
    ConfigCommand(
      verboseHelp: verboseHelp,
      androidContext: toolDependencies.androidContext,
      toolContext: toolContext,
      featureFlags: featureFlags,
      extensionManager: toolDependencies.extensionManager,
    ),
    CustomDevicesCommand(featureFlags: featureFlags, toolContext: toolContext),
    CreateCommand(
      androidContext: toolDependencies.androidContext,
      appleContext: toolDependencies.appleContext,
      templateRenderer: const MustacheTemplateRenderer(),
      toolContext: toolContext,
      extensionTemplateManager: extensionTemplateManager,
      verboseHelp: verboseHelp,
    ),
    DaemonCommand(
      androidContext: toolDependencies.androidContext,
      androidWorkflow: toolDependencies.androidWorkflow,
      buildSystem: toolDependencies.buildSystem,
      buildTargets: toolDependencies.buildTargets,
      deviceManager: toolDependencies.deviceManager,
      hidden: !verboseHelp,
      toolContext: toolContext,
      xcode: toolDependencies.appleContext.xcode,
    ),
    DebugAdapterCommand(toolContext: toolContext, verboseHelp: verboseHelp),
    DevicesCommand(
      deviceManager: toolDependencies.deviceManager,
      doctor: toolDependencies.doctor,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    DoctorCommand(
      doctor: toolDependencies.doctor,
      extensionManager: toolDependencies.extensionManager,
      toolContext: toolContext,
      verbose: verbose,
    ),
    DowngradeCommand(toolContext: toolContext, verboseHelp: verboseHelp),
    DriveCommand(
      buildSystem: toolDependencies.buildSystem,
      buildTargets: toolDependencies.buildTargets,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    EmulatorsCommand(
      doctor: toolDependencies.doctor,
      emulatorManager: toolDependencies.emulatorManager,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    GenerateCommand(toolContext: toolContext),
    GenerateLocalizationsCommand(toolContext: toolContext),
    InstallCommand(toolContext: toolContext, verboseHelp: verboseHelp),
    LogsCommand(toolContext: toolContext),
    PackagesCommand(
      buildSystem: toolDependencies.buildSystem,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    PrecacheCommand(
      verboseHelp: verboseHelp,
      cache: cache,
      logger: logger,
      platform: platform,
      featureFlags: featureFlags,
      toolContext: toolContext,
    ),
    RunCommand(
      appleContext: toolDependencies.appleContext,
      buildSystem: toolDependencies.buildSystem,
      buildTargets: toolDependencies.buildTargets,
      toolContext: toolContext,
      androidContext: toolDependencies.androidContext,
      androidWorkflow: toolDependencies.androidWorkflow,
      deviceManager: toolDependencies.deviceManager,
      verboseHelp: verboseHelp,
    ),
    ScreenshotCommand(toolContext: toolContext),
    ShellCompletionCommand(toolContext: toolContext),
    TestCommand(
      templateRenderer: const MustacheTemplateRenderer(),
      toolContext: toolContext,
      verboseHelp: verboseHelp,
      verbose: verbose,
      nativeAssetsBuilder: nativeAssetsBuilder,
    ),
    WidgetPreviewCommand(
      buildSystem: toolDependencies.buildSystem,
      buildTargets: toolDependencies.buildTargets,
      toolContext: toolContext,
      verboseHelp: verboseHelp,
    ),
    UpgradeCommand(toolContext: toolContext, verboseHelp: verboseHelp),
    SymbolizeCommand(toolContext: toolContext),
    // Development-only commands. These are always hidden,
    IdeConfigCommand(toolContext: toolContext),
    UpdatePackagesCommand(toolContext: toolContext, verboseHelp: verboseHelp),
  ];
}

/// An abstraction for instantiation of the correct logger type.
///
/// Our logger class hierarchy and runtime requirements are overly complicated.
class LoggerFactory {
  LoggerFactory({
    required this._terminal,
    required this._stdio,
    required this._outputPreferences,
    this._stopwatchFactory = const StopwatchFactory(),
  });

  final Terminal _terminal;
  final Stdio _stdio;
  final StopwatchFactory _stopwatchFactory;
  final OutputPreferences _outputPreferences;

  /// Create the appropriate logger for the current platform and configuration.
  Logger createLogger({
    required bool verbose,
    required bool prefixedErrors,
    required bool machine,
    required bool daemon,
    required bool windows,
    required bool widgetPreviews,
  }) {
    Logger logger;
    if (windows) {
      logger = WindowsStdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        stopwatchFactory: _stopwatchFactory,
      );
    } else {
      logger = StdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        stopwatchFactory: _stopwatchFactory,
      );
    }
    if (verbose) {
      logger = VerboseLogger(logger, stopwatchFactory: _stopwatchFactory);
    }
    if (prefixedErrors) {
      logger = PrefixedErrorLogger(logger);
    }
    if (widgetPreviews) {
      return WidgetPreviewMachineAwareLogger(
        logger,
        machine: machine,
        verbose: verbose,
        stdio: _stdio,
      );
    }
    if (daemon) {
      return NotifyingLogger(verbose: verbose, parent: logger);
    }
    if (machine) {
      return MachineOutputLogger(parent: logger);
    }
    return logger;
  }
}
