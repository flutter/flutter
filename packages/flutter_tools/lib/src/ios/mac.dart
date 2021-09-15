// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/project_migrator.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../flutter_manifest.dart';
import '../globals_null_migrated.dart' as globals;
import '../macos/cocoapod_utils.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'application_package.dart';
import 'code_signing.dart';
import 'iproxy.dart';
import 'migrations/deployment_target_migration.dart';
import 'migrations/project_base_configuration_migration.dart';
import 'migrations/project_build_location_migration.dart';
import 'migrations/remove_framework_link_and_embedding_migration.dart';
import 'migrations/xcode_build_system_migration.dart';
import 'xcode_build_settings.dart';
import 'xcodeproj.dart';

class IMobileDevice {
  IMobileDevice({
    required Artifacts artifacts,
    required Cache cache,
    required ProcessManager processManager,
    required Logger logger,
  }) : _idevicesyslogPath = artifacts.getHostArtifact(HostArtifact.idevicesyslog).path,
      _idevicescreenshotPath = artifacts.getHostArtifact(HostArtifact.idevicescreenshot).path,
      _dyLdLibEntry = cache.dyLdLibEntry,
      _processUtils = ProcessUtils(logger: logger, processManager: processManager),
      _processManager = processManager;

  final String _idevicesyslogPath;
  final String _idevicescreenshotPath;
  final MapEntry<String, String> _dyLdLibEntry;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  late final bool isInstalled = _processManager.canRun(_idevicescreenshotPath);

  /// Starts `idevicesyslog` and returns the running process.
  Future<Process> startLogger(String deviceID) {
    return _processUtils.start(
      <String>[
        _idevicesyslogPath,
        '-u',
        deviceID,
      ],
      environment: Map<String, String>.fromEntries(
        <MapEntry<String, String>>[_dyLdLibEntry]
      ),
    );
  }

  /// Captures a screenshot to the specified outputFile.
  Future<void> takeScreenshot(
    File outputFile,
    String deviceID,
    IOSDeviceConnectionInterface interfaceType,
  ) {
    return _processUtils.run(
      <String>[
        _idevicescreenshotPath,
        outputFile.path,
        '--udid',
        deviceID,
        if (interfaceType == IOSDeviceConnectionInterface.network)
          '--network',
      ],
      throwOnError: true,
      environment: Map<String, String>.fromEntries(
        <MapEntry<String, String>>[_dyLdLibEntry]
      ),
    );
  }
}

Future<XcodeBuildResult> buildXcodeProject({
  required BuildableIOSApp app,
  required BuildInfo buildInfo,
  required String targetOverride,
  EnvironmentType environmentType = EnvironmentType.physical,
  DarwinArch? activeArch,
  bool codesign = true,
  String? deviceID,
  bool configOnly = false,
  XcodeBuildAction buildAction = XcodeBuildAction.build,
}) async {
  if (!upgradePbxProjWithFlutterAssets(app.project, globals.logger)) {
    return XcodeBuildResult(success: false);
  }

  final List<ProjectMigrator> migrators = <ProjectMigrator>[
    RemoveFrameworkLinkAndEmbeddingMigration(app.project, globals.logger, globals.flutterUsage),
    XcodeBuildSystemMigration(app.project, globals.logger),
    ProjectBaseConfigurationMigration(app.project, globals.logger),
    ProjectBuildLocationMigration(app.project, globals.logger),
    DeploymentTargetMigration(app.project, globals.logger),
  ];

  final ProjectMigration migration = ProjectMigration(migrators);
  if (!migration.run()) {
    return XcodeBuildResult(success: false);
  }

  if (!_checkXcodeVersion()) {
    return XcodeBuildResult(success: false);
  }

  await removeFinderExtendedAttributes(app.project.parent.directory, globals.processUtils, globals.logger);

  final XcodeProjectInfo? projectInfo = await app.project.projectInfo();
  if (projectInfo == null) {
    globals.printError('Xcode project not found.');
    return XcodeBuildResult(success: false);
  }
  final String? scheme = projectInfo.schemeFor(buildInfo);
  if (scheme == null) {
    projectInfo.reportFlavorNotFoundAndExit();
  }
  final String? configuration = projectInfo.buildConfigurationFor(buildInfo, scheme);
  if (configuration == null) {
    globals.printError('');
    globals.printError('The Xcode project defines build configurations: ${projectInfo.buildConfigurations.join(', ')}');
    globals.printError('Flutter expects a build configuration named ${XcodeProjectInfo.expectedBuildConfigurationFor(buildInfo, scheme)} or similar.');
    globals.printError('Open Xcode to fix the problem:');
    globals.printError('  open ios/Runner.xcworkspace');
    globals.printError('1. Click on "Runner" in the project navigator.');
    globals.printError('2. Ensure the Runner PROJECT is selected, not the Runner TARGET.');
    if (buildInfo.isDebug) {
      globals.printError('3. Click the Editor->Add Configuration->Duplicate "Debug" Configuration.');
    } else {
      globals.printError('3. Click the Editor->Add Configuration->Duplicate "Release" Configuration.');
    }
    globals.printError('');
    globals.printError('   If this option is disabled, it is likely you have the target selected instead');
    globals.printError('   of the project; see:');
    globals.printError('   https://stackoverflow.com/questions/19842746/adding-a-build-configuration-in-xcode');
    globals.printError('');
    globals.printError('   If you have created a completely custom set of build configurations,');
    globals.printError('   you can set the FLUTTER_BUILD_MODE=${buildInfo.modeName.toLowerCase()}');
    globals.printError('   in the .xcconfig file for that configuration and run from Xcode.');
    globals.printError('');
    globals.printError('4. If you are not using completely custom build configurations, name the newly created configuration ${buildInfo.modeName}.');
    return XcodeBuildResult(success: false);
  }

  final FlutterManifest manifest = app.project.parent.manifest;
  final String? buildName = parsedBuildName(manifest: manifest, buildInfo: buildInfo);
  final bool buildNameIsMissing = buildName == null || buildName.isEmpty;

  if (buildNameIsMissing) {
    globals.printStatus('Warning: Missing build name (CFBundleShortVersionString).');
  }

  final String? buildNumber = parsedBuildNumber(manifest: manifest, buildInfo: buildInfo);
  final bool buildNumberIsMissing = buildNumber == null || buildNumber.isEmpty;

  if (buildNumberIsMissing) {
    globals.printStatus('Warning: Missing build number (CFBundleVersion).');
  }
  if (buildNameIsMissing || buildNumberIsMissing) {
    globals.printError('Action Required: You must set a build name and number in the pubspec.yaml '
      'file version field before submitting to the App Store.');
  }

  Map<String, String>? autoSigningConfigs;

  final Map<String, String> buildSettings = await app.project.buildSettingsForBuildInfo(
        buildInfo,
        environmentType: environmentType
      ) ?? <String, String>{};

  if (codesign && environmentType == EnvironmentType.physical) {
    autoSigningConfigs = await getCodeSigningIdentityDevelopmentTeam(
      buildSettings: buildSettings,
      processManager: globals.processManager,
      logger: globals.logger,
      config: globals.config,
      terminal: globals.terminal,
    );
  }

  final FlutterProject project = FlutterProject.current();
  await updateGeneratedXcodeProperties(
    project: project,
    targetOverride: targetOverride,
    buildInfo: buildInfo,
  );
  await processPodsIfNeeded(project.ios, getIosBuildDirectory(), buildInfo.mode);
  if (configOnly) {
    return XcodeBuildResult(success: true);
  }

  final List<String> buildCommands = <String>[
    ...globals.xcode!.xcrunCommand(),
    'xcodebuild',
    '-configuration',
    configuration,
  ];

  if (globals.logger.isVerbose) {
    // An environment variable to be passed to xcode_backend.sh determining
    // whether to echo back executed commands.
    buildCommands.add('VERBOSE_SCRIPT_LOGGING=YES');
  } else {
    // This will print warnings and errors only.
    buildCommands.add('-quiet');
  }

  if (autoSigningConfigs != null) {
    for (final MapEntry<String, String> signingConfig in autoSigningConfigs.entries) {
      buildCommands.add('${signingConfig.key}=${signingConfig.value}');
    }
    buildCommands.add('-allowProvisioningUpdates');
    buildCommands.add('-allowProvisioningDeviceRegistration');
  }

  final List<FileSystemEntity> contents = app.project.hostAppRoot.listSync();
  for (final FileSystemEntity entity in contents) {
    if (globals.fs.path.extension(entity.path) == '.xcworkspace') {
      buildCommands.addAll(<String>[
        '-workspace', globals.fs.path.basename(entity.path),
        '-scheme', scheme,
        if (buildAction != XcodeBuildAction.archive) // dSYM files aren't copied to the archive if BUILD_DIR is set.
          'BUILD_DIR=${globals.fs.path.absolute(getIosBuildDirectory())}',
      ]);
      break;
    }
  }

  // Check if the project contains a watchOS companion app.
  final bool hasWatchCompanion = await app.project.containsWatchCompanion(
    projectInfo.targets,
    buildInfo,
  );
  if (hasWatchCompanion) {
    // The -sdk argument has to be omitted if a watchOS companion app exists.
    // Otherwise the build will fail as WatchKit dependencies cannot be build using the iOS SDK.
    globals.printStatus('Watch companion app found. Adjusting build settings.');
    if (environmentType == EnvironmentType.simulator && (deviceID == null || deviceID == '')) {
      globals.printError('No simulator device ID has been set.');
      globals.printError('A device ID is required to build an app with a watchOS companion app.');
      globals.printError('Please run "flutter devices" to get a list of available device IDs');
      globals.printError('and specify one using the -d, --device-id flag.');
      return XcodeBuildResult(success: false);
    }
    if (environmentType == EnvironmentType.simulator) {
      buildCommands.addAll(<String>['-destination', 'id=$deviceID']);
    }
  } else {
    if (environmentType == EnvironmentType.physical) {
      buildCommands.addAll(<String>['-sdk', 'iphoneos']);
    } else {
      buildCommands.addAll(<String>['-sdk', 'iphonesimulator']);
    }
  }

  if (activeArch != null) {
    final String activeArchName = getNameForDarwinArch(activeArch);
    if (activeArchName != null) {
      buildCommands.add('ONLY_ACTIVE_ARCH=YES');
      // Setting ARCHS to $activeArchName will break the build if a watchOS companion app exists,
      // as it cannot be build for the architecture of the flutter app.
      if (!hasWatchCompanion) {
        buildCommands.add('ARCHS=$activeArchName');
      }
    }
  }

  if (!codesign) {
    buildCommands.addAll(
      <String>[
        'CODE_SIGNING_ALLOWED=NO',
        'CODE_SIGNING_REQUIRED=NO',
        'CODE_SIGNING_IDENTITY=""',
      ],
    );
  }

  Status? buildSubStatus;
  Status? initialBuildStatus;
  Directory? tempDir;

  File? scriptOutputPipeFile;
  if (globals.logger.hasTerminal) {
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_build_log_pipe.');
    scriptOutputPipeFile = tempDir.childFile('pipe_to_stdout');
    globals.os.makePipe(scriptOutputPipeFile.path);

    Future<void> listenToScriptOutputLine() async {
      final List<String> lines = await scriptOutputPipeFile!.readAsLines();
      for (final String line in lines) {
        if (line == 'done' || line == 'all done') {
          buildSubStatus?.stop();
          buildSubStatus = null;
          if (line == 'all done') {
            // Free pipe file.
            tempDir?.deleteSync(recursive: true);
            return;
          }
        } else {
          initialBuildStatus?.cancel();
          initialBuildStatus = null;
          buildSubStatus = globals.logger.startProgress(
            line,
            progressIndicatorPadding: kDefaultStatusPadding - 7,
          );
        }
      }
      await listenToScriptOutputLine();
    }

    // Trigger the start of the pipe -> stdout loop. Ignore exceptions.
    unawaited(listenToScriptOutputLine());

    buildCommands.add('SCRIPT_OUTPUT_STREAM_FILE=${scriptOutputPipeFile.absolute.path}');
  }

  // Don't log analytics for downstream Flutter commands.
  // e.g. `flutter build bundle`.
  buildCommands.add('FLUTTER_SUPPRESS_ANALYTICS=true');
  buildCommands.add('COMPILER_INDEX_STORE_ENABLE=NO');
  buildCommands.addAll(environmentVariablesAsXcodeBuildSettings(globals.platform));

  if (buildAction == XcodeBuildAction.archive) {
    buildCommands.addAll(<String>[
      '-archivePath',
      globals.fs.path.absolute(app.archiveBundlePath),
      'archive',
    ]);
  }

  final Stopwatch sw = Stopwatch()..start();
  initialBuildStatus = globals.logger.startProgress('Running Xcode build...');

  final RunResult? buildResult = await _runBuildWithRetries(buildCommands, app);

  // Notifies listener that no more output is coming.
  scriptOutputPipeFile?.writeAsStringSync('all done');
  buildSubStatus?.stop();
  buildSubStatus = null;
  initialBuildStatus?.cancel();
  initialBuildStatus = null;
  globals.printStatus(
    'Xcode ${xcodeBuildActionToString(buildAction)} done.'.padRight(kDefaultStatusPadding + 1)
        + getElapsedAsSeconds(sw.elapsed).padLeft(5),
  );
  globals.flutterUsage.sendTiming(xcodeBuildActionToString(buildAction), 'xcode-ios', Duration(milliseconds: sw.elapsedMilliseconds));

  if (buildResult != null && buildResult.exitCode != 0) {
    globals.printStatus('Failed to build iOS app');
    if (buildResult.stderr.isNotEmpty) {
      globals.printStatus('Error output from Xcode build:\n↳');
      globals.printStatus(buildResult.stderr, indent: 4);
    }
    if (buildResult.stdout.isNotEmpty) {
      globals.printStatus("Xcode's output:\n↳");
      globals.printStatus(buildResult.stdout, indent: 4);
    }
    return XcodeBuildResult(
      success: false,
      stdout: buildResult.stdout,
      stderr: buildResult.stderr,
      xcodeBuildExecution: XcodeBuildExecution(
        buildCommands: buildCommands,
        appDirectory: app.project.hostAppRoot.path,
        environmentType: environmentType,
        buildSettings: buildSettings,
      ),
    );
  } else {
    String? outputDir;
    if (buildAction == XcodeBuildAction.build) {
      // If the app contains a watch companion target, the sdk argument of xcodebuild has to be omitted.
      // For some reason this leads to TARGET_BUILD_DIR always ending in 'iphoneos' even though the
      // actual directory will end with 'iphonesimulator' for simulator builds.
      // The value of TARGET_BUILD_DIR is adjusted to accommodate for this effect.
      String? targetBuildDir = buildSettings['TARGET_BUILD_DIR'];
      if (targetBuildDir == null) {
        globals.printError('Xcode build is missing expected TARGET_BUILD_DIR build setting.');
        return XcodeBuildResult(success: false);
      }
      if (hasWatchCompanion && environmentType == EnvironmentType.simulator) {
        globals.printTrace('Replacing iphoneos with iphonesimulator in TARGET_BUILD_DIR.');
        targetBuildDir = targetBuildDir.replaceFirst('iphoneos', 'iphonesimulator');
      }
      final String? appBundle = buildSettings['WRAPPER_NAME'];
      final String expectedOutputDirectory = globals.fs.path.join(
        targetBuildDir,
        appBundle,
      );
      if (globals.fs.directory(expectedOutputDirectory).existsSync()) {
        // Copy app folder to a place where other tools can find it without knowing
        // the BuildInfo.
        outputDir = targetBuildDir.replaceFirst('/$configuration-', '/');
        globals.fs.directory(outputDir).createSync(recursive: true);

        // rsync instead of copy to maintain timestamps to support incremental
        // app install deltas. Use --delete to remove incompatible artifacts
        // (for example, kernel binary files produced from previous run).
        await globals.processUtils.run(
          <String>[
            'rsync',
            '-av',
            '--delete',
            expectedOutputDirectory,
            outputDir,
          ],
          throwOnError: true,
        );
        outputDir = globals.fs.path.join(
          outputDir,
          appBundle,
        );
      } else {
        globals.printError('Build succeeded but the expected app at $expectedOutputDirectory not found');
      }
    } else {
      outputDir = globals.fs.path.absolute(app.archiveBundleOutputPath);
      if (!globals.fs.isDirectorySync(outputDir)) {
        globals.printError('Archive succeeded but the expected xcarchive at $outputDir not found');
      }
    }
    return XcodeBuildResult(
        success: true,
        output: outputDir,
        xcodeBuildExecution: XcodeBuildExecution(
          buildCommands: buildCommands,
          appDirectory: app.project.hostAppRoot.path,
          environmentType: environmentType,
          buildSettings: buildSettings,
      ),
    );
  }
}

/// Extended attributes applied by Finder can cause code signing errors. Remove them.
/// https://developer.apple.com/library/archive/qa/qa1940/_index.html
@visibleForTesting
Future<void> removeFinderExtendedAttributes(Directory projectDirectory, ProcessUtils processUtils, Logger logger) async {
  final bool success = await processUtils.exitsHappy(
    <String>[
      'xattr',
      '-r',
      '-d',
      'com.apple.FinderInfo',
      projectDirectory.path,
    ]
  );
  // Ignore all errors, for example if directory is missing.
  if (!success) {
    logger.printTrace('Failed to remove xattr com.apple.FinderInfo from ${projectDirectory.path}');
  }
}

Future<RunResult?> _runBuildWithRetries(List<String> buildCommands, BuildableIOSApp app) async {
  int buildRetryDelaySeconds = 1;
  int remainingTries = 8;

  RunResult? buildResult;
  while (remainingTries > 0) {
    remainingTries--;
    buildRetryDelaySeconds *= 2;

    buildResult = await globals.processUtils.run(
      buildCommands,
      workingDirectory: app.project.hostAppRoot.path,
      allowReentrantFlutter: true,
    );

    // If the result is anything other than a concurrent build failure, exit
    // the loop after the first build.
    if (!_isXcodeConcurrentBuildFailure(buildResult)) {
      break;
    }

    if (remainingTries > 0) {
      globals.printStatus('Xcode build failed due to concurrent builds, '
        'will retry in $buildRetryDelaySeconds seconds.');
      await Future<void>.delayed(Duration(seconds: buildRetryDelaySeconds));
    } else {
      globals.printStatus(
        'Xcode build failed too many times due to concurrent builds, '
        'giving up.');
      break;
    }
  }

  return buildResult;
}

bool _isXcodeConcurrentBuildFailure(RunResult result) {
return result.exitCode != 0 &&
    result.stdout != null &&
    result.stdout.contains('database is locked') &&
    result.stdout.contains('there are two concurrent builds running');
}

Future<void> diagnoseXcodeBuildFailure(XcodeBuildResult result, Usage flutterUsage, Logger logger) async {
  final XcodeBuildExecution? xcodeBuildExecution = result.xcodeBuildExecution;
  if (xcodeBuildExecution != null &&
      xcodeBuildExecution.environmentType == EnvironmentType.physical &&
      result.stdout?.toUpperCase().contains('BITCODE') == true) {
    BuildEvent('xcode-bitcode-failure',
      type: 'ios',
      command: xcodeBuildExecution.buildCommands.toString(),
      settings: xcodeBuildExecution.buildSettings.toString(),
      flutterUsage: flutterUsage,
    ).send();
  }

  // Building for iOS Simulator, but the linked and embedded framework 'App.framework' was built for iOS.
  // or
  // Building for iOS, but the linked and embedded framework 'App.framework' was built for iOS Simulator.
  if (result.stdout?.contains('Building for iOS') == true
      && result.stdout?.contains('but the linked and embedded framework') == true
      && result.stdout?.contains('was built for iOS') == true) {
    logger.printError('');
    logger.printError('Your Xcode project requires migration. See https://flutter.dev/docs/development/ios-project-migration for details.');
    logger.printError('');
    logger.printError('You can temporarily work around this issue by running:');
    logger.printError('  flutter clean');
    return;
  }
  if (xcodeBuildExecution != null &&
      xcodeBuildExecution.environmentType == EnvironmentType.physical &&
      result.stdout?.contains('BCEROR') == true &&
      // May need updating if Xcode changes its outputs.
      result.stdout?.contains("Xcode couldn't find a provisioning profile matching") == true) {
    logger.printError(noProvisioningProfileInstruction, emphasis: true);
    return;
  }
  // Make sure the user has specified one of:
  // * DEVELOPMENT_TEAM (automatic signing)
  // * PROVISIONING_PROFILE (manual signing)
  if (xcodeBuildExecution != null &&
      xcodeBuildExecution.environmentType == EnvironmentType.physical &&
      !<String>['DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE'].any(
        xcodeBuildExecution.buildSettings.containsKey)) {
    logger.printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (xcodeBuildExecution != null &&
      xcodeBuildExecution.environmentType == EnvironmentType.physical &&
      xcodeBuildExecution.buildSettings['PRODUCT_BUNDLE_IDENTIFIER']?.contains('com.example') == true) {
    logger.printError('');
    logger.printError('It appears that your application still contains the default signing identifier.');
    logger.printError("Try replacing 'com.example' with your signing id in Xcode:");
    logger.printError('  open ios/Runner.xcworkspace');
    return;
  }
  if (result.stdout?.contains('Code Sign error') == true) {
    logger.printError('');
    logger.printError('It appears that there was a problem signing your application prior to installation on the device.');
    logger.printError('');
    logger.printError('Verify that the Bundle Identifier in your project is your signing id in Xcode');
    logger.printError('  open ios/Runner.xcworkspace');
    logger.printError('');
    logger.printError("Also try selecting 'Product > Build' to fix the problem:");
    return;
  }
}

/// xcodebuild <buildaction> parameter (see man xcodebuild for details).
///
/// `clean`, `test`, `analyze`, and `install` are not supported.
enum XcodeBuildAction { build, archive }

String xcodeBuildActionToString(XcodeBuildAction action) {
    switch (action) {
      case XcodeBuildAction.build:
        return 'build';
      case XcodeBuildAction.archive:
        return 'archive';
      default:
        throw UnsupportedError('Unknown Xcode build action');
    }
}

class XcodeBuildResult {
  XcodeBuildResult({
    required this.success,
    this.output,
    this.stdout,
    this.stderr,
    this.xcodeBuildExecution,
  });

  final bool success;
  final String? output;
  final String? stdout;
  final String? stderr;
  /// The invocation of the build that resulted in this result instance.
  final XcodeBuildExecution? xcodeBuildExecution;
}

/// Describes an invocation of a Xcode build command.
class XcodeBuildExecution {
  XcodeBuildExecution({
    required this.buildCommands,
    required this.appDirectory,
    required this.environmentType,
    required this.buildSettings,
  });

  /// The original list of Xcode build commands used to produce this build result.
  final List<String> buildCommands;
  final String appDirectory;
  final EnvironmentType environmentType;
  /// The build settings corresponding to the [buildCommands] invocation.
  final Map<String, String> buildSettings;
}

final String _xcodeRequirement = 'Xcode $xcodeRequiredVersion or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!globals.platform.isMacOS) {
    return false;
  }
  final XcodeProjectInterpreter? xcodeProjectInterpreter = globals.xcodeProjectInterpreter;
  if (xcodeProjectInterpreter?.isInstalled != true) {
    globals.printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  if (globals.xcode?.isRequiredVersionSatisfactory != true) {
    globals.printError('Found "${xcodeProjectInterpreter?.versionText}". $_xcodeRequirement');
    return false;
  }
  return true;
}

// TODO(jmagman): Refactor to IOSMigrator.
bool upgradePbxProjWithFlutterAssets(IosProject project, Logger logger) {
  final File xcodeProjectFile = project.xcodeProjectInfoFile;
  assert(xcodeProjectFile.existsSync());
  final List<String> lines = xcodeProjectFile.readAsLinesSync();

  final RegExp oldAssets = RegExp(r'\/\* (flutter_assets|app\.flx)');
  final StringBuffer buffer = StringBuffer();
  final Set<String> printedStatuses = <String>{};

  for (final String line in lines) {
    final Match? match = oldAssets.firstMatch(line);
    if (match != null) {
      if (printedStatuses.add(match.group(1)!)) {
        logger.printStatus('Removing obsolete reference to ${match.group(1)} from ${project.xcodeProject.basename}');
      }
    } else {
      buffer.writeln(line);
    }
  }
  xcodeProjectFile.writeAsStringSync(buffer.toString());
  return true;
}
