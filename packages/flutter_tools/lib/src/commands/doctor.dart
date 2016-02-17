// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../artifacts.dart';
import '../base/globals.dart';
import '../runner/flutter_command.dart';
import '../runner/version.dart';

class DoctorCommand extends FlutterCommand {
  final String name = 'doctor';
  final String description = 'Diagnose the flutter tool.';

  bool get requiresProjectRoot => false;

  Future<int> runInProject() async {
    // general info
    String flutterRoot = ArtifactStore.flutterRoot;
    printStatus('Flutter root is $flutterRoot.');
    printStatus('');

    // doctor
    doctor.diagnose();
    printStatus('');

    // version
    printStatus(getVersion(flutterRoot));

    return 0;
  }
}
