// geopoint.dart

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
import 'enums.g.dart';
import 'igeopoint.dart';
import 'igeopointfactory.dart';
import 'igeoshape.dart';
import 'structs.g.dart';

/// Describes a geographic point.
///
/// {@category Class}
/// {@category winrt}
class Geopoint extends IInspectable implements IGeopoint, IGeoshape {
  Geopoint.fromRawPointer(super.ptr);

  static const _className = 'Windows.Devices.Geolocation.Geopoint';

  // IGeopointFactory methods
  static Geopoint create(BasicGeoposition position) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeopointFactory);
    final object = IGeopointFactory.fromRawPointer(activationFactoryPtr);

    try {
      return object.create(position);
    } finally {
      object.release();
    }
  }

  static Geopoint createWithAltitudeReferenceSystem(BasicGeoposition position,
      AltitudeReferenceSystem altitudeReferenceSystem) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeopointFactory);
    final object = IGeopointFactory.fromRawPointer(activationFactoryPtr);

    try {
      return object.createWithAltitudeReferenceSystem(
          position, altitudeReferenceSystem);
    } finally {
      object.release();
    }
  }

  static Geopoint createWithAltitudeReferenceSystemAndSpatialReferenceId(
      BasicGeoposition position,
      AltitudeReferenceSystem altitudeReferenceSystem,
      int spatialReferenceId) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeopointFactory);
    final object = IGeopointFactory.fromRawPointer(activationFactoryPtr);

    try {
      return object.createWithAltitudeReferenceSystemAndSpatialReferenceId(
          position, altitudeReferenceSystem, spatialReferenceId);
    } finally {
      object.release();
    }
  }

  // IGeopoint methods
  late final _iGeopoint = IGeopoint.from(this);

  @override
  BasicGeoposition get position => _iGeopoint.position;

  // IGeoshape methods
  late final _iGeoshape = IGeoshape.from(this);

  @override
  GeoshapeType get geoshapeType => _iGeoshape.geoshapeType;

  @override
  int get spatialReferenceId => _iGeoshape.spatialReferenceId;

  @override
  AltitudeReferenceSystem get altitudeReferenceSystem =>
      _iGeoshape.altitudeReferenceSystem;
}
