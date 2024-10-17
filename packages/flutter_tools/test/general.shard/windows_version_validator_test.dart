// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/windows_version_validator.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/fake_process_manager.dart';

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
const ValidationResult validWindows11ValidationResult = ValidationResult(
  ValidationType.success,
  <ValidationMessage>[],
  statusInfo: '11 Pro 64-bit, 23H2, 2009',
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

class FakeVersionExtractor extends Fake implements VersionExtractor {
  FakeVersionExtractor({required this.mockData});
  FakeVersionExtractor.win11ProX64() : this(mockData: <String, String>{
    'Caption': '11 Pro 64-bit',
    'ReleaseId': '2009',
    'DisplayVersion': '23H2'});

  final Map<String, String> mockData;

  @override
  Future<Map<String, String>> getDetails() async {
    return mockData;
  }
}

void main() {
  testWithoutContext('Successfully running windows version check on windows 10',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(),
            processLister: ofdNotRunning(),
            versionExtractor: FakeVersionExtractor.win11ProX64());

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows11ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows11ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext(
      'Successfully running windows version check on windows 10 for BR',
      () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(
                'Microsoft Windows [versão 10.0.22621.1105]'),
            processLister: ofdNotRunning(),
            versionExtractor: FakeVersionExtractor.win11ProX64());

    final ValidationResult result = await windowsVersionValidator.validate();

    expect(result.type, validWindows11ValidationResult.type,
        reason: 'The ValidationResult type should be the same (installed)');
    expect(result.statusInfo, validWindows11ValidationResult.statusInfo,
        reason: 'The ValidationResult statusInfo messages should be the same');
  });

  testWithoutContext('Identifying a windows version before 10', () async {
    final WindowsVersionValidator windowsVersionValidator =
        WindowsVersionValidator(
            operatingSystemUtils: FakeValidOperatingSystemUtils(
                'Microsoft Windows [Version 8.0.22621.1105]'),
            processLister: ofdNotRunning(),
            versionExtractor: FakeVersionExtractor.win11ProX64());

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
            processLister: ofdRunning(),
            versionExtractor: FakeVersionExtractor.win11ProX64());
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
            processLister: failure(),
            versionExtractor: FakeVersionExtractor(mockData: <String, String>{}));
    final ValidationResult result = await validator.validate();
    expect(result.type, getProcessFailed.type, reason: 'The ValidationResult type should be the same (partial)');
    expect(result.statusInfo, getProcessFailed.statusInfo, reason: 'The ValidationResult statusInfo should be the same');
    expect(result.messages.length, 1, reason: 'The ValidationResult should have precisely 1 message');
    expect(result.messages[0].message, getProcessFailed.messages[0].message, reason: 'The ValidationMessage message should be the same');
  });

  testWithoutContext('Parses Caption, OSArchitecture, releaseId, and CurrentVersion from the OS', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(
      <FakeCommand>[
        const FakeCommand(
            command: <Pattern>['wmic', 'os', 'get', 'Caption,OSArchitecture'],
            stdout: '''
Caption                          OSArchitecture
Microsoft Windows 10 Enterprise  64-bit
'''),
        const FakeCommand(command: <Pattern>[
          'reg',
          'query',
          r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion',
          '/t',
          'REG_SZ',
        ], stdout: r'''
    SystemRoot    REG_SZ    C:\Windows
    BuildBranch    REG_SZ    vb_release
    BuildGUID    REG_SZ    ffffffff-ffff-ffff-ffff-ffffffffffff
    BuildLab    REG_SZ    19041.vb_release.191206-1406
    BuildLabEx    REG_SZ    19041.1.amd64fre.vb_release.191206-1406
    CompositionEditionID    REG_SZ    Enterprise
    CurrentBuild    REG_SZ    19045
    CurrentBuildNumber    REG_SZ    19045
    CurrentType    REG_SZ    Multiprocessor Free
    CurrentVersion    REG_SZ    6.3
    EditionID    REG_SZ    Enterprise
    EditionSubManufacturer    REG_SZ
    EditionSubstring    REG_SZ
    EditionSubVersion    REG_SZ
    InstallationType    REG_SZ    Client
    ProductName    REG_SZ    Windows 10 Enterprise
    ReleaseId    REG_SZ    2009
    SoftwareType    REG_SZ    System
    PathName    REG_SZ    C:\Windows
    ProductId    REG_SZ    00329-00000-00003-AA153
    DisplayVersion    REG_SZ    22H2
    WinREVersion    REG_SZ    10.0.19041.3920

End of search: 22 match(es) found.
'''),
      ],
    );
    final WindowsVersionValidator validator = WindowsVersionValidator(
      operatingSystemUtils: FakeValidOperatingSystemUtils(),
      processLister: ofdNotRunning(),
      versionExtractor: VersionExtractor(processManager),
    );
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.success);
    expect(result.statusInfo, '10 Enterprise 64-bit, 22H2, 2009');
  });
}
