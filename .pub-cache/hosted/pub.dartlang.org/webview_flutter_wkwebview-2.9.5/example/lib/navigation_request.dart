// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Information about a navigation action that is about to be executed.
class NavigationRequest {
  NavigationRequest._({required this.url, required this.isForMainFrame});

  /// The URL that will be loaded if the navigation is executed.
  final String url;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() {
    return 'NavigationRequest(url: $url, isForMainFrame: $isForMainFrame)';
  }
}
