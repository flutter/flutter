// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;
import 'package:meta/meta.dart';

import '../android/android_builder.dart';
import '../android/gradle.dart';
import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart' show throwToolExit;
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/template.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/extension.dart';
import '../cache.dart';
import '../context/android_context.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../experimental/extension_build_manager.dart';
import '../features.dart';
import '../macos/xcode.dart';
import '../project.dart';
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
    final Set<BuildMode> supportedModes = target.supportedBuildModes;
    if (supportedModes.contains(BuildMode.release)) {
      defaultBuildMode = BuildMode.release;
    } else if (supportedModes.contains(BuildMode.debug)) {
      defaultBuildMode = BuildMode.debug;
    } else if (supportedModes.contains(BuildMode.profile)) {
      defaultBuildMode = BuildMode.profile;
    } else {
      defaultBuildMode = supportedModes.first;
    }
    registerOptionBundle(const CommonBuildOptionsBundle());
    registerOptionBundle(const DartCompileOptionsBundle());
    argParser.addDescriptors(<OptionDescriptor<Object?>>[
      if (supportedModes.contains(BuildMode.debug)) CommonOptions.debugMode,
      if (supportedModes.contains(BuildMode.profile)) CommonOptions.profileMode,
      if (supportedModes.contains(BuildMode.release)) CommonOptions.releaseMode,
      if (supportedModes.contains(BuildMode.jitRelease)) CommonOptions.jitReleaseMode,
      if (target.supportsFlavors) BuildInfoOptions.flavor,
      BuildInfoOptions.splitDebugInfo,
      BuildInfoOptions.obfuscate,
      BuildInfoOptions.extraFrontEndOptions,
      BuildInfoOptions.extraGenSnapshotOptions,
      BuildInfoOptions.trackWidgetCreation,
      if (target.supportsSizeAnalysis) ...const <OptionDescriptor<Object?>>[
        BuildInfoOptions.analyzeSize,
        BuildInfoOptions.codeSizeDirectory,
      ],
      BuildInfoOptions.performanceMeasurementFile,
    ], verboseHelp: verboseHelp);

    if (target.targetPlatforms.length > 1) {
      argParser.addOption(
        _targetPlatformOption,
        allowed: target.targetPlatforms,
        defaultsTo: target.targetPlatforms.first,
        help: 'The target platform for which the app is compiled.',
      );
    }

    final String extensionName = _buildManager.extensionNameForBuildTarget(target.name);
    for (final ExtensionFlag flag in target.flags) {
      if (argParser.options.containsKey(flag.name)) {
        logger.printWarning(
          'Skipping custom build flag "--${flag.name}" on build target "${target.name}" '
          'from extension "$extensionName" because an option with that name already exists.',
        );
        continue;
      }
      argParser.addFlag(
        flag.name,
        defaultsTo: flag.defaultsTo,
        help: flag.help,
        hide: !verboseHelp && (flag.hide || flag.deprecated != null),
        negatable: flag.negatable,
      );
      _registeredFlags.add(flag);
    }

    for (final ExtensionOption option in target.options) {
      if (argParser.options.containsKey(option.name)) {
        logger.printWarning(
          'Skipping custom build option "--${option.name}" on build target "${target.name}" '
          'from extension "$extensionName" because an option with that name already exists.',
        );
        continue;
      }
      argParser.addOption(
        option.name,
        allowed: option.allowed,
        allowedHelp: option.allowedHelp,
        defaultsTo: option.defaultsTo,
        help: option.help,
        hide: !verboseHelp && (option.hide || option.deprecated != null),
        mandatory: option.mandatory,
        valueHelp: option.valueHelp,
      );
      _registeredOptions.add(option);
    }
  }

  static const String _targetPlatformOption = 'target-platform';
  static const String _deviceIdGlobalOption = 'device-id';

  final ExtensionBuildManager _buildManager;
  final _registeredFlags = <ExtensionFlag>[];
  final _registeredOptions = <ExtensionOption>[];

  /// The custom build target definition provided by the tool extension.
  final ExtensionBuildTarget target;

  @override
  String get name => target.name;

  @override
  String get description => target.description;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ToolContext(
      :Artifacts artifacts,
      :Cache cache,
      :Config config,
      :FileSystem fs,
      :Platform platform,
    ) = toolContext;

    for (final ExtensionFlag(:String? deprecated, :String name) in _registeredFlags) {
      if (deprecated != null && argResults!.wasParsed(name)) {
        logger.printWarning('Warning: "--$name" is deprecated: $deprecated');
      }
    }
    for (final ExtensionOption(:String? deprecated, :String name) in _registeredOptions) {
      if (deprecated != null && argResults!.wasParsed(name)) {
        logger.printWarning('Warning: "--$name" is deprecated: $deprecated');
      }
    }

    final Directory projectDir = fs.currentDirectory;
    final FlutterProject flutterProject = project;
    final BuildInfo buildInfo = await getBuildInfo();
    final String? selectedTargetPlatform = target.targetPlatforms.length > 1
        ? stringArg(_targetPlatformOption)
        : target.targetPlatforms.firstOrNull;
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
      for (final ExtensionFlag(:String name) in _registeredFlags) name: boolArg(name),
    };
    final buildOptions = <String, String>{
      for (final ExtensionOption(:String name) in _registeredOptions)
        if (stringArg(name) case final String value) name: value,
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

    final ExtensionBuildResult result;
    try {
      result = await _buildManager.build(
        buildFlags: buildFlags,
        buildMode: buildInfo.mode,
        buildName: buildInfo.buildName ?? flutterProject.manifest.buildName,
        buildNumber: buildInfo.buildNumber ?? flutterProject.manifest.buildNumber,
        buildOptions: buildOptions,
        codeSizeDirectory: codeSizeDirectory,
        dartDefines: parseExtensionDartDefines(buildInfo.dartDefines),
        dartObfuscation: buildInfo.dartObfuscation,
        extraFrontEndOptions: buildInfo.extraFrontEndOptions,
        extraGenSnapshotOptions: buildInfo.extraGenSnapshotOptions,
        flavor: target.supportsFlavors ? buildInfo.flavor : null,
        flutterRoot: fs.directory(cache.flutterRoot).uri,
        mainPath: fs.file(targetFile).absolute.path,
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
    } on ToolExtensionException catch (e) {
      throwToolExit(e.message.isNotEmpty ? 'Build failed: ${e.message}' : 'Build failed.');
    }

    final Uri? bundleDirectoryUri = result.bundleDirectoryUri;
    if (codeSizeDirectory != null && bundleDirectoryUri != null) {
      final String analysisPlatform = selectedTargetPlatform ?? target.name;
      final Directory codeSizeDir = fs.directory(codeSizeDirectory);
      final File codeSizeFile = codeSizeDir.childFile('snapshot.$analysisPlatform.json');
      final File precompilerTrace = codeSizeDir.childFile('trace.$analysisPlatform.json');
      if (!codeSizeFile.existsSync() || !precompilerTrace.existsSync()) {
        throwToolExit(
          'Code size analysis failed for "${target.name}": expected '
          '"${codeSizeFile.basename}" and "${precompilerTrace.basename}" in '
          '"${codeSizeDir.path}".',
        );
      }
      final Directory bundleDir = fs.directory(bundleDirectoryUri);
      if (!_containsFileNamed(bundleDir, result.aotSnapshotFileName)) {
        throwToolExit(
          'Code size analysis failed for "${target.name}": could not find AOT snapshot '
          '"${result.aotSnapshotFileName}" in bundle directory "${bundleDir.path}".',
        );
      }
      final sizeAnalyzer = SizeAnalyzer(
        fileSystem: fs,
        logger: logger,
        analytics: analytics,
        appFilenamePattern: result.aotSnapshotFileName,
      );
      final Map<String, Object?> output = await sizeAnalyzer.analyzeAotSnapshot(
        aotSnapshot: codeSizeFile,
        outputDirectory: bundleDir,
        precompilerTrace: precompilerTrace,
        type: target.name,
      );
      final fileSystemUtils = FileSystemUtils(fileSystem: fs, platform: platform);
      final File outputFile = fileSystemUtils.getUniqueFile(
        fs.directory(fileSystemUtils.homeDirPath).childDirectory('.flutter-devtools'),
        '$analysisPlatform-code-size-analysis',
        'json',
      )..writeAsStringSync(jsonEncode(output));
      logger.printStatus(
        'A summary of your ${target.name} bundle analysis can be found at: ${outputFile.path}',
      );
      logger.printStatus(
        '\nTo analyze your app size in Dart DevTools, run the following command:\n'
        'dart devtools --appSizeBase=${outputFile.path}',
      );
    }

    return FlutterCommandResult.success();
  }

  static bool _containsFileNamed(Directory directory, String fileName) {
    if (!directory.existsSync()) {
      return false;
    }
    for (final FileSystemEntity entity in directory.listSync(recursive: true, followLinks: false)) {
      if (entity is File && entity.basename == fileName) {
        return true;
      }
    }
    return false;
  }
}
