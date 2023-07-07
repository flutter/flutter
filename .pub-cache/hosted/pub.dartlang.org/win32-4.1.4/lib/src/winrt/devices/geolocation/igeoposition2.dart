// igeoposition2.dart

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
import 'civicaddress.dart';
import 'geocoordinate.dart';
import 'igeoposition.dart';
import 'venuedata.dart';

/// @nodoc
const IID_IGeoposition2 = '{7f62f697-8671-4b0d-86f8-474a8496187c}';

/// {@category Interface}
/// {@category winrt}
class IGeoposition2 extends IInspectable implements IGeoposition {
  // vtable begins at 6, is 1 entries long.
  IGeoposition2.fromRawPointer(super.ptr);

  factory IGeoposition2.from(IInspectable interface) =>
      IGeoposition2.fromRawPointer(interface.toInterface(IID_IGeoposition2));

  VenueData? get venueData {
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

    return VenueData.fromRawPointer(retValuePtr);
  }

  // IGeoposition methods
  late final _iGeoposition = IGeoposition.from(this);

  @override
  Geocoordinate? get coordinate => _iGeoposition.coordinate;

  @override
  CivicAddress? get civicAddress => _iGeoposition.civicAddress;
}
