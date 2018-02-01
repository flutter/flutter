// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../doctor.dart';
import '../runner/flutter_command.dart';

class DoctorCommand extends FlutterCommand {
  DoctorCommand({this.verbose: false}) {
    argParser.addFlag('android-licenses',
      defaultsTo: false,
      negatable: false,
      help: 'Run the Android SDK manager tool to accept the SDK\'s licenses.',
    );
  }

  final bool verbose;

  @override
  final String name = 'doctor';

  @override
  final String description = 'Show information about the installed tooling.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool success = await doctor.diagnose(androidLicenses: argResults['android-licenses'], verbose: verbose);
    return new FlutterCommandResult(success ? ExitStatus.success : ExitStatus.warning);
  }
}
