// ifileopenpicker3.dart

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
import '../../internal/hstring_array.dart';
import '../../system/user.dart';

/// @nodoc
const IID_IFileOpenPicker3 = '{d9a5c5b3-c5dc-5b98-bd80-a8d0ca0584d8}';

/// {@category Interface}
/// {@category winrt}
class IFileOpenPicker3 extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IFileOpenPicker3.fromRawPointer(super.ptr);

  factory IFileOpenPicker3.from(IInspectable interface) =>
      IFileOpenPicker3.fromRawPointer(
          interface.toInterface(IID_IFileOpenPicker3));

  User? get user {
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

    return User.fromRawPointer(retValuePtr);
  }
}
