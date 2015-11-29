// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/process.dart';
import '../runner/flutter_command.dart';

class UpgradeCommand extends FlutterCommand {
  final String name = 'upgrade';
  final String description = 'Upgrade your copy of Flutter.';

  @override
  Future<int> runInProject() async {
    int code = await runCommandAndStreamOutput([
      'git', 'pull', '--ff-only'
    ], workingDirectory: ArtifactStore.flutterRoot);

    if (code != 0)
      return code;

    return await runCommandAndStreamOutput([sdkBinaryName('pub'), 'upgrade']);
  }
}
