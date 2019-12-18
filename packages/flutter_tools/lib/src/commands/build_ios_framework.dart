// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';

import '../aot.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/targets/ios.dart';
import '../bundle.dart';
import '../cache.dart';
import '../globals.dart';
import '../macos/cocoapod_utils.dart';
import '../macos/xcode.dart';
import '../plugins.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

/// Produces a .framework for integration into a host iOS app. The .framework
/// contains the Flutter engine and framework code as well as plugins. It can
/// be integrated into plain Xcode projects without using or other package
/// managers.
class BuildIOSFrameworkCommand extends BuildSubCommand {
  BuildIOSFrameworkCommand({this.aotBuilder, this.bundleBuilder}) {
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesDartDefines();
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
    DevelopmentArtifact.iOS,
  };

  FlutterProject _project;

  List<BuildMode> get buildModes {
    final List<BuildMode> buildModes = <BuildMode>[];

    if (boolArg('debug')) {
      buildModes.add(BuildMode.debug);
    }
    if (boolArg('profile')) {
      buildModes.add(BuildMode.profile);
    }
    if (boolArg('release')) {
      buildModes.add(BuildMode.release);
    }

    return buildModes;
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    _project = FlutterProject.current();
    if (!_project.isModule) {
      throwToolExit('Building frameworks for iOS is only supported from a module.');
    }

    if (!platform.isMacOS) {
      throwToolExit('Building frameworks for iOS is only supported on the Mac.');
    }

    if (!boolArg('universal') && !boolArg('xcframework')) {
      throwToolExit('--universal or --xcframework is required.');
    }
    if (boolArg('xcframework') && xcode.majorVersion < 11) {
      throwToolExit('--xcframework requires Xcode 11.');
    }
    if (buildModes.isEmpty) {
      throwToolExit('At least one of "--debug" or "--profile", or "--release" is required.');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();

    final String outputArgument = stringArg('output')
        ?? fs.path.join(fs.currentDirectory.path, 'build', 'ios', 'framework');

    if (outputArgument.isEmpty) {
      throwToolExit('--output is required.');
    }

    final BuildableIOSApp iosProject = await applicationPackages.getPackageForPlatform(TargetPlatform.ios) as BuildableIOSApp;

    if (iosProject == null) {
      throwToolExit("Module's iOS folder missing");
    }

    final Directory outputDirectory = fs.directory(fs.path.absolute(fs.path.normalize(outputArgument)));

    aotBuilder ??= AotBuilder();
    bundleBuilder ??= BundleBuilder();

    for (BuildMode mode in buildModes) {
      printStatus('Building framework for $iosProject in ${getNameForBuildMode(mode)} mode...');
      final String xcodeBuildConfiguration = toTitleCase(getNameForBuildMode(mode));
      final Directory modeDirectory = outputDirectory.childDirectory(xcodeBuildConfiguration);

      if (modeDirectory.existsSync()) {
        modeDirectory.deleteSync(recursive: true);
      }
      final Directory iPhoneBuildOutput = modeDirectory.childDirectory('iphoneos');
      final Directory simulatorBuildOutput = modeDirectory.childDirectory('iphonesimulator');

      // Copy Flutter.framework.
      await _produceFlutterFramework(outputDirectory, mode, iPhoneBuildOutput, simulatorBuildOutput, modeDirectory);

      // Build aot, create module.framework and copy.
      await _produceAppFramework(mode, iPhoneBuildOutput, simulatorBuildOutput, modeDirectory);

      // Build and copy plugins.
      await processPodsIfNeeded(_project.ios, getIosBuildDirectory(), mode);
      if (hasPlugins(_project)) {
        await _producePlugins(xcodeBuildConfiguration, iPhoneBuildOutput, simulatorBuildOutput, modeDirectory, outputDirectory);
      }

      final Status status = logger.startProgress(' └─Moving to ${fs.path.relative(modeDirectory.path)}', timeout: timeoutConfiguration.slowOperation);
      try {
        // Delete the intermediaries since they would have been copied into our
        // output frameworks.
        if (iPhoneBuildOutput.existsSync()) {
          iPhoneBuildOutput.deleteSync(recursive: true);
        }
        if (simulatorBuildOutput.existsSync()) {
          simulatorBuildOutput.deleteSync(recursive: true);
        }
      } finally {
        status.stop();
      }
    }

    printStatus('Frameworks written to ${outputDirectory.path}.');

    return null;
  }

  Future<void> _produceFlutterFramework(Directory outputDirectory, BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory modeDirectory) async {
    final Status status = logger.startProgress(' ├─Populating Flutter.framework...', timeout: timeoutConfiguration.slowOperation);
    try {
      final String engineCacheFlutterFrameworkDirectory = artifacts.getArtifactPath(Artifact.flutterFramework, platform: TargetPlatform.ios, mode: mode);

      // Copy universal engine cache framework to mode directory.
      final String flutterFrameworkFileName = fs.path.basename(engineCacheFlutterFrameworkDirectory);
      final Directory fatFlutterFrameworkCopy = modeDirectory.childDirectory(flutterFrameworkFileName);
      copyDirectorySync(fs.directory(engineCacheFlutterFrameworkDirectory), fatFlutterFrameworkCopy);

      if (boolArg('xcframework')) {
        // Copy universal framework to variant directory.
        final Directory armFlutterFrameworkDirectory = iPhoneBuildOutput.childDirectory(flutterFrameworkFileName);
        final File armFlutterFrameworkBinary = armFlutterFrameworkDirectory.childFile('Flutter');
        final File fatFlutterFrameworkBinary = fatFlutterFrameworkCopy.childFile('Flutter');
        copyDirectorySync(fatFlutterFrameworkCopy, armFlutterFrameworkDirectory);

        // Create iOS framework.
        List<String> lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-remove', 'x86_64', '-output', armFlutterFrameworkBinary.path];

        RunResult lipoResult = processUtils.runSync(
          lipoCommand,
          workingDirectory: outputDirectory.path,
          allowReentrantFlutter: false,
        );

        if (lipoResult.exitCode != 0) {
          throwToolExit('Unable to create ARM engine framework: ${lipoResult.stderr}');
        }

        // Create simulator framework.
        final Directory simulatorFlutterFrameworkDirectory = simulatorBuildOutput.childDirectory(flutterFrameworkFileName);
        final File simulatorFlutterFrameworkBinary = simulatorFlutterFrameworkDirectory.childFile('Flutter');
        copyDirectorySync(fatFlutterFrameworkCopy, simulatorFlutterFrameworkDirectory);

        lipoCommand = <String>['xcrun', 'lipo', fatFlutterFrameworkBinary.path, '-thin', 'x86_64', '-output', simulatorFlutterFrameworkBinary.path];

        lipoResult = processUtils.runSync(
          lipoCommand,
          workingDirectory: outputDirectory.path,
          allowReentrantFlutter: false,
        );

        if (lipoResult.exitCode != 0) {
          throwToolExit('Unable to create simulator engine framework: ${lipoResult.stderr}');
        }

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

        final RunResult xcframeworkResult = processUtils.runSync(
          xcframeworkCommand,
          workingDirectory: outputDirectory.path,
          allowReentrantFlutter: false,
        );

        if (xcframeworkResult.exitCode != 0) {
          throwToolExit('Unable to create engine XCFramework: ${xcframeworkResult.stderr}');
        }
      }

      if (!boolArg('universal')) {
        fatFlutterFrameworkCopy.deleteSync(recursive: true);
      }
    } finally {
      status.stop();
    }
  }

  Future<void> _produceAppFramework(BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory modeDirectory) async {
    const String appFrameworkName = 'App.framework';
    final Directory destinationAppFrameworkDirectory = modeDirectory.childDirectory(appFrameworkName);
    destinationAppFrameworkDirectory.createSync(recursive: true);

    if (mode == BuildMode.debug) {
      final Status status = logger.startProgress(' ├─Add placeholder App.framework for debug...', timeout: timeoutConfiguration.fastOperation);
      try {
        await _produceStubAppFrameworkIfNeeded(mode, iPhoneBuildOutput, simulatorBuildOutput, destinationAppFrameworkDirectory);
      } finally {
        status.stop();
      }
    } else {
      await _produceAotAppFrameworkIfNeeded(mode, iPhoneBuildOutput, destinationAppFrameworkDirectory);
    }

    final File sourceInfoPlist = _project.ios.hostAppRoot.childDirectory('Flutter').childFile('AppFrameworkInfo.plist');
    final File destinationInfoPlist = destinationAppFrameworkDirectory.childFile('Info.plist')..createSync(recursive: true);

    destinationInfoPlist.writeAsBytesSync(sourceInfoPlist.readAsBytesSync());

    final Status status = logger.startProgress(' ├─Assembling Flutter resources for App.framework...', timeout: timeoutConfiguration.slowOperation);
    try {
      await bundleBuilder.build(
        platform: TargetPlatform.ios,
        buildMode: mode,
        // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
        mainPath: fs.path.absolute(targetFile),
        assetDirPath: destinationAppFrameworkDirectory.childDirectory('flutter_assets').path,
        precompiledSnapshot: mode != BuildMode.debug,
      );
    } finally {
      status.stop();
    }
  }

  Future<void> _produceStubAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneBuildOutput, Directory simulatorBuildOutput, Directory destinationAppFrameworkDirectory) async {
    if (mode != BuildMode.debug) {
      return;
    }
    const String appFrameworkName = 'App.framework';
    const String binaryName = 'App';

    final Directory iPhoneAppFrameworkDirectory = iPhoneBuildOutput.childDirectory(appFrameworkName);
    final File iPhoneAppFrameworkFile = iPhoneAppFrameworkDirectory.childFile(binaryName);
    await createStubAppFramework(iPhoneAppFrameworkFile, SdkType.iPhone);

    final Directory simulatorAppFrameworkDirectory = simulatorBuildOutput.childDirectory(appFrameworkName);
    final File simulatorAppFrameworkFile = simulatorAppFrameworkDirectory.childFile(binaryName);
    await createStubAppFramework(simulatorAppFrameworkFile, SdkType.iPhoneSimulator);

    final List<String> lipoCommand = <String>[
      'xcrun',
      'lipo',
      '-create',
      iPhoneAppFrameworkFile.path,
      simulatorAppFrameworkFile.path,
      '-output',
      destinationAppFrameworkDirectory.childFile(binaryName).path
    ];

    final RunResult lipoResult = processUtils.runSync(
      lipoCommand,
      allowReentrantFlutter: false,
    );

    if (lipoResult.exitCode != 0) {
      throwToolExit('Unable to create compiled dart universal framework: ${lipoResult.stderr}');
    }
  }

  Future<void> _produceAotAppFrameworkIfNeeded(BuildMode mode, Directory iPhoneBuildOutput, Directory destinationAppFrameworkDirectory) async {
    if (mode == BuildMode.debug) {
      return;
    }
    final Status status = logger.startProgress(' ├─Building Dart AOT for App.framework...', timeout: timeoutConfiguration.slowOperation);
    try {
      await aotBuilder.build(
        platform: TargetPlatform.ios,
        outputPath: iPhoneBuildOutput.path,
        buildMode: mode,
        // Relative paths show noise in the compiler https://github.com/dart-lang/sdk/issues/37978.
        mainDartFile: fs.path.absolute(targetFile),
        quiet: true,
        bitcode: true,
        reportTimings: false,
        iosBuildArchs: <DarwinArch>[DarwinArch.armv7, DarwinArch.arm64],
        dartDefines: dartDefines,
      );

      const String appFrameworkName = 'App.framework';
      copyDirectorySync(iPhoneBuildOutput.childDirectory(appFrameworkName), destinationAppFrameworkDirectory);
    } finally {
      status.stop();
    }
  }

  Future<void> _producePlugins(
    String xcodeBuildConfiguration,
    Directory iPhoneBuildOutput,
    Directory simulatorBuildOutput,
    Directory modeDirectory,
    Directory outputDirectory,
  ) async {
    final Status status = logger.startProgress(' ├─Building plugins...', timeout: timeoutConfiguration.slowOperation);
    try {
      List<String> pluginsBuildCommand = <String>[
        'xcrun',
        'xcodebuild',
        '-alltargets',
        '-sdk',
        'iphoneos',
        '-configuration',
        xcodeBuildConfiguration,
        'SYMROOT=${iPhoneBuildOutput.path}',
        'ONLY_ACTIVE_ARCH=NO' // No device targeted, so build all valid architectures.
      ];

      RunResult buildPluginsResult = processUtils.runSync(
        pluginsBuildCommand,
        workingDirectory: _project.ios.hostAppRoot.childDirectory('Pods').path,
        allowReentrantFlutter: false,
      );

      if (buildPluginsResult.exitCode != 0) {
        throwToolExit('Unable to build plugin frameworks: ${buildPluginsResult.stderr}');
      }

      pluginsBuildCommand = <String>[
        'xcrun',
        'xcodebuild',
        '-alltargets',
        '-sdk',
        'iphonesimulator',
        '-configuration',
        xcodeBuildConfiguration,
        'SYMROOT=${simulatorBuildOutput.path}',
        'ARCHS=x86_64',
        'ONLY_ACTIVE_ARCH=NO' // No device targeted, so build all valid architectures.
      ];

      buildPluginsResult = processUtils.runSync(
        pluginsBuildCommand,
        workingDirectory: _project.ios.hostAppRoot.childDirectory('Pods').path,
        allowReentrantFlutter: false,
      );

      if (buildPluginsResult.exitCode != 0) {
        throwToolExit('Unable to build plugin frameworks for simulator: ${buildPluginsResult.stderr}');
      }

      final Directory iPhoneBuildConfiguration = iPhoneBuildOutput.childDirectory('$xcodeBuildConfiguration-iphoneos');
      final Directory simulatorBuildConfiguration = simulatorBuildOutput.childDirectory('$xcodeBuildConfiguration-iphonesimulator');

      for (Directory builtProduct in iPhoneBuildConfiguration.listSync(followLinks: false).whereType<Directory>()) {
        for (FileSystemEntity podProduct in builtProduct.listSync(followLinks: false)) {
          final String podFrameworkName = podProduct.basename;
          if (fs.path.extension(podFrameworkName) == '.framework') {
            final String binaryName = fs.path.basenameWithoutExtension(podFrameworkName);
            if (boolArg('universal')) {
              copyDirectorySync(podProduct as Directory, modeDirectory.childDirectory(podFrameworkName));
              final List<String> lipoCommand = <String>[
                'xcrun',
                'lipo',
                '-create',
                fs.path.join(podProduct.path, binaryName),
                simulatorBuildConfiguration.childDirectory(binaryName).childDirectory(podFrameworkName).childFile(binaryName).path,
                '-output',
                modeDirectory.childDirectory(podFrameworkName).childFile(binaryName).path
              ];

              final RunResult pluginsLipoResult = processUtils.runSync(
                lipoCommand,
                workingDirectory: outputDirectory.path,
                allowReentrantFlutter: false,
              );

              if (pluginsLipoResult.exitCode != 0) {
                throwToolExit('Unable to create universal $binaryName.framework: ${buildPluginsResult.stderr}');
              }
            }

            if (boolArg('xcframework')) {
              final List<String> xcframeworkCommand = <String>[
                'xcrun',
                'xcodebuild',
                '-create-xcframework',
                '-framework',
                podProduct.path,
                '-framework',
                simulatorBuildConfiguration.childDirectory(binaryName).childDirectory(podFrameworkName).path,
                '-output',
                modeDirectory.childFile('$binaryName.xcframework').path
              ];

              final RunResult xcframeworkResult = processUtils.runSync(
                xcframeworkCommand,
                workingDirectory: outputDirectory.path,
                allowReentrantFlutter: false,
              );

              if (xcframeworkResult.exitCode != 0) {
                throwToolExit('Unable to create $binaryName.xcframework: ${xcframeworkResult.stderr}');
              }
            }
          }
        }
      }
    } finally {
      status.stop();
    }
  }
}
