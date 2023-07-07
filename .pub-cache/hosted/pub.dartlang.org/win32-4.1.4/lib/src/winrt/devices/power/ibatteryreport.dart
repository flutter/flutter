// ibatteryreport.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/ireference.dart';
import '../../internal/hstring_array.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import '../../system/power/enums.g.dart';

/// @nodoc
const IID_IBatteryReport = '{c9858c3a-4e13-420a-a8d0-24f18f395401}';

/// {@category Interface}
/// {@category winrt}
class IBatteryReport extends IInspectable {
  // vtable begins at 6, is 5 entries long.
  IBatteryReport.fromRawPointer(super.ptr);

  factory IBatteryReport.from(IInspectable interface) =>
      IBatteryReport.fromRawPointer(interface.toInterface(IID_IBatteryReport));

  int? get chargeRateInMilliwatts {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{548cefbd-bc8a-5fa0-8df2-957440fc8bf4}');
    final value = reference.value;
    reference.release();

    return value;
  }

  int? get designCapacityInMilliwattHours {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{548cefbd-bc8a-5fa0-8df2-957440fc8bf4}');
    final value = reference.value;
    reference.release();

    return value;
  }

  int? get fullChargeCapacityInMilliwattHours {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{548cefbd-bc8a-5fa0-8df2-957440fc8bf4}');
    final value = reference.value;
    reference.release();

    return value;
  }

  int? get remainingCapacityInMilliwattHours {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(9)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{548cefbd-bc8a-5fa0-8df2-957440fc8bf4}');
    final value = reference.value;
    reference.release();

    return value;
  }

  BatteryStatus get status {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return BatteryStatus.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }
}
