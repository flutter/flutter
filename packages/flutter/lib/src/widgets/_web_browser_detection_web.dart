// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

/// A class that provides information about the current browser when on the web.
class WebBrowserDetection {
  /// Whether the current browser is webkit (Safari). Always returns false on non-web platforms.
  static bool get isSafari => ui_web.BrowserDetection.instance.isSafari;
}
