// itoastnotification4.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../api_ms_win_core_winrt_string_l1_1_0.dart';
import '../combase.dart';
import '../exceptions.dart';
import '../macros.dart';
import '../utils.dart';
import '../types.dart';
import '../winrt_helpers.dart';

import '../extensions/hstring_array.dart';
import 'ivector.dart';
import 'ivectorview.dart';

import '../com/iinspectable.dart';

/// @nodoc
const IID_IToastNotification4 = '{15154935-28EA-4727-88E9-C58680E2D118}';

/// {@category Interface}
/// {@category winrt}
class IToastNotification4 extends IInspectable {
  // vtable begins at 6, is 4 entries long.
  IToastNotification4(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_IToastNotification4);

  Pointer<COMObject> get Data {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr;
  }

  set Data(Pointer<COMObject> value) {
    final hr = _thisPtr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get Priority {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Priority(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(9)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
