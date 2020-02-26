// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

class SystemGestures {
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
    @required double devicePixelRatio,
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

  static Future<List<Rect>> getSystemGestureExclusionRects({
    @required double devicePixelRatio,
  }) async {
    assert(devicePixelRatio != null);

    try {
      final List<dynamic> rects = await SystemChannels.platform.invokeMethod(
        'SystemGestures.getSystemGestureExclusionRects',
      );
      return _convertToListOfRects(
        rects: rects,
        devicePixelRatio: devicePixelRatio,
      );
    } on Exception catch (error) {
      throw 'Failed to set systemGestureExclusionRects: $error';
    }
  }

  static List<Rect> _convertToListOfRects({
    List<dynamic> rects,
    @required double devicePixelRatio,
  }) {
    assert(devicePixelRatio != null);

    return rects.map((dynamic rect) {
      final Map<String, dynamic> exclusionMap = rect as Map<String, dynamic>;
      final double left = (exclusionMap['left'] as int).toDouble() / devicePixelRatio;
      final double top = (exclusionMap['top'] as int).toDouble() / devicePixelRatio;
      final double right = (exclusionMap['right'] as int).toDouble() / devicePixelRatio;
      final double bottom = (exclusionMap['bottom'] as int).toDouble() / devicePixelRatio;

      return Rect.fromLTRB(left, top, right, bottom);
    }).toList();
  }
}
