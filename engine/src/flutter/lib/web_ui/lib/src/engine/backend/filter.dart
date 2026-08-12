// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
