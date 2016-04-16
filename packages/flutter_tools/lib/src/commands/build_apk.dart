// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../android/android_sdk.dart';
import '../base/file_system.dart' show ensureDirectoryExists;
import '../base/os.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_configuration.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../services.dart';
import '../toolchain.dart';
import 'run.dart';

export '../android/android_device.dart' show AndroidDevice;

const String _kDefaultAndroidManifestPath = 'android/AndroidManifest.xml';
const String _kDefaultOutputPath = 'build/app.apk';
const String _kDefaultResourcesPath = 'android/res';

const String _kFlutterManifestPath = 'flutter.yaml';
const String _kPackagesStatusPath = '.packages';

// Alias of the key provided in the Chromium debug keystore
const String _kDebugKeystoreKeyAlias = "chromiumdebugkey";

// Password for the Chromium debug keystore
const String _kDebugKeystorePassword = "chromium";

/// Copies files into a new directory structure.
class _AssetBuilder {
  final Directory outDir;

  Directory _assetDir;

  _AssetBuilder(this.outDir, String assetDirName) {
    _assetDir = new Directory('${outDir.path}/$assetDirName');
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
    _androidJar = new File(sdk.androidJarPath);
    _aapt = new File(sdk.aaptPath);
    _dx = new File(sdk.dxPath);
    _zipalign = new File(sdk.zipalignPath);
    _jarsigner = os.which('jarsigner');
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

  void package(File outputApk, File androidManifest, Directory assets, Directory artifacts, Directory resources) {
    List<String> packageArgs = <String>[_aapt.path,
      'package',
      '-M', androidManifest.path,
      '-A', assets.path,
      '-I', _androidJar.path,
      '-F', outputApk.path,
    ];
    if (resources != null)
      packageArgs.addAll(['-S', resources.absolute.path]);
    packageArgs.add(artifacts.path);
    runCheckedSync(packageArgs);
  }

  void sign(File keystore, String keystorePassword, String keyAlias, String keyPassword, File outputApk) {
    runCheckedSync(<String>[_jarsigner.path,
      '-keystore', keystore.path,
      '-storepass', keystorePassword,
      '-keypass', keyPassword,
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
  List<Map<String, String>> services = [];
  File libSkyShell;
  File debugKeystore;
  Directory resources;
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

class BuildApkCommand extends FlutterCommand {
  BuildApkCommand() {
    argParser.addFlag('develop',
      negatable: false,
      help: 'Build a development version of your app (the default).');
    argParser.addFlag('deploy',
      negatable: false,
      help: 'Build a deployable version of your app.');

    usesTargetOption();
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
      defaultsTo: _kDefaultOutputPath,
      help: 'Output APK file.');
    argParser.addOption('flx',
      abbr: 'f',
      help: 'Path to the FLX file. If this is not provided, an FLX will be built.');
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
    'This command can build development and deployable versions of your application. \'develop\' builds\n'
    'support debugging and a quick development cycle. \'deploy\' builds don\'t support debugging and are\n'
    'suitable for deploying to app stores.';

  @override
  Future<int> runInProject() async {
    // Validate that we can find an android sdk.
    if (androidSdk == null) {
      printError('No Android SDK found. Try setting the ANDROID_HOME environment variable.');
      return 1;
    }

    List<String> validationResult = androidSdk.validateSdkWellFormed();
    if (validationResult.isNotEmpty) {
      validationResult.forEach(printError);
      printError('Try re-installing or updating your Android SDK.');
      return 1;
    }

    BuildVariant variant = BuildVariant.develop;

    if (argResults['deploy'])
      variant = BuildVariant.deploy;

    // TODO(devoncarew): This command should take an arg for the output type (arm / x64).

    return await buildAndroid(
      TargetPlatform.android_arm,
      variant,
      toolchain: toolchain,
      force: true,
      manifest: argResults['manifest'],
      resources: argResults['resources'],
      outputFile: argResults['output-file'],
      target: argResults['target'],
      flxPath: argResults['flx'],
      keystore: (argResults['keystore'] ?? '').isEmpty ? null : new ApkKeystoreInfo(
        keystore: argResults['keystore'],
        password: argResults['keystore-password'],
        keyAlias: argResults['keystore-key-alias'],
        keyPassword: argResults['keystore-key-password']
      )
    );
  }
}

Future<_ApkComponents> _findApkComponents(
  TargetPlatform platform,
  BuildVariant buildVariant,
  String manifest,
  String resources
) async {
  _ApkComponents components = new _ApkComponents();
  components.manifest = new File(manifest);
  components.resources = resources == null ? null : new Directory(resources);

  if (tools.isLocalEngine) {
    String abiDir = platform == TargetPlatform.android_arm ? 'armeabi-v7a' : 'x86_64';
    String enginePath = tools.engineSrcPath;
    String buildDir = tools.getEngineArtifactsDirectory(platform, buildVariant).path;

    components.icuData = new File('$enginePath/third_party/icu/android/icudtl.dat');
    components.jars = <File>[
      new File('$buildDir/gen/sky/shell/shell/classes.dex.jar')
    ];
    components.libSkyShell = new File('$buildDir/gen/sky/shell/shell/shell/libs/$abiDir/libsky_shell.so');
    components.debugKeystore = new File('$enginePath/build/android/ant/chromium-debug.keystore');
  } else {
    Directory artifacts = tools.getEngineArtifactsDirectory(platform, buildVariant);

    components.icuData = new File(path.join(artifacts.path, 'icudtl.dat'));
    components.jars = <File>[
      new File(path.join(artifacts.path, 'classes.dex.jar'))
    ];
    components.libSkyShell = new File(path.join(artifacts.path, 'libsky_shell.so'));
    components.debugKeystore = new File(path.join(artifacts.path, 'chromium-debug.keystore'));
  }

  await parseServiceConfigs(components.services, jars: components.jars);

  List<File> allFiles = <File>[
    components.manifest, components.icuData, components.libSkyShell, components.debugKeystore
  ]..addAll(components.jars);

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
  BuildVariant buildVariant,
  _ApkComponents components,
  String flxPath,
  ApkKeystoreInfo keystore,
  String outputFile
) {
  assert(platform != null);
  assert(buildVariant != null);

  Directory tempDir = Directory.systemTemp.createTempSync('flutter_tools');

  printTrace('Building APK; buildVariant: ${getVariantName(buildVariant)}.');

  try {
    _ApkBuilder builder = new _ApkBuilder(androidSdk.latestVersion);

    File classesDex = new File('${tempDir.path}/classes.dex');
    builder.compileClassesDex(classesDex, components.jars);

    File servicesConfig =
        generateServiceDefinitions(tempDir.path, components.services);

    _AssetBuilder assetBuilder = new _AssetBuilder(tempDir, 'assets');
    assetBuilder.add(components.icuData, 'icudtl.dat');
    assetBuilder.add(new File(flxPath), 'app.flx');
    assetBuilder.add(servicesConfig, 'services.json');

    _AssetBuilder artifactBuilder = new _AssetBuilder(tempDir, 'artifacts');
    artifactBuilder.add(classesDex, 'classes.dex');
    String abiDir = platform == TargetPlatform.android_arm ? 'armeabi-v7a' : 'x86_64';
    artifactBuilder.add(components.libSkyShell, 'lib/$abiDir/libsky_shell.so');

    File unalignedApk = new File('${tempDir.path}/app.apk.unaligned');
    builder.package(
      unalignedApk, components.manifest, assetBuilder.directory,
      artifactBuilder.directory, components.resources
    );

    int signResult = _signApk(builder, components, unalignedApk, keystore);
    if (signResult != 0)
      return signResult;

    File finalApk = new File(outputFile);
    ensureDirectoryExists(finalApk.path);
    builder.align(unalignedApk, finalApk);

    printTrace('calculateSha: $outputFile');
    File apkShaFile = new File('$outputFile.sha1');
    apkShaFile.writeAsStringSync(calculateSha(finalApk));

    double size = finalApk.lengthSync() / (1024 * 1024);
    printStatus('Built ${finalApk.path} (${size.toStringAsFixed(1)}MB).');

    return 0;
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

int _signApk(
  _ApkBuilder builder, _ApkComponents components, File apk, ApkKeystoreInfo keystoreInfo
) {
  File keystore;
  String keystorePassword;
  String keyAlias;
  String keyPassword;

  if (keystoreInfo == null) {
    printStatus('Warning: signing the APK using the debug keystore.');
    keystore = components.debugKeystore;
    keystorePassword = _kDebugKeystorePassword;
    keyAlias = _kDebugKeystoreKeyAlias;
    keyPassword = _kDebugKeystorePassword;
  } else {
    keystore = new File(keystoreInfo.keystore);
    keystorePassword = keystoreInfo.password ?? '';
    keyAlias = keystoreInfo.keyAlias ?? '';
    if (keystorePassword.isEmpty || keyAlias.isEmpty) {
      printError('Must provide a keystore password and a key alias.');
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
bool _needsRebuild(String apkPath, String manifest) {
  FileStat apkStat = FileStat.statSync(apkPath);
  // Note: This list of dependencies is imperfect, but will do for now. We
  // purposely don't include the .dart files, because we can load those
  // over the network without needing to rebuild (at least on Android).
  Iterable<FileStat> dependenciesStat = [
    manifest,
    _kFlutterManifestPath,
    _kPackagesStatusPath
  ].map((String path) => FileStat.statSync(path));

  if (apkStat.type == FileSystemEntityType.NOT_FOUND)
    return true;

  for (FileStat dep in dependenciesStat) {
    if (dep.modified == null || dep.modified.isAfter(apkStat.modified))
      return true;
  }

  if (!FileSystemEntity.isFileSync('$apkPath.sha1'))
    return true;

  return false;
}

Future<int> buildAndroid(
  TargetPlatform platform,
  BuildVariant buildVariant, {
  Toolchain toolchain,
  bool force: false,
  String manifest: _kDefaultAndroidManifestPath,
  String resources,
  String outputFile: _kDefaultOutputPath,
  String target,
  String flxPath,
  ApkKeystoreInfo keystore
}) async {
  // Validate that we can find an android sdk.
  if (androidSdk == null) {
    printError('No Android SDK found. Try setting the ANDROID_HOME environment variable.');
    return 1;
  }

  List<String> validationResult = androidSdk.validateSdkWellFormed();
  if (validationResult.isNotEmpty) {
    validationResult.forEach(printError);
    printError('Try re-installing or updating your Android SDK.');
    return 1;
  }

  if (!force && !_needsRebuild(outputFile, manifest)) {
    printTrace('APK up to date; skipping build step.');
    return 0;
  }

  if (resources != null) {
    if (!FileSystemEntity.isDirectorySync(resources)) {
      printError('Resources directory "$resources" not found.');
      return 1;
    }
  } else {
    if (FileSystemEntity.isDirectorySync(_kDefaultResourcesPath))
      resources = _kDefaultResourcesPath;
  }

  _ApkComponents components = await _findApkComponents(
    platform, buildVariant, manifest, resources
  );

  if (components == null) {
    printError('Failure building APK: unable to find components.');
    return 1;
  }

  String typeName = path.basename(tools.getEngineArtifactsDirectory(platform, buildVariant).path);
  printStatus('Building APK in ${getVariantName(buildVariant)} mode ($typeName)...');

  if (flxPath != null && flxPath.isNotEmpty) {
    if (!FileSystemEntity.isFileSync(flxPath)) {
      printError('FLX does not exist: $flxPath');
      printError('(Omit the --flx option to build the FLX automatically)');
      return 1;
    }

    return _buildApk(platform, buildVariant, components, flxPath, keystore, outputFile);
  } else {
    // Find the path to the main Dart file; build the FLX.
    String mainPath = findMainDartFile(target);
    String localBundlePath = await flx.buildFlx(
        toolchain,
        mainPath: mainPath,
        includeRobotoFonts: false);

    return _buildApk(platform, buildVariant, components, localBundlePath, keystore, outputFile);
  }
}

Future<int> buildApk(
  TargetPlatform platform,
  Toolchain toolchain, {
  String target,
  BuildVariant buildVariant: BuildVariant.develop
}) async {
  if (!FileSystemEntity.isFileSync(_kDefaultAndroidManifestPath)) {
    printError('Cannot build APK: missing $_kDefaultAndroidManifestPath.');
    return 1;
  }

  int result = await buildAndroid(
    platform,
    buildVariant,
    toolchain: toolchain,
    force: false,
    target: target
  );

  return result;
}
