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

final _crypt32 = DynamicLibrary.open('crypt32.dll');

/// The CryptProtectData function performs encryption on the data in a
/// DATA_BLOB structure. Typically, only a user with the same logon
/// credential as the user who encrypted the data can decrypt the data. In
/// addition, the encryption and decryption usually must be done on the same
/// computer.
///
/// ```c
/// BOOL CryptProtectData(
///   [in]           DATA_BLOB                 *pDataIn,
///   [in, optional] LPCWSTR                   szDataDescr,
///   [in, optional] DATA_BLOB                 *pOptionalEntropy,
///   [in]           PVOID                     pvReserved,
///   [in, optional] CRYPTPROTECT_PROMPTSTRUCT *pPromptStruct,
///   [in]           DWORD                     dwFlags,
///   [out]          DATA_BLOB                 *pDataOut
/// );
/// ```
/// {@category crypt32}
int CryptProtectData(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Utf16> szDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        int dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut) =>
    _CryptProtectData(pDataIn, szDataDescr, pOptionalEntropy, pvReserved,
        pPromptStruct, dwFlags, pDataOut);

final _CryptProtectData = _crypt32.lookupFunction<
    Int32 Function(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Utf16> szDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        Uint32 dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut),
    int Function(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Utf16> szDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        int dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut)>('CryptProtectData');

/// The CryptProtectMemory function encrypts memory to prevent others from
/// viewing sensitive information in your process. For example, use the
/// CryptProtectMemory function to encrypt memory that contains a password.
/// Encrypting the password prevents others from viewing it when the process
/// is paged out to the swap file. Otherwise, the password is in plaintext
/// and viewable by others.
///
/// ```c
/// BOOL CryptProtectMemory(
///   [in, out] LPVOID pDataIn,
///   [in]      DWORD  cbDataIn,
///   [in]      DWORD  dwFlags
/// );
/// ```
/// {@category crypt32}
int CryptProtectMemory(Pointer pDataIn, int cbDataIn, int dwFlags) =>
    _CryptProtectMemory(pDataIn, cbDataIn, dwFlags);

final _CryptProtectMemory = _crypt32.lookupFunction<
    Int32 Function(Pointer pDataIn, Uint32 cbDataIn, Uint32 dwFlags),
    int Function(
        Pointer pDataIn, int cbDataIn, int dwFlags)>('CryptProtectMemory');

/// The CryptUnprotectData function decrypts and does an integrity check of
/// the data in a DATA_BLOB structure. Usually, the only user who can
/// decrypt the data is a user with the same logon credentials as the user
/// who encrypted the data. In addition, the encryption and decryption must
/// be done on the same computer.
///
/// ```c
/// BOOL CryptUnprotectData(
///   [in]            DATA_BLOB                 *pDataIn,
///   [out, optional] LPWSTR                    *ppszDataDescr,
///   [in, optional]  DATA_BLOB                 *pOptionalEntropy,
///                   PVOID                     pvReserved,
///   [in, optional]  CRYPTPROTECT_PROMPTSTRUCT *pPromptStruct,
///   [in]            DWORD                     dwFlags,
///   [out]           DATA_BLOB                 *pDataOut
/// );
/// ```
/// {@category crypt32}
int CryptUnprotectData(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Pointer<Utf16>> ppszDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        int dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut) =>
    _CryptUnprotectData(pDataIn, ppszDataDescr, pOptionalEntropy, pvReserved,
        pPromptStruct, dwFlags, pDataOut);

final _CryptUnprotectData = _crypt32.lookupFunction<
    Int32 Function(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Pointer<Utf16>> ppszDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        Uint32 dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut),
    int Function(
        Pointer<CRYPT_INTEGER_BLOB> pDataIn,
        Pointer<Pointer<Utf16>> ppszDataDescr,
        Pointer<CRYPT_INTEGER_BLOB> pOptionalEntropy,
        Pointer pvReserved,
        Pointer<CRYPTPROTECT_PROMPTSTRUCT> pPromptStruct,
        int dwFlags,
        Pointer<CRYPT_INTEGER_BLOB> pDataOut)>('CryptUnprotectData');

/// The CryptUnprotectMemory function decrypts memory that was encrypted
/// using the CryptProtectMemory function.
///
/// ```c
/// BOOL CryptUnprotectMemory(
///   [in, out] LPVOID pDataIn,
///   [in]      DWORD  cbDataIn,
///   [in]      DWORD  dwFlags
/// );
/// ```
/// {@category crypt32}
int CryptUnprotectMemory(Pointer pDataIn, int cbDataIn, int dwFlags) =>
    _CryptUnprotectMemory(pDataIn, cbDataIn, dwFlags);

final _CryptUnprotectMemory = _crypt32.lookupFunction<
    Int32 Function(Pointer pDataIn, Uint32 cbDataIn, Uint32 dwFlags),
    int Function(
        Pointer pDataIn, int cbDataIn, int dwFlags)>('CryptUnprotectMemory');

/// The CryptUpdateProtectedState function migrates the current user's
/// master keys after the user's security identifier (SID) has changed. This
/// function can be used to preserve encrypted data after a user has been
/// moved from one domain to another.
///
/// ```c
/// BOOL CryptUpdateProtectedState(
///   [in]  PSID    pOldSid,
///   [in]  LPCWSTR pwszOldPassword,
///   [in]  DWORD   dwFlags,
///   [out] DWORD   *pdwSuccessCount,
///   [out] DWORD   *pdwFailureCount
/// );
/// ```
/// {@category crypt32}
int CryptUpdateProtectedState(
        Pointer pOldSid,
        Pointer<Utf16> pwszOldPassword,
        int dwFlags,
        Pointer<Uint32> pdwSuccessCount,
        Pointer<Uint32> pdwFailureCount) =>
    _CryptUpdateProtectedState(
        pOldSid, pwszOldPassword, dwFlags, pdwSuccessCount, pdwFailureCount);

final _CryptUpdateProtectedState = _crypt32.lookupFunction<
    Int32 Function(
        Pointer pOldSid,
        Pointer<Utf16> pwszOldPassword,
        Uint32 dwFlags,
        Pointer<Uint32> pdwSuccessCount,
        Pointer<Uint32> pdwFailureCount),
    int Function(
        Pointer pOldSid,
        Pointer<Utf16> pwszOldPassword,
        int dwFlags,
        Pointer<Uint32> pdwSuccessCount,
        Pointer<Uint32> pdwFailureCount)>('CryptUpdateProtectedState');
