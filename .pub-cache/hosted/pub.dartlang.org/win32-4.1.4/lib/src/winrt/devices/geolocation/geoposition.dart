// geoposition.dart

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
import 'igeoposition2.dart';
import 'venuedata.dart';

/// Represents a location that may contain latitude and longitude data or
/// venue data.
///
/// {@category Class}
/// {@category winrt}
class Geoposition extends IInspectable implements IGeoposition, IGeoposition2 {
  Geoposition.fromRawPointer(super.ptr);

  // IGeoposition methods
  late final _iGeoposition = IGeoposition.from(this);

  @override
  Geocoordinate? get coordinate => _iGeoposition.coordinate;

  @override
  CivicAddress? get civicAddress => _iGeoposition.civicAddress;

  // IGeoposition2 methods
  late final _iGeoposition2 = IGeoposition2.from(this);

  @override
  VenueData? get venueData => _iGeoposition2.venueData;
}
