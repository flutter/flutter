// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Downloads and merges line coverage data files for package:flutter.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const String kBaseLcov = 'packages/flutter/coverage/lcov.base.info';
const String kTargetLcov = 'packages/flutter/coverage/lcov.info';
const String kSourceLcov = 'packages/flutter/coverage/lcov.source.info';

Future<int> main(List<String> args) async {
  if (path.basename(Directory.current.path) == 'tools')
    Directory.current = Directory.current.parent.parent;

  ProcessResult result = Process.runSync('which', <String>['lcov']);
  if (result.exitCode != 0) {
    print('Cannot find lcov. Consider running "apt-get install lcov".\n');
    return 1;
  }

  if (!FileSystemEntity.isFileSync(kBaseLcov)) {
    print(
      'Cannot find "$kBaseLcov". Consider downloading it from from cloud storage.\n'
      'https://storage.googleapis.com/flutter_infra/flutter/coverage/lcov.info\n'
    );
    return 1;
  }

  ArgParser argParser = new ArgParser();
  argParser.addFlag('merge', negatable: false);
  ArgResults results = argParser.parse(args);

  if (FileSystemEntity.isFileSync(kTargetLcov)) {
    if (results['merge']) {
      new File(kTargetLcov).renameSync(kSourceLcov);
    } else {
      print('"$kTargetLcov" already exists. Did you want to --merge?\n');
      return 1;
    }
  }

  if (results['merge']) {
    if (!FileSystemEntity.isFileSync(kSourceLcov)) {
      print('Cannot merge because "$kSourceLcov" does not exist.\n');
      return 1;
    }

    ProcessResult result = Process.runSync('lcov', <String>[
      '--add-tracefile', kBaseLcov,
      '--add-tracefile', kSourceLcov,
      '--output-file', kTargetLcov,
    ]);
    return result.exitCode;
  }

  print('No operation requested. Did you want to --merge?\n');
  return 0;
}
