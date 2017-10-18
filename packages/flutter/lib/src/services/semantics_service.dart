// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'system_channels.dart';

/// Allows access to the semantic feedback interface on the device.
class SemanticsService {
  SemanticsService._();

  /// Sends a semantic announcement.
  ///
  /// Can be used for on-demand accessibility announcements.
  static Future<Null> announce(String message) async {
    final Map<String, dynamic> event = <String, dynamic>{
      'type': 'announce',
      'data': <String, String> {'message': message},
    };
    await SystemChannels.accessibility.send(event);
  }
}
