// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

const String kBuildToolsVersion = '22.0.1';
const String kAndroidPlatformVersion = '22';

const String kKeystoreKeyName = "chromiumdebugkey";
const String kKeystorePassword = "chromium";

class AssetBuilder {
  final Directory outDir;

  Directory _assetDir;

  AssetBuilder(this.outDir) {
    _assetDir = new Directory('${outDir.path}/assets');
    _assetDir.createSync(recursive:  true);
  }

  void add(File asset, String assetName) {
    asset.copySync('${_assetDir.path}/$assetName');
  }

  Directory get directory => _assetDir;
}

class ApkBuilder {
  final String androidSDK;

  File _androidJar;
  File _aapt;
  File _zipalign;
  String _jarsigner;

  ApkBuilder(this.androidSDK) {
    _androidJar = new File('$androidSDK/platforms/android-$kAndroidPlatformVersion/android.jar');

    String buildTools = '$androidSDK/build-tools/$kBuildToolsVersion';
    _aapt = new File('$buildTools/aapt');
    _zipalign = new File('$buildTools/zipalign');
    _jarsigner = 'jarsigner';
  }

  void package(File androidManifest, Directory assets, File outputApk) {
    _run(_aapt.path, [
      'package',
      '-M', androidManifest.path,
      '-A', assets.path,
      '-I', _androidJar.path,
      '-F', outputApk.path,
    ]);
  }

  void add(Directory base, String resource, File outputApk) {
    _run(_aapt.path, [
      'add', '-f', outputApk.absolute.path, resource,
    ], workingDirectory: base.path);
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
    _run(_zipalign.path, ['4', unalignedApk.path, outputApk.path]);
  }

  void _run(String command, List<String> args, { String workingDirectory }) {
    ProcessResult result = Process.runSync(
        command, args, workingDirectory: workingDirectory);
    if (result.exitCode == 0)
      return;
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
}

main(List<String> argv) async {
  ArgParser parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  parser.addOption('android-sdk');
  parser.addOption('skyx');

  ArgResults args = parser.parse(argv);

  Directory artifacts = new Directory('artifacts');
  File keystore = new File('${artifacts.path}/chromium-debug.keystore');
  File androidManifest = new File('${artifacts.path}/AndroidManifest.xml');
  File icuData = new File('${artifacts.path}/assets/icudtl.dat');
  File appSkyx = new File(args['skyx']);

  Directory outDir = new Directory('out');
  outDir.createSync(recursive: true);

  AssetBuilder assetBuilder = new AssetBuilder(outDir);
  assetBuilder.add(icuData, 'icudtl.dat');
  assetBuilder.add(appSkyx, 'app.skyx');

  ApkBuilder builder = new ApkBuilder(args['android-sdk']);

  File unalignedApk = new File('${outDir.path}/Example.apk.unaligned');
  File finalApk = new File('${outDir.path}/Example.apk');

  builder.package(androidManifest, assetBuilder.directory, unalignedApk);
  builder.add(artifacts, 'classes.dex', unalignedApk);
  builder.add(artifacts, 'lib/armeabi-v7a/libsky_shell.so', unalignedApk);
  builder.sign(keystore, kKeystorePassword, kKeystoreKeyName, unalignedApk);
  builder.align(unalignedApk, finalApk);
}
