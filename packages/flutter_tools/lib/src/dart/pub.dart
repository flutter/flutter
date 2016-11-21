// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../cache.dart';
import '../globals.dart';
import 'sdk.dart';

bool _shouldRunPubGet({ File pubSpecYaml, File dotPackages }) {
  if (!dotPackages.existsSync())
    return true;
  DateTime dotPackagesLastModified = dotPackages.lastModifiedSync();
  if (pubSpecYaml.lastModifiedSync().isAfter(dotPackagesLastModified))
    return true;
  File flutterToolsStamp = Cache.instance.getStampFileFor('flutter_tools');
  if (flutterToolsStamp.lastModifiedSync().isAfter(dotPackagesLastModified))
    return true;
  return false;
}

Future<Null> pubGet({
  String directory,
  bool skipIfAbsent: false,
  bool upgrade: false,
  bool checkLastModified: true
}) async {
  if (directory == null)
    directory = Directory.current.path;

  File pubSpecYaml = new File(path.join(directory, 'pubspec.yaml'));
  File dotPackages = new File(path.join(directory, '.packages'));

  if (!pubSpecYaml.existsSync()) {
    if (!skipIfAbsent)
      throwToolExit('$directory: no pubspec.yaml found');
    return;
  }

  if (!checkLastModified || _shouldRunPubGet(pubSpecYaml: pubSpecYaml, dotPackages: dotPackages)) {
    String command = upgrade ? 'upgrade' : 'get';
    Status status = logger.startProgress("Running 'flutter packages $command' in ${path.basename(directory)}...");
    int code = await runCommandAndStreamOutput(
      <String>[sdkBinaryName('pub'), '--verbosity=warning', command, '--no-packages-dir', '--no-precompile'],
      workingDirectory: directory,
      mapFunction: _filterOverrideWarnings,
      environment: <String, String>{ 'FLUTTER_ROOT': Cache.flutterRoot }
    );
    status.stop();
    if (code != 0)
      throwToolExit('pub $command failed ($code)', exitCode: code);
  }

  if (!dotPackages.existsSync())
    throwToolExit('$directory: pub did not create .packages file');

  if (dotPackages.lastModifiedSync().isBefore(pubSpecYaml.lastModifiedSync()))
    throwToolExit('$directory: pub did not update .packages file (pubspec.yaml file has a newer timestamp)');
}

final RegExp _analyzerWarning = new RegExp(r'^! analyzer [^ ]+ from path \.\./\.\./bin/cache/dart-sdk/lib/analyzer$');

String _filterOverrideWarnings(String message) {
  // This function filters out these two messages:
  //   Warning: You are using these overridden dependencies:
  //   ! analyzer 0.29.0-alpha.0 from path ../../bin/cache/dart-sdk/lib/analyzer
  if (message == 'Warning: You are using these overridden dependencies:')
    return null;
  if (message.contains(_analyzerWarning))
    return null;
  return message;
}
