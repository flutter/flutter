// igeolocatorstatics2.dart

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
import 'structs.g.dart';

/// @nodoc
const IID_IGeolocatorStatics2 = '{993011a2-fa1c-4631-a71d-0dbeb1250d9c}';

/// {@category Interface}
/// {@category winrt}
class IGeolocatorStatics2 extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IGeolocatorStatics2.fromRawPointer(super.ptr);

  factory IGeolocatorStatics2.from(IInspectable interface) =>
      IGeolocatorStatics2.fromRawPointer(
          interface.toInterface(IID_IGeolocatorStatics2));

  bool get isDefaultGeopositionRecommended {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set defaultGeoposition(BasicGeoposition? value) {
    final referencePtr = value == null
        ? calloc<COMObject>()
        : boxValue(value, convertToIReference: true);

    final hr = ptr.ref.vtable
        .elementAt(7)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, COMObject)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, COMObject)>()(ptr.ref.lpVtbl, referencePtr.ref);

    if (FAILED(hr)) throw WindowsException(hr);

    if (value == null) free(referencePtr);
  }

  BasicGeoposition? get defaultGeoposition {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
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

    final reference = IReference<BasicGeoposition>.fromRawPointer(retValuePtr,
        referenceIid: '{e4d5dda6-f57c-57cc-b67f-2939a901dabe}');
    final value = reference.value;
    reference.release();

    return value;
  }
}
