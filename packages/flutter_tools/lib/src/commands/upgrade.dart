// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/process.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../runner/version.dart';

class UpgradeCommand extends FlutterCommand {
  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  Validator projectRootValidator = () => true;

  @override
  Future<int> runInProject() async {
    printStatus(FlutterVersion.getVersion(ArtifactStore.flutterRoot).toString());

    try {
      runCheckedSync(<String>[
        'git', 'rev-parse', '@{u}'
      ], workingDirectory: ArtifactStore.flutterRoot);
    } catch (e) {
      printError('Unable to upgrade Flutter. No upstream repository configured for Flutter.');
      return 1;
    }

    printStatus('');
    printStatus('Upgrading Flutter...');

    int code = await runCommandAndStreamOutput(<String>[
      'git', 'pull', '--ff-only'
    ], workingDirectory: ArtifactStore.flutterRoot);

    if (code != 0)
      return code;

    // Causes us to update our locally cached packages.
    code = await runCommandAndStreamOutput(<String>[
      'bin/flutter', '--version'
    ], workingDirectory: ArtifactStore.flutterRoot);

    printStatus('');
    code = await runCommandAndStreamOutput([sdkBinaryName('pub'), 'upgrade']);

    if (code != 0)
      return code;

    printStatus('');
    printStatus(FlutterVersion.getVersion(ArtifactStore.flutterRoot).toString());

    return 0;
  }
}
