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

/// Regex pattern for identifying line from systeminfo stdout with windows version
/// (ie. 10.0.22631.4037)
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
    required WindowsVersionExtractor versionExtractor,
  })  : _operatingSystemUtils = operatingSystemUtils,
        _processLister = processLister,
        _versionExtractor = versionExtractor,
        super('Windows Version');

  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessLister _processLister;
  final WindowsVersionExtractor _versionExtractor;

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
      final WindowsVersionExtractionResult details = await _versionExtractor.getDetails();
      String? caption = details.caption;
      if (caption == null || caption.isEmpty) {
        final bool isWindows11 = int.parse(matches.elementAt(0).group(3)!) > 20000;
        if (isWindows11) {
          caption = 'Windows 11 or higher';
        } else {
          caption = 'Windows 10';
        }
      }
      statusInfo = '$caption, ${details.displayVersion}, ${details.releaseId}';

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

class WindowsVersionExtractor {
  WindowsVersionExtractor(this.processManager);

  final ProcessManager processManager;

  Future<WindowsVersionExtractionResult> getDetails() async {
    String? caption, releaseId, displayVersion;
    try {
      final ProcessResult captionResult = await processManager.run(
        <String>['wmic', 'os', 'get', 'Caption,OSArchitecture'],
      );

      if (captionResult.exitCode == 0) {
        final String? output = captionResult.stdout as String?;
        if (output != null) {
          final List<String> parts = output.split('\n');
          if (parts.length >= 2) {
            caption = parts[1].replaceAll('Microsoft Windows', '').replaceAll('  ', ' ').trim();
          }
        }
      }
    } on ProcessException {
      // Ignored, use default null value.
    }

    try {
      final ProcessResult osDetails = await processManager.run(
        <String>['reg', 'query', r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion', '/t', 'REG_SZ'],
      );

      if (osDetails.exitCode == 0) {
        final String? output = osDetails.stdout as String?;
        if (output != null) {
          final Map<String, String> data = Map<String, String>.fromEntries(
              output.split('\n').where((String line) => line.contains('REG_SZ')).map((String line) {
                final List<String> parts = line.split('REG_SZ');
                return MapEntry<String, String>(parts.first.trim(), parts.last.trim());
              }));
          releaseId = data['ReleaseId'];
          displayVersion = data['DisplayVersion'];
        }
      }
    } on ProcessException {
      // Ignored, use default null values.
    }

    return WindowsVersionExtractionResult(
      caption: caption,
      releaseId: releaseId,
      displayVersion: displayVersion,
    );
  }
}

final class WindowsVersionExtractionResult {
  WindowsVersionExtractionResult({
    required this.caption,
    required this.releaseId,
    required this.displayVersion,
  });

  factory WindowsVersionExtractionResult.empty() {
    return WindowsVersionExtractionResult(
      caption: null,
      releaseId: null,
      displayVersion: null,
    );
  }

  final String? caption;
  final String? releaseId;
  final String? displayVersion;
}
