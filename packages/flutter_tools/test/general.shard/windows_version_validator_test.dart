// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/windows_version_validator.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

/// Example output from `systeminfo` from a Windows 10 host
const String validWindows10StdOut = r'''
Host Name:                 XXXXXXXXXXXX
OS Name:                   Microsoft Windows 10 Enterprise
OS Version:                10.0.19044 N/A Build 19044
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Member Workstation
OS Build Type:             Multiprocessor Free
Registered Owner:          N/A
Registered Organization:   N/A
Product ID:                XXXXXXXXXXXX
Original Install Date:     8/4/2022, 2:51:28 PM
System Boot Time:          8/10/2022, 1:03:10 PM
System Manufacturer:       Google
System Model:              Google Compute Engine
System Type:               x64-based PC
Processor(s):              1 Processor(s) Installed.
                           [01]: AMD64 Family 23 Model 49 Stepping 0 AuthenticAMD ~2250 Mhz
BIOS Version:              Google Google, 6/29/2022
Windows Directory:         C:\\Windows
System Directory:          C:\\Windows\\system32
Boot Device:               \\Device\\HarddiskVolume2
System Locale:             en-us;English (United States)
Input Locale:              en-us;English (United States)
Time Zone:                 (UTC-08:00) Pacific Time (US & Canada)
Total Physical Memory:     32,764 MB
Available Physical Memory: 17,852 MB
Virtual Memory: Max Size:  33,788 MB
Virtual Memory: Available: 18,063 MB
Virtual Memory: In Use:    15,725 MB
Page File Location(s):     C:\\pagefile.sys
Domain:                    ad.corp.google.com
Logon Server:              \\CBF-DC-8
Hotfix(s):                 7 Hotfix(s) Installed.
                           [01]: KB5013624
                           [02]: KB5003791
                           [03]: KB5012170
                           [04]: KB5016616
                           [05]: KB5014032
                           [06]: KB5014671
                           [07]: KB5015895
Hyper-V Requirements:      A hypervisor has been detected. Features required for Hyper-V will not be displayed.
''';

/// Example output from `systeminfo` from version != 10
const String invalidWindowsStdOut = r'''
Host Name:                 XXXXXXXXXXXX
OS Name:                   Microsoft Windows 8.1 Enterprise
OS Version:                6.3.9600 Build 9600
OS Manufacturer:           Microsoft Corporation
OS Configuration:          Member Workstation
OS Build Type:             Multiprocessor Free
Registered Owner:          N/A
Registered Organization:   N/A
Product ID:                XXXXXXXXXXXX
Original Install Date:     8/4/2022, 2:51:28 PM
System Boot Time:          8/10/2022, 1:03:10 PM
System Manufacturer:       Google
System Model:              Google Compute Engine
System Type:               x64-based PC
Processor(s):              1 Processor(s) Installed.
                           [01]: AMD64 Family 23 Model 49 Stepping 0 AuthenticAMD ~2250 Mhz
BIOS Version:              Google Google, 6/29/2022
Windows Directory:         C:\\Windows
System Directory:          C:\\Windows\\system32
Boot Device:               \\Device\\HarddiskVolume2
System Locale:             en-us;English (United States)
Input Locale:              en-us;English (United States)
Time Zone:                 (UTC-08:00) Pacific Time (US & Canada)
Total Physical Memory:     32,764 MB
Available Physical Memory: 17,852 MB
Virtual Memory: Max Size:  33,788 MB
Virtual Memory: Available: 18,063 MB
Virtual Memory: In Use:    15,725 MB
Page File Location(s):     C:\\pagefile.sys
Domain:                    ad.corp.google.com
Logon Server:              \\CBF-DC-8
Hotfix(s):                 7 Hotfix(s) Installed.
                           [01]: KB5013624
                           [02]: KB5003791
                           [03]: KB5012170
                           [04]: KB5016616
                           [05]: KB5014032
                           [06]: KB5014671
                           [07]: KB5015895
Hyper-V Requirements:      A hypervisor has been detected. Features required for Hyper-V will not be displayed.
''';

/// The expected validation result object for
/// a passing windows version test
const ValidationResult validWindows10ValidationResult = ValidationResult(
  ValidationType.installed,
  <ValidationMessage>[],
  statusInfo: 'Installed version of Windows is version 10 or higher',
);

/// The expected validation result object for
/// a failing exit code (!= 0)
const ValidationResult failedValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
);

/// The expected validation result object for
/// a passing windows version test
const ValidationResult invalidWindowsValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Unable to confirm if installed Windows version is 10 or greater',
);

/// Expected return from a nonzero exitcode when
/// running systeminfo
const ValidationResult invalidExitCodeValidationResult = ValidationResult(
  ValidationType.missing,
  <ValidationMessage>[],
  statusInfo: 'Exit status from running `systeminfo` was unsuccessful',
);

void main() {
  testWithoutContext('Successfully running windows version check on windows 10',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: validWindows10StdOut,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows10ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows10ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Failing to invoke the `systeminfo` command', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: validWindows10StdOut,
            exitCode: 1,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, failedValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, failedValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Identifying a windows version before 10', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(
            command: <String>['systeminfo'],
            stdout: invalidWindowsStdOut,
          ),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, invalidWindowsValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, invalidWindowsValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext(
      'Running into an nonzero exit code from systeminfo command', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
      processManager: FakeProcessManager.list(
        <FakeCommand>[
          const FakeCommand(command: <String>['systeminfo'], exitCode: 1),
        ],
      ),
    );

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, invalidExitCodeValidationResult.type,
        reason: 'The ValidationResult type should be the same (missing)');
    expect(result.statusInfo, invalidExitCodeValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Unit testing on a regex pattern validator', () async {
    const String testStr = r'''
OS Version:                10.0.19044 N/A Build 19044
OSz Version:                10.0.19044 N/A Build 19044
OS 6Version:                10.0.19044 N/A Build 19044
OxS Version:                10.0.19044 N/A Build 19044
OS Version:                10.19044 N/A Build 19044
OS Version:                10.x.19044 N/A Build 19044
OS Version:                10.0.19044 N/A Build 19044
OS Version:                .0.19044 N/A Build 19044
''';

    final RegExp regex =
        RegExp(kWindowsOSVersionSemVerPattern, multiLine: true);
    final Iterable<RegExpMatch> matches = regex.allMatches(testStr);

    expect(matches.length, 2,
        reason: 'There should be only two matches for the pattern provided');
  });
}
