// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:native_driver/src/backend/android.dart';

/// A stub of [Adb] that allows overriding its methods.
///
/// The default implementation of each method is a simple success case.
final class FakeAdb implements Adb {
  FakeAdb({
    Future<(bool, String?)> Function()? isDeviceConnected,
    Future<Uint8List> Function()? screencap,
    Future<void> Function(int x, int y)? tap,
    Future<void> Function()? disableImmersiveModeConfirmations,
    Future<void> Function()? disableAnimations,
  })  : _isDeviceConnected = isDeviceConnected,
        _screencap = screencap,
        _tap = tap,
        _disableImmersiveModeConfirmations = disableImmersiveModeConfirmations,
        _disableAnimations = disableAnimations;

  @override
  Future<(bool, String?)> isDeviceConnected() async {
    return _isDeviceConnected?.call() ?? (true, null);
  }

  final Future<(bool, String?)> Function()? _isDeviceConnected;

  @override
  Future<Uint8List> screencap() {
    return _screencap?.call() ?? Future<Uint8List>.value(Uint8List(0));
  }

  final Future<Uint8List> Function()? _screencap;

  @override
  Future<void> tap(int x, int y) async {
    return _tap?.call(x, y) ?? Future<void>.value();
  }

  final Future<void> Function(int x, int y)? _tap;

  @override
  Future<void> disableImmersiveModeConfirmations() {
    return _disableImmersiveModeConfirmations?.call() ?? Future<void>.value();
  }

  final Future<void> Function()? _disableImmersiveModeConfirmations;

  @override
  Future<void> disableAnimations() {
    return _disableAnimations?.call() ?? Future<void>.value();
  }

  final Future<void> Function()? _disableAnimations;
}
