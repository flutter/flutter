// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'package:ffi/ffi.dart';
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
    required VersionExtractor versionExtractor,
  })  : _operatingSystemUtils = operatingSystemUtils,
        _processLister = processLister,
        _versionExtractor = versionExtractor,
        super('Windows Version');

  final OperatingSystemUtils _operatingSystemUtils;
  final ProcessLister _processLister;
  final VersionExtractor _versionExtractor;

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
      final Map<String, String?> details = await _versionExtractor.getDetails();
      String? caption = details['Caption'];
      if (caption == null || caption.isEmpty) {
        final bool isWindows11 = int.parse(matches.elementAt(0).group(3)!) > 20000;
        if (isWindows11) {
          caption = 'Windows 11 or higher';
        } else {
          caption = 'Windows 10';
        }
      }
      statusInfo = '$caption, ${details['DisplayVersion']}, ${details['ReleaseId']}';

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

class VersionExtractor {
  VersionExtractor(this.processManager);

  final ProcessManager processManager;

  Future<Map<String, String?>> getDetails() async {
    final ProcessResult getProcessesResult = await processManager.run(<String>['wmic', 'os', 'get', 'Caption']);

    String? caption;
    if (getProcessesResult.exitCode == 0) {
      String? output = getProcessesResult.stdout as String?;
      if (output != null) {
        final List<String> parts = output.split('\n');
        if (parts.length >= 2) {
          caption = parts[1].replaceAll('Microsoft Windows', '').trim();
        }
      }
    }

    return {
      'Caption': caption,
      'ReleaseId': readRegistryValue(HKEY_LOCAL_MACHINE, CURRENT_VERSION_KEY, 'ReleaseId'),
      'DisplayVersion': readRegistryValue(HKEY_LOCAL_MACHINE, CURRENT_VERSION_KEY, 'DisplayVersion'),
    };
  }
}

typedef RegOpenKeyExNative = Int32 Function(
    IntPtr hKey,
    Pointer<Utf16> lpSubKey,
    Int32 ulOptions,
    Int32 samDesired,
    Pointer<IntPtr> phkResult);
typedef RegOpenKeyExDart = int Function(
    int hKey,
    Pointer<Utf16> lpSubKey,
    int ulOptions,
    int samDesired,
    Pointer<IntPtr> phkResult);
typedef RegQueryValueExNative = Int32 Function(
    IntPtr hKey,
    Pointer<Utf16> lpValueName,
    Pointer<Int32> lpReserved,
    Pointer<Int32> lpType,
    Pointer<Void> lpData,
    Pointer<Int32> lpcbData);
typedef RegQueryValueExDart = int Function(
    int hKey,
    Pointer<Utf16> lpValueName,
    Pointer<Int32> lpReserved,
    Pointer<Int32> lpType,
    Pointer<Void> lpData,
    Pointer<Int32> lpcbData);

typedef RegCloseKeyNative = Int32 Function(IntPtr hKey);
typedef RegCloseKeyDart = int Function(int hKey);

base class KEY_VALUE_BASIC_INFORMATION extends Struct {
  @Uint32()
  external int TitleIndex;
  @Uint32()
  external int Type;
  @Uint32()
  external int NameLength;
  @Uint32()
  external int DataLength;
}

const int HKEY_LOCAL_MACHINE = 0x80000002;
const int KEY_READ = 0x20019;
const int REG_SZ = 1;
const int REG_DWORD = 4;
const String CURRENT_VERSION_KEY = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion';

String? readRegistryValue(int hKey, String subKey, String valueName) {
  final advapi32 = DynamicLibrary.open('advapi32.dll');
  final RegOpenKeyExDart RegOpenKeyEx = advapi32.lookupFunction<RegOpenKeyExNative, RegOpenKeyExDart>('RegOpenKeyExW');
  final RegQueryValueExDart RegQueryValueEx = advapi32.lookupFunction<RegQueryValueExNative, RegQueryValueExDart>('RegQueryValueExW');
  final RegCloseKeyDart RegCloseKey = advapi32.lookupFunction<RegCloseKeyNative, RegCloseKeyDart>('RegCloseKey');

  final Pointer<Utf16> subKeyPtr = subKey.toNativeUtf16();
  final Pointer<Utf16> valueNamePtr = valueName.toNativeUtf16();
  final Pointer<IntPtr> hSubKeyPtr = calloc<IntPtr>();

  final openResult = RegOpenKeyEx(HKEY_LOCAL_MACHINE, subKeyPtr, 0, KEY_READ, hSubKeyPtr);
  if (openResult != 0) {
    calloc.free(hSubKeyPtr);
    return null;
  }

  final hSubKey = hSubKeyPtr.value;

  final Pointer<Int32> dataSizePtr = calloc<Int32>();
  final Pointer<Int32> typePtr = calloc<Int32>();
  RegQueryValueEx(hSubKey, valueNamePtr, nullptr, typePtr, nullptr, dataSizePtr);
  final dataSize = dataSizePtr.value;

  final Pointer<Uint8> dataPtr = calloc<Uint8>(dataSize);
  RegQueryValueEx(hSubKey, valueNamePtr, nullptr, typePtr, dataPtr.cast(), dataSizePtr);

  String? result = null;
  if (typePtr.value == REG_SZ) {
    result = dataPtr.cast<Utf16>().toDartString(length: dataSize ~/ 2);
  } else if (typePtr.value == REG_DWORD) {
    result = dataPtr.cast<Uint32>().value.toString();
  }

  RegCloseKey(hSubKey);
  calloc.free(subKeyPtr);
  calloc.free(valueNamePtr);
  calloc.free(hSubKeyPtr);
  calloc.free(dataSizePtr);
  calloc.free(typePtr);
  calloc.free(dataPtr);

  return result;
}