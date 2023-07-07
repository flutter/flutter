// ijsonvaluestatics2.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../winrt/data/json/jsonvalue.dart';

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

    if (FAILED(hr)) throw WindowsException(hr);

    return JsonValue.fromRawPointer(retValuePtr);
  }
}
