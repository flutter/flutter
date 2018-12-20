// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/fingerprint.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../plugins.dart';
import '../project.dart';
import '../services.dart';
import 'cocoapods.dart';
import 'code_signing.dart';
import 'xcodeproj.dart';

const int kXcodeRequiredVersionMajor = 9;
const int kXcodeRequiredVersionMinor = 0;

IMobileDevice get iMobileDevice => context[IMobileDevice];
PlistBuddy get plistBuddy => context[PlistBuddy];
Xcode get xcode => context[Xcode];

class PlistBuddy {
  const PlistBuddy();

  static const String path = '/usr/libexec/PlistBuddy';

  Future<ProcessResult> run(List<String> args) => processManager.run(<String>[path]..addAll(args));
}

/// A property list is a key-value representation commonly used for
/// configuration on macOS/iOS systems.
class PropertyList {
  const PropertyList(this.plistPath);

  final String plistPath;

  /// Prints the specified key, or returns null if not present.
  Future<String> read(String key) async {
    final ProcessResult result = await _runCommand('Print $key');
    if (result.exitCode == 0)
      return result.stdout.trim();
    return null;
  }

  /// Adds [key]. Has no effect if the key already exists.
  Future<void> addString(String key, String value) async {
    await _runCommand('Add $key string $value');
  }

  /// Updates [key] with the new [value]. Has no effect if the key does not exist.
  Future<void> update(String key, String value) async {
    await _runCommand('Set $key $value');
  }

  /// Deletes [key].
  Future<void> delete(String key) async {
    await _runCommand('Delete $key');
  }

  /// Deletes the content of the property list and creates a new root of the specified type.
  Future<void> clearToDict() async {
    await _runCommand('Clear dict');
  }

  Future<ProcessResult> _runCommand(String command) async {
    return await plistBuddy.run(<String>['-c', command, plistPath]);
  }
}

/// Specialized exception for expected situations where the ideviceinfo
/// tool responds with exit code 255 / 'No device found' message
class IOSDeviceNotFoundError implements Exception {
  IOSDeviceNotFoundError(this.message);

  final String message;

  @override
  String toString() => message;
}

class IMobileDevice {
  const IMobileDevice();

  bool get isInstalled => exitsHappy(<String>['idevice_id', '-h']);

  /// Returns true if libimobiledevice is installed and working as expected.
  ///
  /// Older releases of libimobiledevice fail to work with iOS 10.3 and above.
  Future<bool> get isWorking async {
    if (!isInstalled)
      return false;
    // If usage info is printed in a hyphenated id, we need to update.
    const String fakeIphoneId = '00008020-001C2D903C42002E';
    final ProcessResult ideviceResult = (await runAsync(<String>['ideviceinfo', '-u', fakeIphoneId])).processResult;
    if (ideviceResult.stdout.contains('Usage: ideviceinfo')) {
      return false;
    }

    // If no device is attached, we're unable to detect any problems. Assume all is well.
    final ProcessResult result = (await runAsync(<String>['idevice_id', '-l'])).processResult;
    if (result.exitCode != 0 || result.stdout.isEmpty)
      return true;

    // Check that we can look up the names of any attached devices.
    return await exitsHappyAsync(<String>['idevicename']);
  }

  Future<String> getAvailableDeviceIDs() async {
    try {
      final ProcessResult result = await processManager.run(<String>['idevice_id', '-l']);
      if (result.exitCode != 0)
        throw ToolExit('idevice_id returned an error:\n${result.stderr}');
      return result.stdout;
    } on ProcessException {
      throw ToolExit('Failed to invoke idevice_id. Run flutter doctor.');
    }
  }

  Future<String> getInfoForDevice(String deviceID, String key) async {
    try {
      final ProcessResult result = await processManager.run(<String>['ideviceinfo', '-u', deviceID, '-k', key, '--simple']);
      if (result.exitCode == 255 && result.stdout != null && result.stdout.contains('No device found'))
        throw IOSDeviceNotFoundError('ideviceinfo could not find device:\n${result.stdout}');
      if (result.exitCode != 0)
        throw ToolExit('ideviceinfo returned an error:\n${result.stderr}');
      return result.stdout.trim();
    } on ProcessException {
      throw ToolExit('Failed to invoke ideviceinfo. Run flutter doctor.');
    }
  }

  /// Starts `idevicesyslog` and returns the running process.
  Future<Process> startLogger(String deviceID) => runCommand(<String>['idevicesyslog', '-u', deviceID]);

  /// Captures a screenshot to the specified outputFile.
  Future<void> takeScreenshot(File outputFile) {
    return runCheckedAsync(<String>['idevicescreenshot', outputFile.path]);
  }
}

class Xcode {
  bool get isInstalledAndMeetsVersionCheck => isInstalled && isVersionSatisfactory;

  String _xcodeSelectPath;
  String get xcodeSelectPath {
    if (_xcodeSelectPath == null) {
      try {
        _xcodeSelectPath = processManager.runSync(<String>['/usr/bin/xcode-select', '--print-path']).stdout.trim();
      } on ProcessException {
        // Ignore: return null below.
      }
    }
    return _xcodeSelectPath;
  }

  bool get isInstalled {
    if (xcodeSelectPath == null || xcodeSelectPath.isEmpty)
      return false;
    return xcodeProjectInterpreter.isInstalled;
  }

  int get majorVersion => xcodeProjectInterpreter.majorVersion;

  int get minorVersion => xcodeProjectInterpreter.minorVersion;

  String get versionText => xcodeProjectInterpreter.versionText;

  bool _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned {
    if (_eulaSigned == null) {
      try {
        final ProcessResult result = processManager.runSync(<String>['/usr/bin/xcrun', 'clang']);
        if (result.stdout != null && result.stdout.contains('license'))
          _eulaSigned = false;
        else if (result.stderr != null && result.stderr.contains('license'))
          _eulaSigned = false;
        else
          _eulaSigned = true;
      } on ProcessException {
        _eulaSigned = false;
      }
    }
    return _eulaSigned;
  }

  bool _isSimctlInstalled;

  /// Verifies that simctl is installed by trying to run it.
  bool get isSimctlInstalled {
    if (_isSimctlInstalled == null) {
      try {
        // This command will error if additional components need to be installed in
        // xcode 9.2 and above.
        final ProcessResult result = processManager.runSync(<String>['/usr/bin/xcrun', 'simctl', 'list']);
        _isSimctlInstalled = result.stderr == null || result.stderr == '';
      } on ProcessException {
        _isSimctlInstalled = false;
      }
    }
    return _isSimctlInstalled;
  }

  bool get isVersionSatisfactory {
    if (!xcodeProjectInterpreter.isInstalled)
      return false;
    if (majorVersion > kXcodeRequiredVersionMajor)
      return true;
    if (majorVersion == kXcodeRequiredVersionMajor)
      return minorVersion >= kXcodeRequiredVersionMinor;
    return false;
  }

  Future<RunResult> cc(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'cc']..addAll(args));
  }

  Future<RunResult> clang(List<String> args) {
    return runCheckedAsync(<String>['xcrun', 'clang']..addAll(args));
  }

  String getSimulatorPath() {
    if (xcodeSelectPath == null)
      return null;
    final List<String> searchPaths = <String>[
      fs.path.join(xcodeSelectPath, 'Applications', 'Simulator.app'),
    ];
    return searchPaths.where((String p) => p != null).firstWhere(
      (String p) => fs.directory(p).existsSync(),
      orElse: () => null,
    );
  }
}

/// Sets the Xcode system.
///
/// Xcode 10 added a new (default) build system with better performance and
/// stricter checks. Flutter apps without plugins build fine under the new
/// system, but it causes build breakages in projects with CocoaPods enabled.
/// This affects Flutter apps with plugins.
///
/// Once Flutter has been updated to be fully compliant with the new build
/// system, this can be removed.
//
// TODO(cbracken): remove when https://github.com/flutter/flutter/issues/20685 is fixed.
Future<void> setXcodeWorkspaceBuildSystem({
  @required Directory workspaceDirectory,
  @required File workspaceSettings,
  @required bool modern,
}) async {
  // If this isn't a workspace, we're not using CocoaPods and can use the new
  // build system.
  if (!workspaceDirectory.existsSync())
    return;

  final PropertyList plist = PropertyList(workspaceSettings.path);
  if (!workspaceSettings.existsSync()) {
    workspaceSettings.parent.createSync(recursive: true);
    await plist.clearToDict();
  }

  const String kBuildSystemType = 'BuildSystemType';
  if (modern) {
    printTrace('Using new Xcode build system.');
    await plist.delete(kBuildSystemType);
  } else {
    printTrace('Using legacy Xcode build system.');
    if (await plist.read(kBuildSystemType) == null) {
      await plist.addString(kBuildSystemType, 'Original');
    } else {
      await plist.update(kBuildSystemType, 'Original');
    }
  }
}

Future<XcodeBuildResult> buildXcodeProject({
  BuildableIOSApp app,
  BuildInfo buildInfo,
  String targetOverride,
  bool buildForDevice,
  bool codesign = true,
  bool usesTerminalUi = true,
}) async {
  if (!await upgradePbxProjWithFlutterAssets(app.project))
    return XcodeBuildResult(success: false);

  if (!_checkXcodeVersion())
    return XcodeBuildResult(success: false);

  // TODO(cbracken): remove when https://github.com/flutter/flutter/issues/20685 is fixed.
  await setXcodeWorkspaceBuildSystem(
    workspaceDirectory: app.project.xcodeWorkspace,
    workspaceSettings: app.project.xcodeWorkspaceSharedSettings,
    modern: false,
  );

  final XcodeProjectInfo projectInfo = xcodeProjectInterpreter.getInfo(app.project.hostAppRoot.path);
  if (!projectInfo.targets.contains('Runner')) {
    printError('The Xcode project does not define target "Runner" which is needed by Flutter tooling.');
    printError('Open Xcode to fix the problem:');
    printError('  open ios/Runner.xcworkspace');
    return XcodeBuildResult(success: false);
  }
  final String scheme = projectInfo.schemeFor(buildInfo);
  if (scheme == null) {
    printError('');
    if (projectInfo.definesCustomSchemes) {
      printError('The Xcode project defines schemes: ${projectInfo.schemes.join(', ')}');
      printError('You must specify a --flavor option to select one of them.');
    } else {
      printError('The Xcode project does not define custom schemes.');
      printError('You cannot use the --flavor option.');
    }
    return XcodeBuildResult(success: false);
  }
  final String configuration = projectInfo.buildConfigurationFor(buildInfo, scheme);
  if (configuration == null) {
    printError('');
    printError('The Xcode project defines build configurations: ${projectInfo.buildConfigurations.join(', ')}');
    printError('Flutter expects a build configuration named ${XcodeProjectInfo.expectedBuildConfigurationFor(buildInfo, scheme)} or similar.');
    printError('Open Xcode to fix the problem:');
    printError('  open ios/Runner.xcworkspace');
    printError('1. Click on "Runner" in the project navigator.');
    printError('2. Ensure the Runner PROJECT is selected, not the Runner TARGET.');
    if (buildInfo.isDebug) {
      printError('3. Click the Editor->Add Configuration->Duplicate "Debug" Configuration.');
    } else {
      printError('3. Click the Editor->Add Configuration->Duplicate "Release" Configuration.');
    }
    printError('');
    printError('   If this option is disabled, it is likely you have the target selected instead');
    printError('   of the project; see:');
    printError('   https://stackoverflow.com/questions/19842746/adding-a-build-configuration-in-xcode');
    printError('');
    printError('   If you have created a completely custom set of build configurations,');
    printError('   you can set the FLUTTER_BUILD_MODE=${buildInfo.modeName.toLowerCase()}');
    printError('   in the .xcconfig file for that configuration and run from Xcode.');
    printError('');
    printError('4. If you are not using completely custom build configurations, name the newly created configuration ${buildInfo.modeName}.');
    return XcodeBuildResult(success: false);
  }

  Map<String, String> autoSigningConfigs;
  if (codesign && buildForDevice)
    autoSigningConfigs = await getCodeSigningIdentityDevelopmentTeam(iosApp: app, usesTerminalUi: usesTerminalUi);

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.
  await _addServicesToBundle(app.project.hostAppRoot);

  final FlutterProject project = await FlutterProject.current();
  await updateGeneratedXcodeProperties(
    project: project,
    targetOverride: targetOverride,
    buildInfo: buildInfo,
  );
  refreshPluginsList(project);
  if (hasPlugins(project) || (project.isModule && project.ios.podfile.existsSync())) {
    // If the Xcode project, Podfile, or Generated.xcconfig have changed since
    // last run, pods should be updated.
    final Fingerprinter fingerprinter = Fingerprinter(
      fingerprintPath: fs.path.join(getIosBuildDirectory(), 'pod_inputs.fingerprint'),
      paths: <String>[
        app.project.xcodeProjectInfoFile.path,
        app.project.podfile.path,
        app.project.generatedXcodePropertiesFile.path,
      ],
      properties: <String, String>{},
    );
    final bool didPodInstall = await cocoaPods.processPods(
      iosProject: project.ios,
      iosEngineDir: flutterFrameworkDir(buildInfo.mode),
      isSwift: project.ios.isSwift,
      dependenciesChanged: !await fingerprinter.doesFingerprintMatch()
    );
    if (didPodInstall)
      await fingerprinter.writeFingerprint();
  }

  final List<String> buildCommands = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-configuration', configuration,
  ];

  if (logger.isVerbose) {
    // An environment variable to be passed to xcode_backend.sh determining
    // whether to echo back executed commands.
    buildCommands.add('VERBOSE_SCRIPT_LOGGING=YES');
  } else {
    // This will print warnings and errors only.
    buildCommands.add('-quiet');
  }

  if (autoSigningConfigs != null) {
    for (MapEntry<String, String> signingConfig in autoSigningConfigs.entries) {
      buildCommands.add('${signingConfig.key}=${signingConfig.value}');
    }
    buildCommands.add('-allowProvisioningUpdates');
    buildCommands.add('-allowProvisioningDeviceRegistration');
  }

  final List<FileSystemEntity> contents = app.project.hostAppRoot.listSync();
  for (FileSystemEntity entity in contents) {
    if (fs.path.extension(entity.path) == '.xcworkspace') {
      buildCommands.addAll(<String>[
        '-workspace', fs.path.basename(entity.path),
        '-scheme', scheme,
        'BUILD_DIR=${fs.path.absolute(getIosBuildDirectory())}',
      ]);
      break;
    }
  }

  if (buildForDevice) {
    buildCommands.addAll(<String>['-sdk', 'iphoneos']);
  } else {
    buildCommands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  if (!codesign) {
    buildCommands.addAll(
      <String>[
        'CODE_SIGNING_ALLOWED=NO',
        'CODE_SIGNING_REQUIRED=NO',
        'CODE_SIGNING_IDENTITY=""'
      ]
    );
  }

  Status buildSubStatus;
  Status initialBuildStatus;
  Directory tempDir;

  File scriptOutputPipeFile;
  if (logger.hasTerminal) {
    tempDir = fs.systemTempDirectory.createTempSync('flutter_build_log_pipe.');
    scriptOutputPipeFile = tempDir.childFile('pipe_to_stdout');
    os.makePipe(scriptOutputPipeFile.path);

    Future<void> listenToScriptOutputLine() async {
      final List<String> lines = await scriptOutputPipeFile.readAsLines();
      for (String line in lines) {
        if (line == 'done' || line == 'all done') {
          buildSubStatus?.stop();
          buildSubStatus = null;
          if (line == 'all done') {
            // Free pipe file.
            tempDir?.deleteSync(recursive: true);
            return;
          }
        } else {
          initialBuildStatus.cancel();
          buildSubStatus = logger.startProgress(
            line,
            expectSlowOperation: true,
            progressIndicatorPadding: kDefaultStatusPadding - 7,
          );
        }
      }
      await listenToScriptOutputLine();
    }

    // Trigger the start of the pipe -> stdout loop. Ignore exceptions.
    listenToScriptOutputLine(); // ignore: unawaited_futures

    buildCommands.add('SCRIPT_OUTPUT_STREAM_FILE=${scriptOutputPipeFile.absolute.path}');
  }

  final Stopwatch buildStopwatch = Stopwatch()..start();
  initialBuildStatus = logger.startProgress('Starting Xcode build...');
  final RunResult buildResult = await runAsync(
    buildCommands,
    workingDirectory: app.project.hostAppRoot.path,
    allowReentrantFlutter: true
  );
  // Notifies listener that no more output is coming.
  scriptOutputPipeFile?.writeAsStringSync('all done');
  buildSubStatus?.stop();
  initialBuildStatus?.cancel();
  buildStopwatch.stop();
  printStatus(
    'Xcode build done.'.padRight(kDefaultStatusPadding + 1)
        + '${getElapsedAsSeconds(buildStopwatch.elapsed).padLeft(5)}',
  );

  // Run -showBuildSettings again but with the exact same parameters as the build.
  final Map<String, String> buildSettings = parseXcodeBuildSettings(runCheckedSync(
    (List<String>
        .from(buildCommands)
        ..add('-showBuildSettings'))
        // Undocumented behaviour: xcodebuild craps out if -showBuildSettings
        // is used together with -allowProvisioningUpdates or
        // -allowProvisioningDeviceRegistration and freezes forever.
        .where((String buildCommand) {
          return !const <String>[
            '-allowProvisioningUpdates',
            '-allowProvisioningDeviceRegistration',
          ].contains(buildCommand);
        }).toList(),
    workingDirectory: app.project.hostAppRoot.path,
  ));

  if (buildResult.exitCode != 0) {
    printStatus('Failed to build iOS app');
    if (buildResult.stderr.isNotEmpty) {
      printStatus('Error output from Xcode build:\n↳');
      printStatus(buildResult.stderr, indent: 4);
    }
    if (buildResult.stdout.isNotEmpty) {
      printStatus('Xcode\'s output:\n↳');
      printStatus(buildResult.stdout, indent: 4);
    }
    return XcodeBuildResult(
      success: false,
      stdout: buildResult.stdout,
      stderr: buildResult.stderr,
      xcodeBuildExecution: XcodeBuildExecution(
        buildCommands: buildCommands,
        appDirectory: app.project.hostAppRoot.path,
        buildForPhysicalDevice: buildForDevice,
        buildSettings: buildSettings,
      ),
    );
  } else {
    final String expectedOutputDirectory = fs.path.join(
      buildSettings['TARGET_BUILD_DIR'],
      buildSettings['WRAPPER_NAME'],
    );

    String outputDir;
    if (fs.isDirectorySync(expectedOutputDirectory)) {
      // Copy app folder to a place where other tools can find it without knowing
      // the BuildInfo.
      outputDir = expectedOutputDirectory.replaceFirst('/$configuration-', '/');
      if (fs.isDirectorySync(outputDir)) {
        // Previous output directory might have incompatible artifacts
        // (for example, kernel binary files produced from previous run).
        fs.directory(outputDir).deleteSync(recursive: true);
      }
      copyDirectorySync(fs.directory(expectedOutputDirectory), fs.directory(outputDir));
    } else {
      printError('Build succeeded but the expected app at $expectedOutputDirectory not found');
    }
    return XcodeBuildResult(success: true, output: outputDir);
  }
}

String readGeneratedXcconfig(String appPath) {
  final String generatedXcconfigPath =
      fs.path.join(fs.currentDirectory.path, appPath, 'Flutter', 'Generated.xcconfig');
  final File generatedXcconfigFile = fs.file(generatedXcconfigPath);
  if (!generatedXcconfigFile.existsSync())
    return null;
  return generatedXcconfigFile.readAsStringSync();
}

Future<void> diagnoseXcodeBuildFailure(XcodeBuildResult result) async {
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.contains('BCEROR') == true &&
      // May need updating if Xcode changes its outputs.
      result.stdout?.contains('Xcode couldn\'t find a provisioning profile matching') == true) {
    printError(noProvisioningProfileInstruction, emphasis: true);
    return;
  }
  // Make sure the user has specified one of:
  // * DEVELOPMENT_TEAM (automatic signing)
  // * PROVISIONING_PROFILE (manual signing)
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      !<String>['DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE'].any(
        result.xcodeBuildExecution.buildSettings.containsKey)
      ) {
    printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.xcodeBuildExecution.buildSettings['PRODUCT_BUNDLE_IDENTIFIER']?.contains('com.example') == true) {
    printError('');
    printError('It appears that your application still contains the default signing identifier.');
    printError("Try replacing 'com.example' with your signing id in Xcode:");
    printError('  open ios/Runner.xcworkspace');
    return;
  }
  if (result.stdout?.contains('Code Sign error') == true) {
    printError('');
    printError('It appears that there was a problem signing your application prior to installation on the device.');
    printError('');
    printError('Verify that the Bundle Identifier in your project is your signing id in Xcode');
    printError('  open ios/Runner.xcworkspace');
    printError('');
    printError("Also try selecting 'Product > Build' to fix the problem:");
    return;
  }
}

class XcodeBuildResult {
  XcodeBuildResult(
    {
      @required this.success,
      this.output,
      this.stdout,
      this.stderr,
      this.xcodeBuildExecution,
    }
  );

  final bool success;
  final String output;
  final String stdout;
  final String stderr;
  /// The invocation of the build that resulted in this result instance.
  final XcodeBuildExecution xcodeBuildExecution;
}

/// Describes an invocation of a Xcode build command.
class XcodeBuildExecution {
  XcodeBuildExecution(
    {
      @required this.buildCommands,
      @required this.appDirectory,
      @required this.buildForPhysicalDevice,
      @required this.buildSettings,
    }
  );

  /// The original list of Xcode build commands used to produce this build result.
  final List<String> buildCommands;
  final String appDirectory;
  final bool buildForPhysicalDevice;
  /// The build settings corresponding to the [buildCommands] invocation.
  final Map<String, String> buildSettings;
}

const String _xcodeRequirement = 'Xcode $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!platform.isMacOS)
    return false;
  if (!xcodeProjectInterpreter.isInstalled) {
    printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  if (!xcode.isVersionSatisfactory) {
    printError('Found "${xcodeProjectInterpreter.versionText}". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<void> _addServicesToBundle(Directory bundle) async {
  final List<Map<String, String>> services = <Map<String, String>>[];
  printTrace('Trying to resolve native pub services.');

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace('Found ${services.length} service definition(s).');

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  final Directory frameworksDirectory = fs.directory(fs.path.join(bundle.path, 'Frameworks'));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  final File manifestFile = fs.file(fs.path.join(bundle.path, 'ServiceDefinitions.json'));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future<void> _copyServiceFrameworks(List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace("Copying service frameworks to '${fs.path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    final String dylibPath = await getServiceFromUrl(service['ios-framework'], service['root'], service['name']);
    final File dylib = fs.file(dylibPath);
    printTrace('Copying ${dylib.path} into bundle.');
    if (!dylib.existsSync()) {
      printError("The service dylib '${dylib.path}' does not exist.");
      continue;
    }
    // Shell out so permissions on the dylib are preserved.
    await runCheckedAsync(<String>['/bin/cp', dylib.path, frameworksDirectory.path]);
  }
}

void _copyServiceDefinitionsManifest(List<Map<String, String>> services, File manifest) {
  printTrace("Creating service definitions manifest at '${manifest.path}'");
  final List<Map<String, String>> jsonServices = services.map<Map<String, String>>((Map<String, String> service) => <String, String>{
    'name': service['name'],
    // Since we have already moved it to the Frameworks directory. Strip away
    // the directory and basenames.
    'framework': fs.path.basenameWithoutExtension(service['ios-framework'])
  }).toList();
  final Map<String, dynamic> jsonObject = <String, dynamic>{ 'services' : jsonServices };
  manifest.writeAsStringSync(json.encode(jsonObject), mode: FileMode.write, flush: true);
}

Future<bool> upgradePbxProjWithFlutterAssets(IosProject project) async {
  final File xcodeProjectFile = project.xcodeProjectInfoFile;
  assert(await xcodeProjectFile.exists());
  final List<String> lines = await xcodeProjectFile.readAsLines();

  if (lines.any((String line) => line.contains('flutter_assets in Resources')))
    return true;

  const String l1 = '		3B3967161E833CAA004F5970 /* AppFrameworkInfo.plist in Resources */ = {isa = PBXBuildFile; fileRef = 3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */; };';
  const String l2 = '		2D5378261FAA1A9400D5DBA9 /* flutter_assets in Resources */ = {isa = PBXBuildFile; fileRef = 2D5378251FAA1A9400D5DBA9 /* flutter_assets */; };';
  const String l3 = '		3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; name = AppFrameworkInfo.plist; path = Flutter/AppFrameworkInfo.plist; sourceTree = "<group>"; };';
  const String l4 = '		2D5378251FAA1A9400D5DBA9 /* flutter_assets */ = {isa = PBXFileReference; lastKnownFileType = folder; name = flutter_assets; path = Flutter/flutter_assets; sourceTree = SOURCE_ROOT; };';
  const String l5 = '				3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */,';
  const String l6 = '				2D5378251FAA1A9400D5DBA9 /* flutter_assets */,';
  const String l7 = '				3B3967161E833CAA004F5970 /* AppFrameworkInfo.plist in Resources */,';
  const String l8 = '				2D5378261FAA1A9400D5DBA9 /* flutter_assets in Resources */,';


  printStatus("Upgrading project.pbxproj of ${project.hostAppBundleName}' to include the "
              "'flutter_assets' directory");

  if (!lines.contains(l1) || !lines.contains(l3) ||
      !lines.contains(l5) || !lines.contains(l7)) {
    printError('Automatic upgrade of project.pbxproj failed.');
    printError(' To manually upgrade, open ${xcodeProjectFile.path}:');
    printError(' Add the following line in the "PBXBuildFile" section');
    printError(l2);
    printError(' Add the following line in the "PBXFileReference" section');
    printError(l4);
    printError(' Add the following line in the "children" list of the "Flutter" group in the "PBXGroup" section');
    printError(l6);
    printError(' Add the following line in the "files" list of "Resources" in the "PBXResourcesBuildPhase" section');
    printError(l8);
    return false;
  }

  lines.insert(lines.indexOf(l1) + 1, l2);
  lines.insert(lines.indexOf(l3) + 1, l4);
  lines.insert(lines.indexOf(l5) + 1, l6);
  lines.insert(lines.indexOf(l7) + 1, l8);

  const String l9 = '		9740EEBB1CF902C7004384FC /* app.flx in Resources */ = {isa = PBXBuildFile; fileRef = 9740EEB71CF902C7004384FC /* app.flx */; };';
  const String l10 = '		9740EEB71CF902C7004384FC /* app.flx */ = {isa = PBXFileReference; lastKnownFileType = file; name = app.flx; path = Flutter/app.flx; sourceTree = "<group>"; };';
  const String l11 = '				9740EEB71CF902C7004384FC /* app.flx */,';
  const String l12 = '				9740EEBB1CF902C7004384FC /* app.flx in Resources */,';

  if (lines.contains(l9)) {
    printStatus('Removing app.flx from project.pbxproj since it has been '
        'replaced with flutter_assets.');
    lines.remove(l9);
    lines.remove(l10);
    lines.remove(l11);
    lines.remove(l12);
  }

  final StringBuffer buffer = StringBuffer();
  lines.forEach(buffer.writeln);
  await xcodeProjectFile.writeAsString(buffer.toString());
  return true;
}
