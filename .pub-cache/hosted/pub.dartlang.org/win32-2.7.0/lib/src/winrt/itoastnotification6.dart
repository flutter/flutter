// itoastnotification6.dart

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
const IID_IToastNotification6 = '{43EBFE53-89AE-5C1E-A279-3AECFE9B6F54}';

/// {@category Interface}
/// {@category winrt}
class IToastNotification6 extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IToastNotification6(super.ptr);

  late final Pointer<COMObject> _thisPtr = toInterface(IID_IToastNotification6);

  bool get ExpiresOnReboot {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = _thisPtr.ref.vtable
          .elementAt(6)
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

  set ExpiresOnReboot(bool value) {
    final hr = _thisPtr.ref.vtable
        .elementAt(7)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Bool)>>>()
        .value
        .asFunction<int Function(Pointer, bool)>()(_thisPtr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
