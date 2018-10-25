// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../doctor.dart';
import '../runner/flutter_command.dart';

class DoctorCommand extends FlutterCommand {
  DoctorCommand({this.verbose = false}) {
    argParser.addFlag('android-licenses',
      defaultsTo: false,
      negatable: false,
      help: 'Run the Android SDK manager tool to accept the SDK\'s licenses.',
    );
    argParser.addOption('check-for-remote-artifacts',
      hide: !verbose,
      help: 'Used to determine if Flutter engine artifacts for all platforms '
            'are available for download.',
      valueHelp: 'engine revision',);
  }

  final bool verbose;

  @override
  final String name = 'doctor';

  @override
  final String description = 'Show information about the installed tooling.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String engineRevision = argResults['check-for-remote-artifacts'];
    if (engineRevision != null) {
      final bool success = await doctor.checkRemoteArtifacts(engineRevision);
      if (!success) {
        throwToolExit('Artifacts for engine $engineRevision are missing or are '
            'not yet available.', exitCode: 1);
      }
    }
    final bool success = await doctor.diagnose(androidLicenses: argResults['android-licenses'], verbose: verbose);
    return FlutterCommandResult(success ? ExitStatus.success : ExitStatus.warning);
  }
}
