// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Get general Windows system information

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

bool testFlag(int value, int attribute) => value & attribute == attribute;

/// Test for a minimum version of Windows.
///
/// Per:
/// https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversionexw,
/// applications not manifested for Windows 8.1 or Windows 10 will return the
/// Windows 8 OS version value (6.2).
bool isWindowsVersionAtLeast(int majorVersion, int minorVersion) {
  final versionInfo = calloc<OSVERSIONINFO>();
  versionInfo.ref.dwOSVersionInfoSize = sizeOf<OSVERSIONINFO>();

  try {
    final result = GetVersionEx(versionInfo);

    if (result != 0) {
      if (versionInfo.ref.dwMajorVersion >= majorVersion) {
        if (versionInfo.ref.dwMinorVersion >= minorVersion) {
          return true;
        }
      }
      return false;
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(versionInfo);
  }
}

/// Test if running Windows is at least Windows XP.
bool isWindowsXPOrGreater() => isWindowsVersionAtLeast(5, 1);

/// Test if running Windows is at least Windows Vista.
bool isWindowsVistaOrGreater() => isWindowsVersionAtLeast(6, 0);

/// Test if running Windows is at least Windows 7.
bool isWindows7OrGreater() => isWindowsVersionAtLeast(6, 1);

/// Test if running Windows is at least Windows 8.
bool isWindows8OrGreater() => isWindowsVersionAtLeast(6, 2);

/// Return a value representing the physically installed memory in the computer.
/// This may not be the same as available memory.
int getSystemMemoryInMegabytes() {
  final memory = calloc<ULONGLONG>();

  try {
    final result = GetPhysicallyInstalledSystemMemory(memory);
    if (result != 0) {
      return memory.value ~/ 1024;
    } else {
      final error = GetLastError();
      throw WindowsException(HRESULT_FROM_WIN32(error));
    }
  } finally {
    free(memory);
  }
}

/// Get the computer's fully-qualified DNS name, where available.
String getComputerName() {
  final nameLength = calloc<DWORD>();
  String name;

  GetComputerNameEx(
      COMPUTER_NAME_FORMAT.ComputerNameDnsFullyQualified, nullptr, nameLength);

  final namePtr = wsalloc(nameLength.value);

  try {
    final result = GetComputerNameEx(
        COMPUTER_NAME_FORMAT.ComputerNameDnsFullyQualified,
        namePtr,
        nameLength);

    if (result != 0) {
      name = namePtr.toDartString();
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(namePtr);
    free(nameLength);
  }
  return name;
}

/// Retrieve a value from the registry.
Object getRegistryValue(int key, String subKey, String valueName) {
  late Object dataValue;

  final subKeyPtr = TEXT(subKey);
  final valueNamePtr = TEXT(valueName);
  final openKeyPtr = calloc<HANDLE>();
  final dataType = calloc<DWORD>();

  // 256 bytes is more than enough, and Windows will throw ERROR_MORE_DATA if
  // not, so there won't be an overrun.
  final data = calloc<BYTE>(256);
  final dataSize = calloc<DWORD>()..value = 256;

  try {
    var result = RegOpenKeyEx(key, subKeyPtr, 0, KEY_READ, openKeyPtr);
    if (result == ERROR_SUCCESS) {
      result = RegQueryValueEx(
          openKeyPtr.value, valueNamePtr, nullptr, dataType, data, dataSize);

      if (result == ERROR_SUCCESS) {
        if (dataType.value == REG_DWORD) {
          dataValue = data.value;
        } else if (dataType.value == REG_SZ) {
          dataValue = data.cast<Utf16>().toDartString();
        } else {
          // other data types are available, but this is a sample
        }
      } else {
        throw WindowsException(HRESULT_FROM_WIN32(result));
      }
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(result));
    }
  } finally {
    free(subKeyPtr);
    free(valueNamePtr);
    free(openKeyPtr);
    free(data);
    free(dataSize);
  }
  RegCloseKey(openKeyPtr.value);

  return dataValue;
}

/// Print system power status information.
///
/// Uses the GetSystemPowerStatus API call to get information about the battery.
/// More information on the reported values can be found in the Windows API
/// documentation, here:
/// https://docs.microsoft.com/en-us/windows/win32/api/winbase/ns-winbase-system_power_status
void printPowerInfo() {
  final powerStatus = calloc<SYSTEM_POWER_STATUS>();

  try {
    final result = GetSystemPowerStatus(powerStatus);
    if (result != 0) {
      print('Power status from GetSystemPowerStatus():');

      if (powerStatus.ref.ACLineStatus == 0) {
        print(' - Disconnected from AC power.');
      } else if (powerStatus.ref.ACLineStatus == 1) {
        print(' - Connected to AC power.');
      } else {
        print(' - AC power status unknown.');
      }

      if (testFlag(powerStatus.ref.BatteryFlag, 128)) {
        print(' - No battery installed.');
      } else {
        if (powerStatus.ref.BatteryLifePercent == 255) {
          print(' - Battery status unknown.');
        } else {
          print(' - ${powerStatus.ref.BatteryLifePercent}% '
              'percent battery remaining.');
        }

        if (powerStatus.ref.BatteryLifeTime != 0xFFFFFFFF) {
          print(' - ${powerStatus.ref.BatteryLifeTime / 60} minutes of power '
              'estimated to remain.');
        }
        // New in Windows 10, but should report 0 on older systems
        if (powerStatus.ref.SystemStatusFlag == 1) {
          print(' - Battery saver is on. Save energy where possible.');
        }
      }
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(powerStatus);
  }
}

/// Print battery status information.
///
/// This uses a different, slightly lower-level API to [printPowerInfo] to
/// report more detailed system battery status from the power management
/// library.
void printBatteryStatusInfo() {
  final batteryStatus = calloc<SYSTEM_BATTERY_STATE>();

  try {
    final result = CallNtPowerInformation(
        POWER_INFORMATION_LEVEL.SystemBatteryState,
        nullptr,
        0,
        batteryStatus,
        sizeOf<SYSTEM_BATTERY_STATE>());

    if (result == STATUS_SUCCESS) {
      print('Power status from CallNtPowerInformation():');

      print(batteryStatus.ref.AcOnLine == TRUE
          ? ' - System is currently operating on external power.'
          : ' - System is not currently operating on external power.');

      print(batteryStatus.ref.BatteryPresent == TRUE
          ? ' - At least one battery is present in the system.'
          : ' - No batteries detected in the system.');

      if (batteryStatus.ref.BatteryPresent == TRUE) {
        print(batteryStatus.ref.Charging == TRUE
            ? ' - Battery is charging.'
            : ' - Battery is not charging.');

        print(batteryStatus.ref.Discharging == TRUE
            ? ' - Battery is discharging.'
            : ' - Battery is not discharging.');

        print(' - Theoretical max capacity of the battery is '
            '${batteryStatus.ref.MaxCapacity}.');

        print(' - Estimated remaining capacity of the battery is '
            '${batteryStatus.ref.RemainingCapacity}.');

        print(' - Charge/discharge rate of the battery is '
            '${batteryStatus.ref.EstimatedTime.abs()} mW.');

        print(' - Estimated time remaining on the battery is '
            '${batteryStatus.ref.EstimatedTime} seconds.');

        print(' - Manufacturer suggested low battery alert is at '
            '${batteryStatus.ref.DefaultAlert1} mWh.');
        print(' - Manufacturer suggested warning battery alert is at '
            '${batteryStatus.ref.DefaultAlert2} mWh.');
      }
    }
  } finally {
    free(batteryStatus);
  }
}

String getUserName() {
  const usernameLength = 256;
  final pcbBuffer = calloc<DWORD>()..value = usernameLength + 1;
  final lpBuffer = wsalloc(usernameLength + 1);

  try {
    final result = GetUserName(lpBuffer, pcbBuffer);
    if (result != 0) {
      return lpBuffer.toDartString();
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(pcbBuffer);
    free(lpBuffer);
  }
}

void main() {
  print('This version of Windows supports the APIs in:');
  if (isWindowsXPOrGreater()) print(' - Windows XP');
  if (isWindowsVistaOrGreater()) print(' - Windows Vista');
  if (isWindows7OrGreater()) print(' - Windows 7');
  if (isWindows8OrGreater()) print(' - Windows 8');

  // For more recent versions of Windows, Microsoft strongly recommends that
  // developers avoid version testing because of app compat issues caused by
  // buggy version testing. Indeed, the API goes to some lengths to make it hard
  // to test versions. Yet version detection is the only reliable solution for
  // certain API calls, so the recommendation is noted but not followed.
  final buildNumber = int.parse(getRegistryValue(
      HKEY_LOCAL_MACHINE,
      'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\',
      'CurrentBuildNumber') as String);
  if (buildNumber >= 10240) print(' - Windows 10');
  if (buildNumber >= 22000) print(' - Windows 11');

  print('\nWindows build number is: $buildNumber');

  print('\nRAM physically installed on this computer: '
      '${getSystemMemoryInMegabytes()}MB');

  print('\nActive processors on the system: '
      '${GetActiveProcessorCount(ALL_PROCESSOR_GROUPS)}\n');

  print('User name is: ${getUserName()}');
  print('Computer name is: ${getComputerName()}\n');

  printPowerInfo();

  print('');

  printBatteryStatusInfo();
}
