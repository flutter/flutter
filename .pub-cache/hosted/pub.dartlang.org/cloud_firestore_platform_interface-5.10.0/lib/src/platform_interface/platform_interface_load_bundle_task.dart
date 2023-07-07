// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface a load bundle task must implement.
abstract class LoadBundleTaskPlatform<T> extends PlatformInterface {
  /// Create a [LoadBundleTaskPlatform]
  LoadBundleTaskPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [LoadBundleTaskPlatform].
  ///
  /// This is used by the app-facing [LoadBundleTask] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static void verify(LoadBundleTaskPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  Stream<T> get stream;
}
