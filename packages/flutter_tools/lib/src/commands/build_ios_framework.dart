// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/bundle.dart';

import '../aot.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/process.dart';
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
  BuildIOSFrameworkCommand({this.aotBuilder, this.bundleBuilder}) {
    usesTargetOption();
    usesFlavorOption();
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
        defaultsTo: fs.path.join(fs.currentDirectory.path, 'build', 'ios', 'framework'),
        help: 'Location to write the frameworks.',
      );
  }

  AotBuilder aotBuilder;
  BundleBuilder bundleBuilder;

  @override
  final String name = 'ios-framework';

  @override
  final String description = 'Produces a .framework directory for a Flutter module '
      'and its plugins for integration into existing, plain Xcode projects.\n'
      'This can only be run on macOS hosts.';

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

    final BuildableIOSApp iosProject = await applicationPackages.getPackageForPlatform(TargetPlatform.ios);

    if (iosProject == null) {
      throwToolExit("Module's iOS folder missing");
    }

    final Directory outputDirectory = fs.directory(fs.path.normalize(outputArgument));

    if (outputDirectory.existsSync()) {
      outputDirectory.deleteSync(recursive: true);
    }

    aotBuilder ??= AotBuilder();
    bundleBuilder ??= BundleBuilder();

    for (BuildMode mode in buildModes) {
      printStatus('Building framework for $iosProject in ${getNameForBuildMode(mode)} mode...');
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

      final Status status = logger.startProgress(' └─Moving to ${fs.path.relative(modeDirectory.path)}', timeout: timeoutConfiguration.slowOperation);
      if (iPhoneModeDirectory.existsSync()) {
        iPhoneModeDirectory.deleteSync(recursive: true);
      }

      if (iPhoneSimulatorDirectory.existsSync()) {
        iPhoneSimulatorDirectory.deleteSync(recursive: true);
      }
      status.stop();
    }

    printStatus('Frameworks written to ${outputDirectory.path}.');

    return null;
  }

  Future<void> _produceFlutterFramework(Directory outputDirectory, BuildMode mode, Directory iPhoneModeDirectory, Directory iPhoneSimulatorDirectory, Directory modeDirectory) async {
    final Status status = logger.startProgress(' ├─Populating Flutter.framework...', timeout: timeoutConfiguration.fastOperation);
    final String engineCacheFlutterFrameworkDirectory = artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: mode);

    // Copy universal engine cache framework to mode directory.
    final String flutterFrameworkFileName = fs.path.basename(engineCacheFlutterFrameworkDirectory);
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

      processUtils.runSync(
        lipoCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );

      // Create simulator framework.
      final Directory simulatorFlutterFrameworkDirectory = iPhoneSimulatorDirectory.childDirectory(flutterFrameworkFileName);
      final File simulatorFlutterFrameworkBinary = simulatorFlutterFrameworkDirectory.childFile('Flutter');
      copyDirectorySync(fatFlutterFrameworkCopy, simulatorFlutterFrameworkDirectory);

      lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-thin', 'x86_64', '-output', simulatorFlutterFrameworkBinary.path];

      processUtils.runSync(
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

      processUtils.runSync(
        xcframeworkCommand,
        workingDirectory: outputDirectory.path,
        allowReentrantFlutter: false,
      );
    }

    if (!argResults['universal']) {
      fatFlutterFrameworkCopy.deleteSync(recursive: true);
    }
    status.stop();
  }

  Future<void> _produceAppFramework(BuildMode mode, Directory iPhoneModeDirectory, Directory modeDirectory) async {
    const String appFrameworkName = 'App.framework';
    final Directory destinationAppFrameworkDirectory = modeDirectory.childDirectory(appFrameworkName);

    if (mode == BuildMode.debug) {
      // await createIOSDebugFrameworkBinary(destinationAppFrameworkDirectory);
    } else {
      await _produceAotAppFrameworkIfNeeded(mode, iPhoneModeDirectory, destinationAppFrameworkDirectory);
    }

    final FlutterProject flutterProject = FlutterProject.current();
    final File sourceInfoPlist = flutterProject.ios.hostAppRoot.childDirectory('Flutter').childFile('AppFrameworkInfo.plist');
    final File destinationInfoPlist = destinationAppFrameworkDirectory.childFile('Info.plist')..createSync(recursive: true);

    destinationInfoPlist.writeAsBytesSync(sourceInfoPlist.readAsBytesSync());

    final Status status = logger.startProgress(' ├─Assembling Flutter resources for App.framework...', timeout: timeoutConfiguration.slowOperation);
    await bundleBuilder.build(
      platform: TargetPlatform.ios,
      buildMode: mode,
      // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
      mainPath: fs.path.absolute(targetFile),
      assetDirPath: destinationAppFrameworkDirectory.childDirectory('flutter_assets').path,
      precompiledSnapshot: mode != BuildMode.debug,
    );
    status.stop();
  }

  Future<void> _produceAotAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneModeDirectory, Directory destinationAppFrameworkDirectory) async {
    if (mode == BuildMode.debug) {
      return;
    }
    final Status status = logger.startProgress(' ├─Building Dart AOT for App.framework...', timeout: timeoutConfiguration.slowOperation);
    await aotBuilder.build(
      platform: TargetPlatform.ios,
      outputPath: iPhoneModeDirectory.path,
      buildMode: mode,
      // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
      mainDartFile: fs.path.absolute(targetFile),
      quiet: true,
      reportTimings: false,
      iosBuildArchs: <DarwinArch>[DarwinArch.armv7, DarwinArch.arm64],
    );

    const String appFrameworkName = 'App.framework';
    copyDirectorySync(iPhoneModeDirectory.childDirectory(appFrameworkName), destinationAppFrameworkDirectory);
    status.stop();
  }

  Future<void> _producePlugins(String xcodeBuildConfiguration, Directory iPhoneModeDirectory, Directory iPhoneSimulatorDirectory, Directory modeDirectory,  Directory outputDirectory) async {
    final Status status = logger.startProgress(' ├─Building plugins...', timeout: timeoutConfiguration.slowOperation);
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
    processUtils.runSync(
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

    processUtils.runSync(
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

              processUtils.runSync(
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

              processUtils.runSync(
                xcframeworkCommand,
                workingDirectory: outputDirectory.path,
                allowReentrantFlutter: false,
              );
            }
          }
        }
      }
    }
    status.stop();
  }
}
