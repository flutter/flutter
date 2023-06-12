// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of COM variant structs used in the Win32 API.

// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'com/idispatch.dart';
import 'com/iunknown.dart';
import 'combase.dart';
import 'constants.dart';
import 'structs.g.dart';

// struct tagVARIANT
//    {
//        VARTYPE vt;
//        WORD wReserved1;
//        WORD wReserved2;
//        WORD wReserved3;
//        union
//            {
//            LONGLONG llVal;
//            LONG lVal;
//            BYTE bVal;
//            SHORT iVal;
//            ...
//    } ;

class _VARIANT_Anonymous_3 extends Struct {
  external Pointer pvRecord;
  external Pointer<COMObject> pRecInfo;
}

class _VARIANT_Anonymous_2 extends Union {
  @Int64()
  external int llVal;
  @Int32()
  external int lVal;
  @Uint8()
  external int bVal;
  @Int16()
  external int iVal;
  @Float()
  external double fltVal;
  @Double()
  external double dblVal;
  @Int16()
  external int boolVal;
  @Int16()
  // ignore: unused_field
  external int __OBSOLETE__VARIANT_BOOL;
  @Int32()
  external int scode;
  @Int64()
  external int cyVal;
  @Double()
  external double date;
  external Pointer<Utf16> bstrVal;
  external Pointer<COMObject> punkVal;
  external Pointer<COMObject> pdispVal;
  external Pointer/*<SAFEARRAY>*/ parray;
  external Pointer<Uint8> pbVal;
  external Pointer<Int16> piVal;
  external Pointer<Int32> plVal;
  external Pointer<Int64> pllVal;
  external Pointer<Float> pfltVal;
  external Pointer<Double> pdblVal;
  external Pointer<Int16> pboolVal;
  // ignore: unused_field
  external Pointer<Int16> __OBSOLETE__VARIANT_PBOOL;
  external Pointer<Int32> pscode;
  external Pointer/*<CY>*/ pcyVal;
  external Pointer<Double> pdate;
  external Pointer<Pointer<Utf16>> pbstrVal;
  external Pointer<Pointer<COMObject>> ppunkVal;
  external Pointer<Pointer<COMObject>> ppdispVal;
  external Pointer<Pointer/*<SAFEARRAY>*/ > pparray;
  external Pointer<VARIANT> pvarVal;
  external Pointer byref;
  @Int8()
  external int cVal;
  @Uint16()
  external int uiVal;
  @Uint32()
  external int ulVal;
  @Uint64()
  external int ullVal;
  @Int32()
  external int intVal;
  @Uint32()
  external int uintVal;
  external Pointer<DECIMAL> pdecVal;
  external Pointer<Int8> pcVal;
  external Pointer<Uint16> puiVal;
  external Pointer<Uint32> pulVal;
  external Pointer<Uint64> pullVal;
  external Pointer<Int32> pintVal;
  external Pointer<Uint32> puintVal;
  external _VARIANT_Anonymous_3 __VARIANT_NAME_4;
}

class _VARIANT_Anonymous_1 extends Struct {
  @Uint16()
  external int vt;
  @Uint16()
  external int wReserved1;
  @Uint16()
  external int wReserved2;
  @Uint16()
  external int wReserved3;
  external _VARIANT_Anonymous_2 __VARIANT_NAME_3;
}

class _VARIANT_Anonymous_0 extends Union {
  external _VARIANT_Anonymous_1 __VARIANT_NAME_2;
  external DECIMAL decVal;
}

/// The VARIANT type is used in Win32 to represent a dynamic type. It is
/// represented as a struct containing a union of the types that could be
/// stored.
///
/// VARIANTs must be initialized with [VariantInit] before their use.
///
/// {@category Struct}
class VARIANT extends Struct {
  external _VARIANT_Anonymous_0 __VARIANT_NAME_1;

  int get vt => __VARIANT_NAME_1.__VARIANT_NAME_2.vt;
  set vt(int value) => __VARIANT_NAME_1.__VARIANT_NAME_2.vt = value;

  int get wReserved1 => __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved1;
  set wReserved1(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved1 = value;

  int get wReserved2 => __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved2;
  set wReserved2(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved2 = value;

  int get wReserved3 => __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved3;
  set wReserved3(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.wReserved3 = value;

  // LONGLONG -> __int64 -> Int64
  int get llVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.llVal;
  set llVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.llVal = value;

  // LONG -> long -> Int32
  int get lVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.lVal;
  set lVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.lVal = value;

  // BYTE -> unsigned char -> Uint8
  int get bVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.bVal;
  set bVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.bVal = value;

  // SHORT -> short -> Int16
  int get iVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.iVal;
  set iVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.iVal = value;

  // FLOAT -> float -> double
  double get fltVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.fltVal;
  set fltVal(double value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.fltVal = value;

  // DOUBLE -> double -> double
  double get dblVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.dblVal;
  set dblVal(double value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.dblVal = value;

  // VARIANT_BOOL -> Int16
  bool get boolVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.boolVal ==
      VARIANT_TRUE;
  set boolVal(bool value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.boolVal =
          value ? VARIANT_TRUE : VARIANT_FALSE;

  // SCODE -> LONG -> long -> Int32
  int get scode => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.scode;
  set lscodeVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.scode = value;

  // CY -> Int64
  int get cyVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.cyVal;
  set cyVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.cyVal = value;

  // DATE -> double -> double
  double get date => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.date;
  set date(double value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.date = value;

  // BSTR -> OLECHAR* -> Pointer<Utf16>
  Pointer<Utf16> get bstrVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.bstrVal;
  set bstrVal(Pointer<Utf16> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.bstrVal = value;

  // IUnknown
  IUnknown get punkVal =>
      IUnknown(__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.punkVal);
  set punkVal(IUnknown value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.punkVal = value.ptr;

  // IDispatch
  IDispatch get pdispVal =>
      IDispatch(__VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdispVal);
  set pdispVal(IDispatch value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdispVal = value.ptr;

  Pointer get parray =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.parray;
  set parray(Pointer value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.parray = value;

  // BYTE*
  Pointer<Uint8> get pbVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pbVal;
  set pbVal(Pointer<Uint8> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pbVal = value;

  // SHORT*
  Pointer<Int16> get piVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.piVal;
  set piVal(Pointer<Int16> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.piVal = value;

  // LONG*
  Pointer<Int32> get plVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.plVal;
  set plVal(Pointer<Int32> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.plVal = value;

  // LONGLONG*
  Pointer<Int64> get pllVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pllVal;
  set pllVal(Pointer<Int64> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pllVal = value;

  // FLOAT*
  Pointer<Float> get pfltVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pfltVal;
  set pfltVal(Pointer<Float> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pfltVal = value;

  // DOUBLE*
  Pointer<Double> get pdblVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdblVal;
  set pdblVal(Pointer<Double> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdblVal = value;

  Pointer<Int16> get pboolVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pboolVal;
  set pboolVal(Pointer<Int16> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pboolVal = value;

  Pointer<Int32> get pscode =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pscode;
  set pscode(Pointer<Int32> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pscode = value;

  Pointer get pcyVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pcyVal;
  set pcyVal(Pointer value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pcyVal = value;

  Pointer<Double> get pdate =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdate;
  set pdate(Pointer<Double> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdate = value;

  Pointer<Pointer<Utf16>> get pbstrVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pbstrVal;
  set pbstrVal(Pointer<Pointer<Utf16>> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pbstrVal = value;

  Pointer<Pointer<COMObject>> get ppunkVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ppunkVal;
  set ppunkVal(Pointer<Pointer<COMObject>> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ppunkVal = value;

  Pointer<Pointer<COMObject>> get ppdispVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ppdispVal;
  set ppdispVal(Pointer<Pointer<COMObject>> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ppdispVal = value;

  Pointer<Pointer> get pparray =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pparray;
  set pparray(Pointer<Pointer> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pparray = value;

  Pointer<VARIANT> get pvarVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pvarVal;
  set pvarVal(Pointer<VARIANT> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pvarVal = value;

  Pointer get byref => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.byref;
  set byref(Pointer value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.byref = value;

  // CHAR -> char -> Int8
  int get cVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.cVal;
  set cVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.cVal = value;

  // USHORT -> unsigned short -> Uint16
  int get uiVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.uiVal;
  set uiVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.uiVal = value;

  // ULONG -> unsigned long -> Uint32
  int get ulVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ulVal;
  set ulVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ulVal = value;

  // ULONGLONG -> unsigned long long -> Uint64
  BigInt get ullVal {
    final src = __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ullVal;
    final hi = (((src & 0xFFFFFFFF00000000) >> 32).toUnsigned(32))
        .toRadixString(16)
        .padLeft(8, '0');
    final lo = (src & 0x00000000FFFFFFFF).toRadixString(16).padLeft(8, '0');
    return BigInt.parse('$hi$lo', radix: 16);
  }

  set ullVal(BigInt value) {
    final hi = ((value & BigInt.from(0xFFFFFFFF00000000)) >> 32).toInt();
    final lo = (value & BigInt.from(0x00000000FFFFFFFF)).toInt();
    __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.ullVal = (hi << 32) + lo;
  }

  // INT -> int -> Int32
  int get intVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.intVal;
  set intVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.intVal = value;

  // UINT -> unsigned int -> Uint32
  int get uintVal => __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.uintVal;
  set uintVal(int value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.uintVal = value;

  Pointer<DECIMAL> get pdecVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdecVal;
  set pdecVal(Pointer<DECIMAL> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pdecVal = value;

  Pointer<Int8> get pcVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pcVal;
  set pcVal(Pointer<Int8> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pcVal = value;

  Pointer<Uint16> get puiVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.puiVal;
  set puiVal(Pointer<Uint16> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.puiVal = value;

  Pointer<Uint32> get pulVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pulVal;
  set pulVal(Pointer<Uint32> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pulVal = value;

  Pointer<Uint64> get pullVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pullVal;
  set pullVal(Pointer<Uint64> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pullVal = value;

  Pointer<Int32> get pintVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pintVal;
  set pintVal(Pointer<Int32> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.pintVal = value;

  Pointer<Uint32> get puintVal =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.puintVal;
  set puintVal(Pointer<Uint32> value) =>
      __VARIANT_NAME_1.__VARIANT_NAME_2.__VARIANT_NAME_3.puintVal = value;

  Pointer get pvRecord => __VARIANT_NAME_1
      .__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pvRecord;
  set pvRecord(Pointer value) => __VARIANT_NAME_1
      .__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pvRecord = value;

  Pointer<COMObject> get pRecInfo => __VARIANT_NAME_1
      .__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pRecInfo;
  set pRecInfo(Pointer<COMObject> value) => __VARIANT_NAME_1
      .__VARIANT_NAME_2.__VARIANT_NAME_3.__VARIANT_NAME_4.pRecInfo = value;
}

/// The PROPVARIANT structure is used in the ReadMultiple and WriteMultiple
/// methods of IPropertyStorage to define the type tag and the value of a
/// property in a property set.
///
/// {@category Struct}
class PROPVARIANT extends Struct {
  @Uint16()
  external int vt;
  @Uint16()
  external int wReserved1;
  @Uint16()
  external int wReserved2;
  @Uint16()
  external int wReserved3;
  @IntPtr()
  external int val1;
  @IntPtr()
  external int val2;
}
