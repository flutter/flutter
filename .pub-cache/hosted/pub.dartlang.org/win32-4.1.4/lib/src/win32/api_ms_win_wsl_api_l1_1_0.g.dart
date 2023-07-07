// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../guid.dart';
import '../structs.g.dart';
import '../variant.dart';

final _api_ms_win_wsl_api_l1_1_0 =
    DynamicLibrary.open('api-ms-win-wsl-api-l1-1-0.dll');

/// Modifies the behavior of a distribution registered with the Windows
/// Subsystem for Linux (WSL).
///
/// ```c
/// HRESULT WslConfigureDistribution(
///   _In_ PCWSTR distributionName,
///   _In_ ULONG defaultUID,
///   WSL_DISTRIBUTION_FLAGS wslDistributionFlags
/// );
/// ```
/// {@category wslapi}
int WslConfigureDistribution(Pointer<Utf16> distributionName, int defaultUID,
        int wslDistributionFlags) =>
    _WslConfigureDistribution(
        distributionName, defaultUID, wslDistributionFlags);

final _WslConfigureDistribution = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(Pointer<Utf16> distributionName, Uint32 defaultUID,
        Uint32 wslDistributionFlags),
    int Function(Pointer<Utf16> distributionName, int defaultUID,
        int wslDistributionFlags)>('WslConfigureDistribution');

/// Retrieves the current configuration of a distribution registered with
/// the Windows Subsystem for Linux (WSL).
///
/// ```c
/// HRESULT WslGetDistributionConfiguration(
///   _In_ PCWSTR distributionName,
///   _Out_ ULONG *distributionVersion,
///   _Out_ ULONG *defaultUID,
///   _Out_ WSL_DISTRIBUTION_FLAGS *wslDistributionFlags,
///   _Outptr_result_buffer_ PSTR **defaultEnvironmentVariables,
///   _Out_ ULONG *defaultEnvironmentVariableCount
/// );
/// ```
/// {@category wslapi}
int WslGetDistributionConfiguration(
        Pointer<Utf16> distributionName,
        Pointer<Uint32> distributionVersion,
        Pointer<Uint32> defaultUID,
        Pointer<Uint32> wslDistributionFlags,
        Pointer<Pointer<Pointer<Utf8>>> defaultEnvironmentVariables,
        Pointer<Uint32> defaultEnvironmentVariableCount) =>
    _WslGetDistributionConfiguration(
        distributionName,
        distributionVersion,
        defaultUID,
        wslDistributionFlags,
        defaultEnvironmentVariables,
        defaultEnvironmentVariableCount);

final _WslGetDistributionConfiguration =
    _api_ms_win_wsl_api_l1_1_0.lookupFunction<
            Int32 Function(
                Pointer<Utf16> distributionName,
                Pointer<Uint32> distributionVersion,
                Pointer<Uint32> defaultUID,
                Pointer<Uint32> wslDistributionFlags,
                Pointer<Pointer<Pointer<Utf8>>> defaultEnvironmentVariables,
                Pointer<Uint32> defaultEnvironmentVariableCount),
            int Function(
                Pointer<Utf16> distributionName,
                Pointer<Uint32> distributionVersion,
                Pointer<Uint32> defaultUID,
                Pointer<Uint32> wslDistributionFlags,
                Pointer<Pointer<Pointer<Utf8>>> defaultEnvironmentVariables,
                Pointer<Uint32> defaultEnvironmentVariableCount)>(
        'WslGetDistributionConfiguration');

/// Determines if a distribution is registered with the Windows Subsystem
/// for Linux (WSL).
///
/// ```c
/// BOOL WslIsDistributionRegistered(
///   _In_ PCWSTR distributionName
/// );
/// ```
/// {@category wslapi}
int WslIsDistributionRegistered(Pointer<Utf16> distributionName) =>
    _WslIsDistributionRegistered(distributionName);

final _WslIsDistributionRegistered = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(Pointer<Utf16> distributionName),
    int Function(
        Pointer<Utf16> distributionName)>('WslIsDistributionRegistered');

/// Launches a Windows Subsystem for Linux (WSL) process in the context of a
/// particular distribution.
///
/// ```c
/// HRESULT WslLaunch(
///   _In_ PCWSTR distributionName,
///   _In_opt_ PCWSTR command,
///   _In_ BOOL useCurrentWorkingDirectory,
///   _In_ HANDLE stdIn,
///   _In_ HANDLE stdOut,
///   _In_      HANDLE  stdErr,
///   _Out_     HANDLE  *process
/// );
/// ```
/// {@category wslapi}
int WslLaunch(
        Pointer<Utf16> distributionName,
        Pointer<Utf16> command,
        int useCurrentWorkingDirectory,
        int stdIn,
        int stdOut,
        int stdErr,
        Pointer<IntPtr> process) =>
    _WslLaunch(distributionName, command, useCurrentWorkingDirectory, stdIn,
        stdOut, stdErr, process);

final _WslLaunch = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(
        Pointer<Utf16> distributionName,
        Pointer<Utf16> command,
        Int32 useCurrentWorkingDirectory,
        IntPtr stdIn,
        IntPtr stdOut,
        IntPtr stdErr,
        Pointer<IntPtr> process),
    int Function(
        Pointer<Utf16> distributionName,
        Pointer<Utf16> command,
        int useCurrentWorkingDirectory,
        int stdIn,
        int stdOut,
        int stdErr,
        Pointer<IntPtr> process)>('WslLaunch');

/// Launches an interactive Windows Subsystem for Linux (WSL) process in the
/// context of a particular distribution.This differs from WslLaunch in that
/// the end user will be able to interact with the newly-created process.
///
/// ```c
/// HRESULT WslLaunchInteractive(
///   _In_ PCWSTR distributionName,
///   _In_opt_ command,
///   _In_ BOOL useCurrentWorkingDirectory,
///   _Out_ DWORD *exitCode
/// );
/// ```
/// {@category wslapi}
int WslLaunchInteractive(
        Pointer<Utf16> distributionName,
        Pointer<Utf16> command,
        int useCurrentWorkingDirectory,
        Pointer<Uint32> exitCode) =>
    _WslLaunchInteractive(
        distributionName, command, useCurrentWorkingDirectory, exitCode);

final _WslLaunchInteractive = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(Pointer<Utf16> distributionName, Pointer<Utf16> command,
        Int32 useCurrentWorkingDirectory, Pointer<Uint32> exitCode),
    int Function(
        Pointer<Utf16> distributionName,
        Pointer<Utf16> command,
        int useCurrentWorkingDirectory,
        Pointer<Uint32> exitCode)>('WslLaunchInteractive');

/// Registers a new distribution with the Windows Subsystem for Linux (WSL).
///
/// ```c
/// HRESULT WslRegisterDistribution(
///   _In_ PCWSTR distributionName,
///   _In_ PCWSTR tarGzFilename
/// );
/// ```
/// {@category wslapi}
int WslRegisterDistribution(
        Pointer<Utf16> distributionName, Pointer<Utf16> tarGzFilename) =>
    _WslRegisterDistribution(distributionName, tarGzFilename);

final _WslRegisterDistribution = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(
        Pointer<Utf16> distributionName, Pointer<Utf16> tarGzFilename),
    int Function(Pointer<Utf16> distributionName,
        Pointer<Utf16> tarGzFilename)>('WslRegisterDistribution');

/// Unregisters a distribution from the Windows Subsystem for Linux (WSL).
///
/// ```c
/// HRESULT WslUnregisterDistribution(
///   _In_ PCWSTR distributionName
/// );
/// ```
/// {@category wslapi}
int WslUnregisterDistribution(Pointer<Utf16> distributionName) =>
    _WslUnregisterDistribution(distributionName);

final _WslUnregisterDistribution = _api_ms_win_wsl_api_l1_1_0.lookupFunction<
    Int32 Function(Pointer<Utf16> distributionName),
    int Function(Pointer<Utf16> distributionName)>('WslUnregisterDistribution');
