// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../runner/flutter_command.dart';

/// This command is run when generating the app-JIT snapshot for the tool, so it cannot access the Cache
/// or any artifacts that haven't been downloaded yet.
class TrainingCommand extends FlutterCommand {
  @override
  String get description => 'training run for app-jit snapshot';

  @override
  String get name => 'training';

  @override
  bool get hidden => true;

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    // This command does not do anything yet :).
    return FlutterCommandResult.success();
  }
}
