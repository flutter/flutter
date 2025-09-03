// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The class in this file is an implementation for non-web platforms that will always
// return false. See `_web_browser_detection.dart` for the web implementation.

/// A class that provides information about the current browser when on the web.
class WebBrowserDetection {
  /// Whether the current browser is webkit (Safari). Always returns false on non-web platforms.
  static bool get isSafari => false;
}
