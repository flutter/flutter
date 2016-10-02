// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application_package.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../services.dart';
import 'xcodeproj.dart';

String get homeDirectory => path.absolute(Platform.environment['HOME']);

const int kXcodeRequiredVersionMajor = 7;
const int kXcodeRequiredVersionMinor = 0;

class XCode {
  XCode() {
    _eulaSigned = false;

    try {
      _xcodeSelectPath = runSync(<String>['xcode-select', '--print-path']);
      if (_xcodeSelectPath == null || _xcodeSelectPath.trim().isEmpty) {
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
          ProcessResult result = Process.runSync('/usr/bin/xcrun', <String>['clang']);

          if (result.stdout != null && result.stdout.contains('license'))
            _eulaSigned = false;
          else if (result.stderr != null && result.stderr.contains('license'))
            _eulaSigned = false;
          else
            _eulaSigned = true;
        } catch (error) {
        }
      }
    } catch (error) {
      _isInstalled = false;
    }
  }

  /// Returns [XCode] active in the current app context.
  static XCode get instance => context[XCode] ?? (context[XCode] = new XCode());

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

  final RegExp xcodeVersionRegex = new RegExp(r'Xcode ([0-9.]+)');

  bool get xcodeVersionSatisfactory {
    if (!xcodeVersionRegex.hasMatch(xcodeVersionText))
      return false;

    String version = xcodeVersionRegex.firstMatch(xcodeVersionText).group(1);
    List<String> components = version.split('.');

    int major = int.parse(components[0]);
    int minor = components.length == 1 ? 0 : int.parse(components[1]);

    return _xcodeVersionCheckValid(major, minor);
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
  IOSApp app,
  BuildMode mode,
  String target: flx.defaultMainPath,
  bool buildForDevice,
  bool codesign: true
}) async {
  String flutterProjectPath = Directory.current.path;
  updateXcodeGeneratedProperties(flutterProjectPath, mode, target);

  if (!_checkXcodeVersion())
    return new XcodeBuildResult(false);

  // Before the build, all service definitions must be updated and the dylibs
  // copied over to a location that is suitable for Xcodebuild to find them.

  await _addServicesToBundle(new Directory(app.appDirectory));

  List<String> commands = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    'clean',
    'build',
    '-configuration', 'Release',
    'ONLY_ACTIVE_ARCH=YES',
  ];

  List<FileSystemEntity> contents = new Directory(app.appDirectory).listSync();
  for (FileSystemEntity entity in contents) {
    if (path.extension(entity.path) == '.xcworkspace') {
      commands.addAll(<String>[
        '-workspace', path.basename(entity.path),
        '-scheme', path.basenameWithoutExtension(entity.path),
        "BUILD_DIR=${path.absolute(getIosBuildDirectory())}",
      ]);
      break;
    }
  }

  if (buildForDevice) {
    commands.addAll(<String>['-sdk', 'iphoneos', '-arch', 'arm64']);
    if (!codesign) {
      commands.addAll(
        <String>[
          'CODE_SIGNING_ALLOWED=NO',
          'CODE_SIGNING_REQUIRED=NO',
          'CODE_SIGNING_IDENTITY=""'
        ]
      );
    }
  } else {
    commands.addAll(<String>['-sdk', 'iphonesimulator', '-arch', 'x86_64']);
  }

  RunResult result = await runAsync(
    commands,
    workingDirectory: app.appDirectory,
    allowReentrantFlutter: true
  );

  if (result.exitCode != 0) {
    if (result.stderr.isNotEmpty)
      printStatus(result.stderr);
    if (result.stdout.isNotEmpty)
      printStatus(result.stdout);
    return new XcodeBuildResult(false, stdout: result.stdout, stderr: result.stderr);
  } else {
    // Look for 'clean build/Release-iphoneos/Runner.app'.
    RegExp regexp = new RegExp(r' clean (\S*\.app)$', multiLine: true);
    Match match = regexp.firstMatch(result.stdout);
    String outputDir;
    if (match != null)
      outputDir = path.join(app.appDirectory, match.group(1));
    return new XcodeBuildResult(true, output: outputDir);
  }
}

void diagnoseXcodeBuildFailure(XcodeBuildResult result) {
  File plistFile = new File('ios/Runner/Info.plist');
  if (plistFile.existsSync()) {
    String plistContent = plistFile.readAsStringSync();
    if (plistContent.contains('com.yourcompany')) {
      printError('');
      printError('It appears that your application still contains the default signing identifier.');
      printError("Try replacing 'com.yourcompany' with your signing id");
      printError('in ${plistFile.absolute.path}');
      return;
    }
  }
  if (result.stdout?.contains('Code Sign error') == true) {
    printError('');
    printError('It appears that there was a problem signing your application prior to installation on the device.');
    printError('');
    if (plistFile.existsSync()) {
      printError('Verify that the CFBundleIdentifier in the Info.plist file is your signing id');
      printError('  ${plistFile.absolute.path}');
      printError('');
    }
    printError("Try launching XCode and selecting 'Product > Build' to fix the problem:");
    printError("  open ios/Runner.xcodeproj");
    return;
  }
}

class XcodeBuildResult {
  XcodeBuildResult(this.success, {this.output, this.stdout, this.stderr});

  final bool success;
  final String output;
  final String stdout;
  final String stderr;
}

final RegExp _xcodeVersionRegExp = new RegExp(r'Xcode (\d+)\..*');
final String _xcodeRequirement = 'Xcode 7.0 or greater is required to develop for iOS.';

bool _checkXcodeVersion() {
  if (!Platform.isMacOS)
    return false;
  try {
    String version = runCheckedSync(<String>['xcodebuild', '-version']);
    Match match = _xcodeVersionRegExp.firstMatch(version);
    if (int.parse(match[1]) < 7) {
      printError('Found "${match[0]}". $_xcodeRequirement');
      return false;
    }
  } catch (e) {
    printError('Cannot find "xcodebuid". $_xcodeRequirement');
    return false;
  }
  return true;
}

Future<Null> _addServicesToBundle(Directory bundle) async {
  List<Map<String, String>> services = <Map<String, String>>[];
  printTrace("Trying to resolve native pub services.");

  // Step 1: Parse the service configuration yaml files present in the service
  //         pub packages.
  await parseServiceConfigs(services);
  printTrace("Found ${services.length} service definition(s).");

  // Step 2: Copy framework dylibs to the correct spot for xcodebuild to pick up.
  Directory frameworksDirectory = new Directory(path.join(bundle.path, "Frameworks"));
  await _copyServiceFrameworks(services, frameworksDirectory);

  // Step 3: Copy the service definitions manifest at the correct spot for
  //         xcodebuild to pick up.
  File manifestFile = new File(path.join(bundle.path, "ServiceDefinitions.json"));
  _copyServiceDefinitionsManifest(services, manifestFile);
}

Future<Null> _copyServiceFrameworks(List<Map<String, String>> services, Directory frameworksDirectory) async {
  printTrace("Copying service frameworks to '${path.absolute(frameworksDirectory.path)}'.");
  frameworksDirectory.createSync(recursive: true);
  for (Map<String, String> service in services) {
    String dylibPath = await getServiceFromUrl(service['ios-framework'], service['root'], service['name']);
    File dylib = new File(dylibPath);
    printTrace("Copying ${dylib.path} into bundle.");
    if (!dylib.existsSync()) {
      printError("The service dylib '${dylib.path}' does not exist.");
      continue;
    }
    // Shell out so permissions on the dylib are preserved.
    runCheckedSync(<String>['/bin/cp', dylib.path, frameworksDirectory.path]);
  }
}

void _copyServiceDefinitionsManifest(List<Map<String, String>> services, File manifest) {
  printTrace("Creating service definitions manifest at '${manifest.path}'");
  List<Map<String, String>> jsonServices = services.map((Map<String, String> service) => <String, String>{
    'name': service['name'],
    // Since we have already moved it to the Frameworks directory. Strip away
    // the directory and basenames.
    'framework': path.basenameWithoutExtension(service['ios-framework'])
  }).toList();
  Map<String, dynamic> json = <String, dynamic>{ 'services' : jsonServices };
  manifest.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
}
