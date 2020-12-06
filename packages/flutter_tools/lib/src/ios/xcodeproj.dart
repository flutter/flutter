// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flutter_manifest.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';

final RegExp _settingExpr = RegExp(r'(\w+)\s*=\s*(.*)$');
final RegExp _varExpr = RegExp(r'\$\(([^)]*)\)');

String flutterFrameworkDir(BuildMode mode) {
  return globals.fs.path.normalize(globals.fs.path.dirname(globals.artifacts.getArtifactPath(
      Artifact.flutterFramework, platform: TargetPlatform.ios, mode: mode)));
}

String flutterMacOSFrameworkDir(BuildMode mode) {
  return globals.fs.path.normalize(globals.fs.path.dirname(globals.artifacts.getArtifactPath(
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
    buildDirOverride: buildDirOverride,
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
  for (final String line in xcodeBuildSettings) {
    localsBuffer.writeln('export "$line"');
  }

  final File generatedModuleBuildPhaseScript = useMacOSConfig
    ? project.macos.generatedEnvironmentVariableExportScript
    : project.ios.generatedEnvironmentVariableExportScript;
  generatedModuleBuildPhaseScript.createSync(recursive: true);
  generatedModuleBuildPhaseScript.writeAsStringSync(localsBuffer.toString());
  globals.os.chmod(generatedModuleBuildPhaseScript, '755');
}

/// Build name parsed and validated from build info and manifest. Used for CFBundleShortVersionString.
String parsedBuildName({
  @required FlutterManifest manifest,
  @required BuildInfo buildInfo,
}) {
  final String buildNameToParse = buildInfo?.buildName ?? manifest.buildName;
  return validatedBuildNameForPlatform(TargetPlatform.ios, buildNameToParse, globals.logger);
}

/// Build number parsed and validated from build info and manifest. Used for CFBundleVersion.
String parsedBuildNumber({
  @required FlutterManifest manifest,
  @required BuildInfo buildInfo,
}) {
  String buildNumberToParse = buildInfo?.buildNumber ?? manifest.buildNumber;
  final String buildNumber = validatedBuildNumberForPlatform(
    TargetPlatform.ios,
    buildNumberToParse,
    globals.logger,
  );
  if (buildNumber != null && buildNumber.isNotEmpty) {
    return buildNumber;
  }
  // Drop back to parsing build name if build number is not present. Build number is optional in the manifest, but
  // FLUTTER_BUILD_NUMBER is required as the backing value for the required CFBundleVersion.
  buildNumberToParse = buildInfo?.buildName ?? manifest.buildName;
  return validatedBuildNumberForPlatform(
    TargetPlatform.ios,
    buildNumberToParse,
    globals.logger,
  );
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

  final String flutterRoot = globals.fs.path.normalize(Cache.flutterRoot);
  xcodeBuildSettings.add('FLUTTER_ROOT=$flutterRoot');

  // This holds because requiresProjectRoot is true for this command
  xcodeBuildSettings.add('FLUTTER_APPLICATION_PATH=${globals.fs.path.normalize(project.directory.path)}');

  // Relative to FLUTTER_APPLICATION_PATH, which is [Directory.current].
  if (targetOverride != null) {
    xcodeBuildSettings.add('FLUTTER_TARGET=$targetOverride');
  }

  // The build outputs directory, relative to FLUTTER_APPLICATION_PATH.
  xcodeBuildSettings.add('FLUTTER_BUILD_DIR=${buildDirOverride ?? getBuildDirectory()}');

  if (setSymroot) {
    xcodeBuildSettings.add('SYMROOT=\${SOURCE_ROOT}/../${getIosBuildDirectory()}');
  }

  // iOS does not link on Flutter in any build phase. Add the linker flag.
  if (!useMacOSConfig) {
    xcodeBuildSettings.add('OTHER_LDFLAGS=\$(inherited) -framework Flutter');
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


  final String buildName = parsedBuildName(manifest: project.manifest, buildInfo: buildInfo) ?? '1.0.0';
  xcodeBuildSettings.add('FLUTTER_BUILD_NAME=$buildName');

  final String buildNumber = parsedBuildNumber(manifest: project.manifest, buildInfo: buildInfo) ?? '1';
  xcodeBuildSettings.add('FLUTTER_BUILD_NUMBER=$buildNumber');

  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    xcodeBuildSettings.add('FLUTTER_ENGINE=${globals.fs.path.dirname(globals.fs.path.dirname(engineOutPath))}');
    xcodeBuildSettings.add('LOCAL_ENGINE=${globals.fs.path.basename(engineOutPath)}');

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

  for (final MapEntry<String, String> config in buildInfo.toEnvironmentConfig().entries) {
    xcodeBuildSettings.add('${config.key}=${config.value}');
  }
  return xcodeBuildSettings;
}

/// Interpreter of Xcode projects.
class XcodeProjectInterpreter {
  XcodeProjectInterpreter({
    @required Platform platform,
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Terminal terminal,
    @required Usage usage,
  }) : _platform = platform,
      _fileSystem = fileSystem,
      _terminal = terminal,
      _logger = logger,
      _processUtils = ProcessUtils(logger: logger, processManager: processManager),
      _usage = usage;

  final Platform _platform;
  final FileSystem _fileSystem;
  final ProcessUtils _processUtils;
  final Terminal _terminal;
  final Logger _logger;
  final Usage _usage;

  static const String _executable = '/usr/bin/xcodebuild';
  static final RegExp _versionRegex = RegExp(r'Xcode ([0-9.]+)');

  void _updateVersion() {
    if (!_platform.isMacOS || !_fileSystem.file(_executable).existsSync()) {
      return;
    }
    try {
      if (_versionText == null) {
        final RunResult result = _processUtils.runSync(
          <String>[_executable, '-version'],
        );
        if (result.exitCode != 0) {
          return;
        }
        _versionText = result.stdout.trim().replaceAll('\n', ', ');
      }
      final Match match = _versionRegex.firstMatch(versionText);
      if (match == null) {
        return;
      }
      final String version = match.group(1);
      final List<String> components = version.split('.');
      _majorVersion = int.parse(components[0]);
      _minorVersion = components.length < 2 ? 0 : int.parse(components[1]);
      _patchVersion = components.length < 3 ? 0 : int.parse(components[2]);
    } on ProcessException {
      // Ignored, leave values null.
    }
  }

  bool get isInstalled => majorVersion != null;

  String _versionText;
  String get versionText {
    if (_versionText == null) {
      _updateVersion();
    }
    return _versionText;
  }

  int _majorVersion;
  int get majorVersion {
    if (_majorVersion == null) {
      _updateVersion();
    }
    return _majorVersion;
  }

  int _minorVersion;
  int get minorVersion {
    if (_minorVersion == null) {
      _updateVersion();
    }
    return _minorVersion;
  }

  int _patchVersion;
  int get patchVersion {
    if (_patchVersion == null) {
      _updateVersion();
    }
    return _patchVersion;
  }

  /// Asynchronously retrieve xcode build settings. This one is preferred for
  /// new call-sites.
  ///
  /// If [scheme] is null, xcodebuild will return build settings for the first discovered
  /// target (by default this is Runner).
  Future<Map<String, String>> getBuildSettings(
    String projectPath, {
    String scheme,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    final Status status = Status.withSpinner(
      timeout: const TimeoutConfiguration().fastOperation,
      timeoutConfiguration: const TimeoutConfiguration(),
      stopwatch: Stopwatch(),
      terminal: _terminal,
    );
    final List<String> showBuildSettingsCommand = <String>[
      _executable,
      '-project',
      _fileSystem.path.absolute(projectPath),
      if (scheme != null)
        ...<String>['-scheme', scheme],
      '-showBuildSettings',
      ...environmentVariablesAsXcodeBuildSettings(_platform)
    ];
    try {
      // showBuildSettings is reported to occasionally timeout. Here, we give it
      // a lot of wiggle room (locally on Flutter Gallery, this takes ~1s).
      // When there is a timeout, we retry once.
      final RunResult result = await _processUtils.run(
        showBuildSettingsCommand,
        throwOnError: true,
        workingDirectory: projectPath,
        timeout: timeout,
        timeoutRetries: 1,
      );
      final String out = result.stdout.trim();
      return parseXcodeBuildSettings(out);
    } on Exception catch (error) {
      if (error is ProcessException && error.toString().contains('timed out')) {
        BuildEvent('xcode-show-build-settings-timeout',
          command: showBuildSettingsCommand.join(' '),
          flutterUsage: _usage,
        ).send();
      }
      _logger.printTrace('Unexpected failure to get the build settings: $error.');
      return const <String, String>{};
    } finally {
      status.stop();
    }
  }

  Future<void> cleanWorkspace(String workspacePath, String scheme, { bool verbose = false }) async {
    await _processUtils.run(<String>[
      _executable,
      '-workspace',
      workspacePath,
      '-scheme',
      scheme,
      if (!verbose)
        '-quiet',
      'clean',
      ...environmentVariablesAsXcodeBuildSettings(_platform)
    ], workingDirectory: _fileSystem.currentDirectory.path);
  }

  Future<XcodeProjectInfo> getInfo(String projectPath, {String projectFilename}) async {
    // The exit code returned by 'xcodebuild -list' when either:
    // * -project is passed and the given project isn't there, or
    // * no -project is passed and there isn't a project.
    const int missingProjectExitCode = 66;
    final RunResult result = await _processUtils.run(
      <String>[
        _executable,
        '-list',
        if (projectFilename != null) ...<String>['-project', projectFilename],
      ],
      throwOnError: true,
      allowedFailures: (int c) => c == missingProjectExitCode,
      workingDirectory: projectPath,
    );
    if (result.exitCode == missingProjectExitCode) {
      throwToolExit('Unable to get Xcode project information:\n ${result.stderr}');
    }
    return XcodeProjectInfo.fromXcodeBuildOutput(result.toString(), _logger);
  }
}

/// Environment variables prefixed by FLUTTER_XCODE_ will be passed as build configurations to xcodebuild.
/// This allows developers to pass arbitrary build settings in without the tool needing to make a flag
/// for or be aware of each one. This could be used to set code signing build settings in a CI
/// environment without requiring settings changes in the Xcode project.
List<String> environmentVariablesAsXcodeBuildSettings(Platform platform) {
  const String xcodeBuildSettingPrefix = 'FLUTTER_XCODE_';
  return platform.environment.entries.where((MapEntry<String, String> mapEntry) {
    return mapEntry.key.startsWith(xcodeBuildSettingPrefix);
  }).expand<String>((MapEntry<String, String> mapEntry) {
    // Remove FLUTTER_XCODE_ prefix from the environment variable to get the build setting.
    final String trimmedBuildSettingKey = mapEntry.key.substring(xcodeBuildSettingPrefix.length);
    return <String>['$trimmedBuildSettingKey=${mapEntry.value}'];
  }).toList();
}

Map<String, String> parseXcodeBuildSettings(String showBuildSettingsOutput) {
  final Map<String, String> settings = <String, String>{};
  for (final Match match in showBuildSettingsOutput.split('\n').map<Match>(_settingExpr.firstMatch)) {
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
  if (matches.isEmpty) {
    return str;
  }

  return str.replaceAllMapped(_varExpr, (Match m) => xcodeBuildSettings[m[1]] ?? m[0]);
}

/// Information about an Xcode project.
///
/// Represents the output of `xcodebuild -list`.
class XcodeProjectInfo {
  XcodeProjectInfo(
    this.targets,
    this.buildConfigurations,
    this.schemes,
    Logger logger
  ) : _logger = logger;

  factory XcodeProjectInfo.fromXcodeBuildOutput(String output, Logger logger) {
    final List<String> targets = <String>[];
    final List<String> buildConfigurations = <String>[];
    final List<String> schemes = <String>[];
    List<String> collector;
    for (final String line in output.split('\n')) {
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
    if (schemes.isEmpty) {
      schemes.add('Runner');
    }
    return XcodeProjectInfo(targets, buildConfigurations, schemes, logger);
  }

  final List<String> targets;
  final List<String> buildConfigurations;
  final List<String> schemes;
  final Logger _logger;

  bool get definesCustomSchemes => !(schemes.contains('Runner') && schemes.length == 1);

  /// The expected scheme for [buildInfo].
  @visibleForTesting
  static String expectedSchemeFor(BuildInfo buildInfo) {
    return toTitleCase(buildInfo?.flavor ?? 'runner');
  }

  /// The expected build configuration for [buildInfo] and [scheme].
  static String expectedBuildConfigurationFor(BuildInfo buildInfo, String scheme) {
    final String baseConfiguration = _baseConfigurationFor(buildInfo);
    if (buildInfo.flavor == null) {
      return baseConfiguration;
    }
    return baseConfiguration + '-$scheme';
  }

  /// Checks whether the [buildConfigurations] contains the specified string, without
  /// regard to case.
  bool hasBuildConfiguratinForBuildMode(String buildMode) {
    buildMode = buildMode.toLowerCase();
    for (final String name in buildConfigurations) {
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
    if (schemes.contains(expectedScheme)) {
      return expectedScheme;
    }
    return _uniqueMatch(schemes, (String candidate) {
      return candidate.toLowerCase() == expectedScheme.toLowerCase();
    });
  }

  void reportFlavorNotFoundAndExit() {
    _logger.printError('');
    if (definesCustomSchemes) {
      _logger.printError('The Xcode project defines schemes: ${schemes.join(', ')}');
      throwToolExit('You must specify a --flavor option to select one of the available schemes.');
    } else {
      throwToolExit('The Xcode project does not define custom schemes. You cannot use the --flavor option.');
    }
  }

  /// Returns unique build configuration matching [buildInfo] and [scheme], or
  /// null, if there is no unique best match.
  String buildConfigurationFor(BuildInfo buildInfo, String scheme) {
    final String expectedConfiguration = expectedBuildConfigurationFor(buildInfo, scheme);
    if (hasBuildConfiguratinForBuildMode(expectedConfiguration)) {
      return expectedConfiguration;
    }
    final String baseConfiguration = _baseConfigurationFor(buildInfo);
    return _uniqueMatch(buildConfigurations, (String candidate) {
      candidate = candidate.toLowerCase();
      if (buildInfo.flavor == null) {
        return candidate == expectedConfiguration.toLowerCase();
      }
      return candidate.contains(baseConfiguration.toLowerCase()) && candidate.contains(scheme.toLowerCase());
    });
  }

  static String _baseConfigurationFor(BuildInfo buildInfo) {
    if (buildInfo.isDebug) {
      return 'Debug';
    }
    if (buildInfo.isProfile) {
      return 'Profile';
    }
    return 'Release';
  }

  static String _uniqueMatch(Iterable<String> strings, bool matches(String s)) {
    final List<String> options = strings.where(matches).toList();
    if (options.length == 1) {
      return options.first;
    }
    return null;
  }

  @override
  String toString() {
    return 'XcodeProjectInfo($targets, $buildConfigurations, $schemes)';
  }
}
