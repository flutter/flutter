// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Build properties passed to Gradle via `-P` command line flags.
const String propShouldShrinkResources = 'shrink';
const String propSplitPerAbi = 'split-per-abi';
const String propLocalEngineRepo = 'local-engine-repo';
const String propIsVerbose = 'verbose';
const String propTarget = 'target';
const String propLocalEngineBuildMode = 'local-engine-build-mode';
const String propTargetPlatform = 'target-platform';
const String propDisableAbiFiltering = 'disable-abi-filtering';
const String propSdkManagerPath = 'flutter.sdkManagerPath';
const String propAndroidSdkRoot = 'flutter.androidSdkRoot';
const String propInstalledNdkVersions = 'flutter.installedNdkVersions';
const String propForceVersionCodeIgnoringAbi = 'force-version-code-ignoring-abi';
const String propDartDefines = 'dart-defines';
const String propDartObfuscation = 'dart-obfuscation';
const String propFrontendServerStarterPath = 'frontend-server-starter-path';
const String propExtraFrontEndOptions = 'extra-front-end-options';
const String propExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
const String propSplitDebugInfo = 'split-debug-info';
const String propTrackWidgetCreation = 'track-widget-creation';
const String propTreeShakeIcons = 'tree-shake-icons';
const String propPerformanceMeasurementFile = 'performance-measurement-file';
const String propCodeSizeDirectory = 'code-size-directory';
const String propDeferredComponents = 'deferred-components';
const String propValidateDeferredComponents = 'validate-deferred-components';
const String propDeferredComponentNames = 'deferred-component-names';
const String propFilesystemRoots = 'filesystem-roots';
const String propFilesystemScheme = 'filesystem-scheme';
const String propBuildNumber = 'buildNumber';
const String propOutputPath = 'outputPath';
const String propOutputDir = 'output-dir';
const String propIsPlugin = 'is-plugin';
const String propBaseApplicationName = 'base-application-name';

// Target platforms for Flutter Android builds.
const String platformArm32 = 'android-arm';
const String platformArm64 = 'android-arm64';
const String platformX86_64 = 'android-x64';

// ABI architectures supported by Flutter Android builds.
const String archArm32 = 'armeabi-v7a';
const String archArm64 = 'arm64-v8a';
const String archX86_64 = 'x86_64';

// ABI version overrides for APK splitting.
const int abiVersionArm32 = 1;
const int abiVersionArm64 = 2;
const int abiVersionX86_64 = 4;

// Task names and output prefixes.
const String taskPrintNdkVersion = 'printNdkVersion';
const String ndkVersionOutputPrefix = 'NdkVersion: ';
