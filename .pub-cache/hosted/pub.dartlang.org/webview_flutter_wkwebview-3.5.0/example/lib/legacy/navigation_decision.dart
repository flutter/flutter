// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A decision on how to handle a navigation request.
enum NavigationDecision {
  /// Prevent the navigation from taking place.
  prevent,

  /// Allow the navigation to take place.
  navigate,
}
