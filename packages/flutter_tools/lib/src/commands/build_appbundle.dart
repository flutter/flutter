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
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAppBundleCommand extends BuildSubCommand {
  BuildAppBundleCommand({
    bool verboseHelp = false,
  }) : super(verboseHelp: verboseHelp) {
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
    addMultidexOption();
    addIgnoreDeprecationOption();
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
            ' the regular assets section in pubspec.yaml. This flag has no effect on '
            'non-deferred components apps.',
    );
    argParser.addFlag('validate-deferred-components',
      negatable: true,
      defaultsTo: true,
      help: 'When enabled, deferred component apps will fail to build if setup problems are '
            'detected that would prevent deferred components from functioning properly. The '
            'tooling also provides guidance on how to set up the project files to pass this '
            'verification. Disabling setup verification will always attempt to fully build '
            'the app regardless of any problems detected. Builds that are part of CI testing '
            'and advanced users with custom deferred components implementations should disable '
            'setup verification. This flag has no effect on non-deferred components apps.',
    );
  }

  @override
  final String name = 'appbundle';

  @override
  DeprecationBehavior get deprecationBehavior => boolArg('ignore-deprecation') ? DeprecationBehavior.ignore : DeprecationBehavior.exit;

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
  Future<CustomDimensions> get usageValues async {
    String buildMode;

    if (boolArg('release')) {
      buildMode = 'release';
    } else if (boolArg('debug')) {
      buildMode = 'debug';
    } else if (boolArg('profile')) {
      buildMode = 'profile';
    } else {
      // The build defaults to release.
      buildMode = 'release';
    }

    return CustomDimensions(
      commandBuildAppBundleTargetPlatform: stringsArg('target-platform').join(','),
      commandBuildAppBundleBuildMode: buildMode,
    );
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.androidSdk == null) {
      exitWithNoSdkMessage();
    }

    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(await getBuildInfo(),
      targetArchs: stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName),
      multidexEnabled: boolArg('multidex'),
    );
    // Do all setup verification that doesn't involve loading units. Checks that
    // require generated loading units are done after gen_snapshot in assemble.
    if (FlutterProject.current().manifest.deferredComponents != null && boolArg('deferred-components') && boolArg('validate-deferred-components') && !boolArg('debug')) {
      final DeferredComponentsPrebuildValidator validator = DeferredComponentsPrebuildValidator(
        FlutterProject.current().directory,
        globals.logger,
        globals.platform,
        title: 'Deferred components prebuild validation',
      );
      validator.clearOutputDir();
      await validator.checkAndroidDynamicFeature(FlutterProject.current().manifest.deferredComponents);
      validator.checkAndroidResourcesStrings(FlutterProject.current().manifest.deferredComponents);

      validator.handleResults();

      // Delete intermediates libs dir for components to resolve mismatching
      // abis supported by base and dynamic feature modules.
      for (final DeferredComponent component in FlutterProject.current().manifest.deferredComponents) {
        final Directory deferredLibsIntermediate = FlutterProject.current().directory
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
    globals.terminal.usesTerminalUi = true;
    await androidBuilder.buildAab(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
      validateDeferredComponents: boolArg('validate-deferred-components'),
      deferredComponentsEnabled: boolArg('deferred-components') && !boolArg('debug'),
    );
    return FlutterCommandResult.success();
  }
}
