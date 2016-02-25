// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/process.dart';
import '../globals.dart';

Future<int> pubGet({
  String directory,
  bool skipIfAbsent: false,
  bool upgrade: false,
  bool checkLastModified: true
}) async {
  if (directory == null)
    directory = Directory.current.path;

  File pubSpecYaml = new File(path.join(directory, 'pubspec.yaml'));
  File pubSpecLock = new File(path.join(directory, 'pubspec.lock'));
  File dotPackages = new File(path.join(directory, '.packages'));

  if (!pubSpecYaml.existsSync()) {
    if (skipIfAbsent)
      return 0;
    printError('$directory: no pubspec.yaml found');
    return 1;
  }

  if (!checkLastModified || !pubSpecLock.existsSync() || pubSpecYaml.lastModifiedSync().isAfter(pubSpecLock.lastModifiedSync())) {
    printStatus("Running 'pub get' in $directory${Platform.pathSeparator}...");
    String command = upgrade ? 'upgrade' : 'get';
    int code = await runCommandAndStreamOutput(
      <String>[sdkBinaryName('pub'), '--verbosity=warning', command],
      workingDirectory: directory
    );
    if (code != 0)
      return code;
  }

  if ((pubSpecLock.existsSync() && pubSpecLock.lastModifiedSync().isAfter(pubSpecYaml.lastModifiedSync())) &&
      (dotPackages.existsSync() && dotPackages.lastModifiedSync().isAfter(pubSpecYaml.lastModifiedSync())))
    return 0;

  printError('$directory: pubspec.yaml, pubspec.lock, and .packages are in an inconsistent state');
  return 1;
}
