// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:web/web.dart' as web;

/// Toggles the `pointer-events` CSS property on all `iframe` elements in the document.
///
/// On Flutter Web, platform views (like WebViews/iframes) reside in their own HTML
/// DOM trees above the WebGL canvas. This means they capture native mouse events
/// and prevent them from reaching the parent window, causing the resize drag
/// interaction to lose focus if the cursor passes over the iframe.
///
/// Setting `pointer-events: none` on the iframe DOM elements during a drag
/// operation bypasses this issue, causing the browser to ignore the iframe and
/// deliver all mouse movements to the parent window where the splitter's drag
/// listener can continue smoothly.
void toggleIframePointerEvents(bool disable) {
  final iframes = web.document.querySelectorAll('iframe');
  for (int i = 0; i < iframes.length; i++) {
    final iframe = iframes.item(i) as web.HTMLElement;
    iframe.style.pointerEvents = disable ? 'none' : '';
  }
}

web.HTMLIFrameElement? _testIframe;

/// Appends a test iframe to the document.
void debugAppendTestIframe() {
  _testIframe = web.HTMLIFrameElement();
  web.document.body!.appendChild(_testIframe!);
}

/// Gets the pointer-events style of the test iframe.
String? debugGetIframePointerEvents() {
  return _testIframe?.style.pointerEvents;
}

/// Removes the test iframe.
void debugRemoveTestIframe() {
  _testIframe?.remove();
  _testIframe = null;
}
