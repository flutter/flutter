// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../base/file_system.dart';
import '../base/logging.dart';
import '../build_configuration.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import 'build.dart';
import 'start.dart';

const String _kDefaultAndroidManifestPath = 'apk/AndroidManifest.xml';
const String _kDefaultOutputPath = 'build/app.apk';
const String _kKeystoreKeyName = "chromiumdebugkey";
const String _kKeystorePassword = "chromium";

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
  File _zipalign;
  String _jarsigner;

  _ApkBuilder(this.androidSdk) {
    _androidJar = new File('$androidSdk/platforms/android-$_kAndroidPlatformVersion/android.jar');

    String buildTools = '$androidSdk/build-tools/$_kBuildToolsVersion';
    _aapt = new File('$buildTools/aapt');
    _zipalign = new File('$buildTools/zipalign');
    _jarsigner = 'jarsigner';
  }

  bool checkSdkPath() {
    return (_androidJar.existsSync() && _aapt.existsSync() && _zipalign.existsSync());
  }

  void package(File outputApk, File androidManifest, Directory assets, Directory artifacts) {
    _run(_aapt.path, [
      'package',
      '-M', androidManifest.path,
      '-A', assets.path,
      '-I', _androidJar.path,
      '-F', outputApk.path,
      artifacts.path
    ]);
  }

  void sign(File keystore, String keystorePassword, String keyName, File outputApk) {
    _run(_jarsigner, [
      '-keystore', keystore.path,
      '-storepass', keystorePassword,
      outputApk.path,
      keyName,
    ]);
  }

  void align(File unalignedApk, File outputApk) {
    _run(_zipalign.path, ['-f', '4', unalignedApk.path, outputApk.path]);
  }

  void _run(String command, List<String> args, { String workingDirectory }) {
    ProcessResult result = Process.runSync(
        command, args, workingDirectory: workingDirectory
    );
    if (result.exitCode == 0)
      return;
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
}

class _ApkComponents {
  Directory androidSdk;
  File manifest;
  File icuData;
  File classesDex;
  File libSkyShell;
  File keystore;
}

class ApkCommand extends FlutterCommand {
  final String name = 'apk';
  final String description = 'Build an Android APK package.';

  ApkCommand() {
    argParser.addOption('manifest',
        abbr: 'm',
        defaultsTo: _kDefaultAndroidManifestPath,
        help: 'Android manifest XML file.');
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
  }

  Future<_ApkComponents> _findApkComponents(BuildConfiguration config) async {
    String androidSdkPath;
    List<String> artifactPaths;
    if (runner.enginePath != null) {
      androidSdkPath = '${runner.enginePath}/third_party/android_tools/sdk';
      artifactPaths = [
        '${runner.enginePath}/third_party/icu/android/icudtl.dat',
        '${config.buildDir}/gen/sky/shell/shell/classes.dex',
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
        ArtifactType.androidClassesDex,
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
    components.manifest = new File(argResults['manifest']);;
    components.icuData = new File(artifactPaths[0]);
    components.classesDex = new File(artifactPaths[1]);
    components.libSkyShell = new File(artifactPaths[2]);
    components.keystore = new File(artifactPaths[3]);

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
    for (File f in [components.manifest, components.icuData, components.classesDex,
                    components.libSkyShell, components.keystore]) {
      if (!f.existsSync()) {
        logging.severe('Can not locate file: ${f.path}');
        return null;
      }
    }

    return components;
  }

  int _buildApk(_ApkComponents components, String flxPath) {
    Directory tempDir = Directory.systemTemp.createTempSync('flutter_tools');
    try {
      _AssetBuilder assetBuilder = new _AssetBuilder(tempDir, 'assets');
      assetBuilder.add(components.icuData, 'icudtl.dat');
      assetBuilder.add(new File(flxPath), 'app.flx');

      _AssetBuilder artifactBuilder = new _AssetBuilder(tempDir, 'artifacts');
      artifactBuilder.add(components.classesDex, 'classes.dex');
      artifactBuilder.add(components.libSkyShell, 'lib/armeabi-v7a/libsky_shell.so');

      _ApkBuilder builder = new _ApkBuilder(components.androidSdk.path);
      File unalignedApk = new File('${tempDir.path}/app.apk.unaligned');
      builder.package(unalignedApk, components.manifest, assetBuilder.directory,
                      artifactBuilder.directory);
      builder.sign(components.keystore, _kKeystorePassword, _kKeystoreKeyName, unalignedApk);

      File finalApk = new File(argResults['output-file']);
      ensureDirectoryExists(finalApk.path);
      builder.align(unalignedApk, finalApk);

      return 0;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
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
      String mainPath = StartCommand.findMainDartFile(argResults['target']);

      // Build the FLX.
      BuildCommand builder = new BuildCommand();
      builder.inheritFromParent(this);
      int result;
      await builder.buildInTempDir(
        mainPath: mainPath,
        onBundleAvailable: (String localBundlePath) {
          result = _buildApk(components, localBundlePath);
        }
      );

      return result;
    }
  }
}
