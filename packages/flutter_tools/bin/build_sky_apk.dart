// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

const String kBuildToolsVersion = '22.0.1';
const String kAndroidPlatformVersion = '22';

const String kKeystoreKeyName = "chromiumdebugkey";
const String kKeystorePassword = "chromium";

const String kICUDataFile = 'icudtl.dat';

void run(String command, List<String> args) {
  ProcessResult result = Process.runSync(command, args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
}

main(List<String> argv) async {
  ArgParser parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false);
  parser.addOption('android-sdk');
  parser.addOption('skyx');

  ArgResults args = parser.parse(argv);

  File unalignedApk = new File('out/Example.apk.unaligned');
  File finalApk = new File('out/Example.apk');
  File androidManifest = new File('artifacts/AndroidManifest.xml');
  File classesDex = new File('artifacts/classes.dex');
  File icuDataFile = new File('artifacts/$kICUDataFile');
  File keystore = new File('artifacts/chromium-debug.keystore');

  String androidSDK = args['android-sdk'];
  String buildTools = '$androidSDK/build-tools/$kBuildToolsVersion';
  String aapt = '$buildTools/aapt';
  String zipalign = '$buildTools/zipalign';
  File androidJar = new File('$androidSDK/platforms/android-$kAndroidPlatformVersion/android.jar');
  String jarsigner = 'jarsigner';

  Directory assets = new Directory('out/assets');
  await assets.create(recursive: true);

  icuDataFile.copy('${assets.path}/$kICUDataFile');

  run(aapt, [
    'package',
    '-M', androidManifest.path,
    '-A', assets.path,
    '-I', androidJar.path,
    '-F', unalignedApk.path,
  ]);

  run(aapt, [ 'add', '-f', unalignedApk.path, classesDex.path ]);

  run(jarsigner, [
    '-keystore', keystore.path,
    '-storepass', kKeystorePassword,
    unalignedApk.path,
    kKeystoreKeyName,
  ]);

  run(zipalign, ['4', unalignedApk.path, finalApk.path]);
}
