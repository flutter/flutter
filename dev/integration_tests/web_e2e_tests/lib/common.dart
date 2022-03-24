// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:flutter_test/flutter_test.dart';

/// Whether the current browser is Firefox.
bool get isFirefox => window.navigator.userAgent.toLowerCase().contains('firefox');

/// Finds elements in the DOM tree rendered by the Flutter Web engine.
///
/// If the browser supports shadow DOM, looks in the shadow root under the
/// `<flt-glass-pane>` element. Otherwise, looks under `<flt-glass-pane>`
/// without penetrating the shadow DOM. In the latter case, if the application
/// creates platform views, this will also find platform view elements.
List<Node> findElements(String selector) {
  final Element? glassPane = document.querySelector('flt-glass-pane');
  if (glassPane == null) {
    fail(
      'Failed to locate <flt-glass-pane>. Possible reasons:\n'
      ' - The application failed to start'
      ' - `findElements` was called before the application started'
    );
  }

  final ShadowRoot? shadowRoot = glassPane.shadowRoot;
  return shadowRoot != null
    ? shadowRoot.querySelectorAll(selector)
    : glassPane.querySelectorAll(selector);
}
