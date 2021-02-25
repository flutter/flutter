// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../android/android_builder.dart';
import '../android/build_validation.dart';
import '../android/deferred_components_prebuild_validator.dart';
import '../android/gradle_utils.dart';
import '../base/deferred_component.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/common.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAppBundleCommand extends BuildSubCommand {
  BuildAppBundleCommand({bool verboseHelp = false}) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addShrinkingFlag(verboseHelp: verboseHelp);
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    usesTrackWidgetCreation(verboseHelp: verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
    argParser.addMultiOption('target-platform',
      splitCommas: true,
      defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
      allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
      help: 'The target platform for which the app is compiled.',
    );
    argParser.addFlag('deferred-components',
      negatable: true,
      defaultsTo: true,
      help: 'Setting to false disables building with deferred components. All deferred code '
            'will be compiled into the base app, and assets act as if they were defined under'
            ' the regular assets section in pubspec.yaml. Defaults to true.',
    );
    argParser.addFlag('verify-deferred-components',
      negatable: true,
      defaultsTo: true,
      help: 'When enabled, deferred component apps will fail to build if setup problems are '
            'detected that would prevent deferred components from functioning properly. The '
            'tooling also provides guidance on how to set up the project files to pass this '
            'verification. Disabling setup verification will always attempt to fully build '
            'the app regardless of any problems detected. Builds that are part of CI testing '
            'and advanced users custom deferred components implementations should disable'
            'setup verification. This flag has no effect on non-deferred components apps. '
            'Defaults to true.',
    );
  }

  @override
  final String name = 'appbundle';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  final String description =
      'Build an Android App Bundle file from your app.\n\n'
      "This command can build debug and release versions of an app bundle for your application. 'debug' builds support "
      "debugging and a quick development cycle. 'release' builds don't support debugging and are "
      'suitable for deploying to app stores. \n app bundle improves your app size';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final Map<CustomDimensions, String> usage = <CustomDimensions, String>{};

    usage[CustomDimensions.commandBuildAppBundleTargetPlatform] =
        stringsArg('target-platform').join(',');

    if (boolArg('release')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'release';
    } else if (boolArg('debug')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'debug';
    } else if (boolArg('profile')) {
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'profile';
    } else {
      // The build defaults to release.
      usage[CustomDimensions.commandBuildAppBundleBuildMode] = 'release';
    }
    return usage;
  }

  Environment createEnvironment() {
    final FlutterProject flutterProject = FlutterProject.current();
    final Map<String, String> defines = <String, String>{ kDeferredComponents: 'false' };
    if (FlutterProject.current().manifest.deferredComponents != null && boolArg('deferred-components')) {
      defines[kDeferredComponents] = 'true';
    }
    final String output = flutterProject.directory
        .childDirectory('build')
        .childDirectory('app')
        .childDirectory('intermediates')
        .childDirectory('flutter')
        .childDirectory('release').path;
    final Environment result = Environment(
      outputDir: globals.fs.directory(output),
      buildDir: flutterProject.directory
          .childDirectory('.dart_tool')
          .childDirectory('flutter_build'),
      projectDir: flutterProject.directory,
      defines: defines,
      inputs: <String, String>{},
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      artifacts: globals.artifacts,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      engineVersion: globals.artifacts.isLocalEngine
        ? null
        : globals.flutterVersion.engineRevision
    );
    return result;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.androidSdk == null) {
      exitWithNoSdkMessage();
    }

    // Do all setup verification that doesn't involve loading units. Checks that
    // require generated loading units are done after the compilation in assemble.
    final Environment env = createEnvironment();
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(await getBuildInfo(),
      targetArchs: stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName),
    );
    if (env.defines[kDeferredComponents] == 'true' && boolArg('verify-deferred-components') && !boolArg('debug')) {

      final DeferredComponentsPrebuildValidator validator = DeferredComponentsPrebuildValidator(
        env,
        title: 'Deferred components prebuild verification',
        exitOnFail: true,
      );
      validator.clearOutputDir();
      await validator.checkAndroidDynamicFeature(FlutterProject.current().manifest.deferredComponents);
      validator.checkAndroidResourcesStrings(FlutterProject.current().manifest.deferredComponents);

      validator.handleResults();

      // Delete intermediates libs dir for components to resolve mismatching
      // abis supported by base and dynamic feature modules.
      for (final DeferredComponent component in FlutterProject.current().manifest.deferredComponents) {
        final Directory deferredLibsIntermediate = env.projectDir
          .childDirectory('build')
          .childDirectory(component.name)
          .childDirectory('intermediates')
          .childDirectory('flutter')
          .childDirectory(androidBuildInfo.buildInfo.mode.name)
          .childDirectory('deferred_libs');
        if (deferredLibsIntermediate.existsSync()) {
          deferredLibsIntermediate.deleteSync(recursive: true);
        }
      }
    }

    validateBuild(androidBuildInfo);
    displayNullSafetyMode(androidBuildInfo.buildInfo);
    await androidBuilder.buildAab(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
      verifyDeferredComponents: boolArg('verify-deferred-components'),
      deferredComponentsEnabled: boolArg('deferred-components'),
    );
    return FlutterCommandResult.success();
  }
}
