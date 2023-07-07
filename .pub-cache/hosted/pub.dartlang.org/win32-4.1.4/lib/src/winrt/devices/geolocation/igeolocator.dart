// igeolocator.dart

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
import '../../internal/async_helpers.dart';
import '../../internal/hstring_array.dart';
import 'enums.g.dart';
import 'geolocator.dart';
import 'geoposition.dart';

/// @nodoc
const IID_IGeolocator = '{a9c3bf62-4524-4989-8aa9-de019d2e551f}';

/// {@category Interface}
/// {@category winrt}
class IGeolocator extends IInspectable {
  // vtable begins at 6, is 13 entries long.
  IGeolocator.fromRawPointer(super.ptr);

  factory IGeolocator.from(IInspectable interface) =>
      IGeolocator.fromRawPointer(interface.toInterface(IID_IGeolocator));

  PositionAccuracy get desiredAccuracy {
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

      return PositionAccuracy.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  set desiredAccuracy(PositionAccuracy value) {
    final hr = ptr.ref.vtable
        .elementAt(7)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, value.value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  double get movementThreshold {
    final retValuePtr = calloc<Double>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Double>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Double>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set movementThreshold(double value) {
    final hr = ptr.ref.vtable
        .elementAt(9)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Double)>>>()
        .value
        .asFunction<int Function(Pointer, double)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get reportInterval {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set reportInterval(int value) {
    final hr = ptr.ref.vtable
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Uint32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  PositionStatus get locationStatus {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PositionStatus.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  Future<Geoposition?> getGeopositionAsync() {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<Geoposition?>();

    final hr = ptr.ref.vtable
            .elementAt(13)
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

    final asyncOperation = IAsyncOperation<Geoposition?>.fromRawPointer(
        retValuePtr,
        creator: Geoposition.fromRawPointer);
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }

  Future<Geoposition?> getGeopositionAsyncWithAgeAndTimeout(
      Duration maximumAge, Duration timeout) {
    final retValuePtr = calloc<COMObject>();
    final completer = Completer<Geoposition?>();
    final maximumAgeDuration = maximumAge.inMicroseconds * 10;
    final timeoutDuration = timeout.inMicroseconds * 10;

    final hr =
        ptr.ref.vtable
                .elementAt(14)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(Pointer, Uint64 maximumAge,
                                Uint64 timeout, Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, int maximumAge, int timeout,
                        Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, maximumAgeDuration, timeoutDuration, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    final asyncOperation = IAsyncOperation<Geoposition?>.fromRawPointer(
        retValuePtr,
        creator: Geoposition.fromRawPointer);
    completeAsyncOperation(
        asyncOperation, completer, asyncOperation.getResults);

    return completer.future;
  }

  int add_PositionChanged(Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(15)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_PositionChanged(int token) {
    final hr = ptr.ref.vtable
        .elementAt(16)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int add_StatusChanged(Pointer<NativeFunction<TypedEventHandler>> handler) {
    final retValuePtr = calloc<IntPtr>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(
                          Pointer,
                          Pointer<NativeFunction<TypedEventHandler>> handler,
                          Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<NativeFunction<TypedEventHandler>> handler,
                  Pointer<IntPtr>)>()(ptr.ref.lpVtbl, handler, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  void remove_StatusChanged(int token) {
    final hr = ptr.ref.vtable
        .elementAt(18)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, IntPtr token)>>>()
        .value
        .asFunction<int Function(Pointer, int token)>()(ptr.ref.lpVtbl, token);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}
