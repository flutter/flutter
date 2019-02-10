// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../runner/flutter_command.dart';

class TrainingCommand extends FlutterCommand {
  @override
  String get description => 'training run for app-jit snapshot';

  @override
  String get name => 'training';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    return null;
  }
}