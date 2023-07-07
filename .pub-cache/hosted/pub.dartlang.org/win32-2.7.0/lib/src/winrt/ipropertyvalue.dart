// IPropertyValue.dart

// ignore_for_file: unused_import, directives_ordering, camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../com/iinspectable.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';
import '../winrt_constants.dart';

/// @nodoc
const IID_IPropertyValue = '{4BD682DD-7554-40E9-9A9B-82654EDE7E62}';

typedef _get_Type_Native = Int32 Function(Pointer obj, Pointer<Uint32> value);
typedef _get_Type_Dart = int Function(Pointer obj, Pointer<Uint32> value);

typedef _get_IsNumericScalar_Native = Int32 Function(
    Pointer obj, Pointer< /* Boolean */ Uint8> value);
typedef _get_IsNumericScalar_Dart = int Function(
    Pointer obj, Pointer< /* Boolean */ Uint8> value);

typedef _GetUInt8_Native = Int32 Function(Pointer obj, Pointer<Uint8> result);
typedef _GetUInt8_Dart = int Function(Pointer obj, Pointer<Uint8> result);

typedef _GetInt16_Native = Int32 Function(Pointer obj, Pointer<Int16> result);
typedef _GetInt16_Dart = int Function(Pointer obj, Pointer<Int16> result);

typedef _GetUInt16_Native = Int32 Function(Pointer obj, Pointer<Uint16> result);
typedef _GetUInt16_Dart = int Function(Pointer obj, Pointer<Uint16> result);

typedef _GetInt32_Native = Int32 Function(Pointer obj, Pointer<Int32> result);
typedef _GetInt32_Dart = int Function(Pointer obj, Pointer<Int32> result);

typedef _GetUInt32_Native = Int32 Function(Pointer obj, Pointer<Uint32> result);
typedef _GetUInt32_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetInt64_Native = Int32 Function(Pointer obj, Pointer<Int64> result);
typedef _GetInt64_Dart = int Function(Pointer obj, Pointer<Int64> result);

typedef _GetUInt64_Native = Int32 Function(Pointer obj, Pointer<Uint64> result);
typedef _GetUInt64_Dart = int Function(Pointer obj, Pointer<Uint64> result);

typedef _GetSingle_Native = Int32 Function(Pointer obj, Pointer<Float> result);
typedef _GetSingle_Dart = int Function(Pointer obj, Pointer<Float> result);

typedef _GetDouble_Native = Int32 Function(Pointer obj, Pointer<Double> result);
typedef _GetDouble_Dart = int Function(Pointer obj, Pointer<Double> result);

typedef _GetChar16_Native = Int32 Function(Pointer obj, Pointer<Uint16> result);
typedef _GetChar16_Dart = int Function(Pointer obj, Pointer<Uint16> result);

typedef _GetBoolean_Native = Int32 Function(
    Pointer obj, Pointer< /* Boolean */ Uint8> result);
typedef _GetBoolean_Dart = int Function(
    Pointer obj, Pointer< /* Boolean */ Uint8> result);

typedef _GetString_Native = Int32 Function(Pointer obj, Pointer<IntPtr> result);
typedef _GetString_Dart = int Function(Pointer obj, Pointer<IntPtr> result);

typedef _GetGuid_Native = Int32 Function(Pointer obj, Pointer<GUID> result);
typedef _GetGuid_Dart = int Function(Pointer obj, Pointer<GUID> result);

typedef _GetDateTime_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> result);
typedef _GetDateTime_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetTimeSpan_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> result);
typedef _GetTimeSpan_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetPoint_Native = Int32 Function(Pointer obj, Pointer<Uint32> result);
typedef _GetPoint_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetSize_Native = Int32 Function(Pointer obj, Pointer<Uint32> result);
typedef _GetSize_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetRect_Native = Int32 Function(Pointer obj, Pointer<Uint32> result);
typedef _GetRect_Dart = int Function(Pointer obj, Pointer<Uint32> result);

typedef _GetUInt8Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint8> value);
typedef _GetUInt8Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint8> value);

typedef _GetInt16Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int16> value);
typedef _GetInt16Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int16> value);

typedef _GetUInt16Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint16> value);
typedef _GetUInt16Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint16> value);

typedef _GetInt32Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int32> value);
typedef _GetInt32Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int32> value);

typedef _GetUInt32Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetUInt32Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

typedef _GetInt64Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int64> value);
typedef _GetInt64Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Int64> value);

typedef _GetUInt64Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint64> value);
typedef _GetUInt64Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint64> value);

typedef _GetSingleArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Float> value);
typedef _GetSingleArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Float> value);

typedef _GetDoubleArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Double> value);
typedef _GetDoubleArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Double> value);

typedef _GetChar16Array_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint16> value);
typedef _GetChar16Array_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint16> value);

typedef _GetBooleanArray_Native = Int32 Function(Pointer obj,
    Pointer<Uint32> __valueSize, Pointer< /* Boolean */ Uint8> value);
typedef _GetBooleanArray_Dart = int Function(Pointer obj,
    Pointer<Uint32> __valueSize, Pointer< /* Boolean */ Uint8> value);

typedef _GetStringArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<IntPtr> value);
typedef _GetStringArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<IntPtr> value);

typedef _GetInspectableArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<COMObject> value);
typedef _GetInspectableArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<COMObject> value);

typedef _GetGuidArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<GUID> value);
typedef _GetGuidArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<GUID> value);

typedef _GetDateTimeArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetDateTimeArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

typedef _GetTimeSpanArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetTimeSpanArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

typedef _GetPointArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetPointArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

typedef _GetSizeArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetSizeArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

typedef _GetRectArray_Native = Int32 Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);
typedef _GetRectArray_Dart = int Function(
    Pointer obj, Pointer<Uint32> __valueSize, Pointer<Uint32> value);

/// {@category Interface}
/// {@category winrt}
class IPropertyValue extends IInspectable {
  // vtable begins at 6, ends at 44

  IPropertyValue(super.ptr);

  int get Type {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<Pointer<NativeFunction<_get_Type_Native>>>()
          .value
          .asFunction<_get_Type_Dart>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  bool get IsNumericScalar {
    final retValuePtr = calloc< /* Boolean */ Uint8>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<Pointer<NativeFunction<_get_IsNumericScalar_Native>>>()
          .value
          .asFunction<_get_IsNumericScalar_Dart>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue == 0;
    } finally {
      free(retValuePtr);
    }
  }

  int GetUInt8(Pointer<Uint8> result) => ptr.ref.vtable
      .elementAt(8)
      .cast<Pointer<NativeFunction<_GetUInt8_Native>>>()
      .value
      .asFunction<_GetUInt8_Dart>()(ptr.ref.lpVtbl, result);

  int GetInt16(Pointer<Int16> result) => ptr.ref.vtable
      .elementAt(9)
      .cast<Pointer<NativeFunction<_GetInt16_Native>>>()
      .value
      .asFunction<_GetInt16_Dart>()(ptr.ref.lpVtbl, result);

  int GetUInt16(Pointer<Uint16> result) => ptr.ref.vtable
      .elementAt(10)
      .cast<Pointer<NativeFunction<_GetUInt16_Native>>>()
      .value
      .asFunction<_GetUInt16_Dart>()(ptr.ref.lpVtbl, result);

  int GetInt32(Pointer<Int32> result) => ptr.ref.vtable
      .elementAt(11)
      .cast<Pointer<NativeFunction<_GetInt32_Native>>>()
      .value
      .asFunction<_GetInt32_Dart>()(ptr.ref.lpVtbl, result);

  int GetUInt32(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(12)
      .cast<Pointer<NativeFunction<_GetUInt32_Native>>>()
      .value
      .asFunction<_GetUInt32_Dart>()(ptr.ref.lpVtbl, result);

  int GetInt64(Pointer<Int64> result) => ptr.ref.vtable
      .elementAt(13)
      .cast<Pointer<NativeFunction<_GetInt64_Native>>>()
      .value
      .asFunction<_GetInt64_Dart>()(ptr.ref.lpVtbl, result);

  int GetUInt64(Pointer<Uint64> result) => ptr.ref.vtable
      .elementAt(14)
      .cast<Pointer<NativeFunction<_GetUInt64_Native>>>()
      .value
      .asFunction<_GetUInt64_Dart>()(ptr.ref.lpVtbl, result);

  int GetSingle(Pointer<Float> result) => ptr.ref.vtable
      .elementAt(15)
      .cast<Pointer<NativeFunction<_GetSingle_Native>>>()
      .value
      .asFunction<_GetSingle_Dart>()(ptr.ref.lpVtbl, result);

  int GetDouble(Pointer<Double> result) => ptr.ref.vtable
      .elementAt(16)
      .cast<Pointer<NativeFunction<_GetDouble_Native>>>()
      .value
      .asFunction<_GetDouble_Dart>()(ptr.ref.lpVtbl, result);

  int GetChar16(Pointer<Uint16> result) => ptr.ref.vtable
      .elementAt(17)
      .cast<Pointer<NativeFunction<_GetChar16_Native>>>()
      .value
      .asFunction<_GetChar16_Dart>()(ptr.ref.lpVtbl, result);

  int GetBoolean(Pointer< /* Boolean */ Uint8> result) => ptr.ref.vtable
      .elementAt(18)
      .cast<Pointer<NativeFunction<_GetBoolean_Native>>>()
      .value
      .asFunction<_GetBoolean_Dart>()(ptr.ref.lpVtbl, result);

  int GetString(Pointer<IntPtr> result) => ptr.ref.vtable
      .elementAt(19)
      .cast<Pointer<NativeFunction<_GetString_Native>>>()
      .value
      .asFunction<_GetString_Dart>()(ptr.ref.lpVtbl, result);

  int GetGuid(Pointer<GUID> result) => ptr.ref.vtable
      .elementAt(20)
      .cast<Pointer<NativeFunction<_GetGuid_Native>>>()
      .value
      .asFunction<_GetGuid_Dart>()(ptr.ref.lpVtbl, result);

  int GetDateTime(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(21)
      .cast<Pointer<NativeFunction<_GetDateTime_Native>>>()
      .value
      .asFunction<_GetDateTime_Dart>()(ptr.ref.lpVtbl, result);

  int GetTimeSpan(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(22)
      .cast<Pointer<NativeFunction<_GetTimeSpan_Native>>>()
      .value
      .asFunction<_GetTimeSpan_Dart>()(ptr.ref.lpVtbl, result);

  int GetPoint(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(23)
      .cast<Pointer<NativeFunction<_GetPoint_Native>>>()
      .value
      .asFunction<_GetPoint_Dart>()(ptr.ref.lpVtbl, result);

  int GetSize(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(24)
      .cast<Pointer<NativeFunction<_GetSize_Native>>>()
      .value
      .asFunction<_GetSize_Dart>()(ptr.ref.lpVtbl, result);

  int GetRect(Pointer<Uint32> result) => ptr.ref.vtable
      .elementAt(25)
      .cast<Pointer<NativeFunction<_GetRect_Native>>>()
      .value
      .asFunction<_GetRect_Dart>()(ptr.ref.lpVtbl, result);

  int GetUInt8Array(Pointer<Uint32> __valueSize, Pointer<Uint8> value) => ptr
      .ref.lpVtbl.value
      .elementAt(26)
      .cast<Pointer<NativeFunction<_GetUInt8Array_Native>>>()
      .value
      .asFunction<_GetUInt8Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetInt16Array(Pointer<Uint32> __valueSize, Pointer<Int16> value) => ptr
      .ref.lpVtbl.value
      .elementAt(27)
      .cast<Pointer<NativeFunction<_GetInt16Array_Native>>>()
      .value
      .asFunction<_GetInt16Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetUInt16Array(Pointer<Uint32> __valueSize, Pointer<Uint16> value) => ptr
      .ref.lpVtbl.value
      .elementAt(28)
      .cast<Pointer<NativeFunction<_GetUInt16Array_Native>>>()
      .value
      .asFunction<_GetUInt16Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetInt32Array(Pointer<Uint32> __valueSize, Pointer<Int32> value) => ptr
      .ref.lpVtbl.value
      .elementAt(29)
      .cast<Pointer<NativeFunction<_GetInt32Array_Native>>>()
      .value
      .asFunction<_GetInt32Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetUInt32Array(Pointer<Uint32> __valueSize, Pointer<Uint32> value) => ptr
      .ref.lpVtbl.value
      .elementAt(30)
      .cast<Pointer<NativeFunction<_GetUInt32Array_Native>>>()
      .value
      .asFunction<_GetUInt32Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetInt64Array(Pointer<Uint32> __valueSize, Pointer<Int64> value) => ptr
      .ref.lpVtbl.value
      .elementAt(31)
      .cast<Pointer<NativeFunction<_GetInt64Array_Native>>>()
      .value
      .asFunction<_GetInt64Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetUInt64Array(Pointer<Uint32> __valueSize, Pointer<Uint64> value) => ptr
      .ref.lpVtbl.value
      .elementAt(32)
      .cast<Pointer<NativeFunction<_GetUInt64Array_Native>>>()
      .value
      .asFunction<_GetUInt64Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetSingleArray(Pointer<Uint32> __valueSize, Pointer<Float> value) => ptr
      .ref.lpVtbl.value
      .elementAt(33)
      .cast<Pointer<NativeFunction<_GetSingleArray_Native>>>()
      .value
      .asFunction<_GetSingleArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetDoubleArray(Pointer<Uint32> __valueSize, Pointer<Double> value) => ptr
      .ref.lpVtbl.value
      .elementAt(34)
      .cast<Pointer<NativeFunction<_GetDoubleArray_Native>>>()
      .value
      .asFunction<_GetDoubleArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetChar16Array(Pointer<Uint32> __valueSize, Pointer<Uint16> value) => ptr
      .ref.lpVtbl.value
      .elementAt(35)
      .cast<Pointer<NativeFunction<_GetChar16Array_Native>>>()
      .value
      .asFunction<_GetChar16Array_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetBooleanArray(
          Pointer<Uint32> __valueSize, Pointer< /* Boolean */ Uint8> value) =>
      ptr.ref.vtable
              .elementAt(36)
              .cast<Pointer<NativeFunction<_GetBooleanArray_Native>>>()
              .value
              .asFunction<_GetBooleanArray_Dart>()(
          ptr.ref.lpVtbl, __valueSize, value);

  int GetStringArray(Pointer<Uint32> __valueSize, Pointer<IntPtr> value) => ptr
      .ref.lpVtbl.value
      .elementAt(37)
      .cast<Pointer<NativeFunction<_GetStringArray_Native>>>()
      .value
      .asFunction<_GetStringArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetInspectableArray(
          Pointer<Uint32> __valueSize, Pointer<COMObject> value) =>
      ptr.ref.vtable
              .elementAt(38)
              .cast<Pointer<NativeFunction<_GetInspectableArray_Native>>>()
              .value
              .asFunction<_GetInspectableArray_Dart>()(
          ptr.ref.lpVtbl, __valueSize, value);

  int GetGuidArray(Pointer<Uint32> __valueSize, Pointer<GUID> value) =>
      ptr.ref.vtable
          .elementAt(39)
          .cast<Pointer<NativeFunction<_GetGuidArray_Native>>>()
          .value
          .asFunction<_GetGuidArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetDateTimeArray(Pointer<Uint32> __valueSize, Pointer<Uint32> value) =>
      ptr.ref.vtable
              .elementAt(40)
              .cast<Pointer<NativeFunction<_GetDateTimeArray_Native>>>()
              .value
              .asFunction<_GetDateTimeArray_Dart>()(
          ptr.ref.lpVtbl, __valueSize, value);

  int GetTimeSpanArray(Pointer<Uint32> __valueSize, Pointer<Uint32> value) =>
      ptr.ref.vtable
              .elementAt(41)
              .cast<Pointer<NativeFunction<_GetTimeSpanArray_Native>>>()
              .value
              .asFunction<_GetTimeSpanArray_Dart>()(
          ptr.ref.lpVtbl, __valueSize, value);

  int GetPointArray(Pointer<Uint32> __valueSize, Pointer<Uint32> value) => ptr
      .ref.lpVtbl.value
      .elementAt(42)
      .cast<Pointer<NativeFunction<_GetPointArray_Native>>>()
      .value
      .asFunction<_GetPointArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetSizeArray(Pointer<Uint32> __valueSize, Pointer<Uint32> value) =>
      ptr.ref.vtable
          .elementAt(43)
          .cast<Pointer<NativeFunction<_GetSizeArray_Native>>>()
          .value
          .asFunction<_GetSizeArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);

  int GetRectArray(Pointer<Uint32> __valueSize, Pointer<Uint32> value) =>
      ptr.ref.vtable
          .elementAt(44)
          .cast<Pointer<NativeFunction<_GetRectArray_Native>>>()
          .value
          .asFunction<_GetRectArray_Dart>()(ptr.ref.lpVtbl, __valueSize, value);
}
