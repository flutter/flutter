// geolocator.dart

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
import '../../foundation/collections/ivectorview.dart';
import '../../foundation/iasyncoperation.dart';
import '../../foundation/ireference.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'geoposition.dart';
import 'igeolocator.dart';
import 'igeolocator2.dart';
import 'igeolocatorstatics.dart';
import 'igeolocatorstatics2.dart';
import 'igeolocatorwithscalaraccuracy.dart';
import 'structs.g.dart';

/// Provides access to the current geographic location.
///
/// {@category Class}
/// {@category winrt}
class Geolocator extends IInspectable
    implements IGeolocator, IGeolocatorWithScalarAccuracy, IGeolocator2 {
  Geolocator() : super(ActivateClass(_className));
  Geolocator.fromRawPointer(super.ptr);

  static const _className = 'Windows.Devices.Geolocation.Geolocator';

  // IGeolocatorStatics methods
  static Future<GeolocationAccessStatus> requestAccessAsync() {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics);
    final object = IGeolocatorStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.requestAccessAsync();
    } finally {
      object.release();
    }
  }

  static Future<List<Geoposition>> getGeopositionHistoryAsync(
      DateTime startTime) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics);
    final object = IGeolocatorStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getGeopositionHistoryAsync(startTime);
    } finally {
      object.release();
    }
  }

  static Future<List<Geoposition>> getGeopositionHistoryWithDurationAsync(
      DateTime startTime, Duration duration) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics);
    final object = IGeolocatorStatics.fromRawPointer(activationFactoryPtr);

    try {
      return object.getGeopositionHistoryWithDurationAsync(startTime, duration);
    } finally {
      object.release();
    }
  }

  // IGeolocatorStatics2 methods
  static bool get isDefaultGeopositionRecommended {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics2);
    final object = IGeolocatorStatics2.fromRawPointer(activationFactoryPtr);

    try {
      return object.isDefaultGeopositionRecommended;
    } finally {
      object.release();
    }
  }

  static set defaultGeoposition(BasicGeoposition? value) {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics2);
    final object = IGeolocatorStatics2.fromRawPointer(activationFactoryPtr);

    try {
      object.defaultGeoposition = value;
    } finally {
      object.release();
    }
  }

  static BasicGeoposition? get defaultGeoposition {
    final activationFactoryPtr =
        CreateActivationFactory(_className, IID_IGeolocatorStatics2);
    final object = IGeolocatorStatics2.fromRawPointer(activationFactoryPtr);

    try {
      return object.defaultGeoposition;
    } finally {
      object.release();
    }
  }

  // IGeolocator methods
  late final _iGeolocator = IGeolocator.from(this);

  @override
  PositionAccuracy get desiredAccuracy => _iGeolocator.desiredAccuracy;

  @override
  set desiredAccuracy(PositionAccuracy value) =>
      _iGeolocator.desiredAccuracy = value;

  @override
  double get movementThreshold => _iGeolocator.movementThreshold;

  @override
  set movementThreshold(double value) => _iGeolocator.movementThreshold = value;

  @override
  int get reportInterval => _iGeolocator.reportInterval;

  @override
  set reportInterval(int value) => _iGeolocator.reportInterval = value;

  @override
  PositionStatus get locationStatus => _iGeolocator.locationStatus;

  @override
  Future<Geoposition?> getGeopositionAsync() =>
      _iGeolocator.getGeopositionAsync();

  @override
  Future<Geoposition?> getGeopositionAsyncWithAgeAndTimeout(
          Duration maximumAge, Duration timeout) =>
      _iGeolocator.getGeopositionAsyncWithAgeAndTimeout(maximumAge, timeout);

  @override
  int add_PositionChanged(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iGeolocator.add_PositionChanged(handler);

  @override
  void remove_PositionChanged(int token) =>
      _iGeolocator.remove_PositionChanged(token);

  @override
  int add_StatusChanged(Pointer<NativeFunction<TypedEventHandler>> handler) =>
      _iGeolocator.add_StatusChanged(handler);

  @override
  void remove_StatusChanged(int token) =>
      _iGeolocator.remove_StatusChanged(token);

  // IGeolocatorWithScalarAccuracy methods
  late final _iGeolocatorWithScalarAccuracy =
      IGeolocatorWithScalarAccuracy.from(this);

  @override
  int? get desiredAccuracyInMeters =>
      _iGeolocatorWithScalarAccuracy.desiredAccuracyInMeters;

  @override
  set desiredAccuracyInMeters(int? value) =>
      _iGeolocatorWithScalarAccuracy.desiredAccuracyInMeters = value;

  // IGeolocator2 methods
  late final _iGeolocator2 = IGeolocator2.from(this);

  @override
  void allowFallbackToConsentlessPositions() =>
      _iGeolocator2.allowFallbackToConsentlessPositions();
}
