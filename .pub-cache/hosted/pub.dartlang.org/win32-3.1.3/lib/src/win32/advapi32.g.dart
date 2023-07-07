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

final _advapi32 = DynamicLibrary.open('advapi32.dll');

/// The CredDelete function deletes a credential from the user's credential
/// set. The credential set used is the one associated with the logon
/// session of the current token. The token must not have the user's SID
/// disabled.
///
/// ```c
/// BOOL CredDeleteW(
///   LPCWSTR TargetName,
///   DWORD   Type,
///   DWORD   Flags
/// );
/// ```
/// {@category advapi32}
int CredDelete(Pointer<Utf16> TargetName, int Type, int Flags) =>
    _CredDelete(TargetName, Type, Flags);

final _CredDelete = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> TargetName, Uint32 Type, Uint32 Flags),
    int Function(
        Pointer<Utf16> TargetName, int Type, int Flags)>('CredDeleteW');

/// The CredFree function frees a buffer returned by any of the credentials
/// management functions.
///
/// ```c
/// void CredFree(
///   PVOID Buffer
/// );
/// ```
/// {@category advapi32}
void CredFree(Pointer Buffer) => _CredFree(Buffer);

final _CredFree = _advapi32.lookupFunction<Void Function(Pointer Buffer),
    void Function(Pointer Buffer)>('CredFree');

/// The CredRead function reads a credential from the user's credential set.
/// The credential set used is the one associated with the logon session of
/// the current token. The token must not have the user's SID disabled.
///
/// ```c
/// BOOL CredReadW(
///   LPCWSTR      TargetName,
///   DWORD        Type,
///   DWORD        Flags,
///   PCREDENTIALW *Credential
/// );
/// ```
/// {@category advapi32}
int CredRead(Pointer<Utf16> TargetName, int Type, int Flags,
        Pointer<Pointer<CREDENTIAL>> Credential) =>
    _CredRead(TargetName, Type, Flags, Credential);

final _CredRead = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> TargetName, Uint32 Type, Uint32 Flags,
        Pointer<Pointer<CREDENTIAL>> Credential),
    int Function(Pointer<Utf16> TargetName, int Type, int Flags,
        Pointer<Pointer<CREDENTIAL>> Credential)>('CredReadW');

/// The CredWrite function creates a new credential or modifies an existing
/// credential in the user's credential set. The new credential is
/// associated with the logon session of the current token. The token must
/// not have the user's security identifier (SID) disabled.
///
/// ```c
/// BOOL CredWriteW(
///   PCREDENTIALW Credential,
///   DWORD        Flags
/// );
/// ```
/// {@category advapi32}
int CredWrite(Pointer<CREDENTIAL> Credential, int Flags) =>
    _CredWrite(Credential, Flags);

final _CredWrite = _advapi32.lookupFunction<
    Int32 Function(Pointer<CREDENTIAL> Credential, Uint32 Flags),
    int Function(Pointer<CREDENTIAL> Credential, int Flags)>('CredWriteW');

/// Decrypts an encrypted file or directory.
///
/// ```c
/// BOOL DecryptFileW(
///   LPCWSTR lpFileName,
///   DWORD   dwReserved
/// );
/// ```
/// {@category advapi32}
int DecryptFile(Pointer<Utf16> lpFileName, int dwReserved) =>
    _DecryptFile(lpFileName, dwReserved);

final _DecryptFile = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName, Uint32 dwReserved),
    int Function(Pointer<Utf16> lpFileName, int dwReserved)>('DecryptFileW');

/// Encrypts a file or directory. All data streams in a file are encrypted.
/// All new files created in an encrypted directory are encrypted.
///
/// ```c
/// BOOL EncryptFileW(
///   LPCWSTR lpFileName
/// );
/// ```
/// {@category advapi32}
int EncryptFile(Pointer<Utf16> lpFileName) => _EncryptFile(lpFileName);

final _EncryptFile = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName),
    int Function(Pointer<Utf16> lpFileName)>('EncryptFileW');

/// Retrieves the encryption status of the specified file.
///
/// ```c
/// BOOL FileEncryptionStatusW(
///   LPCWSTR lpFileName,
///   LPDWORD lpStatus
/// );
/// ```
/// {@category advapi32}
int FileEncryptionStatus(Pointer<Utf16> lpFileName, Pointer<Uint32> lpStatus) =>
    _FileEncryptionStatus(lpFileName, lpStatus);

final _FileEncryptionStatus = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpFileName, Pointer<Uint32> lpStatus),
    int Function(Pointer<Utf16> lpFileName,
        Pointer<Uint32> lpStatus)>('FileEncryptionStatusW');

/// The GetTokenInformation function retrieves a specified type of
/// information about an access token. The calling process must have
/// appropriate access rights to obtain the information.
///
/// ```c
/// BOOL GetTokenInformation(
///   HANDLE                  TokenHandle,
///   TOKEN_INFORMATION_CLASS TokenInformationClass,
///   LPVOID                  TokenInformation,
///   DWORD                   TokenInformationLength,
///   PDWORD                  ReturnLength
/// );
/// ```
/// {@category advapi32}
int GetTokenInformation(
        int TokenHandle,
        int TokenInformationClass,
        Pointer TokenInformation,
        int TokenInformationLength,
        Pointer<Uint32> ReturnLength) =>
    _GetTokenInformation(TokenHandle, TokenInformationClass, TokenInformation,
        TokenInformationLength, ReturnLength);

final _GetTokenInformation = _advapi32.lookupFunction<
    Int32 Function(
        IntPtr TokenHandle,
        Int32 TokenInformationClass,
        Pointer TokenInformation,
        Uint32 TokenInformationLength,
        Pointer<Uint32> ReturnLength),
    int Function(
        int TokenHandle,
        int TokenInformationClass,
        Pointer TokenInformation,
        int TokenInformationLength,
        Pointer<Uint32> ReturnLength)>('GetTokenInformation');

/// Retrieves the name of the user associated with the current thread.
///
/// ```c
/// BOOL GetUserNameW(
///   LPWSTR  lpBuffer,
///   LPDWORD pcbBuffer);
/// ```
/// {@category advapi32}
int GetUserName(Pointer<Utf16> lpBuffer, Pointer<Uint32> pcbBuffer) =>
    _GetUserName(lpBuffer, pcbBuffer);

final _GetUserName = _advapi32.lookupFunction<
    Int32 Function(Pointer<Utf16> lpBuffer, Pointer<Uint32> pcbBuffer),
    int Function(
        Pointer<Utf16> lpBuffer, Pointer<Uint32> pcbBuffer)>('GetUserNameW');

/// Initiates a shutdown and restart of the specified computer, and restarts
/// any applications that have been registered for restart.
///
/// ```c
/// DWORD InitiateShutdownW(
///   LPWSTR lpMachineName,
///   LPWSTR lpMessage,
///   DWORD  dwGracePeriod,
///   DWORD  dwShutdownFlags,
///   DWORD  dwReason
/// );
/// ```
/// {@category advapi32}
int InitiateShutdown(Pointer<Utf16> lpMachineName, Pointer<Utf16> lpMessage,
        int dwGracePeriod, int dwShutdownFlags, int dwReason) =>
    _InitiateShutdown(
        lpMachineName, lpMessage, dwGracePeriod, dwShutdownFlags, dwReason);

final _InitiateShutdown = _advapi32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpMachineName, Pointer<Utf16> lpMessage,
        Uint32 dwGracePeriod, Uint32 dwShutdownFlags, Uint32 dwReason),
    int Function(
        Pointer<Utf16> lpMachineName,
        Pointer<Utf16> lpMessage,
        int dwGracePeriod,
        int dwShutdownFlags,
        int dwReason)>('InitiateShutdownW');

/// The OpenProcessToken function opens the access token associated with a
/// process.
///
/// ```c
/// BOOL OpenProcessToken(
///   HANDLE  ProcessHandle,
///   DWORD   DesiredAccess,
///   PHANDLE TokenHandle
/// );
/// ```
/// {@category advapi32}
int OpenProcessToken(
        int ProcessHandle, int DesiredAccess, Pointer<IntPtr> TokenHandle) =>
    _OpenProcessToken(ProcessHandle, DesiredAccess, TokenHandle);

final _OpenProcessToken = _advapi32.lookupFunction<
    Int32 Function(IntPtr ProcessHandle, Uint32 DesiredAccess,
        Pointer<IntPtr> TokenHandle),
    int Function(int ProcessHandle, int DesiredAccess,
        Pointer<IntPtr> TokenHandle)>('OpenProcessToken');

/// The OpenThreadToken function opens the access token associated with a
/// thread.
///
/// ```c
/// BOOL OpenThreadToken(
///   HANDLE  ThreadHandle,
///   DWORD   DesiredAccess,
///   BOOL    OpenAsSelf,
///   PHANDLE TokenHandle
/// );
/// ```
/// {@category advapi32}
int OpenThreadToken(int ThreadHandle, int DesiredAccess, int OpenAsSelf,
        Pointer<IntPtr> TokenHandle) =>
    _OpenThreadToken(ThreadHandle, DesiredAccess, OpenAsSelf, TokenHandle);

final _OpenThreadToken = _advapi32.lookupFunction<
    Int32 Function(IntPtr ThreadHandle, Uint32 DesiredAccess, Int32 OpenAsSelf,
        Pointer<IntPtr> TokenHandle),
    int Function(int ThreadHandle, int DesiredAccess, int OpenAsSelf,
        Pointer<IntPtr> TokenHandle)>('OpenThreadToken');

/// Closes a handle to the specified registry key.
///
/// ```c
/// LSTATUS RegCloseKey(
///   HKEY hKey
/// );
/// ```
/// {@category advapi32}
int RegCloseKey(int hKey) => _RegCloseKey(hKey);

final _RegCloseKey = _advapi32.lookupFunction<Uint32 Function(IntPtr hKey),
    int Function(int hKey)>('RegCloseKey');

/// Establishes a connection to a predefined registry key on another
/// computer.
///
/// ```c
/// LSTATUS RegConnectRegistryW(
///   LPCWSTR lpMachineName,
///   HKEY    hKey,
///   PHKEY   phkResult
/// );
/// ```
/// {@category advapi32}
int RegConnectRegistry(
        Pointer<Utf16> lpMachineName, int hKey, Pointer<IntPtr> phkResult) =>
    _RegConnectRegistry(lpMachineName, hKey, phkResult);

final _RegConnectRegistry = _advapi32.lookupFunction<
    Uint32 Function(
        Pointer<Utf16> lpMachineName, IntPtr hKey, Pointer<IntPtr> phkResult),
    int Function(Pointer<Utf16> lpMachineName, int hKey,
        Pointer<IntPtr> phkResult)>('RegConnectRegistryW');

/// Copies the specified registry key, along with its values and subkeys, to
/// the specified destination key.
///
/// ```c
/// LSTATUS RegCopyTreeW(
///   HKEY    hKeySrc,
///   LPCWSTR lpSubKey,
///   HKEY    hKeyDest
/// );
/// ```
/// {@category advapi32}
int RegCopyTree(int hKeySrc, Pointer<Utf16> lpSubKey, int hKeyDest) =>
    _RegCopyTree(hKeySrc, lpSubKey, hKeyDest);

final _RegCopyTree = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKeySrc, Pointer<Utf16> lpSubKey, IntPtr hKeyDest),
    int Function(
        int hKeySrc, Pointer<Utf16> lpSubKey, int hKeyDest)>('RegCopyTreeW');

/// Creates the specified registry key. If the key already exists in the
/// registry, the function opens it.
///
/// ```c
/// LSTATUS RegCreateKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   PHKEY   phkResult);
/// ```
/// {@category advapi32}
int RegCreateKey(
        int hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult) =>
    _RegCreateKey(hKey, lpSubKey, phkResult);

final _RegCreateKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult),
    int Function(int hKey, Pointer<Utf16> lpSubKey,
        Pointer<IntPtr> phkResult)>('RegCreateKeyW');

/// Creates the specified registry key. If the key already exists, the
/// function opens it. Note that key names are not case sensitive.
///
/// ```c
/// LSTATUS RegCreateKeyExW(
///   HKEY hKey,
///   LPCWSTR lpSubKey,
///   DWORD Reserved,
///   LPWSTR lpClass,
///   DWORD dwOptions,
///   REGSAM samDesired,
///   const LPSECURITY_ATTRIBUTES lpSecurityAttributes,
///   PHKEY phkResult,
///   LPDWORD lpdwDisposition
/// );
/// ```
/// {@category advapi32}
int RegCreateKeyEx(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int Reserved,
        Pointer<Utf16> lpClass,
        int dwOptions,
        int samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition) =>
    _RegCreateKeyEx(hKey, lpSubKey, Reserved, lpClass, dwOptions, samDesired,
        lpSecurityAttributes, phkResult, lpdwDisposition);

final _RegCreateKeyEx = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpSubKey,
        Uint32 Reserved,
        Pointer<Utf16> lpClass,
        Uint32 dwOptions,
        Uint32 samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition),
    int Function(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int Reserved,
        Pointer<Utf16> lpClass,
        int dwOptions,
        int samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition)>('RegCreateKeyExW');

/// Establishes a connection to a predefined registry key on another
/// computer.
///
/// ```c
/// LSTATUS RegCreateKeyTransactedW(
///   HKEY     hKey,
///   LPCWSTR  lpSubKey,
///   DWORD    Reserved,
///   LPWSTR   lpClass,
///   DWORD    dwOptions,
///   REGSAM   samDesired,
///   const LPSECURITY_ATTRIBUTES lpSecurityAttributes,
///   PHKEY    phkResult,
///   LPDWORD  lpdwDisposition,
///   HANDLE   hTransaction,
///   PVOID    pExtendedParemeter);
/// ```
/// {@category advapi32}
int RegCreateKeyTransacted(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int Reserved,
        Pointer<Utf16> lpClass,
        int dwOptions,
        int samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition,
        int hTransaction,
        Pointer pExtendedParemeter) =>
    _RegCreateKeyTransacted(
        hKey,
        lpSubKey,
        Reserved,
        lpClass,
        dwOptions,
        samDesired,
        lpSecurityAttributes,
        phkResult,
        lpdwDisposition,
        hTransaction,
        pExtendedParemeter);

final _RegCreateKeyTransacted = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpSubKey,
        Uint32 Reserved,
        Pointer<Utf16> lpClass,
        Uint32 dwOptions,
        Uint32 samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition,
        IntPtr hTransaction,
        Pointer pExtendedParemeter),
    int Function(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int Reserved,
        Pointer<Utf16> lpClass,
        int dwOptions,
        int samDesired,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        Pointer<IntPtr> phkResult,
        Pointer<Uint32> lpdwDisposition,
        int hTransaction,
        Pointer pExtendedParemeter)>('RegCreateKeyTransactedW');

/// Deletes a subkey and its values. Note that key names are not case
/// sensitive.
///
/// ```c
/// LSTATUS RegDeleteKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey);
/// ```
/// {@category advapi32}
int RegDeleteKey(int hKey, Pointer<Utf16> lpSubKey) =>
    _RegDeleteKey(hKey, lpSubKey);

final _RegDeleteKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
    int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegDeleteKeyW');

/// Deletes a subkey and its values from the specified platform-specific
/// view of the registry. Note that key names are not case sensitive.
///
/// ```c
/// LSTATUS RegDeleteKeyExW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   REGSAM  samDesired,
///   DWORD   Reserved);
/// ```
/// {@category advapi32}
int RegDeleteKeyEx(
        int hKey, Pointer<Utf16> lpSubKey, int samDesired, int Reserved) =>
    _RegDeleteKeyEx(hKey, lpSubKey, samDesired, Reserved);

final _RegDeleteKeyEx = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Uint32 samDesired,
        Uint32 Reserved),
    int Function(int hKey, Pointer<Utf16> lpSubKey, int samDesired,
        int Reserved)>('RegDeleteKeyExW');

/// Deletes a subkey and its values from the specified platform-specific
/// view of the registry as a transacted operation. Note that key names are
/// not case sensitive.
///
/// ```c
/// LSTATUS RegDeleteKeyTransactedW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   REGSAM  samDesired,
///   DWORD   Reserved,
///   HANDLE  hTransaction,
///   PVOID   pExtendedParameter);
/// ```
/// {@category advapi32}
int RegDeleteKeyTransacted(int hKey, Pointer<Utf16> lpSubKey, int samDesired,
        int Reserved, int hTransaction, Pointer pExtendedParameter) =>
    _RegDeleteKeyTransacted(
        hKey, lpSubKey, samDesired, Reserved, hTransaction, pExtendedParameter);

final _RegDeleteKeyTransacted = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Uint32 samDesired,
        Uint32 Reserved, IntPtr hTransaction, Pointer pExtendedParameter),
    int Function(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int samDesired,
        int Reserved,
        int hTransaction,
        Pointer pExtendedParameter)>('RegDeleteKeyTransactedW');

/// Removes the specified value from the specified registry key and subkey.
///
/// ```c
/// LSTATUS RegDeleteKeyValueW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   LPCWSTR lpValueName);
/// ```
/// {@category advapi32}
int RegDeleteKeyValue(
        int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpValueName) =>
    _RegDeleteKeyValue(hKey, lpSubKey, lpValueName);

final _RegDeleteKeyValue = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpValueName),
    int Function(int hKey, Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValueName)>('RegDeleteKeyValueW');

/// Deletes the subkeys and values of the specified key recursively.
///
/// ```c
/// LSTATUS RegDeleteTreeW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey);
/// ```
/// {@category advapi32}
int RegDeleteTree(int hKey, Pointer<Utf16> lpSubKey) =>
    _RegDeleteTree(hKey, lpSubKey);

final _RegDeleteTree = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
    int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegDeleteTreeW');

/// Removes a named value from the specified registry key. Note that value
/// names are not case sensitive.
///
/// ```c
/// LSTATUS RegDeleteValueW(
///   HKEY    hKey,
///   LPCWSTR lpValueName);
/// ```
/// {@category advapi32}
int RegDeleteValue(int hKey, Pointer<Utf16> lpValueName) =>
    _RegDeleteValue(hKey, lpValueName);

final _RegDeleteValue = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpValueName),
    int Function(int hKey, Pointer<Utf16> lpValueName)>('RegDeleteValueW');

/// Disables handle caching of the predefined registry handle for
/// HKEY_CURRENT_USER for the current process. This function does not work
/// on a remote computer.
///
/// ```c
/// LSTATUS RegDisablePredefinedCache();
/// ```
/// {@category advapi32}
int RegDisablePredefinedCache() => _RegDisablePredefinedCache();

final _RegDisablePredefinedCache =
    _advapi32.lookupFunction<Uint32 Function(), int Function()>(
        'RegDisablePredefinedCache');

/// Disables handle caching for all predefined registry handles for the
/// current process.
///
/// ```c
/// LSTATUS RegDisablePredefinedCacheEx();
/// ```
/// {@category advapi32}
int RegDisablePredefinedCacheEx() => _RegDisablePredefinedCacheEx();

final _RegDisablePredefinedCacheEx =
    _advapi32.lookupFunction<Uint32 Function(), int Function()>(
        'RegDisablePredefinedCacheEx');

/// Disables registry reflection for the specified key. Disabling reflection
/// for a key does not affect reflection of any subkeys.
///
/// ```c
/// LONG RegDisableReflectionKey(
///   HKEY hBase);
/// ```
/// {@category advapi32}
int RegDisableReflectionKey(int hBase) => _RegDisableReflectionKey(hBase);

final _RegDisableReflectionKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hBase),
    int Function(int hBase)>('RegDisableReflectionKey');

/// Restores registry reflection for the specified disabled key. Restoring
/// reflection for a key does not affect reflection of any subkeys.
///
/// ```c
/// LONG RegEnableReflectionKey(
///   HKEY hBase);
/// ```
/// {@category advapi32}
int RegEnableReflectionKey(int hBase) => _RegEnableReflectionKey(hBase);

final _RegEnableReflectionKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hBase),
    int Function(int hBase)>('RegEnableReflectionKey');

/// Enumerates the subkeys of the specified open registry key. The function
/// retrieves the name of one subkey each time it is called.
///
/// ```c
/// LSTATUS RegEnumKeyW(
///   HKEY   hKey,
///   DWORD  dwIndex,
///   LPWSTR lpName,
///   DWORD  cchName);
/// ```
/// {@category advapi32}
int RegEnumKey(int hKey, int dwIndex, Pointer<Utf16> lpName, int cchName) =>
    _RegEnumKey(hKey, dwIndex, lpName, cchName);

final _RegEnumKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Uint32 dwIndex, Pointer<Utf16> lpName, Uint32 cchName),
    int Function(int hKey, int dwIndex, Pointer<Utf16> lpName,
        int cchName)>('RegEnumKeyW');

/// Enumerates the subkeys of the specified open registry key. The function
/// retrieves information about one subkey each time it is called.
///
/// ```c
/// LSTATUS RegEnumKeyExW(
///   HKEY      hKey,
///   DWORD     dwIndex,
///   LPWSTR    lpName,
///   LPDWORD   lpcchName,
///   LPDWORD   lpReserved,
///   LPWSTR    lpClass,
///   LPDWORD   lpcchClass,
///   PFILETIME lpftLastWriteTime);
/// ```
/// {@category advapi32}
int RegEnumKeyEx(
        int hKey,
        int dwIndex,
        Pointer<Utf16> lpName,
        Pointer<Uint32> lpcchName,
        Pointer<Uint32> lpReserved,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<FILETIME> lpftLastWriteTime) =>
    _RegEnumKeyEx(hKey, dwIndex, lpName, lpcchName, lpReserved, lpClass,
        lpcchClass, lpftLastWriteTime);

final _RegEnumKeyEx = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Uint32 dwIndex,
        Pointer<Utf16> lpName,
        Pointer<Uint32> lpcchName,
        Pointer<Uint32> lpReserved,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<FILETIME> lpftLastWriteTime),
    int Function(
        int hKey,
        int dwIndex,
        Pointer<Utf16> lpName,
        Pointer<Uint32> lpcchName,
        Pointer<Uint32> lpReserved,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<FILETIME> lpftLastWriteTime)>('RegEnumKeyExW');

/// Enumerates the values for the specified open registry key. The function
/// copies one indexed value name and data block for the key each time it is
/// called.
///
/// ```c
/// LSTATUS RegEnumValueW(
///   HKEY    hKey,
///   DWORD   dwIndex,
///   LPWSTR  lpValueName,
///   LPDWORD lpcchValueName,
///   LPDWORD lpReserved,
///   LPDWORD lpType,
///   LPBYTE  lpData,
///   LPDWORD lpcbData);
/// ```
/// {@category advapi32}
int RegEnumValue(
        int hKey,
        int dwIndex,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpcchValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData) =>
    _RegEnumValue(hKey, dwIndex, lpValueName, lpcchValueName, lpReserved,
        lpType, lpData, lpcbData);

final _RegEnumValue = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Uint32 dwIndex,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpcchValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData),
    int Function(
        int hKey,
        int dwIndex,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpcchValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData)>('RegEnumValueW');

/// Writes all the attributes of the specified open registry key into the
/// registry.
///
/// ```c
/// LSTATUS RegFlushKey(
///   HKEY hKey);
/// ```
/// {@category advapi32}
int RegFlushKey(int hKey) => _RegFlushKey(hKey);

final _RegFlushKey = _advapi32.lookupFunction<Uint32 Function(IntPtr hKey),
    int Function(int hKey)>('RegFlushKey');

/// Retrieves the type and data for the specified registry value.
///
/// ```c
/// LSTATUS RegGetValueW(
///   HKEY    hkey,
///   LPCWSTR lpSubKey,
///   LPCWSTR lpValue,
///   DWORD   dwFlags,
///   LPDWORD pdwType,
///   PVOID   pvData,
///   LPDWORD pcbData);
/// ```
/// {@category advapi32}
int RegGetValue(
        int hkey,
        Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValue,
        int dwFlags,
        Pointer<Uint32> pdwType,
        Pointer pvData,
        Pointer<Uint32> pcbData) =>
    _RegGetValue(hkey, lpSubKey, lpValue, dwFlags, pdwType, pvData, pcbData);

final _RegGetValue = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hkey,
        Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValue,
        Uint32 dwFlags,
        Pointer<Uint32> pdwType,
        Pointer pvData,
        Pointer<Uint32> pcbData),
    int Function(
        int hkey,
        Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValue,
        int dwFlags,
        Pointer<Uint32> pdwType,
        Pointer pvData,
        Pointer<Uint32> pcbData)>('RegGetValueW');

/// Loads the specified registry hive as an application hive.
///
/// ```c
/// LSTATUS RegLoadAppKeyW(
///   LPCWSTR lpFile,
///   PHKEY   phkResult,
///   REGSAM  samDesired,
///   DWORD   dwOptions,
///   DWORD   Reserved);
/// ```
/// {@category advapi32}
int RegLoadAppKey(Pointer<Utf16> lpFile, Pointer<IntPtr> phkResult,
        int samDesired, int dwOptions, int Reserved) =>
    _RegLoadAppKey(lpFile, phkResult, samDesired, dwOptions, Reserved);

final _RegLoadAppKey = _advapi32.lookupFunction<
    Uint32 Function(Pointer<Utf16> lpFile, Pointer<IntPtr> phkResult,
        Uint32 samDesired, Uint32 dwOptions, Uint32 Reserved),
    int Function(Pointer<Utf16> lpFile, Pointer<IntPtr> phkResult,
        int samDesired, int dwOptions, int Reserved)>('RegLoadAppKeyW');

/// Creates a subkey under HKEY_USERS or HKEY_LOCAL_MACHINE and loads the
/// data from the specified registry hive into that subkey.
///
/// ```c
/// LSTATUS RegLoadKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   LPCWSTR lpFile);
/// ```
/// {@category advapi32}
int RegLoadKey(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpFile) =>
    _RegLoadKey(hKey, lpSubKey, lpFile);

final _RegLoadKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpFile),
    int Function(int hKey, Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpFile)>('RegLoadKeyW');

/// Loads the specified string from the specified key and subkey.
///
/// ```c
/// LSTATUS RegLoadMUIStringW(
///   HKEY    hKey,
///   LPCWSTR pszValue,
///   LPWSTR  pszOutBuf,
///   DWORD   cbOutBuf,
///   LPDWORD pcbData,
///   DWORD   Flags,
///   LPCWSTR pszDirectory);
/// ```
/// {@category advapi32}
int RegLoadMUIString(
        int hKey,
        Pointer<Utf16> pszValue,
        Pointer<Utf16> pszOutBuf,
        int cbOutBuf,
        Pointer<Uint32> pcbData,
        int Flags,
        Pointer<Utf16> pszDirectory) =>
    _RegLoadMUIString(
        hKey, pszValue, pszOutBuf, cbOutBuf, pcbData, Flags, pszDirectory);

final _RegLoadMUIString = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> pszValue,
        Pointer<Utf16> pszOutBuf,
        Uint32 cbOutBuf,
        Pointer<Uint32> pcbData,
        Uint32 Flags,
        Pointer<Utf16> pszDirectory),
    int Function(
        int hKey,
        Pointer<Utf16> pszValue,
        Pointer<Utf16> pszOutBuf,
        int cbOutBuf,
        Pointer<Uint32> pcbData,
        int Flags,
        Pointer<Utf16> pszDirectory)>('RegLoadMUIStringW');

/// Notifies the caller about changes to the attributes or contents of a
/// specified registry key.
///
/// ```c
/// LSTATUS RegNotifyChangeKeyValue(
///   HKEY   hKey,
///   BOOL   bWatchSubtree,
///   DWORD  dwNotifyFilter,
///   HANDLE hEvent,
///   BOOL   fAsynchronous);
/// ```
/// {@category advapi32}
int RegNotifyChangeKeyValue(int hKey, int bWatchSubtree, int dwNotifyFilter,
        int hEvent, int fAsynchronous) =>
    _RegNotifyChangeKeyValue(
        hKey, bWatchSubtree, dwNotifyFilter, hEvent, fAsynchronous);

final _RegNotifyChangeKeyValue = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Int32 bWatchSubtree, Uint32 dwNotifyFilter,
        IntPtr hEvent, Int32 fAsynchronous),
    int Function(int hKey, int bWatchSubtree, int dwNotifyFilter, int hEvent,
        int fAsynchronous)>('RegNotifyChangeKeyValue');

/// Retrieves a handle to the HKEY_CURRENT_USER key for the user the current
/// thread is impersonating.
///
/// ```c
/// LSTATUS RegOpenCurrentUser(
///   REGSAM samDesired,
///   PHKEY  phkResult);
/// ```
/// {@category advapi32}
int RegOpenCurrentUser(int samDesired, Pointer<IntPtr> phkResult) =>
    _RegOpenCurrentUser(samDesired, phkResult);

final _RegOpenCurrentUser = _advapi32.lookupFunction<
    Uint32 Function(Uint32 samDesired, Pointer<IntPtr> phkResult),
    int Function(
        int samDesired, Pointer<IntPtr> phkResult)>('RegOpenCurrentUser');

/// Opens the specified registry key.
///
/// ```c
/// LSTATUS RegOpenKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   PHKEY   phkResult);
/// ```
/// {@category advapi32}
int RegOpenKey(int hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult) =>
    _RegOpenKey(hKey, lpSubKey, phkResult);

final _RegOpenKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<IntPtr> phkResult),
    int Function(int hKey, Pointer<Utf16> lpSubKey,
        Pointer<IntPtr> phkResult)>('RegOpenKeyW');

/// Opens the specified registry key. Note that key names are not case
/// sensitive.
///
/// ```c
/// LSTATUS RegOpenKeyExW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   DWORD   ulOptions,
///   REGSAM  samDesired,
///   PHKEY   phkResult
/// );
/// ```
/// {@category advapi32}
int RegOpenKeyEx(int hKey, Pointer<Utf16> lpSubKey, int ulOptions,
        int samDesired, Pointer<IntPtr> phkResult) =>
    _RegOpenKeyEx(hKey, lpSubKey, ulOptions, samDesired, phkResult);

final _RegOpenKeyEx = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Uint32 ulOptions,
        Uint32 samDesired, Pointer<IntPtr> phkResult),
    int Function(int hKey, Pointer<Utf16> lpSubKey, int ulOptions,
        int samDesired, Pointer<IntPtr> phkResult)>('RegOpenKeyExW');

/// Opens the specified registry key and associates it with a transaction.
/// Note that key names are not case sensitive.
///
/// ```c
/// LSTATUS RegOpenKeyTransactedW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   DWORD   ulOptions,
///   REGSAM  samDesired,
///   PHKEY   phkResult,
///   HANDLE  hTransaction,
///   PVOID   pExtendedParemeter);
/// ```
/// {@category advapi32}
int RegOpenKeyTransacted(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int ulOptions,
        int samDesired,
        Pointer<IntPtr> phkResult,
        int hTransaction,
        Pointer pExtendedParemeter) =>
    _RegOpenKeyTransacted(hKey, lpSubKey, ulOptions, samDesired, phkResult,
        hTransaction, pExtendedParemeter);

final _RegOpenKeyTransacted = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpSubKey,
        Uint32 ulOptions,
        Uint32 samDesired,
        Pointer<IntPtr> phkResult,
        IntPtr hTransaction,
        Pointer pExtendedParemeter),
    int Function(
        int hKey,
        Pointer<Utf16> lpSubKey,
        int ulOptions,
        int samDesired,
        Pointer<IntPtr> phkResult,
        int hTransaction,
        Pointer pExtendedParemeter)>('RegOpenKeyTransactedW');

/// Retrieves a handle to the HKEY_CLASSES_ROOT key for a specified user.
/// The user is identified by an access token.
///
/// ```c
/// LSTATUS RegOpenUserClassesRoot(
///   HANDLE hToken,
///   DWORD  dwOptions,
///   REGSAM samDesired,
///   PHKEY  phkResult);
/// ```
/// {@category advapi32}
int RegOpenUserClassesRoot(
        int hToken, int dwOptions, int samDesired, Pointer<IntPtr> phkResult) =>
    _RegOpenUserClassesRoot(hToken, dwOptions, samDesired, phkResult);

final _RegOpenUserClassesRoot = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hToken, Uint32 dwOptions, Uint32 samDesired,
        Pointer<IntPtr> phkResult),
    int Function(int hToken, int dwOptions, int samDesired,
        Pointer<IntPtr> phkResult)>('RegOpenUserClassesRoot');

/// Maps a predefined registry key to the specified registry key.
///
/// ```c
/// LSTATUS RegOverridePredefKey(
///   HKEY hKey,
///   HKEY hNewHKey);
/// ```
/// {@category advapi32}
int RegOverridePredefKey(int hKey, int hNewHKey) =>
    _RegOverridePredefKey(hKey, hNewHKey);

final _RegOverridePredefKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, IntPtr hNewHKey),
    int Function(int hKey, int hNewHKey)>('RegOverridePredefKey');

/// Retrieves information about the specified registry key.
///
/// ```c
/// LSTATUS RegQueryInfoKeyW(
///   HKEY      hKey,
///   LPWSTR    lpClass,
///   LPDWORD   lpcchClass,
///   LPDWORD   lpReserved,
///   LPDWORD   lpcSubKeys,
///   LPDWORD   lpcbMaxSubKeyLen,
///   LPDWORD   lpcbMaxClassLen,
///   LPDWORD   lpcValues,
///   LPDWORD   lpcbMaxValueNameLen,
///   LPDWORD   lpcbMaxValueLen,
///   LPDWORD   lpcbSecurityDescriptor,
///   PFILETIME lpftLastWriteTime);
/// ```
/// {@category advapi32}
int RegQueryInfoKey(
        int hKey,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpcSubKeys,
        Pointer<Uint32> lpcbMaxSubKeyLen,
        Pointer<Uint32> lpcbMaxClassLen,
        Pointer<Uint32> lpcValues,
        Pointer<Uint32> lpcbMaxValueNameLen,
        Pointer<Uint32> lpcbMaxValueLen,
        Pointer<Uint32> lpcbSecurityDescriptor,
        Pointer<FILETIME> lpftLastWriteTime) =>
    _RegQueryInfoKey(
        hKey,
        lpClass,
        lpcchClass,
        lpReserved,
        lpcSubKeys,
        lpcbMaxSubKeyLen,
        lpcbMaxClassLen,
        lpcValues,
        lpcbMaxValueNameLen,
        lpcbMaxValueLen,
        lpcbSecurityDescriptor,
        lpftLastWriteTime);

final _RegQueryInfoKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpcSubKeys,
        Pointer<Uint32> lpcbMaxSubKeyLen,
        Pointer<Uint32> lpcbMaxClassLen,
        Pointer<Uint32> lpcValues,
        Pointer<Uint32> lpcbMaxValueNameLen,
        Pointer<Uint32> lpcbMaxValueLen,
        Pointer<Uint32> lpcbSecurityDescriptor,
        Pointer<FILETIME> lpftLastWriteTime),
    int Function(
        int hKey,
        Pointer<Utf16> lpClass,
        Pointer<Uint32> lpcchClass,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpcSubKeys,
        Pointer<Uint32> lpcbMaxSubKeyLen,
        Pointer<Uint32> lpcbMaxClassLen,
        Pointer<Uint32> lpcValues,
        Pointer<Uint32> lpcbMaxValueNameLen,
        Pointer<Uint32> lpcbMaxValueLen,
        Pointer<Uint32> lpcbSecurityDescriptor,
        Pointer<FILETIME> lpftLastWriteTime)>('RegQueryInfoKeyW');

/// Retrieves the type and data for a list of value names associated with an
/// open registry key.
///
/// ```c
/// LSTATUS RegQueryMultipleValuesW(
///   HKEY     hKey,
///   PVALENTW val_list,
///   DWORD    num_vals,
///   LPWSTR   lpValueBuf,
///   LPDWORD  ldwTotsize);
/// ```
/// {@category advapi32}
int RegQueryMultipleValues(int hKey, Pointer<VALENT> val_list, int num_vals,
        Pointer<Utf16> lpValueBuf, Pointer<Uint32> ldwTotsize) =>
    _RegQueryMultipleValues(hKey, val_list, num_vals, lpValueBuf, ldwTotsize);

final _RegQueryMultipleValues = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<VALENT> val_list, Uint32 num_vals,
        Pointer<Utf16> lpValueBuf, Pointer<Uint32> ldwTotsize),
    int Function(
        int hKey,
        Pointer<VALENT> val_list,
        int num_vals,
        Pointer<Utf16> lpValueBuf,
        Pointer<Uint32> ldwTotsize)>('RegQueryMultipleValuesW');

/// Determines whether reflection has been disabled or enabled for the
/// specified key.
///
/// ```c
/// LONG RegQueryReflectionKey(
///   HKEY hBase,
///   BOOL *bIsReflectionDisabled);
/// ```
/// {@category advapi32}
int RegQueryReflectionKey(int hBase, Pointer<Int32> bIsReflectionDisabled) =>
    _RegQueryReflectionKey(hBase, bIsReflectionDisabled);

final _RegQueryReflectionKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hBase, Pointer<Int32> bIsReflectionDisabled),
    int Function(int hBase,
        Pointer<Int32> bIsReflectionDisabled)>('RegQueryReflectionKey');

/// Retrieves the data associated with the default or unnamed value of a
/// specified registry key. The data must be a null-terminated string.
///
/// ```c
/// LSTATUS RegQueryValueW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   LPWSTR  lpData,
///   PLONG   lpcbData);
/// ```
/// {@category advapi32}
int RegQueryValue(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpData,
        Pointer<Int32> lpcbData) =>
    _RegQueryValue(hKey, lpSubKey, lpData, lpcbData);

final _RegQueryValue = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpData,
        Pointer<Int32> lpcbData),
    int Function(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpData,
        Pointer<Int32> lpcbData)>('RegQueryValueW');

/// Retrieves the type and data for the specified value name associated with
/// an open registry key. To ensure that any string values (REG_SZ,
/// REG_MULTI_SZ, and REG_EXPAND_SZ) returned are null-terminated, use the
/// RegGetValue function.
///
/// ```c
/// LSTATUS RegQueryValueExW(
///   HKEY    hKey,
///   LPCWSTR lpValueName,
///   LPDWORD lpReserved,
///   LPDWORD lpType,
///   LPBYTE  lpData,
///   LPDWORD lpcbData
/// );
/// ```
/// {@category advapi32}
int RegQueryValueEx(
        int hKey,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData) =>
    _RegQueryValueEx(hKey, lpValueName, lpReserved, lpType, lpData, lpcbData);

final _RegQueryValueEx = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData),
    int Function(
        int hKey,
        Pointer<Utf16> lpValueName,
        Pointer<Uint32> lpReserved,
        Pointer<Uint32> lpType,
        Pointer<Uint8> lpData,
        Pointer<Uint32> lpcbData)>('RegQueryValueExW');

/// Changes the name of the specified registry key.
///
/// ```c
/// LSTATUS RegRenameKey(
///   HKEY    hKey,
///   LPCWSTR lpSubKeyName,
///   LPCWSTR lpNewKeyName
/// );
/// ```
/// {@category advapi32}
int RegRenameKey(
        int hKey, Pointer<Utf16> lpSubKeyName, Pointer<Utf16> lpNewKeyName) =>
    _RegRenameKey(hKey, lpSubKeyName, lpNewKeyName);

final _RegRenameKey = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey, Pointer<Utf16> lpSubKeyName, Pointer<Utf16> lpNewKeyName),
    int Function(int hKey, Pointer<Utf16> lpSubKeyName,
        Pointer<Utf16> lpNewKeyName)>('RegRenameKey');

/// Replaces the file backing a registry key and all its subkeys with
/// another file, so that when the system is next started, the key and
/// subkeys will have the values stored in the new file.
///
/// ```c
/// LSTATUS RegReplaceKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   LPCWSTR lpNewFile,
///   LPCWSTR lpOldFile);
/// ```
/// {@category advapi32}
int RegReplaceKey(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpNewFile,
        Pointer<Utf16> lpOldFile) =>
    _RegReplaceKey(hKey, lpSubKey, lpNewFile, lpOldFile);

final _RegReplaceKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpNewFile, Pointer<Utf16> lpOldFile),
    int Function(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpNewFile,
        Pointer<Utf16> lpOldFile)>('RegReplaceKeyW');

/// Reads the registry information in a specified file and copies it over
/// the specified key. This registry information may be in the form of a key
/// and multiple levels of subkeys.
///
/// ```c
/// LSTATUS RegRestoreKeyW(
///   HKEY    hKey,
///   LPCWSTR lpFile,
///   DWORD   dwFlags);
/// ```
/// {@category advapi32}
int RegRestoreKey(int hKey, Pointer<Utf16> lpFile, int dwFlags) =>
    _RegRestoreKey(hKey, lpFile, dwFlags);

final _RegRestoreKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile, Int32 dwFlags),
    int Function(
        int hKey, Pointer<Utf16> lpFile, int dwFlags)>('RegRestoreKeyW');

/// Saves the specified key and all of its subkeys and values to a new file,
/// in the standard format.
///
/// ```c
/// LSTATUS RegSaveKeyW(
///   HKEY                        hKey,
///   LPCWSTR                     lpFile,
///   const LPSECURITY_ATTRIBUTES lpSecurityAttributes);
/// ```
/// {@category advapi32}
int RegSaveKey(int hKey, Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes) =>
    _RegSaveKey(hKey, lpFile, lpSecurityAttributes);

final _RegSaveKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes),
    int Function(int hKey, Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes)>('RegSaveKeyW');

/// Saves the specified key and all of its subkeys and values to a registry
/// file, in the specified format.
///
/// ```c
/// LSTATUS RegSaveKeyExW(
///   HKEY                        hKey,
///   LPCWSTR                     lpFile,
///   const LPSECURITY_ATTRIBUTES lpSecurityAttributes,
///   DWORD                       Flags);
/// ```
/// {@category advapi32}
int RegSaveKeyEx(int hKey, Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes, int Flags) =>
    _RegSaveKeyEx(hKey, lpFile, lpSecurityAttributes, Flags);

final _RegSaveKeyEx = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes, Uint32 Flags),
    int Function(
        int hKey,
        Pointer<Utf16> lpFile,
        Pointer<SECURITY_ATTRIBUTES> lpSecurityAttributes,
        int Flags)>('RegSaveKeyExW');

/// Sets the data for the specified value in the specified registry key and
/// subkey.
///
/// ```c
/// LSTATUS RegSetKeyValueW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   LPCWSTR lpValueName,
///   DWORD   dwType,
///   LPCVOID lpData,
///   DWORD   cbData);
/// ```
/// {@category advapi32}
int RegSetKeyValue(int hKey, Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValueName, int dwType, Pointer lpData, int cbData) =>
    _RegSetKeyValue(hKey, lpSubKey, lpValueName, dwType, lpData, cbData);

final _RegSetKeyValue = _advapi32.lookupFunction<
    Uint32 Function(
        IntPtr hKey,
        Pointer<Utf16> lpSubKey,
        Pointer<Utf16> lpValueName,
        Uint32 dwType,
        Pointer lpData,
        Uint32 cbData),
    int Function(int hKey, Pointer<Utf16> lpSubKey, Pointer<Utf16> lpValueName,
        int dwType, Pointer lpData, int cbData)>('RegSetKeyValueW');

/// Sets the data for the default or unnamed value of a specified registry
/// key. The data must be a text string.
///
/// ```c
/// LSTATUS RegSetValueW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey,
///   DWORD   dwType,
///   LPCWSTR lpData,
///   DWORD   cbData);
/// ```
/// {@category advapi32}
int RegSetValue(int hKey, Pointer<Utf16> lpSubKey, int dwType,
        Pointer<Utf16> lpData, int cbData) =>
    _RegSetValue(hKey, lpSubKey, dwType, lpData, cbData);

final _RegSetValue = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey, Uint32 dwType,
        Pointer<Utf16> lpData, Uint32 cbData),
    int Function(int hKey, Pointer<Utf16> lpSubKey, int dwType,
        Pointer<Utf16> lpData, int cbData)>('RegSetValueW');

/// Sets the data and type of a specified value under a registry key.
///
/// ```c
/// LSTATUS RegSetValueExW(
///   HKEY       hKey,
///   LPCWSTR    lpValueName,
///   DWORD      Reserved,
///   DWORD      dwType,
///   const BYTE *lpData,
///   DWORD      cbData
/// );
/// ```
/// {@category advapi32}
int RegSetValueEx(int hKey, Pointer<Utf16> lpValueName, int Reserved,
        int dwType, Pointer<Uint8> lpData, int cbData) =>
    _RegSetValueEx(hKey, lpValueName, Reserved, dwType, lpData, cbData);

final _RegSetValueEx = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpValueName, Uint32 Reserved,
        Uint32 dwType, Pointer<Uint8> lpData, Uint32 cbData),
    int Function(int hKey, Pointer<Utf16> lpValueName, int Reserved, int dwType,
        Pointer<Uint8> lpData, int cbData)>('RegSetValueExW');

/// Unloads the specified registry key and its subkeys from the registry.
///
/// ```c
/// LSTATUS RegUnLoadKeyW(
///   HKEY    hKey,
///   LPCWSTR lpSubKey);
/// ```
/// {@category advapi32}
int RegUnLoadKey(int hKey, Pointer<Utf16> lpSubKey) =>
    _RegUnLoadKey(hKey, lpSubKey);

final _RegUnLoadKey = _advapi32.lookupFunction<
    Uint32 Function(IntPtr hKey, Pointer<Utf16> lpSubKey),
    int Function(int hKey, Pointer<Utf16> lpSubKey)>('RegUnLoadKeyW');

/// The SetThreadToken function assigns an impersonation token to a thread.
/// The function can also cause a thread to stop using an impersonation
/// token.
///
/// ```c
/// BOOL SetThreadToken(
///   PHANDLE Thread,
///   HANDLE  Token
/// );
/// ```
/// {@category advapi32}
int SetThreadToken(Pointer<IntPtr> Thread, int Token) =>
    _SetThreadToken(Thread, Token);

final _SetThreadToken = _advapi32.lookupFunction<
    Int32 Function(Pointer<IntPtr> Thread, IntPtr Token),
    int Function(Pointer<IntPtr> Thread, int Token)>('SetThreadToken');
