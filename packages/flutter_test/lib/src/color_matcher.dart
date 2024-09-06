// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import '../flutter_test.dart' show Description, Matcher;

/// Positive result if the colors would be mapped to the same argb8888 color.
class _ColorMatcher extends Matcher {
  _ColorMatcher(this._target, this._threshold);

  final ui.Color _target;
  final double _threshold;

  @override
  Description describe(Description description) {
    return description.add('matches "$_target" with threshold "$_threshold".');
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is ui.Color) {
      return item.colorSpace == _target.colorSpace &&
          (item.a - _target.a).abs() <= _threshold &&
          (item.r - _target.r).abs() <= _threshold &&
          (item.g - _target.g).abs() <= _threshold &&
          (item.b - _target.b).abs() <= _threshold;
    } else {
      return false;
    }
  }

}

/// Results in a positive match if compared against an instance of a Color in
/// the same [ui.ColorSpace] as [color] and all the color components do not
/// differ from [color]'s by more than the [threshold].
Matcher matchesColor(ui.Color color, {double threshold = 0.004}) {
  return _ColorMatcher(color, threshold);
}
