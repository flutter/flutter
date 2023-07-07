// itoastnotification.dart

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
const IID_IToastNotification = '{997E2675-059E-4E60-8B06-1760917C8B80}';

/// {@category Interface}
/// {@category winrt}
class IToastNotification extends IInspectable {
  // vtable begins at 6, is 9 entries long.
  IToastNotification(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_IToastNotification);

  Pointer<COMObject> get Content {
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

  set ExpirationTime(Pointer<COMObject> value) {
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

  Pointer<COMObject> get ExpirationTime {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(8)
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

  void remove_Dismissed(int token) {
    final hr = _thisPtr.ref.vtable
        .elementAt(10)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<
            int Function(Pointer, int token)>()(_thisPtr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void remove_Activated(int token) {
    final hr = _thisPtr.ref.vtable
        .elementAt(12)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<
            int Function(Pointer, int token)>()(_thisPtr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void remove_Failed(int token) {
    final hr = _thisPtr.ref.vtable
        .elementAt(14)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<
            int Function(Pointer, int token)>()(_thisPtr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
