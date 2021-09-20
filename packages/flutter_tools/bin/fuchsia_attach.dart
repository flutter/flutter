// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/args.dart';

import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_workflow.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

final ArgParser parser = ArgParser()
  ..addOption('build-dir', help: 'The fuchsia build directory')
  ..addOption('dart-sdk', help: 'The prebuilt dart SDK')
  ..addOption('target', help: 'The GN target to attach to')
  ..addOption('entrypoint', defaultsTo: 'main.dart', help: 'The filename of the main method. Defaults to main.dart')
  ..addOption('device', help: 'The device id to attach to')
  ..addOption('dev-finder', help: 'The location of the device-finder binary')
  ..addOption('ffx', help: 'The location of the ffx binary')
  ..addFlag('verbose', negatable: true);

// Track the original working directory so that the tool can find the
// flutter repo in third_party.
String originalWorkingDirectory;

Future<void> main(List<String> args) async {
  final ArgResults argResults = parser.parse(args);
  final bool verbose = argResults['verbose'] as bool;
  final String target = argResults['target'] as String;
  final List<String> targetParts = _extractPathAndName(target);
  final String path = targetParts[0];
  final String name = targetParts[1];
  final File dartSdk = globals.fs.file(argResults['dart-sdk']);
  final String buildDirectory = argResults['build-dir'] as String;
  final File frontendServer = globals.fs.file('$buildDirectory/host_x64/gen/third_party/flutter/frontend_server/frontend_server_tool.snapshot');
  final File sshConfig = globals.fs.file('$buildDirectory/ssh-keys/ssh_config');
  final File devFinder = globals.fs.file(argResults['dev-finder']);
  final File ffx = globals.fs.file(argResults['ffx']);
  final File platformKernelDill = globals.fs.file('$buildDirectory/flutter_runner_patched_sdk/platform_strong.dill');
  final File flutterPatchedSdk = globals.fs.file('$buildDirectory/flutter_runner_patched_sdk');
  final String packages = '$buildDirectory/dartlang/gen/$path/${name}_dart_library.packages';
  final String outputDill = '$buildDirectory/${name}_tmp.dill';

  // Running from fuchsia root hangs hot reload for some reason.
  // switch to the project root directory and run from there.
  originalWorkingDirectory = globals.fs.currentDirectory.path;
  globals.fs.currentDirectory = path;

  if (!devFinder.existsSync()) {
    print('Error: device-finder not found at ${devFinder.path}.');
    return 1;
  }
  if (!ffx.existsSync()) {
    print('Error: ffx not found at ${ffx.path}.');
    return 1;
  }
  if (!frontendServer.existsSync()) {
    print(
      'Error: frontend_server not found at ${frontendServer.path}. This '
      'Usually means you ran fx set without specifying '
      '--args=flutter_profile=true.'
    );
    return 1;
  }

  // Check for a package with a lib directory.
  final String entrypoint = argResults['entrypoint'] as String;
  String targetFile = 'lib/$entrypoint';
  if (!globals.fs.file(targetFile).existsSync()) {
    // Otherwise assume the package is flat.
    targetFile = entrypoint;
  }
  final String deviceName = argResults['device'] as String;
  final List<String> command = <String>[
    'attach',
    '--module',
    name,
    '--target',
    targetFile,
    '--target-model',
    'flutter_runner',
    '--output-dill',
    outputDill,
    '--packages',
    packages,
    if (deviceName != null && deviceName.isNotEmpty) ...<String>['-d', deviceName],
    if (verbose) '--verbose',
  ];
  Cache.disableLocking(); // ignore: invalid_use_of_visible_for_testing_member
  await runner.run(
    command,
    () => <FlutterCommand>[
      _FuchsiaAttachCommand(),
      _FuchsiaDoctorCommand(), // If attach fails the tool will attempt to run doctor.
    ],
    verbose: verbose,
    muteCommandLogging: false,
    verboseHelp: false,
    overrides: <Type, Generator>{
      FeatureFlags: () => const _FuchsiaFeatureFlags(),
      DeviceManager: () => _FuchsiaDeviceManager(),
      FuchsiaArtifacts: () => FuchsiaArtifacts(
        sshConfig: sshConfig, devFinder: devFinder, ffx: ffx),
      Artifacts: () => OverrideArtifacts(
        parent: CachedArtifacts(
          fileSystem: globals.fs,
          cache: globals.cache,
          platform: globals.platform,
          operatingSystemUtils: globals.os,
        ),
        frontendServer: frontendServer,
        engineDartBinary: dartSdk,
        platformKernelDill: platformKernelDill,
        flutterPatchedSdk: flutterPatchedSdk,
      ),
    },
  );
}

// An implementation of [DeviceManager] that only supports fuchsia devices.
class _FuchsiaDeviceManager extends DeviceManager {
  @override
  List<DeviceDiscovery> get deviceDiscoverers => List<DeviceDiscovery>.unmodifiable(<DeviceDiscovery>[
    FuchsiaDevices(
      logger: globals.logger,
      platform: globals.platform,
      fuchsiaWorkflow: fuchsiaWorkflow,
      fuchsiaSdk: fuchsiaSdk,
    ),
  ]);

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    return true;
  }
}

List<String> _extractPathAndName(String gnTarget) {
  // Separate strings like //path/to/target:app into [path/to/target, app]
  final int lastColon = gnTarget.lastIndexOf(':');
  if (lastColon < 0) {
    throwToolExit('invalid path: $gnTarget');
  }
  final String name = gnTarget.substring(lastColon + 1);
  // Skip '//' and chop off after :
  if ((gnTarget.length < 3) || (gnTarget[0] != '/') || (gnTarget[1] != '/')) {
    throwToolExit('invalid path: $gnTarget');
  }
  final String path = gnTarget.substring(2, lastColon);
  return <String>[path, name];
}

class _FuchsiaDoctorCommand extends DoctorCommand {
  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.flutterRoot = '$originalWorkingDirectory/third_party/dart-pkg/git/flutter';
    return super.runCommand();
  }
}

class _FuchsiaAttachCommand extends AttachCommand {
  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.flutterRoot = '$originalWorkingDirectory/third_party/dart-pkg/git/flutter';
    return super.runCommand();
  }
}

class _FuchsiaFeatureFlags extends FeatureFlags {
  const _FuchsiaFeatureFlags();

  @override
  bool get isLinuxEnabled => false;

  @override
  bool get isMacOSEnabled => false;

  @override
  bool get isWebEnabled => false;

  @override
  bool get isWindowsEnabled => false;

  @override
  bool get isAndroidEnabled => false;

  @override
  bool get isIOSEnabled => false;

  @override
  bool get isFuchsiaEnabled => true;

  @override
  bool get isSingleWidgetReloadEnabled => false;
}
