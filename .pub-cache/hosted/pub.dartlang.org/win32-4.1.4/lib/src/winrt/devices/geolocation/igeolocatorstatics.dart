// igeolocatorstatics.dart

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
import '../../foundation/collections/ivectorview.dart';
import '../../foundation/iasyncoperation.dart';
import '../../internal/async_helpers.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'geoposition.dart';

/// @nodoc
const IID_IGeolocatorStatics = '{9a8e7571-2df5-4591-9f87-eb5fd894e9b7}';

/// {@category Interface}
/// {@category winrt}
class IGeolocatorStatics extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IGeolocatorStatics.fromRawPointer(super.ptr);

  factory IGeolocatorStatics.from(IInspectable interface) =>
      IGeolocatorStatics.fromRawPointer(
          interface.toInterface(IID_IGeolocatorStatics));

  Future<GeolocationAccessStatus> requestAccessAsync() {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<GeolocationAccessStatus>();

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

    final asyncOperation =
        IAsyncOperation<GeolocationAccessStatus>.fromRawPointer(retValuePtr,
            enumCreator: GeolocationAccessStatus.from, intType: Int32);
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }

  Future<List<Geoposition>> getGeopositionHistoryAsync(DateTime startTime) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<List<Geoposition>>();
    final startTimeDateTime =
        startTime.difference(DateTime.utc(1601, 01, 01)).inMicroseconds * 10;

    final hr = ptr.ref.vtable
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, Uint64 startTime, Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(Pointer, int startTime, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, startTimeDateTime, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncOperation =
        IAsyncOperation<IVectorView<Geoposition>>.fromRawPointer(
            retValuePtr,
            creator: (Pointer<COMObject> ptr) => IVectorView.fromRawPointer(ptr,
                creator: Geoposition.fromRawPointer,
                iterableIid: '{135ed72d-75b1-5881-be41-6ffeaa202044}'));
    completeAsyncOperation(
        asyncOperation, completer, () => asyncOperation.getResults().toList());

    return completer.future;
  }

  Future<List<Geoposition>> getGeopositionHistoryWithDurationAsync(
      DateTime startTime, Duration duration) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<List<Geoposition>>();
    final startTimeDateTime =
        startTime.difference(DateTime.utc(1601, 01, 01)).inMicroseconds * 10;
    final durationDuration = duration.inMicroseconds * 10;

    final hr =
        ptr.ref.vtable
                .elementAt(8)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Uint64 startTime,
                                Uint64 duration, Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, int startTime, int duration,
                        Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, startTimeDateTime, durationDuration, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncOperation =
        IAsyncOperation<IVectorView<Geoposition>>.fromRawPointer(
            retValuePtr,
            creator: (Pointer<COMObject> ptr) => IVectorView.fromRawPointer(ptr,
                creator: Geoposition.fromRawPointer,
                iterableIid: '{135ed72d-75b1-5881-be41-6ffeaa202044}'));
    completeAsyncOperation(
        asyncOperation, completer, () => asyncOperation.getResults().toList());

    return completer.future;
  }
}
