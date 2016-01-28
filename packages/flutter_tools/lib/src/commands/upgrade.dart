// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/context.dart';
import '../base/process.dart';
import '../runner/flutter_command.dart';

class UpgradeCommand extends FlutterCommand {
  final String name = 'upgrade';
  final String description = 'Upgrade your copy of Flutter.';

  @override
  Future<int> runInProject() async {
    try {
      runCheckedSync(<String>[
        'git', 'rev-parse', '@{u}'
      ], workingDirectory: ArtifactStore.flutterRoot);
    } catch (e) {
      printError('Unable to upgrade Flutter. No upstream repository configured for Flutter.');
      return 1;
    }

    int code = await runCommandAndStreamOutput(<String>[
      'git', 'pull', '--ff-only'
    ], workingDirectory: ArtifactStore.flutterRoot);

    if (code != 0)
      return code;

    return await runCommandAndStreamOutput([sdkBinaryName('pub'), 'upgrade']);
  }
}
