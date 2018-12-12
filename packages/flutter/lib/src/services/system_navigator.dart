// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'system_channels.dart';

/// Controls specific aspects of the system navigation stack.
class SystemNavigator {
  SystemNavigator._();

  /// Instructs the system navigator to remove this activity from the stack and
  /// return to the previous activity.
  ///
  /// On iOS, calls to this method are ignored because Apple's human interface
  /// guidelines state that applications should not exit themselves.
  ///
  /// This method should be preferred over calling `dart:io`'s [exit] method, as
  /// the latter may cause the underlying platform to act as if the application
  /// had crashed.
  static Future<void> pop() async {
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
