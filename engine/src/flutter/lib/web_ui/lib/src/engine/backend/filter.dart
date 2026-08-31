// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

/// The backend delegate for a ColorFilter.
abstract class BackendColorFilter {
  /// Disposes the native resources held by this filter.
  void dispose();
}

/// The backend delegate for a MaskFilter.
abstract class BackendMaskFilter {
  /// Disposes the native resources held by this filter.
  void dispose();
}

/// The backend delegate for an ImageFilter.
abstract class BackendImageFilter {
  /// Disposes the native resources held by this filter.
  void dispose();

  /// Returns the bounds of the output of applying this filter to [inputBounds].
  ui.Rect filterBounds(ui.Rect inputBounds);
}
