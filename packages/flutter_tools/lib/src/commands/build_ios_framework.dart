// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../globals.dart';
import '../macos/cocoapod_utils.dart';
import '../macos/xcode.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

class BuildIOSFrameworkCommand extends BuildSubCommand {
  BuildIOSFrameworkCommand({this.targetPlatform}) {
    usesTargetOption();
    usesPubOption();
    argParser
      ..addFlag('debug',
        negatable: true,
        defaultsTo: true,
        help: 'Whether to produce a framework for the debug build configuration. '
              'By default, all build configurations are built.'
      )
      ..addFlag('profile',
        negatable: true,
        defaultsTo: true,
        help: 'Whether to produce a framework for the profile build configuration. '
              'By default, all build configurations are built.'
      )
      ..addFlag('release',
        negatable: true,
        defaultsTo: true,
        help: 'Whether to produce a framework for the release build configuration. '
              'By default, all build configurations are built.'
      )
      ..addFlag('universal',
        help: 'Produce universal frameworks that include all valid architectures. '
              'This is true by default.',
        defaultsTo: true,
        negatable: true
      )
      ..addFlag('xcframework',
        help: 'Produce xcframeworks that include all valid architectures (Xcode 11 or later).',
      )
      ..addOption('output',
        abbr: 'o',
        valueHelp: 'path/to/directory/',
        defaultsTo: fs.path.join(fs.currentDirectory.path, 'out'),
        help: 'Location to write the frameworks.',
      );
  }

  final TargetPlatform targetPlatform;

  @override
  final String name = 'ios-framework';

  @override
  final List<String> aliases = <String>['ios-framework'];

  @override
  final String description = 'Produce embeddable iOS frameworks (Mac OS X host only).';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.iOS,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();
    if (!flutterProject.isModule) {
      throwToolExit('Building frameworks for iOS is only supported from a module.');
    }

    if (getCurrentHostPlatform() != HostPlatform.darwin_x64) {
      throwToolExit('Building frameworks for iOS is only supported on the Mac.');
    }

    if (targetPlatform != TargetPlatform.ios) {
      throwToolExit('Building frameworks is only currently supported for iOS.');
    }

    if (argResults['xcframework'] && xcode.majorVersion < 11) {
      throwToolExit('--xcframework requires Xcode 11.');
    }

    if (!argResults['universal'] && !argResults['xcframework']) {
      throwToolExit('--universal or --xcframework is required.');
    }
    final List<BuildMode> buildModes = <BuildMode>[];

    if (argResults['debug']) {
      buildModes.add(BuildMode.debug);
    }

    if (argResults['profile']) {
      buildModes.add(BuildMode.profile);
    }

    if (argResults['release']) {
      buildModes.add(BuildMode.release);
    }

    if (buildModes.isEmpty) {
      throwToolExit('--debug or --profile or --release is required.');
    }

    final String outputArgument = argResults['output'];

    if (outputArgument.isEmpty) {
      throwToolExit('--output is required.');
    }

    final Directory outputDirectory = fs.directory(fs.path.normalize(outputArgument));

    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }

    for (BuildMode mode in buildModes) {
      final String xcodeBuildConfiguration = toTitleCase(getNameForBuildMode(mode));
      final Directory modeDirectory = outputDirectory.childDirectory(xcodeBuildConfiguration);
      final Directory iPhoneModeDirectory = modeDirectory.childDirectory('iphoneos');
      final Directory iPhoneSimulatorDirectory = modeDirectory.childDirectory('iphonesimulator');

      // Copy Flutter.framework.
      await _produceFlutterFramework(outputDirectory, mode, iPhoneModeDirectory, iPhoneSimulatorDirectory, modeDirectory);

      // Build aot, create module.framework and copy.
      await _produceAppFramework(mode, iPhoneModeDirectory, modeDirectory);

      // Build and copy plugins.
      await processPodsIfNeeded(flutterProject.ios, getIosBuildDirectory(), mode);
      if (hasPlugins(FlutterProject.current())) {
        await _producePlugins(xcodeBuildConfiguration, iPhoneModeDirectory, iPhoneSimulatorDirectory, modeDirectory, outputDirectory);
      }

      if (iPhoneModeDirectory.existsSync()) {
        iPhoneModeDirectory.deleteSync(recursive: true);
      }

      if (iPhoneSimulatorDirectory.existsSync()) {
        iPhoneSimulatorDirectory.deleteSync(recursive: true);
      }
    }

    printStatus('Frameworks written to ${outputDirectory.path}.');

    return null;
  }

  Future<void> _produceFlutterFramework(Directory outputDirectory, BuildMode mode, Directory iPhoneModeDirectory, Directory iPhoneSimulatorDirectory, Directory modeDirectory) async {
    final String engineCacheFlutterFrameworkDirectory = artifacts.getArtifactPath(Artifact.flutterFramework, platform: targetPlatform, mode: mode);

    // Copy universal engine cache framework to mode directory.
    final String flutterFrameworkFileName = artifactToFileName(Artifact.flutterFramework);
    final Directory fatFlutterFrameworkCopy = modeDirectory.childDirectory(flutterFrameworkFileName);
    copyDirectorySync(fs.directory(engineCacheFlutterFrameworkDirectory), fatFlutterFrameworkCopy);

    if (argResults['xcframework']) {
      // Copy universal framework to variant directory.
      final Directory armFlutterFrameworkDirectory = iPhoneModeDirectory.childDirectory(flutterFrameworkFileName);
      final File armFlutterFrameworkBinary = armFlutterFrameworkDirectory.childFile('Flutter');
      final File fatFlutterFrameworkBinary = fatFlutterFrameworkCopy.childFile('Flutter');
      copyDirectorySync(fatFlutterFrameworkCopy, armFlutterFrameworkDirectory);

      // Create iOS framework.
      List<String> lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-remove', 'x86_64', '-output', armFlutterFrameworkBinary.path];

      await runAsync(
        lipoCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );

      // Create simulator framework.
      final Directory simulatorFlutterFrameworkDirectory = iPhoneSimulatorDirectory.childDirectory(flutterFrameworkFileName);
      final File simulatorFlutterFrameworkBinary = simulatorFlutterFrameworkDirectory.childFile('Flutter');
      copyDirectorySync(fatFlutterFrameworkCopy, simulatorFlutterFrameworkDirectory);

      lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-thin', 'x86_64', '-output', simulatorFlutterFrameworkBinary.path];

      await runAsync(
        lipoCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );

      // Create XCFramework from iOS and simulator frameworks.
      final List<String> xcframeworkCommand = <String>[
        'xcrun',
        'xcodebuild',
        '-create-xcframework',
        '-framework', armFlutterFrameworkDirectory.path,
        '-framework', simulatorFlutterFrameworkDirectory.path,
        '-output', modeDirectory
          .childFile('Flutter.xcframework')
          .path
      ];

      await runAsync(
        xcframeworkCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );
    }

    if (!argResults['universal']) {
      fatFlutterFrameworkCopy.deleteSync(recursive: true);
    }
  }

  Future<void> _produceAppFramework(BuildMode mode, Directory iPhoneModeDirectory, Directory modeDirectory) async {
    const String appFrameworkName = 'App.framework';
    final Directory destinationAppFrameworkDirectory = modeDirectory.childDirectory(appFrameworkName);

    if (mode == BuildMode.debug) {
      await createIOSDebugFrameworkBinary(destinationAppFrameworkDirectory);
    } else {
      await _produceAotAppFrameworkIfNeeded(mode, iPhoneModeDirectory, destinationAppFrameworkDirectory);
    }

    final FlutterProject flutterProject = FlutterProject.current();
    final File sourceInfoPlist = flutterProject.ios.hostAppRoot.childDirectory('Flutter').childFile('AppFrameworkInfo.plist');
    final File destinationInfoPlist = destinationAppFrameworkDirectory.childFile('Info.plist');

    destinationInfoPlist.writeAsBytesSync(sourceInfoPlist.readAsBytesSync());

    final List<String> flutterAssembleCommand = <String>[
      'flutter',
      'build',
      'bundle',
      '--target=${argResults['target']}',
      '--target-platform=ios',
      '--${getNameForBuildMode(mode)}',
      '--asset-dir=${destinationAppFrameworkDirectory.path}/flutter_assets',
      if (mode != BuildMode.debug) '--precompiled'
    ];
    await runAsync(
      flutterAssembleCommand,
      workingDirectory: flutterProject.directory.path,
      allowReentrantFlutter: true,
    );
  }

  Future<void> _produceAotAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneModeDirectory, Directory destinationAppFrameworkDirectory) async {
    if (mode == BuildMode.debug) {
      return;
    }
    final List<String> buildAOTCommand = <String>[
      'flutter',
      '--suppress-analytics',
      'build',
      'aot',
      '--output-dir=${iPhoneModeDirectory.path}',
      '--target-platform=ios',
      '--${getNameForBuildMode(mode)}',
      '--ios-arch=armv7,arm64'
    ];
    await runAsync(
      buildAOTCommand,
      workingDirectory: FlutterProject.current().directory.path,
      allowReentrantFlutter: true,
    );

    const String appFrameworkName = 'App.framework';
    copyDirectorySync(iPhoneModeDirectory.childDirectory(appFrameworkName), destinationAppFrameworkDirectory);
  }

  Future<void> _producePlugins(String xcodeBuildConfiguration, Directory iPhoneModeDirectory, Directory iPhoneSimulatorDirectory, Directory modeDirectory,  Directory outputDirectory) async {
    List<String> pluginsBuildCommand = <String>[
      'xcrun',
      'xcodebuild',
      '-alltargets',
      '-sdk',
      'iphoneos',
      '-configuration',
      xcodeBuildConfiguration,
      'SYMROOT=${iPhoneModeDirectory.path}',
      'ONLY_ACTIVE_ARCH=NO' // No device targeted, so build all valid architectures.
    ];

    final FlutterProject flutterProject = FlutterProject.current();
    await runAsync(
      pluginsBuildCommand,
      workingDirectory: flutterProject.ios.hostAppRoot.childDirectory('Pods').path,
      allowReentrantFlutter: false,
    );

    pluginsBuildCommand = <String>[
      'xcrun',
      'xcodebuild',
      '-alltargets',
      '-sdk',
      'iphonesimulator',
      '-configuration',
      xcodeBuildConfiguration,
      'SYMROOT=${iPhoneSimulatorDirectory.path}',
      'ARCHS=x86_64',
      'ONLY_ACTIVE_ARCH=NO' // No device targeted, so build all valid architectures.
    ];

    await runAsync(
      pluginsBuildCommand,
      workingDirectory: flutterProject.ios.hostAppRoot.childDirectory('Pods').path,
      allowReentrantFlutter: false,
    );


    final Directory iPhoneBuiltProductsDirectory = iPhoneModeDirectory.childDirectory('$xcodeBuildConfiguration-iphoneos');
    final Directory iPhoneSimulatorBuiltProductsDirectory = iPhoneSimulatorDirectory.childDirectory('$xcodeBuildConfiguration-iphonesimulator');

    for (FileSystemEntity builtProduct in iPhoneBuiltProductsDirectory.listSync(followLinks: false)) {
      if (builtProduct is Directory) {
        for (FileSystemEntity podProduct in builtProduct.listSync(followLinks: false)) {
          final String podFrameworkName = podProduct.basename;
          if (fs.path.extension(podFrameworkName) == '.framework') {

            final String binaryName = fs.path.basenameWithoutExtension(podFrameworkName);
            if (argResults['universal']) {
              copyDirectorySync(podProduct, modeDirectory.childDirectory(podFrameworkName));
              final List<String> lipoCommand = <String>[
                'xcrun',
                'lipo',
                '-create',
                fs.path.join(podProduct.path, binaryName),
                iPhoneSimulatorBuiltProductsDirectory.childDirectory(binaryName).childDirectory(podFrameworkName).childFile(binaryName).path,
                '-output',
                modeDirectory.childDirectory(podFrameworkName).childFile(binaryName).path
              ];

              await runAsync(
                lipoCommand,
                workingDirectory: outputDirectory.path,
                allowReentrantFlutter: false,
              );
            }

            if (argResults['xcframework']) {
              final List<String> xcframeworkCommand = <String>[
                'xcrun',
                'xcodebuild',
                '-create-xcframework',
                '-framework',
                podProduct.path,
                '-framework',
                iPhoneSimulatorBuiltProductsDirectory.childDirectory(binaryName).childDirectory(podFrameworkName).path,
                '-output',
                modeDirectory.childFile('$binaryName.xcframework').path
              ];

              await runAsync(
                xcframeworkCommand,
                workingDirectory: outputDirectory.path,
                allowReentrantFlutter: false,
              );
            }
          }
        }
      }
    }
  }
}
