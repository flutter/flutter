// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Controls specific aspects of the system navigation stack.
class SystemNavigator {
  SystemNavigator._();

  /// Instructs the system navigator to remove this activity from the stack and
  /// return to the previous activity.
  ///
  /// Platform Specific Notes:
  ///
  ///   On iOS, this is a no-op because Apple's human interface guidelines state
  ///   that applications should not exit themselves.
  static Future<Null> pop() async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'SystemNavigator.pop',
      'args': const <Null>[],
    });
  }
}
