// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../build_configuration.dart';
import '../file_system.dart';
import 'build.dart';
import 'flutter_command.dart';
import 'start.dart';

const String _kDefaultAndroidManifestPath = 'apk/AndroidManifest.xml';
const String _kDefaultOutputPath = 'build/app.apk';
const String _kKeystoreKeyName = "chromiumdebugkey";
const String _kKeystorePassword = "chromium";

final Logger _logging = new Logger('flutter_tools.apk');

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
  static const String _kAndroidPlatformVersion = '22';
  static const String _kBuildToolsVersion = '22.0.1';

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

  int _buildApk(BuildConfiguration config, String flxPath) {
    File androidManifest = new File(argResults['manifest']);
    File icuData = new File('${runner.enginePath}/third_party/icu/android/icudtl.dat');
    File classesDex = new File('${config.buildDir}/gen/sky/shell/shell/classes.dex');
    File libSkyShell = new File('${config.buildDir}/gen/sky/shell/shell/shell/libs/armeabi-v7a/libsky_shell.so');
    File keystore = new File('${runner.enginePath}/build/android/ant/chromium-debug.keystore');

    for (File f in [androidManifest, icuData, classesDex, libSkyShell, keystore]) {
      if (!f.existsSync()) {
        _logging.severe('Can not locate file: ${f.path}');
        return 1;
      }
    }

    Directory androidSdk = new Directory('${runner.enginePath}/third_party/android_tools/sdk');
    if (!androidSdk.existsSync()) {
      _logging.severe('Can not locate Android SDK: ${androidSdk.path}');
      return 1;
    }

    Directory tempDir = Directory.systemTemp.createTempSync('flutter_tools');
    try {
      _AssetBuilder assetBuilder = new _AssetBuilder(tempDir, 'assets');
      assetBuilder.add(icuData, 'icudtl.dat');
      assetBuilder.add(new File(flxPath), 'app.flx');

      _AssetBuilder artifactBuilder = new _AssetBuilder(tempDir, 'artifacts');
      artifactBuilder.add(classesDex, 'classes.dex');
      artifactBuilder.add(libSkyShell, 'lib/armeabi-v7a/libsky_shell.so');

      _ApkBuilder builder = new _ApkBuilder(androidSdk.path);
      File unalignedApk = new File('${tempDir.path}/app.apk.unaligned');
      builder.package(unalignedApk, androidManifest, assetBuilder.directory,
                      artifactBuilder.directory);
      builder.sign(keystore, _kKeystorePassword, _kKeystoreKeyName, unalignedApk);

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
    if (runner.enginePath == null) {
      _logging.severe('Unable to locate the Flutter engine.  Use the --engine-src-path option.');
      return 1;
    }

    BuildConfiguration config = buildConfigurations.firstWhere(
        (BuildConfiguration bc) => bc.targetPlatform == TargetPlatform.android
    );

    String flxPath = argResults['flx'];

    if (!flxPath.isEmpty) {
      if (!FileSystemEntity.isFileSync(flxPath)) {
        _logging.severe('FLX does not exist: $flxPath');
        _logging.severe('(Omit the --flx option to build the FLX automatically)');
        return 1;
      }
      return _buildApk(config, flxPath);
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
          result = _buildApk(config, localBundlePath);
        }
      );

      return result;
    }
  }
}
