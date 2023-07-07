// igeocoordinatewithpositionsourcetimestamp.dart

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

/// @nodoc
const IID_IGeocoordinateWithPositionSourceTimestamp =
    '{8543fc02-c9f1-4610-afe0-8bc3a6a87036}';

/// {@category Interface}
/// {@category winrt}
class IGeocoordinateWithPositionSourceTimestamp extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IGeocoordinateWithPositionSourceTimestamp.fromRawPointer(super.ptr);

  factory IGeocoordinateWithPositionSourceTimestamp.from(
          IInspectable interface) =>
      IGeocoordinateWithPositionSourceTimestamp.fromRawPointer(
          interface.toInterface(IID_IGeocoordinateWithPositionSourceTimestamp));

  DateTime? get positionSourceTimestamp {
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

    final reference = IReference<DateTime>.fromRawPointer(retValuePtr,
        referenceIid: '{5541d8a7-497c-5aa4-86fc-7713adbf2a2c}');
    final value = reference.value;
    reference.release();

    return value;
  }
}
