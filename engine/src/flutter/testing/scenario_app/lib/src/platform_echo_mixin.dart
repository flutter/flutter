// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:typed_data';
import 'dart:ui';

import 'scenario.dart';

mixin PlatformEchoMixin on Scenario {
  @override
  void onPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  ) {
    window.sendPlatformMessage(name, data, null);
  }
}
