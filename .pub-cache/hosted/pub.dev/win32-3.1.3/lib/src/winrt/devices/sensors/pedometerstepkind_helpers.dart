// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension methods that provide support for
// IKeyValuePair<PedometerStepKind, PedometerReading>, IMap<.., ..>, and
// IMapView<.., ..> types.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
import '../../foundation/collections/imapview.dart';
import 'enums.g.dart';
import 'pedometerreading.dart';

extension IKeyValuePairPedometerStepKindHelper<K, V> on IKeyValuePair<K, V> {
  PedometerStepKind get keyAsPedometerStepKind {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return PedometerStepKind.from(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  PedometerReading get valueAsPedometerReading {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return PedometerReading.fromRawPointer(retValuePtr);
  }
}

extension IMapPedometerStepKindHelper<K, V> on IMap<K, V> {
  PedometerReading lookupByPedometerStepKind(PedometerStepKind key) =>
      _lookupByPedometerStepKind(ptr, key);

  bool hasKeyByPedometerStepKind(PedometerStepKind value) =>
      _hasKeyByPedometerStepKind(ptr, value);

  bool insertByPedometerStepKind(
      PedometerStepKind key, Pointer<COMObject> value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Int32, COMObject, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int, COMObject, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, key.value, value.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  void removeByPedometerStepKind(PedometerStepKind key) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Int32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, key.value);

    if (FAILED(hr)) throw WindowsException(hr);
  }
}

extension IMapViewPedometerStepKindHelper<K, V> on IMapView<K, V> {
  PedometerReading lookupByPedometerStepKind(PedometerStepKind key) =>
      _lookupByPedometerStepKind(ptr, key);

  bool hasKeyByPedometerStepKind(PedometerStepKind value) =>
      _hasKeyByPedometerStepKind(ptr, value);
}

PedometerReading _lookupByPedometerStepKind(
    Pointer<COMObject> ptr, PedometerStepKind key) {
  final retValuePtr = calloc<COMObject>();

  final hr = ptr.ref.lpVtbl.value
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(Pointer, Int32, Pointer<COMObject>)>>>()
          .value
          .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
      ptr.ref.lpVtbl, key.value, retValuePtr);

  if (FAILED(hr)) throw WindowsException(hr);

  return PedometerReading.fromRawPointer(retValuePtr);
}

bool _hasKeyByPedometerStepKind(
    Pointer<COMObject> ptr, PedometerStepKind value) {
  final retValuePtr = calloc<Bool>();

  try {
    final hr = ptr.ref.lpVtbl.value
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Int32, Pointer<Bool>)>>>()
            .value
            .asFunction<int Function(Pointer, int, Pointer<Bool>)>()(
        ptr.ref.lpVtbl, value.value, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr.value;
  } finally {
    free(retValuePtr);
  }
}
