// ijsonvaluestatics2.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'jsonvalue.dart';
import '../../../com/iinspectable.dart';

/// @nodoc
const IID_IJsonValueStatics2 = '{1D9ECBE4-3FE8-4335-8392-93D8E36865F0}';

/// {@category Interface}
/// {@category winrt}
class IJsonValueStatics2 extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  IJsonValueStatics2.fromRawPointer(super.ptr);

  factory IJsonValueStatics2.from(IInspectable interface) =>
      IJsonValueStatics2.fromRawPointer(
          interface.toInterface(IID_IJsonValueStatics2));

  JsonValue createNullValue() {
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

    return JsonValue.fromRawPointer(retValuePtr);
  }
}
