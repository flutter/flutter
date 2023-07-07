// igeocoordinatewithpositiondata.dart

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
import 'enums.g.dart';
import 'geocoordinatesatellitedata.dart';
import 'igeocoordinate.dart';

/// @nodoc
const IID_IGeocoordinateWithPositionData =
    '{95e634be-dbd6-40ac-b8f2-a65c0340d9a6}';

/// {@category Interface}
/// {@category winrt}
class IGeocoordinateWithPositionData extends IInspectable
    implements IGeocoordinate {
  // vtable begins at 6, is 2 entries long.
  IGeocoordinateWithPositionData.fromRawPointer(super.ptr);

  factory IGeocoordinateWithPositionData.from(IInspectable interface) =>
      IGeocoordinateWithPositionData.fromRawPointer(
          interface.toInterface(IID_IGeocoordinateWithPositionData));

  PositionSource get positionSource {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PositionSource.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  GeocoordinateSatelliteData? get satelliteData {
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return GeocoordinateSatelliteData.fromRawPointer(retValuePtr);
  }

  // IGeocoordinate methods
  late final _iGeocoordinate = IGeocoordinate.from(this);

  @override
  double get latitude => _iGeocoordinate.latitude;

  @override
  double get longitude => _iGeocoordinate.longitude;

  @override
  double? get altitude => _iGeocoordinate.altitude;

  @override
  double get accuracy => _iGeocoordinate.accuracy;

  @override
  double? get altitudeAccuracy => _iGeocoordinate.altitudeAccuracy;

  @override
  double? get heading => _iGeocoordinate.heading;

  @override
  double? get speed => _iGeocoordinate.speed;

  @override
  DateTime get timestamp => _iGeocoordinate.timestamp;
}
