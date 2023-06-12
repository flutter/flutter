// ifileopenpicker.dart

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
const IID_IFileOpenPicker = '{2CA8278A-12C5-4C5F-8977-94547793C241}';

/// {@category Interface}
/// {@category winrt}
class IFileOpenPicker extends IInspectable {
  // vtable begins at 6, is 11 entries long.
  IFileOpenPicker(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_IFileOpenPicker);

  int get ViewMode {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(6)
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

  set ViewMode(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(7)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String get SettingsIdentifier {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(8)
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

  set SettingsIdentifier(String value) {
    final hstr = convertToHString(value);

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(9)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, hstr);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hstr);
    }
  }

  int get SuggestedStartLocation {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(10)
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

  set SuggestedStartLocation(int value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  String get CommitButtonText {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(12)
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

  set CommitButtonText(String value) {
    final hstr = convertToHString(value);

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(13)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(_thisPtr.ref.lpVtbl, hstr);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hstr);
    }
  }

  IVector<String> get FileTypeFilter {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(14)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        _thisPtr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return IVector(retValuePtr);
  }

  Pointer<COMObject> PickSingleFileAsync() {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(15)
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

  Pointer<COMObject> PickMultipleFilesAsync() {
    final retValuePtr = calloc<COMObject>();

    final hr = _thisPtr.ref.vtable
            .elementAt(16)
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
}
