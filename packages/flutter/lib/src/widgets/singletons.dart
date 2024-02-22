// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'app.dart';
import 'navigator.dart';

Set<VoidCallback>? _disposeSingletonsCallbacks;

/// Registers a callback to be called by [disposeSingletons].
///
/// Invoke this function after singleton creation make `disposeSingletons`
/// to dispose the singletons.
///
/// Each callback will be called one time, even if registered multiple times.
/// The order of the callbacks is not guaranteed.
/// It is ok for a callback to dispose multiple singletons.
void registerDisposeSingletons(VoidCallback callback) {
  _disposeSingletonsCallbacks ??= <VoidCallback>{};
  _disposeSingletonsCallbacks!.add(callback);
}

/// Disposes singletons created by the Flutter package and other registered packages.
///
/// Use [registerDisposeSingletons] to register a package singletons to be disposed.
///
/// This function is called in Flutter Framework `tearDown` for:
/// - better test hermeticity
/// - compliance to memory debugging tools that verify that disposables are disposed by the end of test
///
/// Application developers can also call this function in their tests to improve test hermeticity.
///
/// The method does not dispose all singletons, only the ones that are known to
/// noticeably impact test hermeticity.
@visibleForTesting
void disposeSingletons() {
  _disposeFlutterSingletons();

  final Set<VoidCallback>? callbacks = _disposeSingletonsCallbacks;
  if (callbacks == null) {
    return;
  }

  for (final VoidCallback callback in _disposeSingletonsCallbacks!) {
    try {
      callback();
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets library',
        context: ErrorDescription('disposeSingletons while invoking a callback'),
      ));
    }
  }

  _disposeSingletonsCallbacks = null;
}

/// Disposes singletons created by the Flutter package.
///
/// The method does not dispose all singletons, only the ones that are known to
/// noticeably impact test hermeticity.
void _disposeFlutterSingletons() {
  // ignore: invalid_use_of_visible_for_testing_member, https://github.com/dart-lang/sdk/issues/41998
  Navigator.disposeSingletons();
  // ignore: invalid_use_of_visible_for_testing_member, https://github.com/dart-lang/sdk/issues/41998
  WidgetsApp.disposeSingletons();
}
