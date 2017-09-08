// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../plugins.dart';
import '../services.dart';
import 'cocoapods.dart';
import 'code_signing.dart';
import 'xcodeproj.dart';

const int kXcodeRequiredVersionMajor = 8;
const int kXcodeRequiredVersionMinor = 0;

// The Python `six` module is a dependency for Xcode builds, and installed by
// default, but may not be present in custom Python installs; e.g., via
// Homebrew.
const PythonModule kPythonSix = const PythonModule('six');

IMobileDevice get iMobileDevice => context.putIfAbsent(IMobileDevice, () => const IMobileDevice());

Xcode get xcode => context.putIfAbsent(Xcode, () => new Xcode());

class PythonModule {
  const PythonModule(this.name);

  final String name;

  bool get isInstalled => exitsHappy(<String>['python', '-c', 'import $name']);

  String get errorMessage =>
    'Missing Xcode dependency: Python module "$name".\n'
    'Install via \'pip install $name\' or \'sudo easy_install $name\'.';
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
        throw new ToolExit('idevice_id returned an error:\n${result.stderr}');
      return result.stdout;
    } on ProcessException {
      throw new ToolExit('Failed to invoke idevice_id. Run flutter doctor.');
    }
  }

  Future<String> getInfoForDevice(String deviceID, String key) async {
    try {
      final ProcessResult result = await processManager.run(<String>['ideviceinfo', '-u', deviceID, '-k', key,]);
      if (result.exitCode != 0)
        throw new ToolExit('idevice_id returned an error:\n${result.stderr}');
      return result.stdout.trim();
    } on ProcessException {
      throw new ToolExit('Failed to invoke idevice_id. Run flutter doctor.');
    }
  }

  /// Starts `idevicesyslog` and returns the running process.
  Future<Process> startLogger() => runCommand(<String>['idevicesyslog']);

  /// Captures a screenshot to the specified outputfile.
  Future<Null> takeScreenshot(File outputFile) {
    return runCheckedAsync(<String>['idevicescreenshot', outputFile.path]);
  }
}

class Xcode {
  bool get isInstalledAndMeetsVersionCheck => isInstalled && xcodeVersionSatisfactory;

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
    if (xcodeVersionText == null || !xcodeVersionRegex.hasMatch(xcodeVersionText))
      return false;
    return true;
  }

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

  final RegExp xcodeVersionRegex = new RegExp(r'Xcode ([0-9.]+)');
  void _updateXcodeVersion() {
    try {
      _xcodeVersionText = processManager.runSync(<String>['/usr/bin/xcodebuild', '-version']).stdout.trim().replaceAll('\n', ', ');
      final Match match = xcodeVersionRegex.firstMatch(xcodeVersionText);
      if (match == null)
        return;

      final String version = match.group(1);
      final List<String> components = version.split('.');
      _xcodeMajorVersion = int.parse(components[0]);
      _xcodeMinorVersion = components.length == 1 ? 0 : int.parse(components[1]);
    } on ProcessException {
      // Ignore: leave values null.
    }
  }

  String _xcodeVersionText;
  String get xcodeVersionText {
    if (_xcodeVersionText == null)
      _updateXcodeVersion();
    return _xcodeVersionText;
  }

  int _xcodeMajorVersion;
  int get xcodeMajorVersion {
    if (_xcodeMajorVersion == null)
      _updateXcodeVersion();
    return _xcodeMajorVersion;
  }

  int _xcodeMinorVersion;
  int get xcodeMinorVersion {
    if (_xcodeMinorVersion == null)
      _updateXcodeVersion();
    return _xcodeMinorVersion;
  }

  bool get xcodeVersionSatisfactory {
    if (xcodeVersionText == null || !xcodeVersionRegex.hasMatch(xcodeVersionText))
      return false;
    return _xcodeVersionCheckValid(xcodeMajorVersion, xcodeMinorVersion);
  }
}

bool _xcodeVersionCheckValid(int major, int minor) {
  if (major > kXcodeRequiredVersionMajor)
    return true;

  if (major == kXcodeRequiredVersionMajor)
    return minor >= kXcodeRequiredVersionMinor;

  return false;
}

Future<XcodeBuildResult> buildXcodeProject({
  BuildableIOSApp app,
  BuildInfo buildInfo,
  String target: flx.defaultMainPath,
  bool buildForDevice,
  bool codesign: true,
  bool usesTerminalUi: true,
}) async {
  if (!_checkXcodeVersion())
    return new XcodeBuildResult(success: false);

  if (!kPythonSix.isInstalled) {
    printError(kPythonSix.errorMessage);
    return new XcodeBuildResult(success: false);
  }

  final XcodeProjectInfo projectInfo = new XcodeProjectInfo.fromProjectSync(app.appDirectory);
  if (!projectInfo.targets.contains('Runner')) {
    printError('The Xcode project does not define target "Runner" which is needed by Flutter tooling.');
    printError('Open Xcode to fix the problem:');
    printError('  open ios/Runner.xcworkspace');
    return new XcodeBuildResult(success: false);
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
    return new XcodeBuildResult(success: false);
  }
  final String configuration = projectInfo.buildConfigurationFor(buildInfo, scheme);
  if (configuration == null) {
    printError('');
    printError('The Xcode project defines build configurations: ${projectInfo.buildConfigurations.join(', ')}');
    printError('Flutter expects a build configuration named ${XcodeProjectInfo.expectedBuildConfigurationFor(buildInfo, scheme)} or similar.');
    printError('Open Xcode to fix the problem:');
    printError('  open ios/Runner.xcworkspace');
    return new XcodeBuildResult(success: false);
  }

  String developmentTeam;
  if (codesign && buildForDevice)
    developmentTeam = await getCodeSigningIdentityDevelopmentTeam(iosApp: app, usesTerminalUi: usesTerminalUi);

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.
  final Directory appDirectory = fs.directory(app.appDirectory);
  await _addServicesToBundle(appDirectory);
  final bool hasFlutterPlugins = injectPlugins();

  if (hasFlutterPlugins)
    await cocoaPods.processPods(
      appIosDir: appDirectory,
      iosEngineDir: flutterFrameworkDir(buildInfo.mode),
      isSwift: app.isSwift,
    );

  updateXcodeGeneratedProperties(
    projectPath: fs.currentDirectory.path,
    buildInfo: buildInfo,
    target: target,
    hasPlugins: hasFlutterPlugins
  );

  final List<String> commands = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    'clean',
    'build',
    '-configuration', configuration,
    'ONLY_ACTIVE_ARCH=YES',
  ];

  if (developmentTeam != null)
    commands.add('DEVELOPMENT_TEAM=$developmentTeam');

  final List<FileSystemEntity> contents = fs.directory(app.appDirectory).listSync();
  for (FileSystemEntity entity in contents) {
    if (fs.path.extension(entity.path) == '.xcworkspace') {
      commands.addAll(<String>[
        '-workspace', fs.path.basename(entity.path),
        '-scheme', scheme,
        "BUILD_DIR=${fs.path.absolute(getIosBuildDirectory())}",
      ]);
      break;
    }
  }

  if (buildForDevice) {
    commands.addAll(<String>['-sdk', 'iphoneos', '-arch', 'arm64']);
  } else {
    commands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  if (!codesign) {
    commands.addAll(
      <String>[
        'CODE_SIGNING_ALLOWED=NO',
        'CODE_SIGNING_REQUIRED=NO',
        'CODE_SIGNING_IDENTITY=""'
      ]
    );
  }

  final Status status = logger.startProgress('Running Xcode build...', expectSlowOperation: true);
  final RunResult result = await runAsync(
    commands,
    workingDirectory: app.appDirectory,
    allowReentrantFlutter: true
  );
  status.stop();
  if (result.exitCode != 0) {
    printStatus('Failed to build iOS app');
    if (result.stderr.isNotEmpty) {
      printStatus('Error output from Xcode build:\n↳');
      printStatus(result.stderr, indent: 4);
    }
    if (result.stdout.isNotEmpty) {
      printStatus('Xcode\'s output:\n↳');
      printStatus(result.stdout, indent: 4);
    }
    return new XcodeBuildResult(
      success: false,
      stdout: result.stdout,
      stderr: result.stderr,
      xcodeBuildExecution: new XcodeBuildExecution(
        commands,
        app.appDirectory,
        buildForPhysicalDevice: buildForDevice,
      ),
    );
  } else {
    // Look for 'clean build/<configuration>-<sdk>/Runner.app'.
    final RegExp regexp = new RegExp(r' clean (.*\.app)$', multiLine: true);
    final Match match = regexp.firstMatch(result.stdout);
    String outputDir;
    if (match != null) {
      final String actualOutputDir = match.group(1).replaceAll('\\ ', ' ');
      // Copy app folder to a place where other tools can find it without knowing
      // the BuildInfo.
      outputDir = actualOutputDir.replaceFirst('/$configuration-', '/');
      copyDirectorySync(fs.directory(actualOutputDir), fs.directory(outputDir));
    }
    return new XcodeBuildResult(success: true, output: outputDir);
  }
}

Future<Null> diagnoseXcodeBuildFailure(XcodeBuildResult result, BuildableIOSApp app) async {
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      result.stdout?.contains('BCEROR') == true &&
      // May need updating if Xcode changes its outputs.
      result.stdout?.contains('Xcode couldn\'t find a provisioning profile matching') == true) {
    printError(noProvisioningProfileInstruction, emphasis: true);
    return;
  }
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      // Make sure the user has specified one of:
      // DEVELOPMENT_TEAM (automatic signing)
      // PROVISIONING_PROFILE (manual signing)
      !(app.buildSettings?.containsKey('DEVELOPMENT_TEAM')) == true || app.buildSettings?.containsKey('PROVISIONING_PROFILE') == true) {
    printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (result.xcodeBuildExecution != null &&
      result.xcodeBuildExecution.buildForPhysicalDevice &&
      app.id?.contains('com.yourcompany') ?? false) {
    printError('');
    printError('It appears that your application still contains the default signing identifier.');
    printError("Try replacing 'com.yourcompany' with your signing id in Xcode:");
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
    this.buildCommands,
    this.appDirectory,
    {
      @required this.buildForPhysicalDevice,
    }
  );

  /// The original list of Xcode build commands used to produce this build result.
  final List<String> buildCommands;
  final String appDirectory;
  final bool buildForPhysicalDevice;
}

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!platform.isMacOS)
    return false;
  try {
    final String version = runCheckedSync(<String>['xcodebuild', '-version']);
    final Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < kXcodeRequiredVersionMajor) {
      printError('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<Null> _addServicesToBundle(Directory bundle) async {
  final List<Map<String, String>> services = <Map<String, String>>[];
  printTrace("Trying to resolve native pub services.");

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace("Found ${services.length} service definition(s).");

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  final Directory frameworksDirectory = fs.directory(fs.path.join(bundle.path, "Frameworks"));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  final File manifestFile = fs.file(fs.path.join(bundle.path, "ServiceDefinitions.json"));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future<Null> _copyServiceFrameworks(List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace("Copying service frameworks to '${fs.path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    final String dylibPath = await getServiceFromUrl(service['ios-framework'], service['root'], service['name']);
    final File dylib = fs.file(dylibPath);
    printTrace("Copying ${dylib.path} into bundle.");
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
  final List<Map<String, String>> jsonServices = services.map((Map<String, String> service) => <String, String>{
    'name': service['name'],
    // Since we have already moved it to the Frameworks directory. Strip away
    // the directory and basenames.
    'framework': fs.path.basenameWithoutExtension(service['ios-framework'])
  }).toList();
  final Map<String, dynamic> json = <String, dynamic>{ 'services' : jsonServices };
  manifest.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
}
