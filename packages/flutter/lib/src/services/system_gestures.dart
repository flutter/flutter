// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Provides access to Android APIs involving system gestures.
///
/// Starting from Android 10, Android users can enable system gesture
/// navigation, reserving the edges of the device's screen
/// for system level gestures. These APIs provide a way to resolve
/// gesture conflicts and receive system gesture information from the
/// device.
class SystemGestures {
  /// Sets system gesture exclusion rectangles for Android devices.
  ///
  /// Sets a list of [Rect]s within the application where the system should not
  /// intercept touch or other pointing device gestures. A sample use-case for
  /// this API is an image editing app with drag handles to crop an image. A
  /// developer may want to set exclusion rects where the drag handles are if
  /// they get too close to the edges of the screen.
  ///
  /// The system also puts a limit of 200 pixels on the vertical extent of the
  /// exclusions it takes into account on each edge. For example, if 400
  /// vertical pixels were requested from the left edge of the screen, only
  /// the top 200 pixels will be excluded, while the bottom 200 pixels will
  /// continue to be reserved for system level gestures.
  ///
  /// While this gesture exclusions API can fix gesture conflicts for some
  /// applications, it is better to avoid using this API if possible. Using
  /// this API can cause confusion for users who expect a swipe from the
  /// edge of the screen to perform a system action. Hence, this API is meant
  /// to be an escape hatch there is no alternative.
  ///
  /// To clear the system gesture exclusion rects, call this function with
  /// [rects] set to null.
  ///
  /// The [devicePixelRatio] must not be null, and is typically received by
  /// calling MediaQuery.of(context).devicePixelRatio.
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
      throw 'Failed to set system gesture exclusion rects: $error';
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

  /// Gets system gesture exclusion rectangles for Android devices.
  ///
  /// Receives a list of [Rect]s within the application where the system will
  /// not intercept touch or other pointing device gestures. It returns an
  /// empty list if no system gesture exclusion rects have been set.
  ///
  /// The [devicePixelRatio] must not be null, and is typically received by
  /// calling MediaQuery.of(context).devicePixelRatio.
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
      throw 'Failed to get system gesture exclusion rects: $error';
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
