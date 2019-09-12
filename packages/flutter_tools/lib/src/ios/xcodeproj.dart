// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';

final RegExp _settingExpr = RegExp(r'(\w+)\s*=\s*(.*)$');
final RegExp _varExpr = RegExp(r'\$\(([^)]*)\)');

String flutterFrameworkDir(BuildMode mode) {
  return fs.path.normalize(fs.path.dirname(artifacts.getArtifactPath(
      Artifact.flutterFramework, platform: TargetPlatform.ios, mode: mode)));
}

String flutterMacOSFrameworkDir(BuildMode mode) {
  return fs.path.normalize(fs.path.dirname(artifacts.getArtifactPath(
      Artifact.flutterMacOSFramework, platform: TargetPlatform.darwin_x64, mode: mode)));
}

/// Writes or rewrites Xcode property files with the specified information.
///
/// useMacOSConfig: Optional parameter that controls whether we use the macOS
/// project file instead. Defaults to false.
///
/// setSymroot: Optional parameter to control whether to set SYMROOT.
///
/// targetOverride: Optional parameter, if null or unspecified the default value
/// from xcode_backend.sh is used 'lib/main.dart'.
Future<void> updateGeneratedXcodeProperties({
  @required FlutterProject project,
  @required BuildInfo buildInfo,
  String targetOverride,
  bool useMacOSConfig = false,
  bool setSymroot = true,
  String buildDirOverride,
}) async {
  final List<String> xcodeBuildSettings = _xcodeBuildSettingsLines(
    project: project,
    buildInfo: buildInfo,
    targetOverride: targetOverride,
    useMacOSConfig: useMacOSConfig,
    setSymroot: setSymroot,
    buildDirOverride: buildDirOverride
  );

  _updateGeneratedXcodePropertiesFile(
    project: project,
    xcodeBuildSettings: xcodeBuildSettings,
    useMacOSConfig: useMacOSConfig,
  );

  _updateGeneratedEnvironmentVariablesScript(
    project: project,
    xcodeBuildSettings: xcodeBuildSettings,
    useMacOSConfig: useMacOSConfig,
  );
}

/// Generate a xcconfig file to inherit FLUTTER_ build settings
/// for Xcode targets that need them.
/// See [XcodeBasedProject.generatedXcodePropertiesFile].
void _updateGeneratedXcodePropertiesFile({
  @required FlutterProject project,
  @required List<String> xcodeBuildSettings,
  bool useMacOSConfig = false,
}) {
  final StringBuffer localsBuffer = StringBuffer();

  localsBuffer.writeln('// This is a generated file; do not edit or check into version control.');
  xcodeBuildSettings.forEach(localsBuffer.writeln);
  final File generatedXcodePropertiesFile = useMacOSConfig
    ? project.macos.generatedXcodePropertiesFile
    : project.ios.generatedXcodePropertiesFile;

  generatedXcodePropertiesFile.createSync(recursive: true);
  generatedXcodePropertiesFile.writeAsStringSync(localsBuffer.toString());
}

/// Generate a script to export all the FLUTTER_ environment variables needed
/// as flags for Flutter tools.
/// See [XcodeBasedProject.generatedEnvironmentVariableExportScript].
void _updateGeneratedEnvironmentVariablesScript({
  @required FlutterProject project,
  @required List<String> xcodeBuildSettings,
  bool useMacOSConfig = false,
}) {
  final StringBuffer localsBuffer = StringBuffer();

  localsBuffer.writeln('#!/bin/sh');
  localsBuffer.writeln('# This is a generated file; do not edit or check into version control.');
  for (String line in xcodeBuildSettings) {
    localsBuffer.writeln('export "$line"');
  }

  final File generatedModuleBuildPhaseScript = useMacOSConfig
    ? project.macos.generatedEnvironmentVariableExportScript
    : project.ios.generatedEnvironmentVariableExportScript;
  generatedModuleBuildPhaseScript.createSync(recursive: true);
  generatedModuleBuildPhaseScript.writeAsStringSync(localsBuffer.toString());
  os.chmod(generatedModuleBuildPhaseScript, '755');
}

/// List of lines of build settings. Example: 'FLUTTER_BUILD_DIR=build'
List<String> _xcodeBuildSettingsLines({
  @required FlutterProject project,
  @required BuildInfo buildInfo,
  String targetOverride,
  bool useMacOSConfig = false,
  bool setSymroot = true,
  String buildDirOverride,
}) {
  final List<String> xcodeBuildSettings = <String>[];

  final String flutterRoot = fs.path.normalize(Cache.flutterRoot);
  xcodeBuildSettings.add('FLUTTER_ROOT=$flutterRoot');

  // This holds because requiresProjectRoot is true for this command
  xcodeBuildSettings.add('FLUTTER_APPLICATION_PATH=${fs.path.normalize(project.directory.path)}');

  // Relative to FLUTTER_APPLICATION_PATH, which is [Directory.current].
  if (targetOverride != null)
    xcodeBuildSettings.add('FLUTTER_TARGET=$targetOverride');

  // The build outputs directory, relative to FLUTTER_APPLICATION_PATH.
  xcodeBuildSettings.add('FLUTTER_BUILD_DIR=${buildDirOverride ?? getBuildDirectory()}');

  if (setSymroot) {
    xcodeBuildSettings.add('SYMROOT=\${SOURCE_ROOT}/../${getIosBuildDirectory()}');
  }

  if (!project.isModule) {
    // For module projects we do not want to write the FLUTTER_FRAMEWORK_DIR
    // explicitly. Rather we rely on the xcode backend script and the Podfile
    // logic to derive it from FLUTTER_ROOT and FLUTTER_BUILD_MODE.
    // However, this is necessary for regular projects using Cocoapods.
    final String frameworkDir = useMacOSConfig
      ? flutterMacOSFrameworkDir(buildInfo.mode)
      : flutterFrameworkDir(buildInfo.mode);
    xcodeBuildSettings.add('FLUTTER_FRAMEWORK_DIR=$frameworkDir');
  }

  final String buildNameToParse = buildInfo?.buildName ?? project.manifest.buildName;
  final String buildName = validatedBuildNameForPlatform(TargetPlatform.ios, buildNameToParse);
  if (buildName != null) {
    xcodeBuildSettings.add('FLUTTER_BUILD_NAME=$buildName');
  }

  String buildNumber = validatedBuildNumberForPlatform(TargetPlatform.ios, buildInfo?.buildNumber ?? project.manifest.buildNumber);
  // Drop back to parsing build name if build number is not present. Build number is optional in the manifest, but
  // FLUTTER_BUILD_NUMBER is required as the backing value for the required CFBundleVersion.
  buildNumber ??= validatedBuildNumberForPlatform(TargetPlatform.ios, buildNameToParse);

  if (buildNumber != null) {
    xcodeBuildSettings.add('FLUTTER_BUILD_NUMBER=$buildNumber');
  }

  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    xcodeBuildSettings.add('FLUTTER_ENGINE=${fs.path.dirname(fs.path.dirname(engineOutPath))}');
    xcodeBuildSettings.add('LOCAL_ENGINE=${fs.path.basename(engineOutPath)}');

    // Tell Xcode not to build universal binaries for local engines, which are
    // single-architecture.
    //
    // NOTE: this assumes that local engine binary paths are consistent with
    // the conventions uses in the engine: 32-bit iOS engines are built to
    // paths ending in _arm, 64-bit builds are not.
    //
    // Skip this step for macOS builds.
    if (!useMacOSConfig) {
      final String arch = engineOutPath.endsWith('_arm') ? 'armv7' : 'arm64';
      xcodeBuildSettings.add('ARCHS=$arch');
    }
  }

  if (buildInfo.trackWidgetCreation) {
    xcodeBuildSettings.add('TRACK_WIDGET_CREATION=true');
  }

  return xcodeBuildSettings;
}

XcodeProjectInterpreter get xcodeProjectInterpreter => context.get<XcodeProjectInterpreter>();

/// Interpreter of Xcode projects.
class XcodeProjectInterpreter {
  static const String _executable = '/usr/bin/xcodebuild';
  static final RegExp _versionRegex = RegExp(r'Xcode ([0-9.]+)');

  void _updateVersion() {
    if (!platform.isMacOS || !fs.file(_executable).existsSync()) {
      return;
    }
    try {
      final RunResult result = processUtils.runSync(
        <String>[_executable, '-version'],
      );
      if (result.exitCode != 0) {
        return;
      }
      _versionText = result.stdout.trim().replaceAll('\n', ', ');
      final Match match = _versionRegex.firstMatch(versionText);
      if (match == null)
        return;
      final String version = match.group(1);
      final List<String> components = version.split('.');
      _majorVersion = int.parse(components[0]);
      _minorVersion = components.length == 1 ? 0 : int.parse(components[1]);
    } on ProcessException {
      // Ignored, leave values null.
    }
  }

  bool get isInstalled => majorVersion != null;

  String _versionText;
  String get versionText {
    if (_versionText == null)
      _updateVersion();
    return _versionText;
  }

  int _majorVersion;
  int get majorVersion {
    if (_majorVersion == null)
      _updateVersion();
    return _majorVersion;
  }

  int _minorVersion;
  int get minorVersion {
    if (_minorVersion == null)
      _updateVersion();
    return _minorVersion;
  }

  /// Synchronously retrieve xcode build settings. Prefer using the async
  /// version below.
  Map<String, String> getBuildSettings(String projectPath, String target) {
    try {
      final String out = processUtils.runSync(
        <String>[
          _executable,
          '-project',
          fs.path.absolute(projectPath),
          '-target',
          target,
          '-showBuildSettings',
        ],
        throwOnError: true,
        workingDirectory: projectPath,
      ).stdout.trim();
      return parseXcodeBuildSettings(out);
    } on ProcessException catch (error) {
      printTrace('Unexpected failure to get the build settings: $error.');
      return const <String, String>{};
    }
  }

  /// Asynchronously retrieve xcode build settings. This one is preferred for
  /// new call-sites.
  Future<Map<String, String>> getBuildSettingsAsync(
      String projectPath, String target, {
    Duration timeout = const Duration(minutes: 1),
  }) async {
    final Status status = Status.withSpinner(
      timeout: timeoutConfiguration.fastOperation,
    );
    final List<String> showBuildSettingsCommand = <String>[
      _executable,
      '-project',
      fs.path.absolute(projectPath),
      '-target',
      target,
      '-showBuildSettings',
    ];
    try {
      // showBuildSettings is reported to ocassionally timeout. Here, we give it
      // a lot of wiggle room (locally on Flutter Gallery, this takes ~1s).
      // When there is a timeout, we retry once.
      final RunResult result = await processUtils.run(
        showBuildSettingsCommand,
        throwOnError: true,
        workingDirectory: projectPath,
        timeout: timeout,
        timeoutRetries: 1,
      );
      final String out = result.stdout.trim();
      return parseXcodeBuildSettings(out);
    } catch(error) {
      if (error is ProcessException && error.toString().contains('timed out')) {
        BuildEvent('xcode-show-build-settings-timeout',
          command: showBuildSettingsCommand.join(' '),
        ).send();
      }
      printTrace('Unexpected failure to get the build settings: $error.');
      return const <String, String>{};
    } finally {
      status.stop();
    }
  }

  void cleanWorkspace(String workspacePath, String scheme) {
    processUtils.runSync(<String>[
      _executable,
      '-workspace',
      workspacePath,
      '-scheme',
      scheme,
      '-quiet',
      'clean'
    ], workingDirectory: fs.currentDirectory.path);
  }

  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    final RunResult result = await processUtils.run(
      <String>[
        _executable,
        '-list',
        if (projectFilename != null) ...<String>['-project', projectFilename],
      ],
      throwOnError: true,
      workingDirectory: projectPath,
    );
    return XcodeProjectInfo.fromXcodeBuildOutput(result.toString());
  }
}

Map<String, String> parseXcodeBuildSettings(String showBuildSettingsOutput) {
  final Map<String, String> settings = <String, String>{};
  for (Match match in showBuildSettingsOutput.split('\n').map<Match>(_settingExpr.firstMatch)) {
    if (match != null) {
      settings[match[1]] = match[2];
    }
  }
  return settings;
}

/// Substitutes variables in [str] with their values from the specified Xcode
/// project and target.
String substituteXcodeVariables(String str, Map<String, String> xcodeBuildSettings) {
  final Iterable<Match> matches = _varExpr.allMatches(str);
  if (matches.isEmpty)
    return str;

  return str.replaceAllMapped(_varExpr, (Match m) => xcodeBuildSettings[m[1]] ?? m[0]);
}

/// Information about an Xcode project.
///
/// Represents the output of `xcodebuild -list`.
class XcodeProjectInfo {
  XcodeProjectInfo(this.targets, this.buildConfigurations, this.schemes);

  factory XcodeProjectInfo.fromXcodeBuildOutput(String output) {
    final List<String> targets = <String>[];
    final List<String> buildConfigurations = <String>[];
    final List<String> schemes = <String>[];
    List<String> collector;
    for (String line in output.split('\n')) {
      if (line.isEmpty) {
        collector = null;
        continue;
      } else if (line.endsWith('Targets:')) {
        collector = targets;
        continue;
      } else if (line.endsWith('Build Configurations:')) {
        collector = buildConfigurations;
        continue;
      } else if (line.endsWith('Schemes:')) {
        collector = schemes;
        continue;
      }
      collector?.add(line.trim());
    }
    if (schemes.isEmpty)
      schemes.add('Runner');
    return XcodeProjectInfo(targets, buildConfigurations, schemes);
  }

  final List<String> targets;
  final List<String> buildConfigurations;
  final List<String> schemes;

  bool get definesCustomTargets => !(targets.contains('Runner') && targets.length == 1);
  bool get definesCustomSchemes => !(schemes.contains('Runner') && schemes.length == 1);
  bool get definesCustomBuildConfigurations {
    return !(buildConfigurations.contains('Debug') &&
        buildConfigurations.contains('Release') &&
        buildConfigurations.length == 2);
  }

  /// The expected scheme for [buildInfo].
  static String expectedSchemeFor(BuildInfo buildInfo) {
    return toTitleCase(buildInfo.flavor ?? 'runner');
  }

  /// The expected build configuration for [buildInfo] and [scheme].
  static String expectedBuildConfigurationFor(BuildInfo buildInfo, String scheme) {
    final String baseConfiguration = _baseConfigurationFor(buildInfo);
    if (buildInfo.flavor == null)
      return baseConfiguration;
    else
      return baseConfiguration + '-$scheme';
  }

  /// Checks whether the [buildConfigurations] contains the specified string, without
  /// regard to case.
  bool hasBuildConfiguratinForBuildMode(String buildMode) {
    buildMode = buildMode.toLowerCase();
    for (String name in buildConfigurations) {
      if (name.toLowerCase() == buildMode) {
        return true;
      }
    }
    return false;
  }
  /// Returns unique scheme matching [buildInfo], or null, if there is no unique
  /// best match.
  String schemeFor(BuildInfo buildInfo) {
    final String expectedScheme = expectedSchemeFor(buildInfo);
    if (schemes.contains(expectedScheme))
      return expectedScheme;
    return _uniqueMatch(schemes, (String candidate) {
      return candidate.toLowerCase() == expectedScheme.toLowerCase();
    });
  }

  /// Returns unique build configuration matching [buildInfo] and [scheme], or
  /// null, if there is no unique best match.
  String buildConfigurationFor(BuildInfo buildInfo, String scheme) {
    final String expectedConfiguration = expectedBuildConfigurationFor(buildInfo, scheme);
    if (hasBuildConfiguratinForBuildMode(expectedConfiguration))
      return expectedConfiguration;
    final String baseConfiguration = _baseConfigurationFor(buildInfo);
    return _uniqueMatch(buildConfigurations, (String candidate) {
      candidate = candidate.toLowerCase();
      if (buildInfo.flavor == null)
        return candidate == expectedConfiguration.toLowerCase();
      else
        return candidate.contains(baseConfiguration.toLowerCase()) && candidate.contains(scheme.toLowerCase());
    });
  }

  static String _baseConfigurationFor(BuildInfo buildInfo) {
    if (buildInfo.isDebug)
      return 'Debug';
    if (buildInfo.isProfile)
      return 'Profile';
    return 'Release';
  }

  static String _uniqueMatch(Iterable<String> strings, bool matches(String s)) {
    final List<String> options = strings.where(matches).toList();
    if (options.length == 1)
      return options.first;
    else
      return null;
  }

  @override
  String toString() {
    return 'XcodeProjectInfo($targets, $buildConfigurations, $schemes)';
  }
}
