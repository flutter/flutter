// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'assertions.dart';
import 'core_stub.dart' as core;
import 'platform.dart';

///
TargetPlatform get defaultTargetPlatform {
  TargetPlatform result = TargetPlatform.android;
  if (debugDefaultTargetPlatformOverride != null)
    result = debugDefaultTargetPlatformOverride;
  if (result == null) {
    throw FlutterError(
      'Unknown platform.\n'
      'Platform was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.'
    );
  }
  return result;
}

///
const int kMaxUnsignedSMI = 0;

///
class BitField<T extends dynamic> implements core.BitField<T> {
  ///
  // ignore: avoid_unused_constructor_parameters
  BitField(int length);

  ///
  // ignore: avoid_unused_constructor_parameters
  BitField.filled(int length, bool value);

  @override
  bool operator [](T index) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  @override
  void operator []=(T index, bool value) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }

  @override
  void reset([ bool value = false ]) {
    throw UnsupportedError('Not supported when compiling to JavaScript');
  }
}

///
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

///
Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message, { String debugLabel }) async {
  await null;
  return callback(message);
}
