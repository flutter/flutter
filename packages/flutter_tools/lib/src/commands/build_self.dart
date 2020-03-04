// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// Document the "build self" command which is actually performed by
/// code in <flutter src root>/bin/flutter.
class BuildSelfCommand extends BuildSubCommand {
  @override
  final String name = 'self';

  @override
  String get description => 'build the flutter tool itself.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}
