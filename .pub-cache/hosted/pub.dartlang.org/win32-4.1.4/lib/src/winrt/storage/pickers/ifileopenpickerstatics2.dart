// ifileopenpickerstatics2.dart

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
import 'fileopenpicker.dart';

/// @nodoc
const IID_IFileOpenPickerStatics2 = '{e8917415-eddd-5c98-b6f3-366fdfcad392}';

/// {@category Interface}
/// {@category winrt}
class IFileOpenPickerStatics2 extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IFileOpenPickerStatics2.fromRawPointer(super.ptr);

  factory IFileOpenPickerStatics2.from(IInspectable interface) =>
      IFileOpenPickerStatics2.fromRawPointer(
          interface.toInterface(IID_IFileOpenPickerStatics2));

  FileOpenPicker? createForUser(User? user) {
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
        ptr.ref.lpVtbl,
        user == null ? nullptr : user.ptr.cast<Pointer<COMObject>>().value,
        retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return FileOpenPicker.fromRawPointer(retValuePtr);
  }
}
