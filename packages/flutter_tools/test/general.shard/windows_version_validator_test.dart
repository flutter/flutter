// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/windows_version_validator.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

/// Fake [_WindowsUtils] to use for testing
class FakeValidOperatingSystemUtils extends Fake
    implements OperatingSystemUtils {
  FakeValidOperatingSystemUtils(
      [this.name = 'Microsoft Windows [Version 11.0.22621.963]']);

  @override
  final String name;
}

class FakeProcessLister extends Fake implements ProcessLister {
  FakeProcessLister({required this.result, this.exitCode = 0});
  final String result;
  final int exitCode;

  @override
  Future<ProcessResult> getProcessesWithPath() async {
    return ProcessResult(0, exitCode, result, null);
  }
}

FakeProcessLister ofdRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Topaz OFD\Warsaw\core.exe"');
}

FakeProcessLister ofdNotRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Google\Chrome\Application\chrome.exe');
}

FakeProcessLister failure() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Google\Chrome\Application\chrome.exe', exitCode: 10);
}

/// The expected validation result object for
/// a passing windows version test
const ValidationResult validWindows10ValidationResult = ValidationResult(
  ValidationType.success,
  <ValidationMessage>[],
  statusInfo: 'Installed version of Windows is version 10 or higher',
);

/// The expected validation result object for
/// a passing windows version test
const ValidationResult invalidWindowsValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Unable to confirm if installed Windows version is 10 or greater',
);

const ValidationResult ofdFoundRunning = ValidationResult(
  ValidationType.partial,
  <ValidationMessage>[
    ValidationMessage.hint(
      'The Topaz OFD Security Module was detected on your machine. '
      'You may need to disable it to build Flutter applications.',
    ),
  ],
  statusInfo: 'Problem detected with Windows installation',
);

const ValidationResult getProcessFailed = ValidationResult(
  ValidationType.partial,
  <ValidationMessage>[
    ValidationMessage.hint('Get-Process failed to complete'),
  ],
  statusInfo: 'Problem detected with Windows installation',
);

void main() {
  testWithoutContext('Successfully running windows version check on windows 10',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(),
            processLister: ofdNotRunning());

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows10ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows10ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext(
      'Successfully running windows version check on windows 10 for BR',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(
                'Microsoft Windows [versão 10.0.22621.1105]'),
            processLister: ofdNotRunning());

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows10ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows10ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Identifying a windows version before 10', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(
                'Microsoft Windows [Version 8.0.22621.1105]'),
            processLister: ofdNotRunning());

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, invalidWindowsValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
  });

  testWithoutContext('Unit testing on a regex pattern validator', () async {
    const String testStr = r'''
OS Version:                10.0.19044 N/A Build 19044
OSz Version:                10.0.19044 N/A Build 19044
OxS Version:                10.0.19044 N/A Build 19044
OS Version:                10.19044 N/A Build 19044
OS Version:                10.x.19044 N/A Build 19044
OS Version:                10.0.19044 N/A Build 19044
OS Version:                .0.19044 N/A Build 19044
OS 版本:          10.0.22621 暂缺 Build 22621
''';

    final RegExp regex = RegExp(
      kWindowsOSVersionSemVerPattern,
      multiLine: true,
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(testStr);

    expect(matches.length, 5,
        reason: 'There should be only 5 matches for the pattern provided');
  });

  testWithoutContext('Successfully checks for Topaz OFD when it is running', () async {
    final WindowsVersionValidator validator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(),
            processLister: ofdRunning());
    final ValidationResult result = await validator.validate();
    expect(result.type, ofdFoundRunning.type, reason: 'The ValidationResult type should be the same (partial)');
    expect(result.statusInfo, ofdFoundRunning.statusInfo, reason: 'The ValidationResult statusInfo should be the same');
    expect(result.messages.length, 1, reason: 'The ValidationResult should have precisely 1 message');
    expect(result.messages[0].message, ofdFoundRunning.messages[0].message, reason: 'The ValidationMessage message should be the same');
  });

  testWithoutContext('Reports failure of Get-Process', () async {
    final WindowsVersionValidator validator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(),
            processLister: failure());
    final ValidationResult result = await validator.validate();
    expect(result.type, getProcessFailed.type, reason: 'The ValidationResult type should be the same (partial)');
    expect(result.statusInfo, getProcessFailed.statusInfo, reason: 'The ValidationResult statusInfo should be the same');
    expect(result.messages.length, 1, reason: 'The ValidationResult should have precisely 1 message');
    expect(result.messages[0].message, getProcessFailed.messages[0].message, reason: 'The ValidationMessage message should be the same');
  });
}
