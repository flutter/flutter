// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../flutter_manifest.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'gradle_errors.dart';
import 'gradle_utils.dart';

/// The directory where the APK artifact is generated.
@visibleForTesting
Directory getApkDirectory(FlutterProject project) {
  return project.isModule
    ? project.android.buildDirectory
        .childDirectory('host')
        .childDirectory('outputs')
        .childDirectory('apk')
    : project.android.buildDirectory
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk');
}

/// The directory where the app bundle artifact is generated.
@visibleForTesting
Directory getBundleDirectory(FlutterProject project) {
  return project.isModule
    ? project.android.buildDirectory
        .childDirectory('host')
        .childDirectory('outputs')
        .childDirectory('bundle')
    : project.android.buildDirectory
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('bundle');
}

/// The directory where the repo is generated.
/// Only applicable to AARs.
Directory getRepoDirectory(Directory buildDirectory) {
  return buildDirectory
    .childDirectory('outputs')
    .childDirectory('repo');
}

/// Returns the name of Gradle task that starts with [prefix].
String _taskFor(String prefix, BuildInfo buildInfo) {
  final String buildType = camelCase(buildInfo.modeName);
  final String productFlavor = buildInfo.flavor ?? '';
  return '$prefix${toTitleCase(productFlavor)}${toTitleCase(buildType)}';
}

/// Returns the task to build an APK.
@visibleForTesting
String getAssembleTaskFor(BuildInfo buildInfo) {
  return _taskFor('assemble', buildInfo);
}

/// Returns the task to build an AAB.
@visibleForTesting
String getBundleTaskFor(BuildInfo buildInfo) {
  return _taskFor('bundle', buildInfo);
}

/// Returns the task to build an AAR.
@visibleForTesting
String getAarTaskFor(BuildInfo buildInfo) {
  return _taskFor('assembleAar', buildInfo);
}

/// Returns the output APK file names for a given [AndroidBuildInfo].
///
/// For example, when [splitPerAbi] is true, multiple APKs are created.
Iterable<String> _apkFilesFor(AndroidBuildInfo androidBuildInfo) {
  final String buildType = camelCase(androidBuildInfo.buildInfo.modeName);
  final String productFlavor = androidBuildInfo.buildInfo.flavor ?? '';
  final String flavorString = productFlavor.isEmpty ? '' : '-$productFlavor';
  if (androidBuildInfo.splitPerAbi) {
    return androidBuildInfo.targetArchs.map<String>((AndroidArch arch) {
      final String abi = getNameForAndroidArch(arch);
      return 'app$flavorString-$abi-$buildType.apk';
    });
  }
  return <String>['app$flavorString-$buildType.apk'];
}

/// Returns true if the current version of the Gradle plugin is supported.
bool _isSupportedVersion(AndroidProject project) {
  final File plugin = project.hostAppGradleRoot.childFile(
      globals.fs.path.join('buildSrc', 'src', 'main', 'groovy', 'FlutterPlugin.groovy'));
  if (plugin.existsSync()) {
    return false;
  }
  final File appGradle = project.hostAppGradleRoot.childFile(
      globals.fs.path.join('app', 'build.gradle'));
  if (!appGradle.existsSync()) {
    return false;
  }
  for (final String line in appGradle.readAsLinesSync()) {
    if (line.contains(RegExp(r'apply from: .*/flutter.gradle')) ||
        line.contains("def flutterPluginVersion = 'managed'")) {
      return true;
    }
  }
  return false;
}

/// Returns the apk file created by [buildGradleProject]
Future<File> getGradleAppOut(AndroidProject androidProject) async {
  if (!_isSupportedVersion(androidProject)) {
    _exitWithUnsupportedProjectMessage();
  }
  return getApkDirectory(androidProject.parent).childFile('app.apk');
}

/// Runs `gradlew dependencies`, ensuring that dependencies are resolved and
/// potentially downloaded.
Future<void> checkGradleDependencies() async {
  final Status progress = globals.logger.startProgress(
    'Ensuring gradle dependencies are up to date...',
    timeout: timeoutConfiguration.slowOperation,
  );
  final FlutterProject flutterProject = FlutterProject.current();
  await processUtils.run(<String>[
      gradleUtils.getExecutable(flutterProject),
      'dependencies',
    ],
    throwOnError: true,
    workingDirectory: flutterProject.android.hostAppGradleRoot.path,
    environment: gradleEnvironment,
  );
  globals.androidSdk?.reinitialize();
  progress.stop();
}

/// Tries to create `settings_aar.gradle` in an app project by removing the subprojects
/// from the existing `settings.gradle` file. This operation will fail if the existing
/// `settings.gradle` file has local edits.
@visibleForTesting
void createSettingsAarGradle(Directory androidDirectory) {
  final File newSettingsFile = androidDirectory.childFile('settings_aar.gradle');
  if (newSettingsFile.existsSync()) {
    return;
  }
  final File currentSettingsFile = androidDirectory.childFile('settings.gradle');
  if (!currentSettingsFile.existsSync()) {
    return;
  }
  final String currentFileContent = currentSettingsFile.readAsStringSync();

  final String newSettingsRelativeFile = globals.fs.path.relative(newSettingsFile.path);
  final Status status = globals.logger.startProgress('✏️  Creating `$newSettingsRelativeFile`...',
      timeout: timeoutConfiguration.fastOperation);

  final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
  final File legacySettingsDotGradleFiles = globals.fs.file(globals.fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'settings.gradle.legacy_versions'));
  assert(legacySettingsDotGradleFiles.existsSync());
  final String settingsAarContent = globals.fs.file(globals.fs.path.join(flutterRoot, 'packages','flutter_tools',
      'gradle', 'settings_aar.gradle.tmpl')).readAsStringSync();

  // Get the `settings.gradle` content variants that should be patched.
  final List<String> existingVariants = legacySettingsDotGradleFiles.readAsStringSync().split(';EOF');
  existingVariants.add(settingsAarContent);

  bool exactMatch = false;
  for (final String fileContentVariant in existingVariants) {
    if (currentFileContent.trim() == fileContentVariant.trim()) {
      exactMatch = true;
      break;
    }
  }
  if (!exactMatch) {
    status.cancel();
    globals.printStatus('$warningMark Flutter tried to create the file `$newSettingsRelativeFile`, but failed.');
    // Print how to manually update the file.
    globals.printStatus(globals.fs.file(globals.fs.path.join(flutterRoot, 'packages','flutter_tools',
        'gradle', 'manual_migration_settings.gradle.md')).readAsStringSync());
    throwToolExit('Please create the file and run this command again.');
  }
  // Copy the new file.
  newSettingsFile.writeAsStringSync(settingsAarContent);
  status.stop();
  globals.printStatus('$successMark `$newSettingsRelativeFile` created successfully.');
}

/// Builds an app.
///
/// * [project] is typically [FlutterProject.current()].
/// * [androidBuildInfo] is the build configuration.
/// * [target] is the target dart entry point. Typically, `lib/main.dart`.
/// * If [isBuildingBundle] is `true`, then the output artifact is an `*.aab`,
///   otherwise the output artifact is an `*.apk`.
/// * The plugins are built as AARs if [shouldBuildPluginAsAar] is `true`. This isn't set by default
///   because it makes the build slower proportional to the number of plugins.
/// * [retries] is the max number of build retries in case one of the [GradleHandledError] handler
///   returns [GradleBuildStatus.retry] or [GradleBuildStatus.retryWithAarPlugins].
Future<void> buildGradleApp({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required bool isBuildingBundle,
  @required List<GradleHandledError> localGradleErrors,
  bool shouldBuildPluginAsAar = false,
  int retries = 1,
}) async {
  assert(project != null);
  assert(androidBuildInfo != null);
  assert(target != null);
  assert(isBuildingBundle != null);
  assert(localGradleErrors != null);
  assert(globals.androidSdk != null);

  if (!project.android.isUsingGradle) {
    _exitWithProjectNotUsingGradleMessage();
  }
  if (!_isSupportedVersion(project.android)) {
    _exitWithUnsupportedProjectMessage();
  }
  final Directory buildDirectory = project.android.buildDirectory;

  final bool usesAndroidX = isAppUsingAndroidX(project.android.hostAppGradleRoot);
  if (usesAndroidX) {
    BuildEvent('app-using-android-x', flutterUsage: globals.flutterUsage).send();
  } else if (!usesAndroidX) {
    BuildEvent('app-not-using-android-x', flutterUsage: globals.flutterUsage).send();
    globals.printStatus("$warningMark Your app isn't using AndroidX.", emphasis: true);
    globals.printStatus(
      'To avoid potential build failures, you can quickly migrate your app '
      'by following the steps on https://goo.gl/CP92wY .',
      indent: 4,
    );
  }
  // The default Gradle script reads the version name and number
  // from the local.properties file.
  updateLocalProperties(project: project, buildInfo: androidBuildInfo.buildInfo);

  if (shouldBuildPluginAsAar) {
    // Create a settings.gradle that doesn't import the plugins as subprojects.
    createSettingsAarGradle(project.android.hostAppGradleRoot);
    await buildPluginsAsAar(
      project,
      androidBuildInfo,
      buildDirectory: buildDirectory.childDirectory('app'),
    );
  }

  final BuildInfo buildInfo = androidBuildInfo.buildInfo;
  final String assembleTask = isBuildingBundle
    ? getBundleTaskFor(buildInfo)
    : getAssembleTaskFor(buildInfo);

  final Status status = globals.logger.startProgress(
    "Running Gradle task '$assembleTask'...",
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );

  final List<String> command = <String>[
    gradleUtils.getExecutable(project),
  ];
  if (globals.logger.isVerbose) {
    command.add('-Pverbose=true');
  } else {
    command.add('-q');
  }
  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final Directory localEngineRepo = _getLocalEngineRepo(
      engineOutPath: localEngineArtifacts.engineOutPath,
      androidBuildInfo: androidBuildInfo,
    );
    globals.printTrace(
      'Using local engine: ${localEngineArtifacts.engineOutPath}\n'
      'Local Maven repo: ${localEngineRepo.path}'
    );
    command.add('-Plocal-engine-repo=${localEngineRepo.path}');
    command.add('-Plocal-engine-build-mode=${buildInfo.modeName}');
    command.add('-Plocal-engine-out=${localEngineArtifacts.engineOutPath}');
    command.add('-Ptarget-platform=${_getTargetPlatformByLocalEnginePath(
        localEngineArtifacts.engineOutPath)}');
  } else if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo
        .targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }
  if (target != null) {
    command.add('-Ptarget=$target');
  }
  assert(buildInfo.trackWidgetCreation != null);
  command.add('-Ptrack-widget-creation=${buildInfo.trackWidgetCreation}');

  if (buildInfo.extraFrontEndOptions != null) {
    command.add('-Pextra-front-end-options=${encodeDartDefines(buildInfo.extraFrontEndOptions)}');
  }
  if (buildInfo.extraGenSnapshotOptions != null) {
    command.add('-Pextra-gen-snapshot-options=${encodeDartDefines(buildInfo.extraGenSnapshotOptions)}');
  }
  if (buildInfo.fileSystemRoots != null && buildInfo.fileSystemRoots.isNotEmpty) {
    command.add('-Pfilesystem-roots=${buildInfo.fileSystemRoots.join('|')}');
  }
  if (buildInfo.fileSystemScheme != null) {
    command.add('-Pfilesystem-scheme=${buildInfo.fileSystemScheme}');
  }
  if (androidBuildInfo.splitPerAbi) {
    command.add('-Psplit-per-abi=true');
  }
  if (androidBuildInfo.shrink) {
    command.add('-Pshrink=true');
  }
  if (androidBuildInfo.buildInfo.dartDefines?.isNotEmpty ?? false) {
    command.add('-Pdart-defines=${encodeDartDefines(androidBuildInfo.buildInfo.dartDefines)}');
  }
  if (shouldBuildPluginAsAar) {
    // Pass a system flag instead of a project flag, so this flag can be
    // read from include_flutter.groovy.
    command.add('-Dbuild-plugins-as-aars=true');
    // Don't use settings.gradle from the current project since it includes the plugins as subprojects.
    command.add('--settings-file=settings_aar.gradle');
  }
  if (androidBuildInfo.fastStart) {
    command.add('-Pfast-start=true');
  }
  if (androidBuildInfo.buildInfo.splitDebugInfoPath != null) {
    command.add('-Psplit-debug-info=${androidBuildInfo.buildInfo.splitDebugInfoPath}');
  }
  if (androidBuildInfo.buildInfo.treeShakeIcons) {
    command.add('-Ptree-shake-icons=true');
  }
  if (androidBuildInfo.buildInfo.dartObfuscation) {
    command.add('-Pdart-obfuscation=true');
  }
  if (androidBuildInfo.buildInfo.bundleSkSLPath != null) {
    command.add('-Pbundle-sksl-path=${androidBuildInfo.buildInfo.bundleSkSLPath}');
  }
  if (androidBuildInfo.buildInfo.performanceMeasurementFile != null) {
    command.add('-Pperformance-measurement-file=${androidBuildInfo.buildInfo.performanceMeasurementFile}');
  }
  if (buildInfo.codeSizeDirectory != null) {
    command.add('-Pcode-size-directory=${buildInfo.codeSizeDirectory}');
  }
  command.add(assembleTask);

  GradleHandledError detectedGradleError;
  String detectedGradleErrorLine;
  String consumeLog(String line) {
    // This message was removed from first-party plugins,
    // but older plugin versions still display this message.
    if (androidXPluginWarningRegex.hasMatch(line)) {
      // Don't pipe.
      return null;
    }
    if (detectedGradleError != null) {
      // Pipe stdout/stderr from Gradle.
      return line;
    }
    for (final GradleHandledError gradleError in localGradleErrors) {
      if (gradleError.test(line)) {
        detectedGradleErrorLine = line;
        detectedGradleError = gradleError;
        // The first error match wins.
        break;
      }
    }
    // Pipe stdout/stderr from Gradle.
    return line;
  }

  final Stopwatch sw = Stopwatch()..start();
  int exitCode = 1;
  try {
    exitCode = await processUtils.stream(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: gradleEnvironment,
      mapFunction: consumeLog,
    );
  } on ProcessException catch (exception) {
    consumeLog(exception.toString());
    // Rethrow the exception if the error isn't handled by any of the
    // `localGradleErrors`.
    if (detectedGradleError == null) {
      rethrow;
    }
  } finally {
    status.stop();
  }

  globals.flutterUsage.sendTiming('build', 'gradle', sw.elapsed);

  if (exitCode != 0) {
    if (detectedGradleError == null) {
      BuildEvent('gradle-unkown-failure', flutterUsage: globals.flutterUsage).send();
      throwToolExit(
        'Gradle task $assembleTask failed with exit code $exitCode',
        exitCode: exitCode,
      );
    } else {
      final GradleBuildStatus status = await detectedGradleError.handler(
        line: detectedGradleErrorLine,
        project: project,
        usesAndroidX: usesAndroidX,
        shouldBuildPluginAsAar: shouldBuildPluginAsAar,
      );

      if (retries >= 1) {
        final String successEventLabel = 'gradle-${detectedGradleError.eventLabel}-success';
        switch (status) {
          case GradleBuildStatus.retry:
            await buildGradleApp(
              project: project,
              androidBuildInfo: androidBuildInfo,
              target: target,
              isBuildingBundle: isBuildingBundle,
              localGradleErrors: localGradleErrors,
              shouldBuildPluginAsAar: shouldBuildPluginAsAar,
              retries: retries - 1,
            );
            BuildEvent(successEventLabel, flutterUsage: globals.flutterUsage).send();
            return;
          case GradleBuildStatus.retryWithAarPlugins:
            await buildGradleApp(
              project: project,
              androidBuildInfo: androidBuildInfo,
              target: target,
              isBuildingBundle: isBuildingBundle,
              localGradleErrors: localGradleErrors,
              shouldBuildPluginAsAar: true,
              retries: retries - 1,
            );
            BuildEvent(successEventLabel, flutterUsage: globals.flutterUsage).send();
            return;
          case GradleBuildStatus.exit:
            // noop.
        }
      }
      BuildEvent('gradle-${detectedGradleError.eventLabel}-failure', flutterUsage: globals.flutterUsage).send();
      throwToolExit(
        'Gradle task $assembleTask failed with exit code $exitCode',
        exitCode: exitCode,
      );
    }
  }

  if (isBuildingBundle) {
    final File bundleFile = findBundleFile(project, buildInfo);
    final String appSize = (buildInfo.mode == BuildMode.debug)
      ? '' // Don't display the size when building a debug variant.
      : ' (${getSizeAsMB(bundleFile.lengthSync())})';

    if (buildInfo.codeSizeDirectory != null) {
      await _performCodeSizeAnalysis('aab', bundleFile, androidBuildInfo);
    }

    globals.printStatus(
      '$successMark Built ${globals.fs.path.relative(bundleFile.path)}$appSize.',
      color: TerminalColor.green,
    );
    return;
  }
  // Gradle produced an APK.
  final Iterable<String> apkFilesPaths = project.isModule
    ? findApkFilesModule(project, androidBuildInfo)
    : listApkPaths(androidBuildInfo);
  final Directory apkDirectory = getApkDirectory(project);
  final File apkFile = apkDirectory.childFile(apkFilesPaths.first);
  if (!apkFile.existsSync()) {
    _exitWithExpectedFileNotFound(
      project: project,
      fileExtension: '.apk',
    );
  }

  // Copy the first APK to app.apk, so `flutter run` can find it.
  // TODO(egarciad): Handle multiple APKs.
  apkFile.copySync(apkDirectory.childFile('app.apk').path);
  globals.printTrace('calculateSha: $apkDirectory/app.apk');

  final File apkShaFile = apkDirectory.childFile('app.apk.sha1');
  apkShaFile.writeAsStringSync(_calculateSha(apkFile));

  final String appSize = (buildInfo.mode == BuildMode.debug)
    ? '' // Don't display the size when building a debug variant.
    : ' (${getSizeAsMB(apkFile.lengthSync())})';
  globals.printStatus(
    '$successMark Built ${globals.fs.path.relative(apkFile.path)}$appSize.',
    color: TerminalColor.green,
  );

  if (buildInfo.codeSizeDirectory != null) {
    await _performCodeSizeAnalysis('apk', apkFile, androidBuildInfo);
  }
}

Future<void> _performCodeSizeAnalysis(
  String kind,
  File zipFile,
  AndroidBuildInfo androidBuildInfo,
) async {
  final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
    fileSystem: globals.fs,
    logger: globals.logger,
    flutterUsage: globals.flutterUsage,
  );
  final String archName = getNameForAndroidArch(androidBuildInfo.targetArchs.single);
  final BuildInfo buildInfo = androidBuildInfo.buildInfo;
  final File aotSnapshot = globals.fs.directory(buildInfo.codeSizeDirectory)
    .childFile('snapshot.$archName.json');
  final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
    .childFile('trace.$archName.json');
  final Map<String, Object> output = await sizeAnalyzer.analyzeZipSizeAndAotSnapshot(
    zipFile: zipFile,
    aotSnapshot: aotSnapshot,
    precompilerTrace: precompilerTrace,
    kind: kind,
  );
  final File outputFile = globals.fsUtils.getUniqueFile(
    globals.fs.directory(getBuildDirectory()),'$kind-code-size-analysis', 'json',
  )..writeAsStringSync(jsonEncode(output));
  // This message is used as a sentinel in analyze_apk_size_test.dart
  globals.printStatus(
    'A summary of your ${kind.toUpperCase()} analysis can be found at: ${outputFile.path}',
  );
}

/// Builds AAR and POM files.
///
/// * [project] is typically [FlutterProject.current()].
/// * [androidBuildInfo] is the build configuration.
/// * [outputDir] is the destination of the artifacts,
/// * [buildNumber] is the build number of the output aar,
Future<void> buildGradleAar({
  @required FlutterProject project,
  @required AndroidBuildInfo androidBuildInfo,
  @required String target,
  @required Directory outputDirectory,
  @required String buildNumber,
}) async {
  assert(project != null);
  assert(target != null);
  assert(androidBuildInfo != null);
  assert(outputDirectory != null);
  assert(globals.androidSdk != null);

  final FlutterManifest manifest = project.manifest;
  if (!manifest.isModule && !manifest.isPlugin) {
    throwToolExit('AARs can only be built for plugin or module projects.');
  }

  final BuildInfo buildInfo = androidBuildInfo.buildInfo;
  final String aarTask = getAarTaskFor(buildInfo);
  final Status status = globals.logger.startProgress(
    "Running Gradle task '$aarTask'...",
    timeout: timeoutConfiguration.slowOperation,
    multilineOutput: true,
  );

  final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
  final String initScript = globals.fs.path.join(
    flutterRoot,
    'packages',
    'flutter_tools',
    'gradle',
    'aar_init_script.gradle',
  );
  final List<String> command = <String>[
    gradleUtils.getExecutable(project),
    '-I=$initScript',
    '-Pflutter-root=$flutterRoot',
    '-Poutput-dir=${outputDirectory.path}',
    '-Pis-plugin=${manifest.isPlugin}',
    '-PbuildNumber=$buildNumber'
  ];
  if (globals.logger.isVerbose) {
    command.add('-Pverbose=true');
  } else {
    command.add('-q');
  }

  if (target != null && target.isNotEmpty) {
    command.add('-Ptarget=$target');
  }
  if (buildInfo.splitDebugInfoPath != null) {
    command.add('-Psplit-debug-info=${buildInfo.splitDebugInfoPath}');
  }
  if (buildInfo.treeShakeIcons) {
    command.add('-Pfont-subset=true');
  }
  if (buildInfo.dartObfuscation) {
    if (buildInfo.mode == BuildMode.debug || buildInfo.mode == BuildMode.profile) {
      globals.printStatus('Dart obfuscation is not supported in ${toTitleCase(buildInfo.friendlyModeName)} mode, building as unobfuscated.');
    } else {
      command.add('-Pdart-obfuscation=true');
    }
  }

  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final Directory localEngineRepo = _getLocalEngineRepo(
      engineOutPath: localEngineArtifacts.engineOutPath,
      androidBuildInfo: androidBuildInfo,
    );
    globals.printTrace(
      'Using local engine: ${localEngineArtifacts.engineOutPath}\n'
      'Local Maven repo: ${localEngineRepo.path}'
    );
    command.add('-Plocal-engine-repo=${localEngineRepo.path}');
    command.add('-Plocal-engine-build-mode=${buildInfo.modeName}');
    command.add('-Plocal-engine-out=${localEngineArtifacts.engineOutPath}');

    // Copy the local engine repo in the output directory.
    try {
      globals.fsUtils.copyDirectorySync(
        localEngineRepo,
        getRepoDirectory(outputDirectory),
      );
    } on FileSystemException catch(_) {
      throwToolExit(
        'Failed to copy the local engine ${localEngineRepo.path} repo '
        'in ${outputDirectory.path}'
      );
    }
    command.add('-Ptarget-platform=${_getTargetPlatformByLocalEnginePath(
        localEngineArtifacts.engineOutPath)}');
  } else if (androidBuildInfo.targetArchs.isNotEmpty) {
    final String targetPlatforms = androidBuildInfo.targetArchs
        .map(getPlatformNameForAndroidArch).join(',');
    command.add('-Ptarget-platform=$targetPlatforms');
  }

  command.add(aarTask);

  final Stopwatch sw = Stopwatch()..start();
  RunResult result;
  try {
    result = await processUtils.run(
      command,
      workingDirectory: project.android.hostAppGradleRoot.path,
      allowReentrantFlutter: true,
      environment: gradleEnvironment,
    );
  } finally {
    status.stop();
  }
  globals.flutterUsage.sendTiming('build', 'gradle-aar', sw.elapsed);

  if (result.exitCode != 0) {
    globals.printStatus(result.stdout, wrap: false);
    globals.printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed with exit code $exitCode.',
      exitCode: exitCode,
    );
  }
  final Directory repoDirectory = getRepoDirectory(outputDirectory);
  if (!repoDirectory.existsSync()) {
    globals.printStatus(result.stdout, wrap: false);
    globals.printError(result.stderr, wrap: false);
    throwToolExit(
      'Gradle task $aarTask failed to produce $repoDirectory.',
      exitCode: exitCode,
    );
  }
  globals.printStatus(
    '$successMark Built ${globals.fs.path.relative(repoDirectory.path)}.',
    color: TerminalColor.green,
  );
}

/// Prints how to consume the AAR from a host app.
void printHowToConsumeAar({
  @required Set<String> buildModes,
  @required String androidPackage,
  @required Directory repoDirectory,
  @required Logger logger,
  @required FileSystem fileSystem,
  String buildNumber,
}) {
  assert(buildModes != null && buildModes.isNotEmpty);
  assert(androidPackage != null);
  assert(repoDirectory != null);
  buildNumber ??= '1.0';

  logger.printStatus('\nConsuming the Module', emphasis: true);
  logger.printStatus('''
  1. Open ${fileSystem.path.join('<host>', 'app', 'build.gradle')}
  2. Ensure you have the repositories configured, otherwise add them:

      String storageUrl = System.env.FLUTTER_STORAGE_BASE_URL ?: "https://storage.googleapis.com"
      repositories {
        maven {
            url '${repoDirectory.path}'
        }
        maven {
            url '\$storageUrl/download.flutter.io'
        }
      }

  3. Make the host app depend on the Flutter module:

    dependencies {''');

  for (final String buildMode in buildModes) {
    logger.printStatus("""
      ${buildMode}Implementation '$androidPackage:flutter_$buildMode:$buildNumber'""");
  }

  logger.printStatus('''
    }
''');

  if (buildModes.contains('profile')) {
    logger.printStatus('''

  4. Add the `profile` build type:

    android {
      buildTypes {
        profile {
          initWith debug
        }
      }
    }
''');
  }

  logger.printStatus('To learn more, visit https://flutter.dev/go/build-aar');
}

String _hex(List<int> bytes) {
  final StringBuffer result = StringBuffer();
  for (final int part in bytes) {
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

String _calculateSha(File file) {
  final Stopwatch sw = Stopwatch()..start();
  final List<int> bytes = file.readAsBytesSync();
  globals.printTrace('calculateSha: reading file took ${sw.elapsedMilliseconds}us');
  globals.flutterUsage.sendTiming('build', 'apk-sha-read', sw.elapsed);
  sw.reset();
  final String sha = _hex(sha1.convert(bytes).bytes);
  globals.printTrace('calculateSha: computing sha took ${sw.elapsedMilliseconds}us');
  globals.flutterUsage.sendTiming('build', 'apk-sha-calc', sw.elapsed);
  return sha;
}

void _exitWithUnsupportedProjectMessage() {
  BuildEvent('unsupported-project', eventError: 'gradle-plugin', flutterUsage: globals.flutterUsage).send();
  throwToolExit(
    '$warningMark Your app is using an unsupported Gradle project. '
    'To fix this problem, create a new project by running `flutter create -t app <app-directory>` '
    'and then move the dart code, assets and pubspec.yaml to the new project.',
  );
}

void _exitWithProjectNotUsingGradleMessage() {
  BuildEvent('unsupported-project', eventError: 'app-not-using-gradle', flutterUsage: globals.flutterUsage).send();
  throwToolExit(
    '$warningMark The build process for Android has changed, and the '
    'current project configuration is no longer valid. Please consult\n\n'
    'https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
    'for details on how to upgrade the project.'
  );
}

/// Returns [true] if the current app uses AndroidX.
// TODO(egarciad): https://github.com/flutter/flutter/issues/40800
// Remove `FlutterManifest.usesAndroidX` and provide a unified `AndroidProject.usesAndroidX`.
bool isAppUsingAndroidX(Directory androidDirectory) {
  final File properties = androidDirectory.childFile('gradle.properties');
  if (!properties.existsSync()) {
    return false;
  }
  return properties.readAsStringSync().contains('android.useAndroidX=true');
}

/// Builds the plugins as AARs.
@visibleForTesting
Future<void> buildPluginsAsAar(
  FlutterProject flutterProject,
  AndroidBuildInfo androidBuildInfo, {
  Directory buildDirectory,
}) async {
  final File flutterPluginFile = flutterProject.flutterPluginsFile;
  if (!flutterPluginFile.existsSync()) {
    return;
  }
  final List<String> plugins = flutterPluginFile.readAsStringSync().split('\n');
  for (final String plugin in plugins) {
    final List<String> pluginParts = plugin.split('=');
    if (pluginParts.length != 2) {
      continue;
    }
    final Directory pluginDirectory = globals.fs.directory(pluginParts.last);
    assert(pluginDirectory.existsSync());

    final String pluginName = pluginParts.first;
    final File buildGradleFile = pluginDirectory.childDirectory('android').childFile('build.gradle');
    if (!buildGradleFile.existsSync()) {
      globals.printTrace("Skipping plugin $pluginName since it doesn't have a android/build.gradle file");
      continue;
    }
    globals.logger.printStatus('Building plugin $pluginName...');
    try {
      await buildGradleAar(
        project: FlutterProject.fromDirectory(pluginDirectory),
        androidBuildInfo: AndroidBuildInfo(
          BuildInfo(
            BuildMode.release, // Plugins are built as release.
            null, // Plugins don't define flavors.
            treeShakeIcons: androidBuildInfo.buildInfo.treeShakeIcons,
            packagesPath: androidBuildInfo.buildInfo.packagesPath,
          ),
        ),
        target: '',
        outputDirectory: buildDirectory,
        buildNumber: '1.0'
      );
    } on ToolExit {
      // Log the entire plugin entry in `.flutter-plugins` since it
      // includes the plugin name and the version.
      BuildEvent('gradle-plugin-aar-failure', eventError: plugin, flutterUsage: globals.flutterUsage).send();
      throwToolExit('The plugin $pluginName could not be built due to the issue above.');
    }
  }
}

/// Returns the APK files for a given [FlutterProject] and [AndroidBuildInfo].
@visibleForTesting
Iterable<String> findApkFilesModule(
  FlutterProject project,
  AndroidBuildInfo androidBuildInfo,
) {
  final Iterable<String> apkFileNames = _apkFilesFor(androidBuildInfo);
  final Directory apkDirectory = getApkDirectory(project);
  final Iterable<File> apks = apkFileNames.expand<File>((String apkFileName) {
    File apkFile = apkDirectory.childFile(apkFileName);
    if (apkFile.existsSync()) {
      return <File>[apkFile];
    }
    final BuildInfo buildInfo = androidBuildInfo.buildInfo;
    final String modeName = camelCase(buildInfo.modeName);
    apkFile = apkDirectory
      .childDirectory(modeName)
      .childFile(apkFileName);
    if (apkFile.existsSync()) {
      return <File>[apkFile];
    }
    if (buildInfo.flavor != null) {
      // Android Studio Gradle plugin v3 adds flavor to path.
      apkFile = apkDirectory
        .childDirectory(buildInfo.flavor)
        .childDirectory(modeName)
        .childFile(apkFileName);
      if (apkFile.existsSync()) {
        return <File>[apkFile];
      }
    }
    return const <File>[];
  });
  if (apks.isEmpty) {
    _exitWithExpectedFileNotFound(
      project: project,
      fileExtension: '.apk',
    );
  }
  return apks.map((File file) => file.path);
}

/// Returns the APK files for a given [FlutterProject] and [AndroidBuildInfo].
///
/// The flutter.gradle plugin will copy APK outputs into:
/// `$buildDir/app/outputs/flutter-apk/app-<abi>-<flavor-flag>-<build-mode-flag>.apk`
@visibleForTesting
Iterable<String> listApkPaths(
  AndroidBuildInfo androidBuildInfo,
) {
  final String buildType = camelCase(androidBuildInfo.buildInfo.modeName);
  final List<String> apkPartialName = <String>[
    if (androidBuildInfo.buildInfo.flavor?.isNotEmpty ?? false)
      androidBuildInfo.buildInfo.flavor,
    '$buildType.apk',
  ];
  if (androidBuildInfo.splitPerAbi) {
    return <String>[
      for (AndroidArch androidArch in androidBuildInfo.targetArchs)
        <String>[
          'app',
          getNameForAndroidArch(androidArch),
          ...apkPartialName
        ].join('-')
    ];
  }
  return <String>[
    <String>[
      'app',
      ...apkPartialName,
    ].join('-')
  ];
}

@visibleForTesting
File findBundleFile(FlutterProject project, BuildInfo buildInfo) {
  final List<File> fileCandidates = <File>[
    getBundleDirectory(project)
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app.aab'),
    getBundleDirectory(project)
      .childDirectory(camelCase(buildInfo.modeName))
      .childFile('app-${buildInfo.modeName}.aab'),
  ];
  if (buildInfo.flavor != null) {
    // The Android Gradle plugin 3.0.0 adds the flavor name to the path.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the directory name is `foo_barRelease`.
    fileCandidates.add(
      getBundleDirectory(project)
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app.aab'));

    // The Android Gradle plugin 3.5.0 adds the flavor name to file name.
    // For example: In release mode, if the flavor name is `foo_bar`, then
    // the file name name is `app-foo_bar-release.aab`.
    fileCandidates.add(
      getBundleDirectory(project)
        .childDirectory('${buildInfo.flavor}${camelCase('_' + buildInfo.modeName)}')
        .childFile('app-${buildInfo.flavor}-${buildInfo.modeName}.aab'));
  }
  for (final File bundleFile in fileCandidates) {
    if (bundleFile.existsSync()) {
      return bundleFile;
    }
  }
  _exitWithExpectedFileNotFound(
    project: project,
    fileExtension: '.aab',
  );
  return null;
}

/// Throws a [ToolExit] exception and logs the event.
void _exitWithExpectedFileNotFound({
  @required FlutterProject project,
  @required String fileExtension,
}) {
  assert(project != null);
  assert(fileExtension != null);

  final String androidGradlePluginVersion =
  getGradleVersionForAndroidPlugin(project.android.hostAppGradleRoot);
  BuildEvent('gradle-expected-file-not-found',
    settings:
    'androidGradlePluginVersion: $androidGradlePluginVersion, '
      'fileExtension: $fileExtension',
    flutterUsage: globals.flutterUsage,
  ).send();
  throwToolExit(
    'Gradle build failed to produce an $fileExtension file. '
    "It's likely that this file was generated under ${project.android.buildDirectory.path}, "
    "but the tool couldn't find it."
  );
}

void _createSymlink(String targetPath, String linkPath) {
  final File targetFile = globals.fs.file(targetPath);
  if (!targetFile.existsSync()) {
    throwToolExit("The file $targetPath wasn't found in the local engine out directory.");
  }
  final File linkFile = globals.fs.file(linkPath);
  final Link symlink = linkFile.parent.childLink(linkFile.basename);
  try {
    symlink.createSync(targetPath, recursive: true);
  } on FileSystemException catch (exception) {
    throwToolExit(
      'Failed to create the symlink $linkPath->$targetPath: $exception'
    );
  }
}

String _getLocalArtifactVersion(String pomPath) {
  final File pomFile = globals.fs.file(pomPath);
  if (!pomFile.existsSync()) {
    throwToolExit("The file $pomPath wasn't found in the local engine out directory.");
  }
  XmlDocument document;
  try {
    document = XmlDocument.parse(pomFile.readAsStringSync());
  } on XmlParserException {
    throwToolExit(
      'Error parsing $pomPath. Please ensure that this is a valid XML document.'
    );
  } on FileSystemException {
    throwToolExit(
      'Error reading $pomPath. Please ensure that you have read permission to this '
      'file and try again.');
  }
  final Iterable<XmlElement> project = document.findElements('project');
  assert(project.isNotEmpty);
  for (final XmlElement versionElement in document.findAllElements('version')) {
    if (versionElement.parent == project.first) {
      return versionElement.text;
    }
  }
  throwToolExit('Error while parsing the <version> element from $pomPath');
  return null;
}

/// Returns the local Maven repository for a local engine build.
/// For example, if the engine is built locally at <home>/engine/src/out/android_release_unopt
/// This method generates symlinks in the temp directory to the engine artifacts
/// following the convention specified on https://maven.apache.org/pom.html#Repositories
Directory _getLocalEngineRepo({
  @required String engineOutPath,
  @required AndroidBuildInfo androidBuildInfo,
}) {
  assert(engineOutPath != null);
  assert(androidBuildInfo != null);

  final String abi = _getAbiByLocalEnginePath(engineOutPath);
  final Directory localEngineRepo = globals.fs.systemTempDirectory
    .createTempSync('flutter_tool_local_engine_repo.');

  // Remove the local engine repo before the tool exits.
  shutdownHooks.addShutdownHook(() {
      if (localEngineRepo.existsSync()) {
        localEngineRepo.deleteSync(recursive: true);
      }
    },
    ShutdownStage.CLEANUP,
  );

  final String buildMode = androidBuildInfo.buildInfo.modeName;
  final String artifactVersion = _getLocalArtifactVersion(
    globals.fs.path.join(
      engineOutPath,
      'flutter_embedding_$buildMode.pom',
    )
  );
  for (final String artifact in const <String>['pom', 'jar']) {
    // The Android embedding artifacts.
    _createSymlink(
      globals.fs.path.join(
        engineOutPath,
        'flutter_embedding_$buildMode.$artifact',
      ),
      globals.fs.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        'flutter_embedding_$buildMode',
        artifactVersion,
        'flutter_embedding_$buildMode-$artifactVersion.$artifact',
      ),
    );
    // The engine artifacts (libflutter.so).
    _createSymlink(
      globals.fs.path.join(
        engineOutPath,
        '${abi}_$buildMode.$artifact',
      ),
      globals.fs.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        '${abi}_$buildMode',
        artifactVersion,
        '${abi}_$buildMode-$artifactVersion.$artifact',
      ),
    );
  }
  return localEngineRepo;
}

String _getAbiByLocalEnginePath(String engineOutPath) {
  String result = 'armeabi_v7a';
  if (engineOutPath.contains('x86')) {
    result = 'x86';
  } else if (engineOutPath.contains('x64')) {
    result = 'x86_64';
  } else if (engineOutPath.contains('arm64')) {
    result = 'arm64_v8a';
  }
  return result;
}

String _getTargetPlatformByLocalEnginePath(String engineOutPath) {
  String result = 'android-arm';
  if (engineOutPath.contains('x86')) {
    result = 'android-x86';
  } else if (engineOutPath.contains('x64')) {
    result = 'android-x64';
  } else if (engineOutPath.contains('arm64')) {
    result = 'android-arm64';
  }
  return result;
}
