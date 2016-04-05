// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// Return the total number of projects run; throws the exit code on error.
Future<int> _runPub(Directory directory, { bool upgrade: false }) async {
  int updateCount = 0;
  for (FileSystemEntity dir in directory.listSync()) {
    if (dir is Directory && FileSystemEntity.isFileSync(dir.path + Platform.pathSeparator + 'pubspec.yaml')) {
      updateCount++;
      int code = await pubGet(directory: dir.path, upgrade: upgrade, checkLastModified: false);
      if (code != 0)
        throw code;
    }
  }
  return updateCount;
}

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser.addFlag(
      'upgrade',
      help: 'Run "pub upgrade" rather than "pub get".',
      defaultsTo: false
    );
  }

  @override
  final String name = 'update-packages';

  @override
  final String description = 'Update the packages inside the Flutter repo.';

  @override
  final bool hidden;

  @override
  bool get requiresProjectRoot => false;

  @override
  Future<int> runInProject() async {
    try {
      Stopwatch timer = new Stopwatch()..start();
      int count = 0;
      bool upgrade = argResults['upgrade'];

      count += await _runPub(new Directory("${ArtifactStore.flutterRoot}/packages"), upgrade: upgrade);
      count += await _runPub(new Directory("${ArtifactStore.flutterRoot}/examples"), upgrade: upgrade);
      count += await _runPub(new Directory("${ArtifactStore.flutterRoot}/dev"), upgrade: upgrade);

      printStatus('Ran "pub" $count time${count == 1 ? "" : "s"} in ${timer.elapsedMilliseconds} ms');

      return 0;
    } on int catch (code) {
      return code;
    }
  }
}
