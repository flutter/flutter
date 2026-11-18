// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;
import 'package:meta/meta.dart';

import '../android/android_builder.dart';
import '../android/gradle.dart';
import '../artifacts.dart';
import '../base/common.dart' show throwToolExit;
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/template.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/extension.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../experimental/extension_build_manager.dart';
import '../features.dart';
import '../macos/xcode.dart';
import '../runner/flutter_command.dart';
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
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildIOSFrameworkCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        codesign: codesign,
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        codesign: codesign,
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        analytics: analytics,
        buildSystem: buildSystem,
        cocoaPods: appleContext.cocoaPods,
        codesign: codesign,
        featureFlags: featureFlags,
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
        xcode: xcode,
      ),
    );

    _addSubcommand(
      BuildIOSArchiveCommand(
        appleContext: appleContext,
        buildSystem: buildSystem,
        templateRenderer: templateRenderer,
        toolContext: toolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildBundleCommand(
        androidContext: androidContext,
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
        appleContext: appleContext,
        buildSystem: buildSystem,
        featureFlags: featureFlags,
        templateRenderer: templateRenderer,
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
        visualStudio: VisualStudio(toolContext: toolContext),
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
          final String extensionName = extensionBuildManager.extensionNameForBuildTarget(
            target.name,
          );
          toolContext.logger.printWarning(
            'Skipping custom build target "${target.name}" from extension "$extensionName" because a subcommand with that name already exists.',
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
    required super.toolContext,
  }) {
    requiresPubspecYaml();
    CommonOptions.fatalWarnings.addTo(argParser, verboseHelp: verboseHelp);
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
    required super.toolContext,
    required super.verboseHelp,
  }) : super(logger: toolContext.logger) {
    registerOptionBundle(const BuildModeOptionsBundle());
    registerOptionBundle(const CommonBuildOptionsBundle());
    registerOptionBundle(const DartCompileOptionsBundle());
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      BuildInfoOptions.flavor,
      BuildInfoOptions.splitDebugInfo,
      BuildInfoOptions.obfuscate,
      BuildInfoOptions.extraFrontEndOptions,
      BuildInfoOptions.extraGenSnapshotOptions,
      BuildInfoOptions.trackWidgetCreation,
      BuildInfoOptions.analyzeSize,
      BuildInfoOptions.codeSizeDirectory,
      BuildInfoOptions.performanceMeasurementFile,
    ], verboseHelp: verboseHelp);

    if (target.targetPlatforms.length > 1) {
      argParser.addOption(
        _targetPlatformOption,
        allowed: target.targetPlatforms,
        defaultsTo: target.targetPlatform ?? target.targetPlatforms.first,
        help: 'The target platform for which the app is compiled.',
      );
    }

    for (final BuildFlag flag in target.buildFlags) {
      if (_hasOptionOrAbbrCollision(name: flag.name, abbr: flag.abbr)) {
        logger.printWarning(
          'Skipping custom build flag "--${flag.name}" on build target "${target.name}" '
          'because an option or abbreviation with that name already exists.',
        );
        continue;
      }
      argParser.addFlag(
        flag.name,
        abbr: flag.abbr,
        defaultsTo: flag.defaultsTo,
        help: flag.help,
        negatable: flag.negatable,
      );
      _registeredFlagNames.add(flag.name);
    }

    for (final BuildOption option in target.buildOptions) {
      if (_hasOptionOrAbbrCollision(name: option.name, abbr: option.abbr)) {
        logger.printWarning(
          'Skipping custom build option "--${option.name}" on build target "${target.name}" '
          'because an option or abbreviation with that name already exists.',
        );
        continue;
      }
      argParser.addOption(
        option.name,
        abbr: option.abbr,
        allowed: option.allowed,
        allowedHelp: option.allowedHelp,
        defaultsTo: option.defaultsTo,
        help: option.help,
        mandatory: option.mandatory,
        valueHelp: option.valueHelp,
      );
      _registeredOptionNames.add(option.name);
    }
  }

  static const String _targetPlatformOption = 'target-platform';
  static const String _deviceIdGlobalOption = 'device-id';

  final ExtensionBuildManager _buildManager;
  final _registeredFlagNames = <String>{};
  final _registeredOptionNames = <String>{};

  /// The custom build target definition provided by the tool extension.
  final ExtensionBuildTarget target;

  bool _hasOptionOrAbbrCollision({required String name, String? abbr}) {
    if (argParser.options.containsKey(name)) {
      return true;
    }
    if (abbr != null && argParser.findByAbbreviation(abbr) != null) {
      return true;
    }
    return false;
  }

  @override
  String get name => target.name;

  @override
  String get description => target.description;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ToolContext(:Artifacts artifacts, :Cache cache, :Config config, :FileSystem fs) =
        toolContext;
    final Directory projectDir = fs.currentDirectory;
    final BuildInfo buildInfo = await getBuildInfo();
    final String? selectedTargetPlatform = target.targetPlatforms.length > 1
        ? stringArg(_targetPlatformOption)
        : (target.targetPlatform ?? target.targetPlatforms.firstOrNull);
    final Directory outputDir = resolveExtensionOutputDir(
      buildMode: buildInfo.mode,
      buildOutputDir: projectDir.childDirectory(getBuildDirectory(config, fs)),
      fileSystem: fs,
      projectDir: projectDir,
      target: target,
      targetPlatform: selectedTargetPlatform,
    );
    final Map<String, String> resolvedArtifacts = resolveExtensionBuildTargetArtifacts(
      artifacts: artifacts,
      buildMode: buildInfo.mode,
      target: target,
      targetPlatform: selectedTargetPlatform,
    );

    final buildFlags = <String, bool>{
      for (final String flagName in _registeredFlagNames) flagName: boolArg(flagName),
    };
    final buildOptions = <String, String?>{
      for (final String optionName in _registeredOptionNames) optionName: stringArg(optionName),
    };
    final String? targetDeviceId = switch (globalResults?[_deviceIdGlobalOption]) {
      final String id when id.isNotEmpty => id,
      final List<String> ids when ids.isNotEmpty => ids.first,
      _ => null,
    };
    final Uri? splitDebugInfo = switch (buildInfo.splitDebugInfoPath) {
      final String raw when raw.isNotEmpty =>
        (fs.path.isRelative(raw) ? projectDir.childDirectory(raw) : fs.directory(raw)).uri,
      _ => null,
    };
    final Uri? codeSizeDirectory = switch (buildInfo.codeSizeDirectory) {
      final String raw when raw.isNotEmpty =>
        (fs.path.isRelative(raw) ? projectDir.childDirectory(raw) : fs.directory(raw)).uri,
      _ => null,
    };

    final ExtensionBuildResult result = await _buildManager.build(
      buildFlags: buildFlags,
      buildMode: buildInfo.mode,
      buildName: buildInfo.buildName,
      buildNumber: buildInfo.buildNumber,
      buildOptions: buildOptions,
      codeSizeDirectory: codeSizeDirectory,
      dartDefines: parseExtensionDartDefines(buildInfo.dartDefines),
      dartObfuscation: buildInfo.dartObfuscation,
      extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      extraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions,
      flavor: buildInfo.flavor,
      flutterRoot: fs.directory(cache.flutterRoot).uri,
      mainPath: targetFile,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      splitDebugInfo: splitDebugInfo,
      targetDeviceId: targetDeviceId,
      targetName: target.name,
      targetPlatform: selectedTargetPlatform,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      treeShakeIcons: buildInfo.treeShakeIcons,
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
