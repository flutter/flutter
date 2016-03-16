// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

List<Future<Null>> _runPub(Directory directory, { bool upgrade: false, bool offline: false }) {
  List<Future<Null>> result = <Future<Null>>[];
  for (FileSystemEntity dir in directory.listSync()) {
    if (dir is Directory && FileSystemEntity.isFileSync(dir.path + Platform.pathSeparator + 'pubspec.yaml')) {
      result.add(pubGet(directory: dir.path, upgrade: upgrade, offline: offline, checkLastModified: false).then/*<Null>*/((int result) {
        if (result != 0)
          throw 'pub failed with exit code $result in ${dir.path}';
        return null;
      }));
    }
  }
  return result;
}

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser.addFlag(
      'upgrade',
      help: 'Run "pub upgrade" rather than "pub get".',
      defaultsTo: false
    );
    argParser.addFlag(
      'offline',
      help: 'Pass --offline to pub, forcing it to use cached packages instead of accessing the network.',
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
    Stopwatch timer = new Stopwatch()..start();
    bool upgrade = argResults['upgrade'];
    bool offline = argResults['offline'];
    List<Future<Null>> processes = <Future<Null>>[];
    processes.addAll(_runPub(new Directory("${ArtifactStore.flutterRoot}/packages"), upgrade: upgrade, offline: offline));
    processes.addAll(_runPub(new Directory("${ArtifactStore.flutterRoot}/examples"), upgrade: upgrade, offline: offline));
    processes.addAll(_runPub(new Directory("${ArtifactStore.flutterRoot}/dev"), upgrade: upgrade, offline: offline));
    printTrace('Waiting for pub...');
    int count = (await Future.wait(processes, eagerError: true)).length;
    printStatus('Ran "pub" $count time${count == 1 ? "" : "s"} in ${timer.elapsedMilliseconds} ms');
    return 0;
  }
}
