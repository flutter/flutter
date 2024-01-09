// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../doctor_validator.dart';

const String kCoreProcessPattern = r'Topaz OFD\\Warsaw\\core\.exe';

class TopazOfdValidator extends DoctorValidator {
  const TopazOfdValidator({required this.processLister}) : super('Topaz OFD');

  final ProcessLister processLister;

  @override
  Future<ValidationResult> validate() async {
    final ProcessResult processResult = await processLister.getProcessesWithPath('core');
    final int exitCode = processResult.exitCode;
    if (exitCode != 0) {
      return ValidationResult(
        ValidationType.missing,
        <ValidationMessage>[
          ValidationMessage.hint('Check for Topaz OFD did not complete normally. Returned exit code $exitCode'),
        ],
        statusInfo: 'Get-Process failed to complete',
      );
    }
    final String tasks = processResult.stdout as String;
    final RegExp pattern = RegExp(kCoreProcessPattern, multiLine: true, caseSensitive: false);
    final bool matches = pattern.hasMatch(tasks);
    if (matches) {
      return const ValidationResult(
        ValidationType.missing,
        <ValidationMessage>[
          ValidationMessage.hint('The Topaz OFD Security Module process has been found running. If you are unable to build, you will need to disable it.'),
        ],
        statusInfo: 'Topaz OFD may be running');
    } else {
      return const ValidationResult(
        ValidationType.success,
        <ValidationMessage>[],
      );
    }
  }
}

class ProcessLister {
  const ProcessLister();

  Future<ProcessResult> getProcessesWithPath(String? filter) async {
    final String argument = filter != null ? 'Get-Process $filter | Format-List Path' : 'Get-Process | Format-List Path';
    const ProcessManager processManager = LocalProcessManager();
    return processManager.run(<String>['powershell', '-command', argument]);
  }
}
