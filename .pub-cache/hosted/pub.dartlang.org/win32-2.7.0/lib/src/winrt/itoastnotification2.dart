// itoastnotification2.dart

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
const IID_IToastNotification2 = '{9DFB9FD1-143A-490E-90BF-B9FBA7132DE7}';

/// {@category Interface}
/// {@category winrt}
class IToastNotification2 extends IInspectable {
  // vtable begins at 6, is 6 entries long.
  IToastNotification2(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_IToastNotification2);

  set Tag(String value) {
    final hstr = convertToHString(value);

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(6)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, hstr);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hstr);
    }
  }

  String get Tag {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  set Group(String value) {
    final hstr = convertToHString(value);

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(8)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, hstr);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hstr);
    }
  }

  String get Group {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<IntPtr>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  set SuppressPopup(bool value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(10)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Bool)>>>()
        .value
        .asFunction<int Function(Pointer, bool)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  bool get SuppressPopup {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(_thisPtr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }
}
