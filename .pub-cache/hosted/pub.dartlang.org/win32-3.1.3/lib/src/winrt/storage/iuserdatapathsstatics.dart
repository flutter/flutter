// iuserdatapathsstatics.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';
import '../internal/hstring_array.dart';
import '../system/user.dart';
import 'userdatapaths.dart';

/// @nodoc
const IID_IUserDataPathsStatics = '{01b29def-e062-48a1-8b0c-f2c7a9ca56c0}';

/// {@category Interface}
/// {@category winrt}
class IUserDataPathsStatics extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  IUserDataPathsStatics.fromRawPointer(super.ptr);

  factory IUserDataPathsStatics.from(IInspectable interface) =>
      IUserDataPathsStatics.fromRawPointer(
          interface.toInterface(IID_IUserDataPathsStatics));

  UserDataPaths getForUser(User user) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject> user,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer, Pointer<COMObject> user, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, user.ptr.cast<Pointer<COMObject>>().value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return UserDataPaths.fromRawPointer(retValuePtr);
  }

  UserDataPaths getDefault() {
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

    return UserDataPaths.fromRawPointer(retValuePtr);
  }
}
