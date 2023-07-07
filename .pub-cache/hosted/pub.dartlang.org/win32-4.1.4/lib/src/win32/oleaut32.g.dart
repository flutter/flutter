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

final _oleaut32 = DynamicLibrary.open('oleaut32.dll');

/// Converts the MS-DOS representation of time to the date and time
/// representation stored in a variant.
///
/// ```c
/// INT DosDateTimeToVariantTime(
///   USHORT wDosDate,
///   USHORT wDosTime,
///   DOUBLE *pvtime
/// );
/// ```
/// {@category oleaut32}
int DosDateTimeToVariantTime(
        int wDosDate, int wDosTime, Pointer<Double> pvtime) =>
    _DosDateTimeToVariantTime(wDosDate, wDosTime, pvtime);

final _DosDateTimeToVariantTime = _oleaut32.lookupFunction<
    Int32 Function(Uint16 wDosDate, Uint16 wDosTime, Pointer<Double> pvtime),
    int Function(int wDosDate, int wDosTime,
        Pointer<Double> pvtime)>('DosDateTimeToVariantTime');

/// Retrieves a pointer to a running object that has been registered with
/// OLE.
///
/// ```c
/// HRESULT GetActiveObject(
///   REFCLSID rclsid,
///   void     *pvReserved,
///   IUnknown **ppunk
/// );
/// ```
/// {@category oleaut32}
int GetActiveObject(Pointer<GUID> rclsid, Pointer pvReserved,
        Pointer<Pointer<COMObject>> ppunk) =>
    _GetActiveObject(rclsid, pvReserved, ppunk);

final _GetActiveObject = _oleaut32.lookupFunction<
    Int32 Function(Pointer<GUID> rclsid, Pointer pvReserved,
        Pointer<Pointer<COMObject>> ppunk),
    int Function(Pointer<GUID> rclsid, Pointer pvReserved,
        Pointer<Pointer<COMObject>> ppunk)>('GetActiveObject');

/// Allocates a new string and copies the passed string into it.
///
/// ```c
/// BSTR SysAllocString(
///   const OLECHAR *psz
/// );
/// ```
/// {@category oleaut32}
Pointer<Utf16> SysAllocString(Pointer<Utf16> psz) => _SysAllocString(psz);

final _SysAllocString = _oleaut32.lookupFunction<
    Pointer<Utf16> Function(Pointer<Utf16> psz),
    Pointer<Utf16> Function(Pointer<Utf16> psz)>('SysAllocString');

/// Takes an ANSI string as input, and returns a BSTR that contains an ANSI
/// string. Does not perform any ANSI-to-Unicode translation.
///
/// ```c
/// BSTR SysAllocStringByteLen(
///   LPCSTR psz,
///   UINT   len
/// );
/// ```
/// {@category oleaut32}
Pointer<Utf16> SysAllocStringByteLen(Pointer<Utf8> psz, int len) =>
    _SysAllocStringByteLen(psz, len);

final _SysAllocStringByteLen = _oleaut32.lookupFunction<
    Pointer<Utf16> Function(Pointer<Utf8> psz, Uint32 len),
    Pointer<Utf16> Function(
        Pointer<Utf8> psz, int len)>('SysAllocStringByteLen');

/// Allocates a new string, copies the specified number of characters from
/// the passed string, and appends a null-terminating character.
///
/// ```c
/// BSTR SysAllocStringLen(
///   const OLECHAR *strIn,
///   UINT          ui
/// );
/// ```
/// {@category oleaut32}
Pointer<Utf16> SysAllocStringLen(Pointer<Utf16> strIn, int ui) =>
    _SysAllocStringLen(strIn, ui);

final _SysAllocStringLen = _oleaut32.lookupFunction<
    Pointer<Utf16> Function(Pointer<Utf16> strIn, Uint32 ui),
    Pointer<Utf16> Function(Pointer<Utf16> strIn, int ui)>('SysAllocStringLen');

/// Deallocates a string allocated previously by SysAllocString,
/// SysAllocStringByteLen, SysReAllocString, SysAllocStringLen, or
/// SysReAllocStringLen.
///
/// ```c
/// void SysFreeString(
///   BSTR bstrString
/// );
/// ```
/// {@category oleaut32}
void SysFreeString(Pointer<Utf16> bstrString) => _SysFreeString(bstrString);

final _SysFreeString = _oleaut32.lookupFunction<
    Void Function(Pointer<Utf16> bstrString),
    void Function(Pointer<Utf16> bstrString)>('SysFreeString');

/// Reallocates a previously allocated string to be the size of a second
/// string and copies the second string into the reallocated memory.
///
/// ```c
/// INT SysReAllocString(
///   BSTR          *pbstr,
///   const OLECHAR *psz
/// );
/// ```
/// {@category oleaut32}
int SysReAllocString(Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz) =>
    _SysReAllocString(pbstr, psz);

final _SysReAllocString = _oleaut32.lookupFunction<
    Int32 Function(Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz),
    int Function(
        Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz)>('SysReAllocString');

/// Creates a new BSTR containing a specified number of characters from an
/// old BSTR, and frees the old BSTR.
///
/// ```c
/// INT SysReAllocStringLen(
///   BSTR          *pbstr,
///   const OLECHAR *psz,
///   UINT  len
/// );
/// ```
/// {@category oleaut32}
int SysReAllocStringLen(
        Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz, int len) =>
    _SysReAllocStringLen(pbstr, psz, len);

final _SysReAllocStringLen = _oleaut32.lookupFunction<
    Int32 Function(
        Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz, Uint32 len),
    int Function(Pointer<Pointer<Utf16>> pbstr, Pointer<Utf16> psz,
        int len)>('SysReAllocStringLen');

/// Decreases the pinning reference count for the specified string by one.
/// When that count reaches 0, the memory for that string is no longer
/// prevented from being freed.
///
/// ```c
/// void SysReleaseString(
/// BSTR bstrString
/// );
/// ```
/// {@category oleaut32}
void SysReleaseString(Pointer<Utf16> bstrString) =>
    _SysReleaseString(bstrString);

final _SysReleaseString = _oleaut32.lookupFunction<
    Void Function(Pointer<Utf16> bstrString),
    void Function(Pointer<Utf16> bstrString)>('SysReleaseString');

/// Returns the length (in bytes) of a BSTR.
///
/// ```c
/// UINT SysStringByteLen(
///   BSTR bstr
/// );
/// ```
/// {@category oleaut32}
int SysStringByteLen(Pointer<Utf16> bstr) => _SysStringByteLen(bstr);

final _SysStringByteLen = _oleaut32.lookupFunction<
    Uint32 Function(Pointer<Utf16> bstr),
    int Function(Pointer<Utf16> bstr)>('SysStringByteLen');

/// Returns the length of a BSTR.
///
/// ```c
/// UINT SysStringLen(
///   BSTR pbstr
/// );
/// ```
/// {@category oleaut32}
int SysStringLen(Pointer<Utf16> pbstr) => _SysStringLen(pbstr);

final _SysStringLen = _oleaut32.lookupFunction<
    Uint32 Function(Pointer<Utf16> pbstr),
    int Function(Pointer<Utf16> pbstr)>('SysStringLen');

/// Converts a variant from one type to another.
///
/// ```c
/// HRESULT VarBstrCat(
///   [in]  BSTR   bstrLeft,
///   [in]  BSTR   bstrRight,
///   [out] LPBSTR pbstrResult
/// );
/// ```
/// {@category oleaut32}
int VarBstrCat(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
        Pointer<Pointer<Uint16>> pbstrResult) =>
    _VarBstrCat(bstrLeft, bstrRight, pbstrResult);

final _VarBstrCat = _oleaut32.lookupFunction<
    Int32 Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
        Pointer<Pointer<Uint16>> pbstrResult),
    int Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
        Pointer<Pointer<Uint16>> pbstrResult)>('VarBstrCat');

/// Compares two variants of type BSTR.
///
/// ```c
/// HRESULT VarBstrCmp(
///   [in] BSTR  bstrLeft,
///   [in] BSTR  bstrRight,
///   [in] LCID  lcid,
///   [in] ULONG dwFlags
/// );
/// ```
/// {@category oleaut32}
int VarBstrCmp(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight, int lcid,
        int dwFlags) =>
    _VarBstrCmp(bstrLeft, bstrRight, lcid, dwFlags);

final _VarBstrCmp = _oleaut32.lookupFunction<
    Int32 Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight,
        Uint32 lcid, Uint32 dwFlags),
    int Function(Pointer<Utf16> bstrLeft, Pointer<Utf16> bstrRight, int lcid,
        int dwFlags)>('VarBstrCmp');

/// Converts a variant from one type to another.
///
/// ```c
/// HRESULT VariantChangeType(
///   VARIANTARG       *pvargDest,
///   const VARIANTARG *pvarSrc,
///   USHORT           wFlags,
///   VARTYPE          vt
/// );
/// ```
/// {@category oleaut32}
int VariantChangeType(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvarSrc,
        int wFlags, int vt) =>
    _VariantChangeType(pvargDest, pvarSrc, wFlags, vt);

final _VariantChangeType = _oleaut32.lookupFunction<
    Int32 Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvarSrc,
        Uint16 wFlags, Uint16 vt),
    int Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvarSrc,
        int wFlags, int vt)>('VariantChangeType');

/// Clears a variant.
///
/// ```c
/// HRESULT VariantClear(
///   VARIANTARG *pvarg
/// );
/// ```
/// {@category oleaut32}
int VariantClear(Pointer<VARIANT> pvarg) => _VariantClear(pvarg);

final _VariantClear = _oleaut32.lookupFunction<
    Int32 Function(Pointer<VARIANT> pvarg),
    int Function(Pointer<VARIANT> pvarg)>('VariantClear');

/// Frees the destination variant and makes a copy of the source variant.
///
/// ```c
/// HRESULT VariantCopy(
///   VARIANTARG       *pvargDest,
///   const VARIANTARG *pvargSrc
/// );
/// ```
/// {@category oleaut32}
int VariantCopy(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvargSrc) =>
    _VariantCopy(pvargDest, pvargSrc);

final _VariantCopy = _oleaut32.lookupFunction<
    Int32 Function(Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvargSrc),
    int Function(
        Pointer<VARIANT> pvargDest, Pointer<VARIANT> pvargSrc)>('VariantCopy');

/// Initializes a variant.
///
/// ```c
/// void VariantInit(
///   VARIANTARG *pvarg
/// );
/// ```
/// {@category oleaut32}
void VariantInit(Pointer<VARIANT> pvarg) => _VariantInit(pvarg);

final _VariantInit = _oleaut32.lookupFunction<
    Void Function(Pointer<VARIANT> pvarg),
    void Function(Pointer<VARIANT> pvarg)>('VariantInit');

/// Converts the variant representation of a date and time to MS-DOS date
/// and time values.
///
/// ```c
/// INT VariantTimeToDosDateTime(
///   DOUBLE vtime,
///   USHORT *pwDosDate,
///   USHORT *pwDosTime
/// );
/// ```
/// {@category oleaut32}
int VariantTimeToDosDateTime(
        double vtime, Pointer<Uint16> pwDosDate, Pointer<Uint16> pwDosTime) =>
    _VariantTimeToDosDateTime(vtime, pwDosDate, pwDosTime);

final _VariantTimeToDosDateTime = _oleaut32.lookupFunction<
    Int32 Function(
        Double vtime, Pointer<Uint16> pwDosDate, Pointer<Uint16> pwDosTime),
    int Function(double vtime, Pointer<Uint16> pwDosDate,
        Pointer<Uint16> pwDosTime)>('VariantTimeToDosDateTime');

/// Converts the variant representation of time to system time values.
///
/// ```c
/// INT VariantTimeToSystemTime(
///   DOUBLE       vtime,
///   LPSYSTEMTIME lpSystemTime
/// );
/// ```
/// {@category oleaut32}
int VariantTimeToSystemTime(double vtime, Pointer<SYSTEMTIME> lpSystemTime) =>
    _VariantTimeToSystemTime(vtime, lpSystemTime);

final _VariantTimeToSystemTime = _oleaut32.lookupFunction<
    Int32 Function(Double vtime, Pointer<SYSTEMTIME> lpSystemTime),
    int Function(double vtime,
        Pointer<SYSTEMTIME> lpSystemTime)>('VariantTimeToSystemTime');
