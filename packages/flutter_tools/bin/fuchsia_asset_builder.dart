// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart' as libfs;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/disabled_usage.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:flutter_tools/src/usage.dart';

const String _kOptionPackages = 'packages';
const String _kOptionAsset = 'asset-dir';
const String _kOptionManifest = 'manifest';
const String _kOptionAssetManifestOut = 'asset-manifest-out';
const List<String> _kRequiredOptions = const <String>[
  _kOptionPackages,
  _kOptionAsset,
  _kOptionAssetManifestOut,
];

Future<Null> main(List<String> args) {
  return runInContext<Null>(() => run(args), overrides: <Type, dynamic>{
    Usage: new DisabledUsage(),
  });
}

Future<Null> writeFile(libfs.File outputFile, DevFSContent content) async {
  outputFile.createSync(recursive: true);
  final List<int> data = await content.contentsAsBytes();
  outputFile.writeAsBytesSync(data);
  return null;
}

Future<Null> run(List<String> args) async {
  final ArgParser parser = new ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionAsset,
        help: 'The directory where to put temporary files')
    ..addOption(_kOptionManifest, help: 'The manifest file')
    ..addOption(_kOptionAssetManifestOut);
  final ArgResults argResults = parser.parse(args);
  if (_kRequiredOptions
      .any((String option) => !argResults.options.contains(option))) {
    printError('Missing option! All options must be specified.');
    exit(1);
  }
  Cache.flutterRoot = platform.environment['FLUTTER_ROOT'];

  final String assetDir = argResults[_kOptionAsset];
  final AssetBundle assets = await buildAssets(
    manifestPath: argResults[_kOptionManifest] ?? defaultManifestPath,
    assetDirPath: assetDir,
    packagesPath: argResults[_kOptionPackages],
    includeDefaultFonts: false,
  );

  if (assets == null) {
    print('Unable to find assets.');
    exit(1);
  }

  final List<Future<Null>> calls = <Future<Null>>[];
  assets.entries.forEach((String fileName, DevFSContent content) {
    final libfs.File outputFile = libfs.fs.file(libfs.fs.path.join(assetDir, fileName));
    calls.add(writeFile(outputFile, content));
  });
  await Future.wait(calls);

  final String outputMan = argResults[_kOptionAssetManifestOut];
  await writeFuchsiaManifest(assets, argResults[_kOptionAsset], outputMan);
}

Future<Null> writeFuchsiaManifest(AssetBundle assets, String outputBase, String fileDest) async {

  final libfs.File destFile = libfs.fs.file(fileDest);
  await destFile.create(recursive: true);
  final libfs.IOSink outFile = destFile.openWrite();

  for (String path in assets.entries.keys) {
    outFile.write('data/$path=$outputBase/$path\n');
  }
  await outFile.flush();
  await outFile.close();
}
