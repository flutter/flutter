// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Prints out information about one of a number of given Windows Subsystem for
// Linux distributions.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Represents a configuration of an installed WSL distribution.
class DistributionConfiguration {
  final String name;
  final int wslVersion;
  final int userID;
  final int flags;
  final List<String> environmentVariables;

  const DistributionConfiguration(this.name, this.wslVersion, this.userID,
      this.flags, this.environmentVariables);
}

/// Check whether a distribution exists
bool isDistributionRegistered(String distributionName) {
  final pDistributionName = distributionName.toNativeUtf16();
  try {
    return WslIsDistributionRegistered(pDistributionName) == TRUE;
  } finally {
    free(pDistributionName);
  }
}

/// Get information about a specified WSL distribution.
DistributionConfiguration getDistributionConfiguration(
    String distributionName) {
  final pDistributionName = distributionName.toNativeUtf16();
  final distributionVersion = calloc<ULONG>();
  final defaultUID = calloc<ULONG>();
  final wslDistributionFlags = calloc<ULONG>();
  final defaultEnvironmentVariables = calloc<Pointer<PSTR>>();
  final defaultEnvironmentVariableCount = calloc<ULONG>();

  try {
    final hr = WslGetDistributionConfiguration(
        TEXT(distributionName),
        distributionVersion,
        defaultUID,
        wslDistributionFlags,
        defaultEnvironmentVariables,
        defaultEnvironmentVariableCount);

    if (FAILED(hr)) throw WindowsException(hr);

    final vars = <String>[];
    for (var idx = 0; idx < defaultEnvironmentVariableCount.value; idx++) {
      vars.add(defaultEnvironmentVariables.value[idx].toDartString());
    }
    return DistributionConfiguration(
        distributionName,
        distributionVersion.value,
        defaultUID.value,
        wslDistributionFlags.value,
        vars);
  } finally {
    free(pDistributionName);
    free(distributionVersion);
    free(defaultUID);
    free(wslDistributionFlags);
    free(defaultEnvironmentVariables);
    free(defaultEnvironmentVariableCount);
  }
}

/// Run a test Linux shell command on a given distribution.
int runCommand(String distributionName, String command) {
  final pDistributionName = distributionName.toNativeUtf16();
  final pCommand = command.toNativeUtf16();
  final processHandle = calloc<HANDLE>();
  final exitCode = calloc<DWORD>();
  try {
    final hr = WslLaunch(
        pDistributionName,
        pCommand,
        FALSE,
        GetStdHandle(STD_INPUT_HANDLE), // redirect as appropriate
        GetStdHandle(STD_OUTPUT_HANDLE), // redirect as appropriate
        GetStdHandle(STD_ERROR_HANDLE), // redirect as appropriate
        processHandle);
    if (FAILED(hr)) throw WindowsException(hr);
    WaitForSingleObject(processHandle.value, INFINITE);
    GetExitCodeProcess(processHandle.value, exitCode);
    return exitCode.value;
  } finally {
    free(pDistributionName);
    free(pCommand);
    free(processHandle);
    free(exitCode);
  }
}

void main() {
  print('WSL distributions registered:');
  for (final distributionName in ['Ubuntu', 'Debian', 'kali-linux']) {
    if (isDistributionRegistered(distributionName)) {
      final config = getDistributionConfiguration(distributionName);
      print('Distribution: $distributionName');
      print('Version: ${config.wslVersion}');
      final driveMounting = config.flags &
              WSL_DISTRIBUTION_FLAGS
                  .WSL_DISTRIBUTION_FLAGS_ENABLE_DRIVE_MOUNTING ==
          WSL_DISTRIBUTION_FLAGS.WSL_DISTRIBUTION_FLAGS_ENABLE_DRIVE_MOUNTING;
      print('Windows drives automatically mounted: $driveMounting');
      print('Environment variables: ');
      config.environmentVariables.forEach(print);

      print('Test command (uname -a) reports:');
      final exitCode = runCommand(distributionName, 'uname -a');
      print('Command returned exit code: $exitCode');
    }
  }
}
