// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

/// Dispatch an event to signal to the service worker binding that registration
/// is safe.
void dispatchFirstFrame(Duration timeStamp) {
  html.window.dispatchEvent(html.Event('flutter-first-frame'));
}
