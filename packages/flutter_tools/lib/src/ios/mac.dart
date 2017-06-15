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
import '../doctor.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../plugins.dart';
import '../services.dart';
import 'code_signing.dart';
import 'xcodeproj.dart';

const int kXcodeRequiredVersionMajor = 7;
const int kXcodeRequiredVersionMinor = 0;

// The Python `six` module is a dependency for Xcode builds, and installed by
// default, but may not be present in custom Python installs; e.g., via
// Homebrew.
const PythonModule kPythonSix = const PythonModule('six');

class PythonModule {
  const PythonModule(this.name);

  final String name;

  bool get isInstalled => exitsHappy(<String>['python', '-c', 'import $name']);

  String get errorMessage =>
    'Missing Xcode dependency: Python module "$name".\n'
    'Install via \'pip install $name\' or \'sudo easy_install $name\'.';
}

class Xcode {
  Xcode() {
    _eulaSigned = false;

    try {
      _xcodeSelectPath = runSync(<String>['xcode-select', '--print-path'])?.trim();
      if (_xcodeSelectPath == null || _xcodeSelectPath.isEmpty) {
        _isInstalled = false;
        return;
      }
      _isInstalled = true;

      _xcodeVersionText = runSync(<String>['xcodebuild', '-version']).replaceAll('\n', ', ');

      if (!xcodeVersionRegex.hasMatch(_xcodeVersionText)) {
        _isInstalled = false;
      } else {
        try {
          printTrace('xcrun clang');
          final ProcessResult result = processManager.runSync(<String>['/usr/bin/xcrun', 'clang']);

          if (result.stdout != null && result.stdout.contains('license'))
            _eulaSigned = false;
          else if (result.stderr != null && result.stderr.contains('license'))
            _eulaSigned = false;
          else
            _eulaSigned = true;
        } catch (error) {
          _eulaSigned = false;
        }
      }
    } catch (error) {
      _isInstalled = false;
    }
  }

  /// Returns [Xcode] active in the current app context.
  static Xcode get instance => context.putIfAbsent(Xcode, () => new Xcode());

  bool get isInstalledAndMeetsVersionCheck => isInstalled && xcodeVersionSatisfactory;

  String _xcodeSelectPath;
  String get xcodeSelectPath => _xcodeSelectPath;

  bool _isInstalled;
  bool get isInstalled => _isInstalled;

  bool _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned => _eulaSigned;

  String _xcodeVersionText;
  String get xcodeVersionText => _xcodeVersionText;

  int _xcodeMajorVersion;
  int get xcodeMajorVersion => _xcodeMajorVersion;

  int _xcodeMinorVersion;
  int get xcodeMinorVersion => _xcodeMinorVersion;

  final RegExp xcodeVersionRegex = new RegExp(r'Xcode ([0-9.]+)');

  bool get xcodeVersionSatisfactory {
    if (!xcodeVersionRegex.hasMatch(xcodeVersionText))
      return false;

    final String version = xcodeVersionRegex.firstMatch(xcodeVersionText).group(1);
    final List<String> components = version.split('.');

    _xcodeMajorVersion = int.parse(components[0]);
    _xcodeMinorVersion = components.length == 1 ? 0 : int.parse(components[1]);

    return _xcodeVersionCheckValid(_xcodeMajorVersion, _xcodeMinorVersion);
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
  BuildMode mode,
  String target: flx.defaultMainPath,
  bool buildForDevice,
  bool codesign: true
}) async {
  if (!_checkXcodeVersion())
    return new XcodeBuildResult(success: false);

  if (!kPythonSix.isInstalled) {
    printError(kPythonSix.errorMessage);
    return new XcodeBuildResult(success: false);
  }

  String developmentTeam;
  if (codesign && buildForDevice)
    developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.
  final Directory appDirectory = fs.directory(app.appDirectory);
  await _addServicesToBundle(appDirectory);
  final bool hasFlutterPlugins = injectPlugins();

  if (hasFlutterPlugins)
    await _runPodInstall(appDirectory, flutterFrameworkDir(mode));

  updateXcodeGeneratedProperties(
    projectPath: fs.currentDirectory.path,
    mode: mode,
    target: target,
    hasPlugins: hasFlutterPlugins
  );

  final List<String> commands = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    'clean',
    'build',
    '-configuration', 'Release',
    'ONLY_ACTIVE_ARCH=YES',
  ];

  if (developmentTeam != null)
    commands.add('DEVELOPMENT_TEAM=$developmentTeam');

  final List<FileSystemEntity> contents = fs.directory(app.appDirectory).listSync();
  for (FileSystemEntity entity in contents) {
    if (fs.path.extension(entity.path) == '.xcworkspace') {
      commands.addAll(<String>[
        '-workspace', fs.path.basename(entity.path),
        '-scheme', fs.path.basenameWithoutExtension(entity.path),
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
    // Look for 'clean build/Release-iphoneos/Runner.app'.
    final RegExp regexp = new RegExp(r' clean (\S*\.app)$', multiLine: true);
    final Match match = regexp.firstMatch(result.stdout);
    String outputDir;
    if (match != null)
      outputDir = fs.path.join(app.appDirectory, match.group(1));
    return new XcodeBuildResult(success:true, output: outputDir);
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
      // Make sure the user has specified at least the DEVELOPMENT_TEAM (for automatic Xcode 8)
      // signing or the PROVISIONING_PROFILE (for manual signing or Xcode 7).
      !(app.buildSettings?.containsKey('DEVELOPMENT_TEAM')) == true || app.buildSettings?.containsKey('PROVISIONING_PROFILE') == true) {
    printError(noDevelopmentTeamInstruction, emphasis: true);
    return;
  }
  if (app.id?.contains('com.yourcompany') ?? false) {
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
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!platform.isMacOS)
    return false;
  try {
    final String version = runCheckedSync(<String>['xcodebuild', '-version']);
    final Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < 7) {
      printError('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    printError('Cannot find "xcodebuild". $_xcodeRequirement');
    return false;
  }
  return true;
}

final String noCocoaPodsConsequence = '''
  CocoaPods is used to retrieve the iOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without resolving iOS dependencies with CocoaPods, plugins will not work on iOS.
  For more info, see https://flutter.io/platform-plugins''';

final String cocoaPodsInstallInstructions = '''
  brew update
  brew install cocoapods
  pod setup''';

final String cocoaPodsUpgradeInstructions = '''
  brew update
  brew upgrade cocoapods
  pod setup''';

Future<Null> _runPodInstall(Directory bundle, String engineDirectory) async {
  if (fs.file(fs.path.join(bundle.path, 'Podfile')).existsSync()) {
    if (!await doctor.iosWorkflow.isCocoaPodsInstalledAndMeetsVersionCheck) {
      final String minimumVersion = doctor.iosWorkflow.cocoaPodsMinimumVersion;
      printError(
        'Warning: CocoaPods version $minimumVersion or greater not installed. Skipping pod install.\n'
        '$noCocoaPodsConsequence\n'
        'To install:\n'
        '$cocoaPodsInstallInstructions\n',
        emphasis: true,
      );
      return;
    }
    if (!await doctor.iosWorkflow.isCocoaPodsInitialized) {
      printError(
        'Warning: CocoaPods installed but not initialized. Skipping pod install.\n'
        '$noCocoaPodsConsequence\n'
        'To initialize CocoaPods, run:\n'
        '  pod setup\n'
        'once to finalize CocoaPods\' installation.',
        emphasis: true,
      );
      return;
    }
    try {
      final Status status = logger.startProgress('Running pod install...', expectSlowOperation: true);
      await runCheckedAsync(
          <String>['pod', 'install'],
          workingDirectory: bundle.path,
          environment: <String, String>{'FLUTTER_FRAMEWORK_DIR': engineDirectory},
      );
      status.stop();
    } catch (e) {
      throwToolExit('Error running pod install: $e');
    }
  }
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
