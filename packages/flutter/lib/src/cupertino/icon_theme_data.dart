// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'colors.dart';

/// An [IconThemeData] subclass that automatically resolves its [color] when retrieved
/// using [IconTheme.of].
class CupertinoIconThemeData extends IconThemeData {
  /// Called by [IconThemeData.of] to resolve [color] against the given [BuildContext].
  @override
  CupertinoIconThemeData resolve(BuildContext context) {
    final Color resolvedColor = CupertinoDynamicColor.resolve(color, context);
    return resolvedColor == color ? this : copyWith(color: resolvedColor);
  }
}
