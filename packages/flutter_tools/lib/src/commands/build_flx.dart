// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildFlxCommand extends BuildSubCommand {
  @override
  final String name = 'flx';

  @override
  final String description = 'Deprecated';

  @override
  final String usageFooter = 'FLX archives are deprecated.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();

    printError("'build flx' is no longer supported. Instead, use 'build "
               "bundle' to build and assemble the application code and resources "
               'for your app.');

    return null;
  }
}
