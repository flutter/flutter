// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './globals.dart';
import './repository.dart';
import './state.dart';
import './stdio.dart';

/// Verify the local system is has pre-requisites for conducting a release.
class DoctorCommand extends Command<void> {
  DoctorCommand({
    @required this.checkouts,
  })  : platform = checkouts.platform,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      'state-file',
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Verify the host computer is set up to conduct a release';

  @override
  void run() {
    final Doctor doctor = Doctor(checkouts: checkouts);
    if (!doctor.validate()) {
      throw ConductorException('Failed validations!');
    }

    stdio.printStatus('Your local setup is ready to conduct a Flutter release.');
  }
}

class Doctor {
  Doctor({
    @required this.checkouts,
  })  : processManager = checkouts.processManager,
        platform = checkouts.platform,
        stdio = checkouts.stdio;

  final Checkouts checkouts;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// External binary tools that the Conductor depends on.
  ///
  /// Keys are binary names required to be on the user's path with execute
  /// permissions, the values are the error message to give when the doctor
  /// fails to validate them.
  static Map<String, String> requiredBinaries = <String, String>{
    'git': 'It is used for managing repositories.',
    gsutilBinary: 'It is used for accessing cloud storage. Provided by depot_tools, see \nhttps://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up for more information.',
  };

  bool validate() {
    bool success = true;

    for (final MapEntry<String, String> requiredBinary in requiredBinaries.entries) {
      stdio.printTrace('Verifying that binary ${requiredBinary.key} can run...');
      if (processManager.canRun(requiredBinary.key)) {
        stdio.printTrace('${requiredBinary.key} is present and executable.');
      } else {
        stdio.printError('There are problems with ${requiredBinary.key}.');
        stdio.printError(requiredBinary.value);
        success = false;
      }
      stdio.printTrace('');
    }

    return success;
  }
}
