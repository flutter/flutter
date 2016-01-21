// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../android/device_android.dart';
import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logging.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../flx.dart' as flx;
import '../runner/flutter_command.dart';
import 'start.dart';

const String _kDefaultAndroidManifestPath = 'apk/AndroidManifest.xml';
const String _kDefaultOutputPath = 'build/app.apk';
const String _kDefaultResourcesPath = 'apk/res';

const String _kFlutterManifestPath = 'flutter.yaml';
const String _kPubspecYamlPath = 'pubspec.yaml';

// Alias of the key provided in the Chromium debug keystore
const String _kDebugKeystoreKeyAlias = "chromiumdebugkey";

// Password for the Chromium debug keystore
const String _kDebugKeystorePassword = "chromium";

const String _kAndroidPlatformVersion = '22';
const String _kBuildToolsVersion = '22.0.1';

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
  final String androidSdk;

  File _androidJar;
  File _aapt;
  File _dx;
  File _zipalign;
  String _jarsigner;

  _ApkBuilder(this.androidSdk) {
    _androidJar = new File('$androidSdk/platforms/android-$_kAndroidPlatformVersion/android.jar');

    String buildTools = '$androidSdk/build-tools/$_kBuildToolsVersion';
    _aapt = new File('$buildTools/aapt');
    _dx = new File('$buildTools/dx');
    _zipalign = new File('$buildTools/zipalign');
    _jarsigner = 'jarsigner';
  }

  bool checkSdkPath() {
    return (_androidJar.existsSync() && _aapt.existsSync() && _dx.existsSync() && _zipalign.existsSync());
  }

  void compileClassesDex(File classesDex, List<File> jars) {
    List<String> packageArgs = [_dx.path,
      '--dex',
      '--force-jumbo',
      '--output', classesDex.path
    ];

    packageArgs.addAll(jars.map((File f) => f.path));

    runCheckedSync(packageArgs);
  }

  void package(File outputApk, File androidManifest, Directory assets, Directory artifacts, Directory resources) {
    List<String> packageArgs = [_aapt.path,
      'package',
      '-M', androidManifest.path,
      '-A', assets.path,
      '-I', _androidJar.path,
      '-F', outputApk.path,
    ];
    if (resources != null) {
      packageArgs.addAll(['-S', resources.absolute.path]);
    }
    packageArgs.add(artifacts.path);
    runCheckedSync(packageArgs);
  }

  void sign(File keystore, String keystorePassword, String keyAlias, String keyPassword, File outputApk) {
    runCheckedSync([_jarsigner,
      '-keystore', keystore.path,
      '-storepass', keystorePassword,
      '-keypass', keyPassword,
      outputApk.path,
      keyAlias,
    ]);
  }

  void align(File unalignedApk, File outputApk) {
    runCheckedSync([_zipalign.path, '-f', '4', unalignedApk.path, outputApk.path]);
  }
}

class _ApkComponents {
  Directory androidSdk;
  File manifest;
  File icuData;
  List<File> jars;
  List<Map<String, String>> services = [];
  File libSkyShell;
  File debugKeystore;
  Directory resources;
}

// TODO(mpcomplete): find a better home for this.
dynamic _loadYamlFile(String path) {
  if (!FileSystemEntity.isFileSync(path))
    return null;
  String manifestString = new File(path).readAsStringSync();
  return loadYaml(manifestString);
}

class ApkCommand extends FlutterCommand {
  final String name = 'apk';
  final String description = 'Build an Android APK package.';

  ApkCommand() {
    argParser.addOption('manifest',
        abbr: 'm',
        defaultsTo: _kDefaultAndroidManifestPath,
        help: 'Android manifest XML file.');
    argParser.addOption('resources',
        abbr: 'r',
        defaultsTo: _kDefaultResourcesPath,
        help: 'Resources directory path.');
    argParser.addOption('output-file',
        abbr: 'o',
        defaultsTo: _kDefaultOutputPath,
        help: 'Output APK file.');
    argParser.addOption('target',
        abbr: 't',
        defaultsTo: '',
        help: 'Target app path or filename used to build the FLX.');
    argParser.addOption('flx',
        abbr: 'f',
        defaultsTo: '',
        help: 'Path to the FLX file. If this is not provided, an FLX will be built.');
    argParser.addOption('keystore',
        defaultsTo: '',
        help: 'Path to the keystore used to sign the app.');
    argParser.addOption('keystore-password',
        defaultsTo: '',
        help: 'Password used to access the keystore.');
    argParser.addOption('keystore-key-alias',
        defaultsTo: '',
        help: 'Alias of the entry within the keystore.');
    argParser.addOption('keystore-key-password',
        defaultsTo: '',
        help: 'Password for the entry within the keystore.');
  }

  Future _findServices(_ApkComponents components) async {
    if (!ArtifactStore.isPackageRootValid)
      return;

    dynamic manifest = _loadYamlFile(_kFlutterManifestPath);
    if (manifest['services'] == null)
      return;

    for (String service in manifest['services']) {
      String serviceRoot = '${ArtifactStore.packageRoot}/$service/apk';
      dynamic serviceConfig = _loadYamlFile('$serviceRoot/config.yaml');
      if (serviceConfig == null || serviceConfig['jars'] == null)
        continue;
      components.services.addAll(serviceConfig['services']);
      for (String jar in serviceConfig['jars']) {
        // Jar might refer to an android SDK jar, or URL to download.
        if (jar.startsWith("android-sdk:")) {
          jar = jar.replaceAll('android-sdk:', '${components.androidSdk.path}/');
          components.jars.add(new File(jar));
        } else if (jar.startsWith("http")) {
          String cachePath = await ArtifactStore.getThirdPartyFile(jar, service);
          components.jars.add(new File(cachePath));
        } else {
          logging.severe('Service depends on a jar in an unrecognized format: $jar');
          throw new ProcessExit(2);
        }
      }
    }
  }

  Future<_ApkComponents> _findApkComponents(BuildConfiguration config) async {
    String androidSdkPath;
    List<String> artifactPaths;
    if (runner.enginePath != null) {
      androidSdkPath = '${runner.enginePath}/third_party/android_tools/sdk';
      artifactPaths = [
        '${runner.enginePath}/third_party/icu/android/icudtl.dat',
        '${config.buildDir}/gen/sky/shell/shell/classes.dex.jar',
        '${config.buildDir}/gen/sky/shell/shell/shell/libs/armeabi-v7a/libsky_shell.so',
        '${runner.enginePath}/build/android/ant/chromium-debug.keystore',
      ];
    } else {
      androidSdkPath = AndroidDevice.getAndroidSdkPath();
      if (androidSdkPath == null) {
        return null;
      }
      List<ArtifactType> artifactTypes = <ArtifactType>[
        ArtifactType.androidIcuData,
        ArtifactType.androidClassesJar,
        ArtifactType.androidLibSkyShell,
        ArtifactType.androidKeystore,
      ];
      Iterable<Future<String>> pathFutures = artifactTypes.map(
          (ArtifactType type) => ArtifactStore.getPath(ArtifactStore.getArtifact(
              type: type, targetPlatform: TargetPlatform.android)));
      artifactPaths = await Future.wait(pathFutures);
    }

    _ApkComponents components = new _ApkComponents();
    components.androidSdk = new Directory(androidSdkPath);
    components.manifest = new File(argResults['manifest']);
    components.icuData = new File(artifactPaths[0]);
    components.jars = [new File(artifactPaths[1])];
    components.libSkyShell = new File(artifactPaths[2]);
    components.debugKeystore = new File(artifactPaths[3]);
    components.resources = new Directory(argResults['resources']);

    await _findServices(components);

    if (!components.resources.existsSync()) {
      // TODO(eseidel): This level should be higher when path is manually set.
      logging.info('Can not locate Resources: ${components.resources}, ignoring.');
      components.resources = null;
    }

    if (!components.androidSdk.existsSync()) {
      logging.severe('Can not locate Android SDK: $androidSdkPath');
      return null;
    }
    if (!(new _ApkBuilder(components.androidSdk.path).checkSdkPath())) {
      logging.severe('Can not locate expected Android SDK tools at $androidSdkPath');
      logging.severe('You must install version $_kAndroidPlatformVersion of the SDK platform');
      logging.severe('and version $_kBuildToolsVersion of the build tools.');
      return null;
    }
    for (File f in [components.manifest, components.icuData,
                    components.libSkyShell, components.debugKeystore]
                    ..addAll(components.jars)) {
      if (!f.existsSync()) {
        logging.severe('Can not locate file: ${f.path}');
        return null;
      }
    }

    return components;
  }

  // Outputs a services.json file for the flutter engine to read. Format:
  // {
  //   services: [
  //     { name: string, class: string },
  //     ...
  //   ]
  // }
  void _generateServicesConfig(File servicesConfig, List<Map<String, String>> servicesIn) {
    List<Map<String, String>> services =
        servicesIn.map((Map<String, String> service) => {
          'name': service['name'],
          'class': service['registration-class']
        }).toList();

    Map<String, dynamic> json = { 'services': services };
    servicesConfig.writeAsStringSync(JSON.encode(json), mode: FileMode.WRITE, flush: true);
  }

  int _buildApk(_ApkComponents components, String flxPath) {
    Directory tempDir = Directory.systemTemp.createTempSync('flutter_tools');
    try {
      _ApkBuilder builder = new _ApkBuilder(components.androidSdk.path);

      File classesDex = new File('${tempDir.path}/classes.dex');
      builder.compileClassesDex(classesDex, components.jars);

      File servicesConfig = new File('${tempDir.path}/services.json');
      _generateServicesConfig(servicesConfig, components.services);

      _AssetBuilder assetBuilder = new _AssetBuilder(tempDir, 'assets');
      assetBuilder.add(components.icuData, 'icudtl.dat');
      assetBuilder.add(new File(flxPath), 'app.flx');
      assetBuilder.add(servicesConfig, 'services.json');

      _AssetBuilder artifactBuilder = new _AssetBuilder(tempDir, 'artifacts');
      artifactBuilder.add(classesDex, 'classes.dex');
      artifactBuilder.add(components.libSkyShell, 'lib/armeabi-v7a/libsky_shell.so');

      File unalignedApk = new File('${tempDir.path}/app.apk.unaligned');
      builder.package(unalignedApk, components.manifest, assetBuilder.directory,
                      artifactBuilder.directory, components.resources);

      int signResult = _signApk(builder, components, unalignedApk);
      if (signResult != 0)
        return signResult;

      File finalApk = new File(argResults['output-file']);
      ensureDirectoryExists(finalApk.path);
      builder.align(unalignedApk, finalApk);

      print('APK generated: ${finalApk.path}');

      return 0;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  }

  int _signApk(_ApkBuilder builder, _ApkComponents components, File apk) {
    File keystore;
    String keystorePassword;
    String keyAlias;
    String keyPassword;

    if (argResults['keystore'].isEmpty) {
      logging.warning('Signing the APK using the debug keystore');
      keystore = components.debugKeystore;
      keystorePassword = _kDebugKeystorePassword;
      keyAlias = _kDebugKeystoreKeyAlias;
      keyPassword = _kDebugKeystorePassword;
    } else {
      keystore = new File(argResults['keystore']);
      keystorePassword = argResults['keystore-password'];
      keyAlias = argResults['keystore-key-alias'];
      if (keystorePassword.isEmpty || keyAlias.isEmpty) {
        logging.severe('Must provide a keystore password and a key alias');
        return 1;
      }
      keyPassword = argResults['keystore-key-password'];
      if (keyPassword.isEmpty)
        keyPassword = keystorePassword;
    }

    builder.sign(keystore, keystorePassword, keyAlias, keyPassword, apk);

    return 0;
  }

  @override
  Future<int> runInProject() async {
    BuildConfiguration config = buildConfigurations.firstWhere(
        (BuildConfiguration bc) => bc.targetPlatform == TargetPlatform.android
    );

    _ApkComponents components = await _findApkComponents(config);
    if (components == null) {
      logging.severe('Unable to build APK.');
      return 1;
    }

    String flxPath = argResults['flx'];

    if (!flxPath.isEmpty) {
      if (!FileSystemEntity.isFileSync(flxPath)) {
        logging.severe('FLX does not exist: $flxPath');
        logging.severe('(Omit the --flx option to build the FLX automatically)');
        return 1;
      }
      return _buildApk(components, flxPath);
    } else {
      await downloadToolchain();

      // Find the path to the main Dart file.
      String mainPath = findMainDartFile(argResults['target']);

      // Build the FLX.
      flx.DirectoryResult buildResult = await flx.buildInTempDir(toolchain, mainPath: mainPath);

      try {
        return _buildApk(components, buildResult.localBundlePath);
      } finally {
        buildResult.dispose();
      }
    }
  }
}
