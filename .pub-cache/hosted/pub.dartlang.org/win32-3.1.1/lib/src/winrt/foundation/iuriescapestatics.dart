// iuriescapestatics.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import '../../com/iinspectable.dart';

/// @nodoc
const IID_IUriEscapeStatics = '{C1D432BA-C824-4452-A7FD-512BC3BBE9A1}';

/// {@category Interface}
/// {@category winrt}
class IUriEscapeStatics extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IUriEscapeStatics.fromRawPointer(super.ptr);

  factory IUriEscapeStatics.from(IInspectable interface) =>
      IUriEscapeStatics.fromRawPointer(
          interface.toInterface(IID_IUriEscapeStatics));

  String unescapeComponent(String toUnescape) {
    final retValuePtr = calloc<HSTRING>();
    final toUnescapeHstring = convertToHString(toUnescape);

    try {
      final hr = ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr toUnescape, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int toUnescape, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, toUnescapeHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(toUnescapeHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  String escapeComponent(String toEscape) {
    final retValuePtr = calloc<HSTRING>();
    final toEscapeHstring = convertToHString(toEscape);

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, IntPtr toEscape, Pointer<IntPtr>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int toEscape, Pointer<IntPtr>)>()(
          ptr.ref.lpVtbl, toEscapeHstring, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(toEscapeHstring);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }
}
