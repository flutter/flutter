// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// Builds an iOS .ipa package for App Store submission.
///
/// A wrapper around "xcodebuild -exportArchive". Can only be run on a macOS host.
class BuildIPACommand extends BuildSubCommand {
  BuildIPACommand({
    @visibleForTesting Platform platform,
    @visibleForTesting FileSystem fileSystem,
    @visibleForTesting Logger logger,
    @visibleForTesting ProcessManager processManager,
    @visibleForTesting XcodeProjectInterpreter xcodeProjectInterpreter,
  })  : _platform = platform,
        _xcodeProjectInterpreter = xcodeProjectInterpreter,
        _fileSystem = fileSystem,
        _logger = logger,
        _processUtils =
            ProcessUtils(processManager: processManager, logger: logger) {
    argParser.addOption(
      'export-options-plist',
      valueHelp: 'ExportOptions.plist',
      help:
          'Path to the "-exportOptionsPlist" file passed to Xcode. See "man xcodebuild" for available keys.',
    );
    // Flavors may have different target names, and therefore different archive output paths.
    usesFlavorOption();
  }

  Platform _platform;
  XcodeProjectInterpreter _xcodeProjectInterpreter;
  FileSystem _fileSystem;
  Logger _logger;
  ProcessUtils _processUtils;

  @override
  final String name = 'ipa';

  @override
  final String description =
      'Build an iOS App Store package after running "flutter build xcarchive" (Mac OS X host only).';

  String get exportOptionsPlist => stringArg('export-options-plist');

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Populate the "globals" that are not injected from tests.
    _platform ??= globals.platform;
    _xcodeProjectInterpreter ??= globals.xcodeProjectInterpreter;
    _fileSystem ??= globals.fs;
    _logger ??= globals.logger;
    _processUtils ??=
        ProcessUtils(processManager: globals.processManager, logger: _logger);

    if (!_platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on macOS.');
    }

    if (exportOptionsPlist == null) {
      throwToolExit(
          '--export-options-plist file is required. See "man xcodebuild" for available keys.');
    }

    final FileSystemEntityType type = _fileSystem.typeSync(exportOptionsPlist);
    if (type == FileSystemEntityType.notFound) {
      throwToolExit(
          '"$exportOptionsPlist" property list does not exist. See "man xcodebuild" for available keys.');
    } else if (type != FileSystemEntityType.file) {
      throwToolExit(
          '"$exportOptionsPlist" is not a file. See "man xcodebuild" for available keys.');
    }

    if (!_xcodeProjectInterpreter.isInstalled) {
      throwToolExit('Cannot find "xcodebuild". Run "flutter doctor".');
    }

    final BuildInfo buildInfo =
        getBuildInfo(forcedBuildMode: BuildMode.release);

    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(
      TargetPlatform.ios,
      buildInfo,
    ) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS.');
    }

    final String archiveBundleOutputPath =
        _fileSystem.path.absolute(app.archiveBundleOutputPath);
    if (!_fileSystem.directory(archiveBundleOutputPath).existsSync()) {
      final String flavorFlag =
          buildInfo.flavor == null ? '' : ' --flavor ${buildInfo.flavor}';
      throwToolExit('xcarchive not found at $archiveBundleOutputPath. '
          'Run "flutter build xcarchive$flavorFlag" to generate it.');
    }

    Status status;
    RunResult result;
    final String outputPath = _fileSystem.path.absolute(app.ipaOutputPath);
    try {
      status = _logger.startProgress('Building IPA...',
          timeout: timeoutConfiguration.slowOperation);
      result = await _processUtils.run(
        <String>[
          'xcrun',
          'xcodebuild',
          '-exportArchive',
          '-archivePath',
          archiveBundleOutputPath,
          '-exportPath',
          outputPath,
          '-exportOptionsPlist',
          exportOptionsPlist,
        ],
      );
    } finally {
      status.stop();
    }
    if (result.exitCode != 0) {
      final StringBuffer errorMessage = StringBuffer();

      // "error:" prefixed lines are the nicely formatted error message, the rest is the same message but printed as a IDEFoundationErrorDomain.
      // Example:
      // error: exportArchive: exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd
      // Error Domain=IDEFoundationErrorDomain Code=1 "exportOptionsPlist error for key 'method': expected one of {app-store, ad-hoc, enterprise, development, validation}, but found developmentasdasd" ...
      LineSplitter.split(result.stderr)
          .where((String line) => line.contains('error: '))
          .forEach(errorMessage.writeln);
      throwToolExit('Encountered error while building IPA:\n$errorMessage');
    }

    _logger.printStatus('Built IPA to $outputPath.');

    return FlutterCommandResult.success();
  }
}
