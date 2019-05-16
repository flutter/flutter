// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs
// ignore_for_file: avoid_unused_constructor_parameters
import 'dart:async';
import 'dart:html' as html; // ignore: uri_does_not_exist

import 'core_stub.dart' as core;
import 'platform.dart';

TargetPlatform get defaultTargetPlatform {
  TargetPlatform result;
  // The existence of this method is tested via the dart2js compile test.
  final String userAgent = html.window.navigator.userAgent;
  if (userAgent.contains('iPhone')
    || userAgent.contains('iPad')
    || userAgent.contains('iPod')) {
    result = TargetPlatform.iOS;
  } else {
    result = TargetPlatform.android;
  }
  if (debugDefaultTargetPlatformOverride != null)
    result = debugDefaultTargetPlatformOverride;
  return result;
}

const int kMaxUnsignedSMI = 0;

class BitField<T extends dynamic> implements core.BitField<T> {
  BitField(int length);

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

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message, { String debugLabel }) async {
  await null;
  return callback(message);
}
