// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

class SystemGesture {
  static Future<void> setSystemGestureExclusionRects({
    @required List<Rect> rects,
    @required double devicePixelRatio,
  }) async {
    assert(devicePixelRatio != null);

    try {
      await SystemChannels.platform.invokeMethod<void>(
        'SystemGestures.setSystemGestureExclusionRects',
        _convertToListOfMaps(
          rects: rects,
          devicePixelRatio: devicePixelRatio
        ),
      );
    } on Exception catch (error) {
      throw 'Failed to set systemGestureExclusionRects: $error';
    }
  }

  static List<Map<String, int>> _convertToListOfMaps({
    List<Rect> rects,
    double devicePixelRatio = 1.0,
  }) {
    assert(devicePixelRatio != null);

    if (rects != null && rects.isNotEmpty) {
      return rects.map<Map<String,int>>((Rect rect) {
        return <String, int>{
          'left': (rect.left * devicePixelRatio).toInt(),
          'top': (rect.top * devicePixelRatio).toInt(),
          'right': (rect.right * devicePixelRatio).toInt(),
          'bottom': (rect.bottom * devicePixelRatio).toInt(),
        };
      }).toList();
    }
    return <Map<String, int>>[];
  }
}