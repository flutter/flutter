// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:xml/xml.dart' as xml;

import '../android/device_android.dart';
import '../application_package.dart';
import '../artifacts.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../flx.dart' as flx;
import '../runner/flutter_command.dart';
import '../toolchain.dart';
import 'start.dart';

const String _kDefaultAndroidManifestPath = 'apk/AndroidManifest.xml';
const String _kDefaultOutputPath = 'build/app.apk';
const String _kDefaultResourcesPath = 'apk/res';

const String _kFlutterManifestPath = 'flutter.yaml';
const String _kPubspecYamlPath = 'pubspec.yaml';
const String _kPackagesStatusPath = '.packages';

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

class ApkKeystoreInfo {
  String keystore;
  String password;
  String keyAlias;
  String keyPassword;
  ApkKeystoreInfo({ this.keystore, this.password, this.keyAlias, this.keyPassword });
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
        defaultsTo: flx.defaultMainPath,
        help: 'Target app path / main entry-point file.');
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

  @override
  Future<int> runInProject() async {
    await downloadToolchain();
    return await buildAndroid(
      toolchain: toolchain,
      configs: buildConfigurations,
      enginePath: runner.enginePath,
      force: true,
      manifest: argResults['manifest'],
      resources: argResults['resources'],
      outputFile: argResults['output-file'],
      target: argResults['target'],
      flxPath: argResults['flx'],
      keystore: argResults['keystore'].isEmpty ? null : new ApkKeystoreInfo(
        keystore: argResults['keystore'],
        password: argResults['keystore-password'],
        keyAlias: argResults['keystore-key-alias'],
        keyPassword: argResults['keystore-key-password']
      )
    );
  }
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
      if (jar.startsWith("android-sdk:")) {
        // Jar is something shipped in the standard android SDK.
        jar = jar.replaceAll('android-sdk:', '${components.androidSdk.path}/');
        components.jars.add(new File(jar));
      } else if (jar.startsWith("http")) {
        // Jar is a URL to download.
        String cachePath = await ArtifactStore.getThirdPartyFile(jar, service);
        components.jars.add(new File(cachePath));
      } else {
        // Assume jar is a path relative to the service's root dir.
        components.jars.add(new File(path.join(serviceRoot, jar)));
      }
    }
  }
}

Future<_ApkComponents> _findApkComponents(
  BuildConfiguration config, String enginePath, String manifest, String resources
) async {
  String androidSdkPath;
  List<String> artifactPaths;
  if (enginePath != null) {
    androidSdkPath = '$enginePath/third_party/android_tools/sdk';
    artifactPaths = [
      '$enginePath/third_party/icu/android/icudtl.dat',
      '${config.buildDir}/gen/sky/shell/shell/classes.dex.jar',
      '${config.buildDir}/gen/sky/shell/shell/shell/libs/armeabi-v7a/libsky_shell.so',
      '$enginePath/build/android/ant/chromium-debug.keystore',
    ];
  } else {
    androidSdkPath = AndroidDevice.getAndroidSdkPath();
    if (androidSdkPath == null)
      return null;
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
  components.manifest = new File(manifest);
  components.icuData = new File(artifactPaths[0]);
  components.jars = [new File(artifactPaths[1])];
  components.libSkyShell = new File(artifactPaths[2]);
  components.debugKeystore = new File(artifactPaths[3]);
  components.resources = new Directory(resources);

  await _findServices(components);

  if (!components.resources.existsSync()) {
    // TODO(eseidel): This level should be higher when path is manually set.
    printStatus('Can not locate Resources: ${components.resources}, ignoring.');
    components.resources = null;
  }

  if (!components.androidSdk.existsSync()) {
    printError('Can not locate Android SDK: $androidSdkPath');
    return null;
  }
  if (!(new _ApkBuilder(components.androidSdk.path).checkSdkPath())) {
    printError('Can not locate expected Android SDK tools at $androidSdkPath');
    printError('You must install version $_kAndroidPlatformVersion of the SDK platform');
    printError('and version $_kBuildToolsVersion of the build tools.');
    return null;
  }
  for (File f in [components.manifest, components.icuData,
                  components.libSkyShell, components.debugKeystore]
                  ..addAll(components.jars)) {
    if (!f.existsSync()) {
      printError('Can not locate file: ${f.path}');
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

int _buildApk(
  _ApkComponents components, String flxPath, ApkKeystoreInfo keystore, String outputFile
) {
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

    int signResult = _signApk(builder, components, unalignedApk, keystore);
    if (signResult != 0)
      return signResult;

    File finalApk = new File(outputFile);
    ensureDirectoryExists(finalApk.path);
    builder.align(unalignedApk, finalApk);

    printStatus('Generated APK to ${finalApk.path}.');

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
    printError('Signing the APK using the debug keystore.');
    keystore = components.debugKeystore;
    keystorePassword = _kDebugKeystorePassword;
    keyAlias = _kDebugKeystoreKeyAlias;
    keyPassword = _kDebugKeystorePassword;
  } else {
    keystore = new File(keystoreInfo.keystore);
    keystorePassword = keystoreInfo.password;
    keyAlias = keystoreInfo.keyAlias;
    if (keystorePassword.isEmpty || keyAlias.isEmpty) {
      printError('Must provide a keystore password and a key alias.');
      return 1;
    }
    keyPassword = keystoreInfo.keyPassword;
    if (keyPassword.isEmpty)
      keyPassword = keystorePassword;
  }

  builder.sign(keystore, keystorePassword, keyAlias, keyPassword, apk);

  return 0;
}

// Creates a new ApplicationPackage from the Android manifest.
AndroidApk _getApplicationPackage(String apkPath, String manifest) {
  if (!FileSystemEntity.isFileSync(manifest))
    return null;
  String manifestString = new File(manifest).readAsStringSync();
  xml.XmlDocument document = xml.parse(manifestString);

  Iterable<xml.XmlElement> manifests = document.findElements('manifest');
  if (manifests.isEmpty)
    return null;
  String id = manifests.toList()[0].getAttribute('package');

  String launchActivity;
  for (xml.XmlElement category in document.findAllElements('category')) {
    if (category.getAttribute('android:name') == 'android.intent.category.LAUNCHER') {
      xml.XmlElement activity = category.parent.parent as xml.XmlElement;
      String activityName = activity.getAttribute('android:name');
      launchActivity = "$id/$activityName";
      break;
    }
  }
  if (id == null || launchActivity == null)
    return null;

  return new AndroidApk(localPath: apkPath, id: id, launchActivity: launchActivity);
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
    if (dep.modified.isAfter(apkStat.modified))
      return true;
  }
  return false;
}

Future<int> buildAndroid({
  Toolchain toolchain,
  List<BuildConfiguration> configs,
  String enginePath,
  bool force: false,
  String manifest: _kDefaultAndroidManifestPath,
  String resources: _kDefaultResourcesPath,
  String outputFile: _kDefaultOutputPath,
  String target: '',
  String flxPath: '',
  ApkKeystoreInfo keystore
}) async {
  if (!_needsRebuild(outputFile, manifest)) {
    printTrace('APK up to date. Skipping build step.');
    return 0;
  }

  BuildConfiguration config = configs.firstWhere(
      (BuildConfiguration bc) => bc.targetPlatform == TargetPlatform.android
  );
  _ApkComponents components = await _findApkComponents(config, enginePath, manifest, resources);
  if (components == null) {
    printError('Failure building APK. Unable to find components.');
    return 1;
  }

  printStatus('Building APK...');

  if (!flxPath.isEmpty) {
    if (!FileSystemEntity.isFileSync(flxPath)) {
      printError('FLX does not exist: $flxPath');
      printError('(Omit the --flx option to build the FLX automatically)');
      return 1;
    }
    return _buildApk(components, flxPath, keystore, outputFile);
  } else {
    // Find the path to the main Dart file.
    String mainPath = findMainDartFile(target);

    // Build the FLX.
    flx.DirectoryResult buildResult = await flx.buildInTempDir(toolchain, mainPath: mainPath);

    try {
      return _buildApk(components, buildResult.localBundlePath, keystore, outputFile);
    } finally {
      buildResult.dispose();
    }
  }
}

Future<ApplicationPackageStore> buildAll(
  DeviceStore devices,
  ApplicationPackageStore applicationPackages,
  Toolchain toolchain,
  List<BuildConfiguration> configs, {
  String enginePath,
  String target: ''
}) async {
  for (Device device in devices.all) {
    ApplicationPackage package = applicationPackages.getPackageForPlatform(device.platform);
    if (package == null || !device.isConnected())
      continue;

    // TODO(mpcomplete): Temporary hack. We only support the apk builder atm.
    if (package == applicationPackages.android) {
      if (!FileSystemEntity.isFileSync(_kDefaultAndroidManifestPath)) {
        printStatus('Using pre-built SkyShell.apk.');
        continue;
      }

      await buildAndroid(
        toolchain: toolchain,
        configs: configs,
        enginePath: enginePath,
        force: false,
        target: target
      );
      // Replace our pre-built AndroidApk with this custom-built one.
      applicationPackages = new ApplicationPackageStore(
        android: _getApplicationPackage(_kDefaultOutputPath, _kDefaultAndroidManifestPath),
        iOS: applicationPackages.iOS,
        iOSSimulator: applicationPackages.iOSSimulator
      );
    }
  }
  return applicationPackages;
}
