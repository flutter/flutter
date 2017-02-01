// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:path/path.dart' as path;

import '../android/android_sdk.dart';
import '../android/gradle.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../resident_runner.dart';
import '../services.dart';
import 'build_aot.dart';
import 'build.dart';

export '../android/android_device.dart' show AndroidDevice;

const String _kDefaultAndroidManifestPath = 'android/AndroidManifest.xml';
const String _kDefaultResourcesPath = 'android/res';
const String _kDefaultAssetsPath = 'android/assets';

const String _kFlutterManifestPath = 'pubspec.yaml';
const String _kPackagesStatusPath = '.packages';

// Alias of the key provided in the Chromium debug keystore
const String _kDebugKeystoreKeyAlias = "chromiumdebugkey";

// Password for the Chromium debug keystore
const String _kDebugKeystorePassword = "chromium";

// Default APK output path.
String get _defaultOutputPath => path.join(getAndroidBuildDirectory(), 'app.apk');

/// Copies files into a new directory structure.
class _AssetBuilder {
  final Directory outDir;

  Directory _assetDir;

  _AssetBuilder(this.outDir, String assetDirName) {
    _assetDir = fs.directory('${outDir.path}/$assetDirName');
    _assetDir.createSync(recursive:  true);
  }

  void add(File asset, String relativePath) {
    String destPath = path.join(_assetDir.path, relativePath);
    ensureDirectoryExists(destPath);
    asset.copySync(destPath);
  }

  Directory get directory => _assetDir;
}

/// Builds an APK package using Android SDK tools.
class _ApkBuilder {
  final AndroidSdkVersion sdk;

  File _androidJar;
  File _aapt;
  File _dx;
  File _zipalign;
  File _jarsigner;

  _ApkBuilder(this.sdk) {
    _androidJar = fs.file(sdk.androidJarPath);
    _aapt = fs.file(sdk.aaptPath);
    _dx = fs.file(sdk.dxPath);
    _zipalign = fs.file(sdk.zipalignPath);
    _jarsigner = os.which('jarsigner');
  }

  String checkDependencies() {
    if (!_androidJar.existsSync())
      return 'Cannot find android.jar at ${_androidJar.path}';
    if (!_aapt.existsSync())
      return 'Cannot find aapt at ${_aapt.path}';
    if (!_dx.existsSync())
      return 'Cannot find dx at ${_dx.path}';
    if (!_zipalign.existsSync())
      return 'Cannot find zipalign at ${_zipalign.path}';
    if (_jarsigner == null)
      return 'Cannot find jarsigner in PATH.';
    if (!_jarsigner.existsSync())
      return 'Cannot find jarsigner at ${_jarsigner.path}';
    return null;
  }

  void compileClassesDex(File classesDex, List<File> jars) {
    List<String> packageArgs = <String>[_dx.path,
      '--dex',
      '--force-jumbo',
      '--output', classesDex.path
    ];

    packageArgs.addAll(jars.map((File f) => f.path));

    runCheckedSync(packageArgs);
  }

  void package(File outputApk, File androidManifest, Directory assets, Directory artifacts, Directory resources, BuildMode buildMode) {
    List<String> packageArgs = <String>[_aapt.path,
      'package',
      '-M', androidManifest.path,
      '-A', assets.path,
      '-I', _androidJar.path,
      '-F', outputApk.path,
    ];
    if (buildMode == BuildMode.debug)
      packageArgs.add('--debug-mode');
    if (resources != null)
      packageArgs.addAll(<String>['-S', resources.absolute.path]);
    packageArgs.add(artifacts.path);
    runCheckedSync(packageArgs);
  }

  void sign(File keystore, String keystorePassword, String keyAlias, String keyPassword, File outputApk) {
    assert(_jarsigner != null);
    runCheckedSync(<String>[_jarsigner.path,
      '-keystore', keystore.path,
      '-storepass', keystorePassword,
      '-keypass', keyPassword,
      '-digestalg', 'SHA1',
      '-sigalg', 'MD5withRSA',
      outputApk.path,
      keyAlias,
    ]);
  }

  void align(File unalignedApk, File outputApk) {
    runCheckedSync(<String>[_zipalign.path, '-f', '4', unalignedApk.path, outputApk.path]);
  }
}

class _ApkComponents {
  File manifest;
  File icuData;
  List<File> jars;
  List<Map<String, String>> services = <Map<String, String>>[];
  File libSkyShell;
  File debugKeystore;
  Directory resources;
  Map<String, File> extraFiles;
}

class ApkKeystoreInfo {
  ApkKeystoreInfo({ this.keystore, this.password, this.keyAlias, this.keyPassword }) {
    assert(keystore != null);
  }

  final String keystore;
  final String password;
  final String keyAlias;
  final String keyPassword;
}

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand() {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();

    argParser.addOption('manifest',
      abbr: 'm',
      defaultsTo: _kDefaultAndroidManifestPath,
      help: 'Android manifest XML file.');
    argParser.addOption('resources',
      abbr: 'r',
      help: 'Resources directory path.');
    argParser.addOption('output-file',
      abbr: 'o',
      defaultsTo: _defaultOutputPath,
      help: 'Output APK file.');
    argParser.addOption('flx',
      abbr: 'f',
      help: 'Path to the FLX file. If this is not provided, an FLX will be built.');
    argParser.addOption('target-arch',
      defaultsTo: 'arm',
      allowed: <String>['arm', 'x86', 'x64'],
      help: 'Architecture of the target device.');
    argParser.addOption('aot-path',
      help: 'Path to the ahead-of-time compiled snapshot directory.\n'
            'If this is not provided, an AOT snapshot will be built.');
    argParser.addOption('keystore',
      help: 'Path to the keystore used to sign the app.');
    argParser.addOption('keystore-password',
      help: 'Password used to access the keystore.');
    argParser.addOption('keystore-key-alias',
      help: 'Alias of the entry within the keystore.');
    argParser.addOption('keystore-key-password',
      help: 'Password for the entry within the keystore.');
  }

  @override
  final String name = 'apk';

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    'This command can build debug and release versions of your application. \'debug\' builds support\n'
    'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are\n'
    'suitable for deploying to app stores.';

  TargetPlatform _getTargetPlatform(String targetArch) {
    switch (targetArch) {
      case 'arm':
        return TargetPlatform.android_arm;
      case 'x86':
        return TargetPlatform.android_x86;
      case 'x64':
        return TargetPlatform.android_x64;
      default:
        throw new Exception('Unrecognized target architecture: $targetArch');
    }
  }

  @override
  Future<Null> runCommand() async {
    await super.runCommand();

    TargetPlatform targetPlatform = _getTargetPlatform(argResults['target-arch']);
    BuildMode buildMode = getBuildMode();
    if (targetPlatform != TargetPlatform.android_arm && buildMode != BuildMode.debug)
      throwToolExit('Profile and release builds are only supported on ARM targets.');

    if (isProjectUsingGradle()) {
      await buildAndroidWithGradle(
        targetPlatform,
        buildMode,
        target: targetFile
      );
    } else {
      await buildAndroid(
        targetPlatform,
        buildMode,
        force: true,
        manifest: argResults['manifest'],
        resources: argResults['resources'],
        outputFile: argResults['output-file'],
        target: targetFile,
        flxPath: argResults['flx'],
        aotPath: argResults['aot-path'],
        keystore: (argResults['keystore'] ?? '').isEmpty ? null : new ApkKeystoreInfo(
          keystore: argResults['keystore'],
          password: argResults['keystore-password'],
          keyAlias: argResults['keystore-key-alias'],
          keyPassword: argResults['keystore-key-password']
        )
      );
    }
  }
}

// Return the directory name within the APK that is used for native code libraries
// on the given platform.
String getAbiDirectory(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android_arm:
      return 'armeabi-v7a';
    case TargetPlatform.android_x64:
      return 'x86_64';
    case TargetPlatform.android_x86:
      return 'x86';
    default:
      throw new Exception('Unsupported platform.');
  }
}

Future<_ApkComponents> _findApkComponents(
  TargetPlatform platform,
  BuildMode buildMode,
  String manifest,
  String resources,
  Map<String, File> extraFiles
) async {
  _ApkComponents components = new _ApkComponents();
  components.manifest = fs.file(manifest);
  components.resources = resources == null ? null : fs.directory(resources);
  components.extraFiles = extraFiles != null ? extraFiles : <String, File>{};

  if (tools.isLocalEngine) {
    String abiDir = getAbiDirectory(platform);
    String enginePath = tools.engineSrcPath;
    String buildDir = tools.getEngineArtifactsDirectory(platform, buildMode).path;

    components.icuData = fs.file('$enginePath/third_party/icu/android/icudtl.dat');
    components.jars = <File>[
      fs.file('$buildDir/gen/flutter/shell/platform/android/android/classes.dex.jar')
    ];
    components.libSkyShell = fs.file('$buildDir/gen/flutter/shell/platform/android/android/android/libs/$abiDir/libsky_shell.so');
    components.debugKeystore = fs.file('$enginePath/build/android/ant/chromium-debug.keystore');
  } else {
    Directory artifacts = tools.getEngineArtifactsDirectory(platform, buildMode);

    components.icuData = fs.file(path.join(artifacts.path, 'icudtl.dat'));
    components.jars = <File>[
      fs.file(path.join(artifacts.path, 'classes.dex.jar'))
    ];
    components.libSkyShell = fs.file(path.join(artifacts.path, 'libsky_shell.so'));
    components.debugKeystore = fs.file(path.join(artifacts.path, 'chromium-debug.keystore'));
  }

  await parseServiceConfigs(components.services, jars: components.jars);

  List<File> allFiles = <File>[
    components.manifest, components.icuData, components.libSkyShell, components.debugKeystore
  ]..addAll(components.jars)
   ..addAll(components.extraFiles.values);

  for (File file in allFiles) {
    if (!file.existsSync()) {
      printError('Cannot locate file: ${file.path}');
      return null;
    }
  }

  return components;
}

int _buildApk(
  TargetPlatform platform,
  BuildMode buildMode,
  _ApkComponents components,
  String flxPath,
  ApkKeystoreInfo keystore,
  String outputFile
) {
  assert(platform != null);
  assert(buildMode != null);

  Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_tools');

  printTrace('Building APK; buildMode: ${getModeName(buildMode)}.');

  try {
    _ApkBuilder builder = new _ApkBuilder(androidSdk.latestVersion);
    String error = builder.checkDependencies();
    if (error != null) {
      printError(error);
      return 1;
    }

    File classesDex = fs.file('${tempDir.path}/classes.dex');
    builder.compileClassesDex(classesDex, components.jars);

    File servicesConfig =
        generateServiceDefinitions(tempDir.path, components.services);

    _AssetBuilder assetBuilder = new _AssetBuilder(tempDir, 'assets');
    assetBuilder.add(components.icuData, 'icudtl.dat');
    assetBuilder.add(fs.file(flxPath), 'app.flx');
    assetBuilder.add(servicesConfig, 'services.json');

    _AssetBuilder artifactBuilder = new _AssetBuilder(tempDir, 'artifacts');
    artifactBuilder.add(classesDex, 'classes.dex');
    String abiDir = getAbiDirectory(platform);
    artifactBuilder.add(components.libSkyShell, 'lib/$abiDir/libsky_shell.so');

    for (String relativePath in components.extraFiles.keys)
      artifactBuilder.add(components.extraFiles[relativePath], relativePath);

    File unalignedApk = fs.file('${tempDir.path}/app.apk.unaligned');
    builder.package(
      unalignedApk, components.manifest, assetBuilder.directory,
      artifactBuilder.directory, components.resources, buildMode
    );

    int signResult = _signApk(builder, components, unalignedApk, keystore, buildMode);
    if (signResult != 0)
      return signResult;

    File finalApk = fs.file(outputFile);
    ensureDirectoryExists(finalApk.path);
    builder.align(unalignedApk, finalApk);

    printTrace('calculateSha: $outputFile');
    File apkShaFile = fs.file('$outputFile.sha1');
    apkShaFile.writeAsStringSync(calculateSha(finalApk));

    return 0;
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

int _signApk(
  _ApkBuilder builder,
  _ApkComponents components,
  File apk,
  ApkKeystoreInfo keystoreInfo,
  BuildMode buildMode,
) {
  File keystore;
  String keystorePassword;
  String keyAlias;
  String keyPassword;

  if (keystoreInfo == null) {
    if (buildMode == BuildMode.release) {
      printStatus('Warning! Signing the APK using the debug keystore.');
      printStatus('You will need a real keystore to distribute your application.');
    } else {
      printTrace('Signing the APK using the debug keystore.');
    }
    keystore = components.debugKeystore;
    keystorePassword = _kDebugKeystorePassword;
    keyAlias = _kDebugKeystoreKeyAlias;
    keyPassword = _kDebugKeystorePassword;
  } else {
    keystore = fs.file(keystoreInfo.keystore);
    keystorePassword = keystoreInfo.password ?? '';
    keyAlias = keystoreInfo.keyAlias ?? '';
    if (keystorePassword.isEmpty || keyAlias.isEmpty) {
      printError('You must provide a keystore password and a key alias.');
      return 1;
    }
    keyPassword = keystoreInfo.keyPassword ?? '';
    if (keyPassword.isEmpty)
      keyPassword = keystorePassword;
  }

  builder.sign(keystore, keystorePassword, keyAlias, keyPassword, apk);

  return 0;
}

// Returns true if the apk is out of date and needs to be rebuilt.
bool _needsRebuild(
  String apkPath,
  String manifest,
  TargetPlatform platform,
  BuildMode buildMode,
  Map<String, File> extraFiles
) {
  FileStat apkStat = fs.statSync(apkPath);
  // Note: This list of dependencies is imperfect, but will do for now. We
  // purposely don't include the .dart files, because we can load those
  // over the network without needing to rebuild (at least on Android).
  List<String> dependencies = <String>[
    manifest,
    _kFlutterManifestPath,
    _kPackagesStatusPath
  ];
  dependencies.addAll(extraFiles.values.map((File file) => file.path));
  Iterable<FileStat> dependenciesStat =
    dependencies.map((String path) => fs.statSync(path));

  if (apkStat.type == FileSystemEntityType.NOT_FOUND)
    return true;

  for (FileStat dep in dependenciesStat) {
    if (dep.modified == null || dep.modified.isAfter(apkStat.modified))
      return true;
  }

  if (!fs.isFileSync('$apkPath.sha1'))
    return true;

  String lastBuildType = _readBuildMeta(path.dirname(apkPath))['targetBuildType'];
  String targetBuildType = _getTargetBuildTypeToken(platform, buildMode, fs.file(apkPath));
  if (lastBuildType != targetBuildType)
    return true;

  return false;
}

Future<Null> buildAndroid(
  TargetPlatform platform,
  BuildMode buildMode, {
  bool force: false,
  String manifest: _kDefaultAndroidManifestPath,
  String resources,
  String outputFile,
  String target,
  String flxPath,
  String aotPath,
  ApkKeystoreInfo keystore,
  bool applicationNeedsRebuild: false
}) async {
  outputFile ??= _defaultOutputPath;

  // Validate that we can find an android sdk.
  if (androidSdk == null)
    throwToolExit('No Android SDK found. Try setting the ANDROID_HOME environment variable.');

  List<String> validationResult = androidSdk.validateSdkWellFormed();
  if (validationResult.isNotEmpty) {
    validationResult.forEach(printError);
    throwToolExit('Try re-installing or updating your Android SDK.');
  }

  Map<String, File> extraFiles = <String, File>{};
  if (fs.isDirectorySync(_kDefaultAssetsPath)) {
    Directory assetsDir = fs.directory(_kDefaultAssetsPath);
    for (FileSystemEntity entity in assetsDir.listSync(recursive: true)) {
      if (entity is File) {
        String targetPath = entity.path.substring(assetsDir.path.length);
        extraFiles["assets/$targetPath"] = entity;
      }
    }
  }

  final bool needRebuild =
      applicationNeedsRebuild ||
          _needsRebuild(outputFile, manifest, platform, buildMode, extraFiles);

  // In debug (JIT) mode, the snapshot lives in the FLX, and we can skip the APK
  // rebuild if none of the resources in the APK are stale.
  // In AOT modes, the snapshot lives in the APK, so the APK must be rebuilt.
  if (!isAotBuildMode(buildMode) && !force && !needRebuild) {
    printTrace('APK up to date; skipping build step.');
    return;
  }

  if (resources != null) {
    if (!fs.isDirectorySync(resources))
      throwToolExit('Resources directory "$resources" not found.');
  } else {
    if (fs.isDirectorySync(_kDefaultResourcesPath))
      resources = _kDefaultResourcesPath;
  }

  _ApkComponents components = await _findApkComponents(platform, buildMode, manifest, resources, extraFiles);

  if (components == null)
    throwToolExit('Failure building APK: unable to find components.');

  String typeName = path.basename(tools.getEngineArtifactsDirectory(platform, buildMode).path);
  Status status = logger.startProgress('Building APK in ${getModeName(buildMode)} mode ($typeName)...');

  if (flxPath != null && flxPath.isNotEmpty) {
    if (!fs.isFileSync(flxPath)) {
      throwToolExit('FLX does not exist: $flxPath\n'
        '(Omit the --flx option to build the FLX automatically)');
    }
  } else {
    // Build the FLX.
    flxPath = await flx.buildFlx(
      mainPath: findMainDartFile(target),
      precompiledSnapshot: isAotBuildMode(buildMode),
      includeRobotoFonts: false);

    if (flxPath == null)
      throwToolExit(null);
  }

  // Build an AOT snapshot if needed.
  if (isAotBuildMode(buildMode) && aotPath == null) {
    aotPath = await buildAotSnapshot(findMainDartFile(target), platform, buildMode);
    if (aotPath == null)
      throwToolExit('Failed to build AOT snapshot');
  }

  if (aotPath != null) {
    if (!isAotBuildMode(buildMode))
      throwToolExit('AOT snapshot can not be used in build mode $buildMode');
    if (!fs.isDirectorySync(aotPath))
      throwToolExit('AOT snapshot does not exist: $aotPath');
    for (String aotFilename in kAotSnapshotFiles) {
      String aotFilePath = path.join(aotPath, aotFilename);
      if (!fs.isFileSync(aotFilePath))
        throwToolExit('Missing AOT snapshot file: $aotFilePath');
      components.extraFiles['assets/$aotFilename'] = fs.file(aotFilePath);
    }
  }

  int result = _buildApk(platform, buildMode, components, flxPath, keystore, outputFile);
  status.stop();

  if (result != 0)
    throwToolExit('Build APK failed ($result)', exitCode: result);

  File apkFile = fs.file(outputFile);
  printTrace('Built $outputFile (${getSizeAsMB(apkFile.lengthSync())}).');

  _writeBuildMetaEntry(
    path.dirname(outputFile),
    'targetBuildType',
    _getTargetBuildTypeToken(platform, buildMode, fs.file(outputFile))
  );
}

Future<Null> buildAndroidWithGradle(
  TargetPlatform platform,
  BuildMode buildMode, {
  bool force: false,
  String target
}) async {
  if (platform != TargetPlatform.android_arm && buildMode != BuildMode.debug) {
    throwToolExit('Profile and release builds are only supported on ARM targets.');
  }
  // Validate that we can find an android sdk.
  if (androidSdk == null)
    throwToolExit('No Android SDK found. Try setting the ANDROID_HOME environment variable.');

  List<String> validationResult = androidSdk.validateSdkWellFormed();
  if (validationResult.isNotEmpty) {
    validationResult.forEach(printError);
    throwToolExit('Try re-installing or updating your Android SDK.');
  }

  return buildGradleProject(buildMode);
}

Future<Null> buildApk(
  TargetPlatform platform, {
  String target,
  BuildMode buildMode: BuildMode.debug,
  bool applicationNeedsRebuild: false,
}) async {
  if (isProjectUsingGradle()) {
    return await buildAndroidWithGradle(
      platform,
      buildMode,
      force: false,
      target: target
    );
  } else {
    if (!fs.isFileSync(_kDefaultAndroidManifestPath))
      throwToolExit('Cannot build APK: missing $_kDefaultAndroidManifestPath.');

    return await buildAndroid(
      platform,
      buildMode,
      force: false,
      target: target,
      applicationNeedsRebuild: applicationNeedsRebuild,
    );
  }
}

Map<String, dynamic> _readBuildMeta(String buildDirectoryPath) {
  File buildMetaFile = fs.file(path.join(buildDirectoryPath, 'build_meta.json'));
  if (buildMetaFile.existsSync())
    return JSON.decode(buildMetaFile.readAsStringSync());
  return <String, dynamic>{};
}

void _writeBuildMetaEntry(String buildDirectoryPath, String key, dynamic value) {
  Map<String, dynamic> meta = _readBuildMeta(buildDirectoryPath);
  meta[key] = value;
  File buildMetaFile = fs.file(path.join(buildDirectoryPath, 'build_meta.json'));
  buildMetaFile.writeAsStringSync(toPrettyJson(meta));
}

String _getTargetBuildTypeToken(TargetPlatform platform, BuildMode buildMode, File outputBinary) {
  String buildType = getNameForTargetPlatform(platform) + '-' + getModeName(buildMode);
  if (tools.isLocalEngine)
    buildType += ' [${tools.engineBuildPath}]';
  if (outputBinary.existsSync())
    buildType += ' [${outputBinary.lastModifiedSync().millisecondsSinceEpoch}]';
  return buildType;
}
