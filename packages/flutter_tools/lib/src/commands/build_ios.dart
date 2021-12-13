// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/application_package.dart';
import '../ios/mac.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host.
class BuildIOSCommand extends _BuildIOSSubCommand {
  BuildIOSCommand({ @required bool verboseHelp }) : super(verboseHelp: verboseHelp) {
    argParser
      ..addFlag('config-only',
        help: 'Update the project configuration without performing a build. '
          'This can be used in CI/CD process that create an archive to avoid '
          'performing duplicate work.'
      )
      ..addFlag('simulator',
        help: 'Build for the iOS simulator instead of the device. This changes '
          'the default build mode to debug if otherwise unspecified.',
      )
      ..addFlag('codesign',
        defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).',
      );
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  @override
  final XcodeBuildAction xcodeBuildAction = XcodeBuildAction.build;

  @override
  EnvironmentType get environmentType => boolArg('simulator') ? EnvironmentType.simulator : EnvironmentType.physical;

  @override
  bool get configOnly => boolArg('config-only');

  @override
  bool get shouldCodesign => boolArg('codesign');

  @override
  Directory _outputAppDirectory(String xcodeResultOutput) => globals.fs.directory(xcodeResultOutput).parent;
}

/// Builds an .xcarchive and optionally .ipa for an iOS app to be generated for
/// App Store submission.
///
/// Can only be run on a macOS host.
class BuildIOSArchiveCommand extends _BuildIOSSubCommand {
  BuildIOSArchiveCommand({@required bool verboseHelp})
      : super(verboseHelp: verboseHelp) {
    argParser.addOption(
      'export-options-plist',
      valueHelp: 'ExportOptions.plist',
      // TODO(jmagman): Update help text with link to Flutter docs.
      help:
          'Optionally export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys.',
    );
  }

  @override
  final String name = 'ipa';

  @override
  final List<String> aliases = <String>['xcarchive'];

  @override
  final String description = 'Build an iOS archive bundle (Mac OS X host only).';

  @override
  final XcodeBuildAction xcodeBuildAction = XcodeBuildAction.archive;

  @override
  final EnvironmentType environmentType = EnvironmentType.physical;

  @override
  final bool configOnly = false;

  @override
  final bool shouldCodesign = true;

  String get exportOptionsPlist => stringArg('export-options-plist');

  @override
  Directory _outputAppDirectory(String xcodeResultOutput) => globals.fs
      .directory(xcodeResultOutput)
      .childDirectory('Products')
      .childDirectory('Applications');

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (exportOptionsPlist != null) {
      final FileSystemEntityType type = globals.fs.typeSync(exportOptionsPlist);
      if (type == FileSystemEntityType.notFound) {
        throwToolExit(
            '"$exportOptionsPlist" property list does not exist.');
      } else if (type != FileSystemEntityType.file) {
        throwToolExit(
            '"$exportOptionsPlist" is not a file. See "xcodebuild -h" for available keys.');
      }
    }
    final FlutterCommandResult xcarchiveResult = await super.runCommand();
    final BuildInfo buildInfo = await getBuildInfo();
    displayNullSafetyMode(buildInfo);

    if (exportOptionsPlist == null) {
      return xcarchiveResult;
    }

    // xcarchive failed or not at expected location.
    if (xcarchiveResult.exitStatus != ExitStatus.success) {
      globals.printStatus('Skipping IPA');
      return xcarchiveResult;
    }

    // Build IPA from generated xcarchive.
    final BuildableIOSApp app = await buildableIOSApp(buildInfo);
    Status status;
    RunResult result;
    final String outputPath = globals.fs.path.absolute(app.ipaOutputPath);
    try {
      status = globals.logger.startProgress('Building IPA...');

      result = await globals.processUtils.run(
        <String>[
          ...globals.xcode.xcrunCommand(),
          'xcodebuild',
          '-exportArchive',
          if (shouldCodesign) ...<String>[
            '-allowProvisioningDeviceRegistration',
            '-allowProvisioningUpdates',
          ],
          '-archivePath',
          globals.fs.path.absolute(app.archiveBundleOutputPath),
          '-exportPath',
          outputPath,
          '-exportOptionsPlist',
          globals.fs.path.absolute(exportOptionsPlist),
        ],
      );
    } finally {
      status.stop();
    }

    if (result.exitCode != 0) {
      final StringBuffer errorMessage = StringBuffer();

      // "error:" prefixed lines are the nicely formatted error message, the
      // rest is the same message but printed as a IDEFoundationErrorDomain.
      // Example:
      // error: exportArchive: exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd
      // Error Domain=IDEFoundationErrorDomain Code=1 "exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd" ...
      LineSplitter.split(result.stderr)
          .where((String line) => line.contains('error: '))
          .forEach(errorMessage.writeln);
      throwToolExit('Encountered error while building IPA:\n$errorMessage');
    }

    globals.printStatus('Built IPA to $outputPath.');

    return FlutterCommandResult.success();
  }
}

abstract class _BuildIOSSubCommand extends BuildSubCommand {
  _BuildIOSSubCommand({
    @required bool verboseHelp
  }) : super(verboseHelp: verboseHelp) {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
  };

  XcodeBuildAction get xcodeBuildAction;
  EnvironmentType get environmentType;
  bool get configOnly;
  bool get shouldCodesign;

  Future<BuildableIOSApp> buildableIOSApp(BuildInfo buildInfo) async {
    _buildableIOSApp ??= await applicationPackages.getPackageForPlatform(
      TargetPlatform.ios,
      buildInfo: buildInfo,
    ) as BuildableIOSApp;
    return _buildableIOSApp;
  }

  BuildableIOSApp _buildableIOSApp;

  Directory _outputAppDirectory(String xcodeResultOutput);

  @override
  bool get supported => globals.platform.isMacOS;

  @override
  Future<FlutterCommandResult> runCommand() async {
    defaultBuildMode = environmentType == EnvironmentType.simulator ? BuildMode.debug : BuildMode.release;
    final BuildInfo buildInfo = await getBuildInfo();

    if (!supported) {
      throwToolExit('Building for iOS is only supported on macOS.');
    }
    if (environmentType == EnvironmentType.simulator && !buildInfo.supportsSimulator) {
      throwToolExit('${sentenceCase(buildInfo.friendlyModeName)} mode is not supported for simulators.');
    }
    if (configOnly && buildInfo.codeSizeDirectory != null) {
      throwToolExit('Cannot analyze code size without performing a full build.');
    }
    if (environmentType == EnvironmentType.physical && !shouldCodesign) {
      globals.printStatus(
        'Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.',
      );
    }

    final BuildableIOSApp app = await buildableIOSApp(buildInfo);

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final String logTarget = environmentType == EnvironmentType.simulator ? 'simulator' : 'device';
    final String typeName = globals.artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    if (xcodeBuildAction == XcodeBuildAction.build) {
      globals.printStatus('Building $app for $logTarget ($typeName)...');
    } else {
      globals.printStatus('Archiving $app...');
    }
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      environmentType: environmentType,
      codesign: shouldCodesign,
      configOnly: configOnly,
      buildAction: xcodeBuildAction,
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result, globals.flutterUsage, globals.logger);
      final String presentParticiple = xcodeBuildAction == XcodeBuildAction.build ? 'building' : 'archiving';
      throwToolExit('Encountered error while $presentParticiple for $logTarget.');
    }

    if (buildInfo.codeSizeDirectory != null) {
      final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        flutterUsage: globals.flutterUsage,
        appFilenamePattern: 'App'
      );
      // Only support 64bit iOS code size analysis.
      final String arch = getNameForDarwinArch(DarwinArch.arm64);
      final File aotSnapshot = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('snapshot.$arch.json');
      final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('trace.$arch.json');

      final Directory outputAppDirectoryCandidate = _outputAppDirectory(result.output);

      Directory appDirectory;
      if (outputAppDirectoryCandidate.existsSync()) {
        appDirectory = outputAppDirectoryCandidate.listSync()
            .whereType<Directory>()
            .firstWhere((Directory directory) {
          return globals.fs.path.extension(directory.path) == '.app';
        }, orElse: () => null);
      }
      if (appDirectory == null) {
        throwToolExit('Could not find app to analyze code size in ${outputAppDirectoryCandidate.path}');
      }
      final Map<String, Object> output = await sizeAnalyzer.analyzeAotSnapshot(
        aotSnapshot: aotSnapshot,
        precompilerTrace: precompilerTrace,
        outputDirectory: appDirectory,
        type: 'ios',
      );
      final File outputFile = globals.fsUtils.getUniqueFile(
        globals.fs
          .directory(globals.fsUtils.homeDirPath)
          .childDirectory('.flutter-devtools'), 'ios-code-size-analysis', 'json',
      )..writeAsStringSync(jsonEncode(output));
      // This message is used as a sentinel in analyze_apk_size_test.dart
      globals.printStatus(
        'A summary of your iOS bundle analysis can be found at: ${outputFile.path}',
      );

      // DevTools expects a file path relative to the .flutter-devtools/ dir.
      final String relativeAppSizePath = outputFile.path.split('.flutter-devtools/').last.trim();
      globals.printStatus(
        '\nTo analyze your app size in Dart DevTools, run the following command:\n'
        'flutter pub global activate devtools; flutter pub global run devtools '
        '--appSizeBase=$relativeAppSizePath'
      );
    }

    if (result.output != null) {
      globals.printStatus('Built ${result.output}.');

      return FlutterCommandResult.success();
    }

    return FlutterCommandResult.fail();
  }
}
