// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common enumerations used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: constant_identifier_names

import '../../foundation/winrt_enum.dart';

/// Indicates the altitude reference system to be used in defining a
/// geographic shape.
///
/// {@category Enum}
enum AltitudeReferenceSystem implements WinRTEnum {
  unspecified(0),
  terrain(1),
  ellipsoid(2),
  geoid(3),
  surface(4);

  @override
  final int value;

  const AltitudeReferenceSystem(this.value);

  factory AltitudeReferenceSystem.from(int value) =>
      AltitudeReferenceSystem.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates if your app has permission to access location data.
///
/// {@category Enum}
enum GeolocationAccessStatus implements WinRTEnum {
  unspecified(0),
  allowed(1),
  denied(2);

  @override
  final int value;

  const GeolocationAccessStatus(this.value);

  factory GeolocationAccessStatus.from(int value) =>
      GeolocationAccessStatus.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates the shape of a geographic region.
///
/// {@category Enum}
enum GeoshapeType implements WinRTEnum {
  geopoint(0),
  geocircle(1),
  geopath(2),
  geoboundingBox(3);

  @override
  final int value;

  const GeoshapeType(this.value);

  factory GeoshapeType.from(int value) =>
      GeoshapeType.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates the requested accuracy level for the location data that the
/// application uses.
///
/// {@category Enum}
enum PositionAccuracy implements WinRTEnum {
  default_(0),
  high(1);

  @override
  final int value;

  const PositionAccuracy(this.value);

  factory PositionAccuracy.from(int value) =>
      PositionAccuracy.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates the source used to obtain a Geocoordinate.
///
/// {@category Enum}
enum PositionSource implements WinRTEnum {
  cellular(0),
  satellite(1),
  wifi(2),
  ipAddress(3),
  unknown(4),
  default_(5),
  obfuscated(6);

  @override
  final int value;

  const PositionSource(this.value);

  factory PositionSource.from(int value) =>
      PositionSource.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}

/// Indicates the ability of the Geolocator object to provide location data.
///
/// {@category Enum}
enum PositionStatus implements WinRTEnum {
  ready(0),
  initializing(1),
  noData(2),
  disabled(3),
  notInitialized(4),
  notAvailable(5);

  @override
  final int value;

  const PositionStatus(this.value);

  factory PositionStatus.from(int value) =>
      PositionStatus.values.firstWhere((e) => e.value == value,
          orElse: () => throw ArgumentError.value(
              value, 'value', 'No enum value with that value'));
}
