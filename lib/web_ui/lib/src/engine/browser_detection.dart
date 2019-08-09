// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// The HTML engine used by the current browser.
enum BrowserEngine {
  /// The engine that powers Chrome, Samsung Internet Browser, UC Browser,
  /// Microsoft Edge, Opera, and others.
  blink,

  /// The engine that powers Safari.
  webkit,

  /// We were unable to detect the current browser engine.
  unknown,
}

/// Lazily initialized current browser engine.
BrowserEngine _browserEngine;

/// Returns the [BrowserEngine] used by the current browser.
///
/// This is used to implement browser-specific behavior.
BrowserEngine get browserEngine => _browserEngine ??= _detectBrowserEngine();

BrowserEngine _detectBrowserEngine() {
  final String vendor = html.window.navigator.vendor;
  if (vendor == 'Google Inc.') {
    return BrowserEngine.blink;
  } else if (vendor == 'Apple Computer, Inc.') {
    return BrowserEngine.webkit;
  }

  // Assume blink otherwise, but issue a warning.
  print('WARNING: failed to detect current browser engine.');

  return BrowserEngine.unknown;
}
