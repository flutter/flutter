// geocoordinate.dart

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
import 'enums.g.dart';
import 'geocoordinatesatellitedata.dart';
import 'geopoint.dart';
import 'igeocoordinate.dart';
import 'igeocoordinatewithpoint.dart';
import 'igeocoordinatewithpositiondata.dart';
import 'igeocoordinatewithpositionsourcetimestamp.dart';
import 'igeocoordinatewithremotesource.dart';

/// Contains the information for identifying a geographic location.
///
/// {@category Class}
/// {@category winrt}
class Geocoordinate extends IInspectable
    implements
        IGeocoordinate,
        IGeocoordinateWithPositionData,
        IGeocoordinateWithPoint,
        IGeocoordinateWithPositionSourceTimestamp,
        IGeocoordinateWithRemoteSource {
  Geocoordinate.fromRawPointer(super.ptr);

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

  // IGeocoordinateWithPositionData methods
  late final _iGeocoordinateWithPositionData =
      IGeocoordinateWithPositionData.from(this);

  @override
  PositionSource get positionSource =>
      _iGeocoordinateWithPositionData.positionSource;

  @override
  GeocoordinateSatelliteData? get satelliteData =>
      _iGeocoordinateWithPositionData.satelliteData;

  // IGeocoordinateWithPoint methods
  late final _iGeocoordinateWithPoint = IGeocoordinateWithPoint.from(this);

  @override
  Geopoint? get point => _iGeocoordinateWithPoint.point;

  // IGeocoordinateWithPositionSourceTimestamp methods
  late final _iGeocoordinateWithPositionSourceTimestamp =
      IGeocoordinateWithPositionSourceTimestamp.from(this);

  @override
  DateTime? get positionSourceTimestamp =>
      _iGeocoordinateWithPositionSourceTimestamp.positionSourceTimestamp;

  // IGeocoordinateWithRemoteSource methods
  late final _iGeocoordinateWithRemoteSource =
      IGeocoordinateWithRemoteSource.from(this);

  @override
  bool get isRemoteSource => _iGeocoordinateWithRemoteSource.isRemoteSource;
}
