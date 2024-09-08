// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/io.dart';
import '../base/os.dart';
import '../doctor_validator.dart';

/// Flutter only supports development on Windows host machines version 10 and greater.
const List<String> kUnsupportedVersions = <String>[
  '6',
  '7',
  '8',
];

const kKnownWindowsVersions = <String, String> {
  // from: https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information
  '22631': 'Windows 11 - 23H2',
  '22621': 'Windows 11 - 22H2',
  '22000': 'Windows 11 - 21H2',
  // from: https://learn.microsoft.com/en-us/windows/release-health/release-information
  '19045': 'Windows 10 - 22H2',
  '19044': 'Windows 10 - 21H2/LTSC',
  '19043': 'Windows 10 - 21H1',
  '19042': 'Windows 10 - 20H2',
  '19041': 'Windows 10 - 2004',
  '18363': 'Windows 10 - 1909',
  '18362': 'Windows 10 - 1903',
  '17763': 'Windows 10 - 1809/LTSC',
  '17134': 'Windows 10 - 1803',
  '16299': 'Windows 10 - 1709',
  '15063': 'Windows 10 - 1703',
  '14393': 'Windows 10 - 1607/LTSB',
  '10586': 'Windows 10 - 1511',
  '10240': 'Windows 10 - 1507/LTSB',
};

/// Regex pattern for identifying line from systeminfo stdout with windows version
/// (ie. 10.5.4123)
const String kWindowsOSVersionSemVerPattern = r'([0-9]+)\.([0-9]+)\.([0-9]+)\.?([0-9\.]+)?';

/// Regex pattern for identifying a running instance of the Topaz OFD process.
/// This is a known process that interferes with the build toolchain.
/// See https://github.com/flutter/flutter/issues/121366
const String kCoreProcessPattern = r'Topaz\s+OFD\\Warsaw\\core\.exe';

/// Validator for supported Windows host machine operating system version.
class WindowsVersionValidator extends DoctorValidator {
  const WindowsVersionValidator({
    required OperatingSystemUtils operatingSystemUtils,
    required ProcessLister processLister,
  })  : _operatingSystemUtils = operatingSystemUtils,
        _processLister = processLister,
        super('Windows Version');

  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessLister _processLister;

  Future<ValidationResult> _topazScan() async {
      final ProcessResult getProcessesResult = await _processLister.getProcessesWithPath();
      if (getProcessesResult.exitCode != 0) {
        return const ValidationResult(ValidationType.missing, <ValidationMessage>[ValidationMessage.hint('Get-Process failed to complete')]);
      }
      final RegExp topazRegex = RegExp(kCoreProcessPattern, caseSensitive: false,  multiLine: true);
      final String processes = getProcessesResult.stdout as String;
      final bool topazFound = topazRegex.hasMatch(processes);
      if (topazFound) {
        return const ValidationResult(
          ValidationType.missing,
          <ValidationMessage>[
            ValidationMessage.hint(
              'The Topaz OFD Security Module was detected on your machine. '
              'You may need to disable it to build Flutter applications.',
            ),
          ],
        );
      }
      return const ValidationResult(ValidationType.success, <ValidationMessage>[]);
  }

  @override
  Future<ValidationResult> validate() async {
    final RegExp regex =
        RegExp(kWindowsOSVersionSemVerPattern, multiLine: true);
    final String commandResult = _operatingSystemUtils.name;
    final Iterable<RegExpMatch> matches = regex.allMatches(commandResult);

    // Use the string split method to extract the major version
    // and check against the [kUnsupportedVersions] list
    ValidationType windowsVersionStatus;
    final List<ValidationMessage> messages = <ValidationMessage>[];
    String statusInfo;
    if (matches.length == 1 &&
        !kUnsupportedVersions.contains(matches.elementAt(0).group(1))) {
      windowsVersionStatus = ValidationType.success;
      final String? knownVersion = kKnownWindowsVersions[matches.elementAt(0).group(3)];
      statusInfo = knownVersion ?? 'Installed version of Windows is version 10 or higher';

      // Check if the Topaz OFD security module is running, and warn the user if it is.
      // See https://github.com/flutter/flutter/issues/121366
      final List<ValidationResult> subResults = <ValidationResult>[
        await _topazScan(),
      ];
      for (final ValidationResult subResult in subResults) {
        if (subResult.type != ValidationType.success) {
          statusInfo = 'Problem detected with Windows installation';
          windowsVersionStatus = ValidationType.partial;
          messages.addAll(subResult.messages);
        }
      }
    } else {
      windowsVersionStatus = ValidationType.missing;
      statusInfo =
          'Unable to determine Windows version (command `ver` returned $commandResult)';
    }

    return ValidationResult(
      windowsVersionStatus,
      messages,
      statusInfo: statusInfo,
    );
  }
}

class ProcessLister {
  ProcessLister(this.processManager);

  final ProcessManager processManager;

  Future<ProcessResult> getProcessesWithPath() async {
    const String argument = 'Get-Process | Format-List Path';
    return processManager.run(<String>['powershell', '-command', argument]);
  }
}
