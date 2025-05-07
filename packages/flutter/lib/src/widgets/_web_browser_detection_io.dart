// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The widget in this file is an empty mock for non-web platforms. See
// `_web_browser_detection.dart` for the web implementation.

/// A class that provides information about the current browser when on the web.
class WebBrowserDetection {
  /// Whether the current browser is webkit (Safari).
  static bool get browserIsSafari => throw UnimplementedError();
}
