// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

void main() {
  testWithoutContext('Successfully running windows version check on windows 10',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils());

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
                'Microsoft Windows [versão 10.0.22621.1105]'));

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
                'Microsoft Windows [Version 8.0.22621.1105]'));

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
}
