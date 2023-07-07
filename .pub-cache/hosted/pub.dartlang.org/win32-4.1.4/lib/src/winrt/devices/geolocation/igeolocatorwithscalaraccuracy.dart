// igeolocatorwithscalaraccuracy.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
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
import '../../foundation/iasyncoperation.dart';
import '../../foundation/ireference.dart';
import '../../internal/async_helpers.dart';
import '../../internal/hstring_array.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import 'enums.g.dart';
import 'geolocator.dart';
import 'geoposition.dart';
import 'igeolocator.dart';

/// @nodoc
const IID_IGeolocatorWithScalarAccuracy =
    '{96f5d3c1-b80f-460a-994d-a96c47a51aa4}';

/// {@category Interface}
/// {@category winrt}
class IGeolocatorWithScalarAccuracy extends IInspectable
    implements IGeolocator {
  // vtable begins at 6, is 2 entries long.
  IGeolocatorWithScalarAccuracy.fromRawPointer(super.ptr);

  factory IGeolocatorWithScalarAccuracy.from(IInspectable interface) =>
      IGeolocatorWithScalarAccuracy.fromRawPointer(
          interface.toInterface(IID_IGeolocatorWithScalarAccuracy));

  int? get desiredAccuracyInMeters {
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

    final reference = IReference<int>.fromRawPointer(retValuePtr,
        referenceIid: '{513ef3af-e784-5325-a91e-97c2b8111cf3}');
    final value = reference.value;
    reference.release();

    return value;
  }

  set desiredAccuracyInMeters(int? value) {
    final referencePtr = value == null
        ? calloc<COMObject>()
        : boxValue(value, convertToIReference: true, nativeType: Uint32);

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
}
