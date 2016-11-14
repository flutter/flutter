// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// This setup command will install dependencies necessary for Flutter development.
///
/// This is a hidden command, and is currently designed to work in a custom kiosk
/// environment, but may be generalized in the future.
class SetupCommand extends FlutterCommand {
  SetupCommand({ this.hidden: false });

  @override
  final String name = 'setup';

  @override
  final String description = 'Setup a machine to support Flutter development.';

  @override
  final bool hidden;

  @override
  Future<Null> runCommand() async {
    printStatus('Running Flutter setup...');

    // setup brew on mac
    if (os.isMacOS) {
      printStatus('\nChecking brew:');

      if (os.which('brew') == null) {
        printError('homebrew is not installed; please install at http://brew.sh/.');
      } else {
        printStatus('brew is installed.');

        await runCommandAndStreamOutput(<String>['brew', 'install', 'ideviceinstaller']);
        await runCommandAndStreamOutput(<String>['brew', 'install', 'ios-deploy']);
      }
    }

    // run doctor
    printStatus('\nFlutter doctor:');
    bool goodInstall = await doctor.diagnose();

    // Validate that flutter is available on the path.
    if (os.which('flutter') == null) {
      printError(
        '\nThe flutter command is not available on the path.\n'
        'Please set up your PATH environment variable to point to the flutter/bin directory.'
      );
    } else {
      printStatus('\nThe flutter command is available on the path.');
    }

    if (!goodInstall)
      throwToolExit(null);

    printStatus('\nFlutter setup complete!');
  }
}
