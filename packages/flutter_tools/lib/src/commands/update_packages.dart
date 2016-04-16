// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

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

      for (Directory dir in runner.getRepoPackages()) {
        int code = await pubGet(directory: dir.path, upgrade: upgrade, checkLastModified: false);
        if (code != 0)
          throw code;
        count++;
      }

      double seconds = timer.elapsedMilliseconds / 1000.0;
      printStatus('\nRan \'pub\' $count time${count == 1 ? "" : "s"} in ${seconds.toStringAsFixed(1)}s.');

      return 0;
    } on int catch (code) {
      return code;
    }
  }
}
